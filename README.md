# Social Welfare Accessibility Project

## Overview

This project aims to analyze and visualize the accessibility of social welfare services using cloud technologies and geographical information systems (GIS). It utilizes Azure PostgreSQL for database management and integrates with QGIS for spatial data analysis, providing an interactive web interface for exploring social welfare accessibility.

## Features

- Azure PostgreSQL database setup for managing project data.
- Integration with QGIS for advanced spatial data analysis.
- An interactive web interface built with HTML, CSS, and JavaScript for data exploration.
- Data visualization tools incorporated into the web interface.

## Project Structure

- `Create_tables.sql`: SQL script for creating the necessary database tables, including Azure Cloud shell commands for Azure PostgreSQL setup.
- `index.html`: The main entry point of the web application.
- `css/`: Directory containing CSS files for styling the web application.
- `js/`: Directory containing JavaScript files for the web application logic.
- `data/`: Directory containing data files used by the project.
- `legend/`: Contains files related to the visualization legends.
- `webfonts/`: Directory for web fonts used in the project.

## Getting Started

### Prerequisites

- An Azure account with an active subscription.
- Azure PostgreSQL database instance.
- QGIS installed on your local machine for spatial data analysis.
- A web server to host the web application.

### Setup

1. **Azure PostgreSQL Database Setup:**
   - Follow the Azure documentation to create a PostgreSQL database instance.
   - Use the Azure Cloud Shell commands provided in `Create_tables.sql` to set up your database schema.

2. **Web Application Setup:**
   - Place the contents of this repository in your web server's document root.
   - Ensure the `data/`, `css/`, `js/`, `legend/`, and `webfonts/` directories are correctly placed on the server.

3. **Data Import and Connection:**
   - Import your data into the Azure PostgreSQL database.
   - For spatial data analysis, connect your Azure `myspatialdb` with QGIS by configuring the PostgreSQL connection in QGIS.

### Running the Application

After setting up the database and web application, and establishing the connection between Azure `myspatialdb` and QGIS, navigate to `index.html` through your web browser to access the application.

## Contributing

Contributions to the Social Welfare Accessibility project are welcome. Feel free to make a pull request or open an issue for feature suggestions, bug reports, or code contributions.

## License

This project is open-source and available under [MIT License](LICENSE).

