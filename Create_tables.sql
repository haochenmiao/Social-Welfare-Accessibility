-- Connect to the Azure PostgreSQL server using psql command line tool. Replace placeholders with your actual server details.
psql --host=#####.postgres.database.azure.com --port=5432 --username=##### --dbname=postgres

-- Create a new database named 'myspatialdb' to store our GIS data.
CREATE DATABASE myspatialdb;

-- List all available extensions in PostgreSQL to verify the availability of PostGIS, which is essential for geospatial data.
SELECT * FROM pg_available_extensions;

-- Enable PostGIS extension in Azure Cloud Shell to allow for geospatial data storage and queries within our newly created database.
CREATE EXTENSION postgis;


-- Ensure the PostGIS extension is enabled in the database in QGIS DB MNger, allowing for spatial queries and data types.
CREATE EXTENSION postgis;

-- Create schemas to organize the database into logical groups, improving data management and access control.
CREATE SCHEMA boundaries;
CREATE SCHEMA maps;
CREATE SCHEMA parks_and_rec;
CREATE SCHEMA services;


-- Create a 'read_only' role for users who should only view data without making changes.
CREATE ROLE read_only WITH 
NOLOGIN 
OSUPERUSER 
INHERIT 
NOCREATEDB 
NOCREATEROLE 
NOREPLICATION;

-- Create an 'editor' role for users who are allowed to edit data within the database.
CREATE ROLE editor WITH 
NOLOGIN 
NOSUPERUSER 
INHERIT 
NOCREATEROLE 
NOREPLICATION;

-- Grant the 'read_only' and 'editor' roles permission to connect to the 'myspatialdb' database.
GRANT CONNECT ON DATABASE myspatialdb TO read_only;
GRANT CONNECT ON DATABASE myspatialdb TO editor;

-- Create two users, 'haochen' and 'miao', assigning them passwords and roles with specific privileges.
CREATE USER haochen WITH 
LOGIN 
NOSUPERUSER 
NOCREATEDB 
NOCREATEROLE 
INHERIT 
NOREPLICATION 
CONNECTION LIMIT -1 
PASSWORD 'test1234';

GRANT read_only TO haochen;

CREATE USER miao WITH 
LOGIN 
NOSUPERUSER 
NOCREATEDB 
NOCREATEROLE 
INHERIT 
NOREPLICATION 
CONNECTION LIMIT -1 PASSWORD 'test5678';

GRANT read_only TO miao;
GRANT editor TO miao;


-- Grant 'read_only' role usage on schemas, enabling them to view data in specified schemas.
GRANT USAGE ON SCHEMA boundaries TO read_only;
GRANT USAGE ON SCHEMA maps TO read_only;
GRANT USAGE ON SCHEMA parks_and_rec TO read_only;
GRANT USAGE ON SCHEMA services TO read_only;

-- Grant 'read_only' permission to select (view) data in specific tables, controlling data access.
GRANT SELECT ON TABLE boundaries.kc2010_censustracts TO read_only;
GRANT SELECT ON TABLE parks_and_rec.park3 TO read_only;
GRANT SELECT ON TABLE services.fire_stations TO read_only;
GRANT SELECT ON TABLE services.hospitals TO read_only;
GRANT SELECT ON TABLE services.police TO read_only;

-- Grant 'editor' role permissions to edit the 'park3' table, allowing for data modifications.
GRANT ALL ON SEQUENCE parks_and_rec.park_id_seq TO editor;
GRANT ALL ON TABLE parks_and_rec.park3 TO editor;

-- if park3 does not exist, run below code and run GRANT code again
ALTER TABLE parks_and_rec.park3
DROP COLUMN id, 
ADD COLUMN id serial;

-- set column id as primary key

ALTER TABLE parks_and_rec.park3
    ADD CONSTRAINT park3_pk PRIMARY KEY (id);


-- Modify the 'park3' table structure, adding new columns for geospatial analysis and metadata.
ALTER TABLE parks_and_rec.park3 ADD COLUMN area_sqm numeric;
ALTER TABLE parks_and_rec.park3 ADD COLUMN census_tracts varchar;
ALTER TABLE parks_and_rec.park3 ADD COLUMN nearest_police_station varchar;
ALTER TABLE parks_and_rec.park3 ADD COLUMN nearest_police_station_distance_m numeric;
ALTER TABLE parks_and_rec.park3 ADD COLUMN nearest_hospital varchar;
ALTER TABLE parks_and_rec.park3 ADD COLUMN nearest_hospital_distance_m numeric;
ALTER TABLE parks_and_rec.park3 ADD COLUMN nearest_fire_station varchar;
ALTER TABLE parks_and_rec.park3 ADD COLUMN nearest_fire_station_distance_m numeric;
ALTER TABLE parks_and_rec.park3 ADD COLUMN data_created timestamp with time zone DEFAULT now();
ALTER TABLE parks_and_rec.park3 ADD COLUMN created_by varchar DEFAULT "current_user"();
ALTER TABLE parks_and_rec.park3 ADD COLUMN date_modified timestamp with time zone;
ALTER TABLE parks_and_rec.park3 ADD COLUMN modified_by varchar;
ALTER TABLE parks_and_rec.park3 ADD COLUMN status integer DEFAULT 1;

-- Create a trigger function to automatically update fields in 'park3' table when a row is added or modified.
--create a function to be executed whenever a row is added or modified
CREATE FUNCTION parks_and_rec.park_trigger_function()
RETURNS trigger
AS $$
BEGIN

            NEW.area_sqm = round(st_area(ST_TRANSFORM(NEW.geom, 26911))::numeric,2);  
            NEW.census_tracts = (SELECT a.tract_lbl
                        from boundaries.kc2010_censustracts a
                        WHERE st_intersects(a.geom,st_centroid(NEW.geom)));

            NEW.nearest_police_station = (
                  WITH nearest_location AS (
                  SELECT b.name, min(st_distance(NEW.geom,b.geom)) as min_distance
                  FROM services.police b
                  GROUP BY b.name
                  ORDER BY min_distance
                  LIMIT 1)
                  SELECT name from nearest_location);
                 
            NEW.nearest_police_station_distance_m = (
                  SELECT round(min(st_distance(NEW.geom,b.geom))::numeric,2) as min_distance
                  FROM services.police b
                  ORDER BY min_distance
                  LIMIT 1);

            NEW.nearest_hospital = (
                  WITH nearest_location AS (
                  SELECT b.name, min(st_distance(NEW.geom,b.geom)) as min_distance
                  FROM services.hospitals b
                  GROUP BY b.name
                  ORDER BY min_distance
                  LIMIT 1)
                  SELECT name from nearest_location);

            NEW.nearest_hospital_distance_m = (
                  SELECT round(min(st_distance(NEW.geom,b.geom))::numeric,2) as min_distance
                  FROM services.hospitals b
                  ORDER BY min_distance
                  LIMIT 1);      

           NEW.nearest_fire_station = (
                  WITH nearest_location AS (
                  SELECT b.name, min(st_Distance(NEW.geom,b.geom)) as min_distance
                  FROM services.fire_stations b
                  GROUP BY b.name
                  ORDER BY min_distance
                  LIMIT 1)
                  SELECT name from nearest_location);

          NEW.nearest_fire_station_distance_m = (
                  SELECT round(min(st_distance(NEW.geom,b.geom))::numeric,2) as min_distance
                  FROM services.fire_stations b
                  ORDER BY min_distance
                  LIMIT 1);  

          NEW.date_modified = now();

          NEW.modified_by = "current_user"();

Return NEW;
END;

$$ language plpgsql

-- Attach the trigger to the 'park3' table, specifying it should run before any insert or update operation.
CREATE TRIGGER park_trigger 
    BEFORE INSERT OR UPDATE 
    ON parks_and_rec.park 
    FOR EACH ROW 
    EXECUTE PROCEDURE parks_and_rec.park_trigger_function();


-- Reset the 'area_sqm' column for existing records in 'park3' table to trigger automatic calculations.
UPDATE parks_and_rec.park3 SET area_sqm = 0;

-- Azure Cloud Shell command to list all roles and their permissions in the database, useful for verifying user setup.
\du
