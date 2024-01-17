#!/bin/bash

# Path to your docker-compose.yml and initdb.sql file
DOCKER_COMPOSE_FILE="docker-compose.yml"
INITDB_SQL_FILE="./init/initdb.sql"
ENV_FILE=".env"

# Function to prompt for input with a default value
prompt_for_input() {
    read -p "$1 ($2): " value
    echo ${value:-$2}
}

# Function to generate a safe password
generate_safe_password() {
    tr -dc 'A-Za-z0-9_-' < /dev/urandom | head -c 16
}

 # Automatically generate passwords
    POSTGRES_PASSWORD=$(generate_safe_password)
    GUACADMIN_PASSWORD=$(generate_safe_password)

# Check if .env file exists
if [ ! -f "$ENV_FILE" ]; then
    echo ".env file not found, creating one..."

    # Prompt for required settings
    LDAP_HOSTNAME=$(prompt_for_input "Enter LDAP_HOSTNAME" "10.0.1.10")
    LDAP_USER_BASE_DN=$(prompt_for_input "Enter LDAP_USER_BASE_DN" "DC=example,DC=com")
    LDAP_SEARCH_BIND_DN=$(prompt_for_input "Enter LDAP_SEARCH_BIND_DN" "CN=user,CN=Users,DC=example,DC=com")
    LDAP_SEARCH_BIND_PASSWORD=$(prompt_for_input "Enter LDAP_SEARCH_BIND_PASSWORD" "Password")
    LDAP_USERNAME_ATTRIBUTE=$(prompt_for_input "Enter LDAP_USERNAME_ATTRIBUTE" "sAMAccountName")
    LDAP_GROUP_BASE_DN=$(prompt_for_input "Enter LDAP_GROUP_BASE_DN" "OU=Groups,DC=example,DC=com")
    LDAP_USER_SEARCH_FILTER=$(prompt_for_input "Enter Base DN for AD Group" "CN=Guacamole-Users,OU=Groups,DC=example,DC=com")

    # Write settings to .env file
    {
        echo "POSTGRES_PASSWORD=${POSTGRES_PASSWORD}"
        echo "POSTGRES_USER=guacamole_user"
	echo "GUACADMIN_PASSWORD=${GUACADMIN_PASSWORD}"
        echo "LDAP_HOSTNAME=${LDAP_HOSTNAME}"
        echo "LDAP_USER_BASE_DN=${LDAP_USER_BASE_DN}"
        echo "LDAP_SEARCH_BIND_DN=${LDAP_SEARCH_BIND_DN}"
        echo "LDAP_SEARCH_BIND_PASSWORD=${LDAP_SEARCH_BIND_PASSWORD}"
        echo "LDAP_USERNAME_ATTRIBUTE=${LDAP_USERNAME_ATTRIBUTE}"
        echo "LDAP_GROUP_BASE_DN=${LDAP_GROUP_BASE_DN}"
        echo "POSTGRESQL_AUTO_CREATE_ACCOUNTS=true"
        echo "LDAP_USER_SEARCH_FILTER=(|(memberOf=${LDAP_USER_SEARCH_FILTER}))"
    } > $ENV_FILE

    echo ".env file created."
else
    echo ".env file already exists, using existing file."
fi

# Run reset.sh script
echo "Running reset.sh..."
echo "y" | sudo ./reset.sh

# Run prepare.sh script
echo "preparing Database and Folders"
#!/bin/sh
#
# check if docker is running
if ! (docker ps >/dev/null 2>&1)
then
	echo "docker daemon not running, will exit here!"
	exit
fi
echo "Preparing folder init and creating ./init/initdb.sql"
mkdir ./init >/dev/null 2>&1
mkdir -p ./nginx/ssl >/dev/null 2>&1
chmod -R +x ./init
docker run --rm guacamole/guacamole /opt/guacamole/bin/initdb.sh --postgresql > ./init/initdb.sql
echo "done"
echo "Creating SSL certificates"
openssl req -nodes -newkey rsa:2048 -new -x509 -keyout nginx/ssl/self-ssl.key -out nginx/ssl/self.cert -subj '/C=DE/ST=BY/L=Hintertupfing/O=Dorfwirt/OU=Theke/CN=www.createyourown.domain/emailAddress=docker@createyourown.domain'
echo "You can use your own certificates by placing the private key in nginx/ssl/self-ssl.key and the cert in nginx/ssl/self.cert"
echo "done"

# Stop the current Docker Compose deployment
echo "Stopping current Docker Compose deployment..."
docker-compose -f "$DOCKER_COMPOSE_FILE" down

# Deploy the updated Docker Compose configuration
echo "Deploying updated Docker Compose configuration..."
docker-compose -f "$DOCKER_COMPOSE_FILE" up -d

sudo chown -R 1000:1001 ./record/
sudo chmod -R 2750 ./record/

# Print all generated credentials
echo "Generated Credentials:"
echo "POSTGRES_PASSWORD: ${credentials[POSTGRES_PASSWORD]}"
echo "GUACADMIN_PASSWORD: ${credentials[GUACADMIN_PASSWORD]}"

done
