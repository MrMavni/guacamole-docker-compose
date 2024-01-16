#!/bin/bash

# Path to your docker-compose.yml and initdb.sql file
DOCKER_COMPOSE_FILE="docker-compose.yml"
INITDB_SQL_FILE="./init/initdb.sql"

# Function to generate a safe password
generate_safe_password() {
    tr -dc 'A-Za-z0-9_-' < /dev/urandom | head -c 16
}

# Function to generate password hash and salt
generate_hash_and_salt() {
    local password=$1
    local salt=$(openssl rand -hex 32)
    local hash=$(echo -n "$password$salt" | openssl dgst -sha256 -binary | openssl enc -base64)
    echo "$hash $salt"
}

# Declare associative array for credentials
declare -A credentials

# Function to update the password in the docker-compose file
update_password() {
    local env_var=$1
    local new_pass=$(generate_safe_password)

    # Store new password in credentials array
    credentials[$env_var]=$new_pass

    # Update the password in the docker-compose file
    #sed -i "s/${env_var}: '.*'/${env_var}: '${new_pass}'/" "$DOCKER_COMPOSE_FILE"
    export GUACADMIN_PASSWORD=${credentials[GUACADMIN_PASSWORD]}
}

# Function to update the guacadmin password in the initdb.sql file
update_guacadmin_password() {
    local new_pass=$(generate_safe_password)
    local hash_salt=($(generate_hash_and_salt "$new_pass"))

    # Store new password in credentials array
    credentials["GUACADMIN_PASSWORD"]=$new_pass

    # Update the guacadmin password in the initdb.sql file
    #sed -i "s/('guacadmin'.*decode(').*(', 'hex'),  -- 'guacadmin'/('guacadmin', decode('${hash_salt[0]}', 'base64'), decode('${hash_salt[1]}', 'hex'), CURRENT_TIMESTAMP)/" "$INITDB_SQL_FILE"
    export POSTGRES_PASSWORD=${credentials[POSTGRES_PASSWORD]}
    }

# Run reset.sh script
echo "Running reset.sh..."
echo "y" | sudo ./reset.sh

# Update passwords
update_password "POSTGRES_PASSWORD"
update_guacadmin_password

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
for key in "${!credentials[@]}"; do
    echo "$key: ${credentials[$key]}"
done
