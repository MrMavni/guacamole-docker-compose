# Guacamole Docker Compose Deployment
This repository provides a Docker Compose setup for deploying Apache Guacamole, a clientless remote desktop gateway. It simplifies the process of setting up Guacamole, PostgreSQL, and optional LDAP integration, with SSL support for secure connections.
This customized version includes the following features out-of-the-box:
- LDAP support with a wizard-based configuration
- MFA for every user, based on TOTP
- Automatically generated random passwords for Postgres and guacadmin
- Session recording (note required configuration below)
- File transfer disabled and clipboard limited to 1MB. 
## Prerequisites
Before you begin, ensure you have the following installed on your system:
- Docker
- Docker Compose
Install Docker from an official repository, follow these instructions:
https://docs.docker.com/engine/install/ubuntu/
## Quick Start
To quickly deploy Guacamole with Docker Compose, follow these steps:

### 1. Clone the Repository and execute the deploy.sh script to start the deployment process
~~~bash
git clone https://github.com/MrMavni/guacamole-docker-compose.git
cd guacamole-docker-compose
sudo ./deploy.sh
~~~
The script will perform the following actions:
- Check for the existence of an .env file.
- If the .env file does not exist, it will automatically generate necessary passwords and create the file.
- Automatically generate SSL certificates for secure HTTPS access.
- Deploy Guacamole using Docker Compose.
- Print generated credentials for PostgreSQL and Guacamole admin (guacadmin).
### 2. Access Guacamole

Once the deployment is complete, access Guacamole at https://your-server-ip/.
The default login credentials are:
* Username: guacadmin
* Password: (Auto-generated, printed at the end of the deployment script)

Note: The default port for accessing Guacamole is 443 (HTTPS).

## Session Recording
For session recording to work, this path should be used for each new connection
~~~bash
${HISTORY_PATH}/${HISTORY_UUID}
~~~
Also make sure to check the “Automatically create recording path” box.
See article below:
https://theko2fi.medium.com/apache-guacamole-session-recordings-and-playback-in-browser-f095fcfca387

## Customization
You can customize your deployment by modifying the .env file. This file contains various settings like database credentials and LDAP configuration (if used).

LDAP Integration (Optional yet recommended!)
If you plan to use LDAP, ensure that the LDAP-related environment variables in the .env file are correctly set. The deployment script will use these values to configure Guacamole for LDAP authentication.

## Resetting the Deployment
To reset your Guacamole deployment (which will erase the database and all configurations), re-run the deploy.sh script:
~~~bash
sudo ./deploy.sh
~~~

### Security Notes
- Always secure your deployment, especially if exposed to the internet.
- Manage your .env file securely as it contains sensitive information.

## Contributing
Contributions to this repository are welcome. Please submit pull requests or issues to the GitHub repository.
