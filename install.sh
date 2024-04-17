#!/bin/bash

# Function to print colored text
print_color() {
    local color="$1"
    local text="$2"
    case "$color" in
        "black") echo -e "\033[1;30m$text\033[0m" ;;
        "red") echo -e "\033[1;31m$text\033[0m" ;;
        "green") echo -e "\033[1;32m$text\033[0m" ;;
        "yellow") echo -e "\033[1;33m$text\033[0m" ;;
        "blue") echo -e "\033[1;34m$text\033[0m" ;;
        "magenta") echo -e "\033[1;35m$text\033[0m" ;;
        "cyan") echo -e "\033[1;36m$text\033[0m" ;;
        "white") echo -e "\033[1;37m$text\033[0m" ;;
        "bgred") echo -e "\033[1;37;41m$text\033[0m" ;;
        "bggreen") echo -e "\033[1;37;42m$text\033[0m" ;;
        *) echo "Invalid color" >&2 ;;
    esac
}

print_color "magenta" "Welcome to eQualpress setup script!"

# if .env file is missing, download it
if [ ! -f .env ]
then
    print_color "yellow" ".env file not found."
    print_color "yellow" "Downloading .env file..."
    wget https://github.com/eQualPress/equalpress/raw/main/files/.env -O .env
fi

if [ -f .env ]
then
    print_color "yellow" "Load .env file..."

    # load .env variables
    . ./.env

    if [ -z "$USERNAME" ]
    then
        print_color "bgred" "A file named .env is expected and should contain following vars definition:"
        print_color "bgred" "USERNAME={domain-name-as-user-name}"
        print_color "bgred" "PASSWORD={user-password}"
        print_color "bgred" "TEMPLATE={account-template}"
    else
        if [ ${#USERNAME} -gt 32 ]; then
          print_color "bgred" "Error: username must be max 32 chars long" ;
          exit 1;
        fi

        # shellcheck disable=SC2155
        script_dir=$(pwd)

        cd /home/"$USERNAME"/www || exit

        # Define a hash value with the first 5 characters of the md5sum of the username
        HASH_VALUE=$(printf "%.5s" "$(echo "$USERNAME" | md5sum | cut -d ' ' -f 1)")

        # Name of the database
        DB_NAME="equal"

        # Define DB_HOST with the hash value
        #DB_HOSTNAME="db_$HASH_VALUE"

        # DEVELOPPEMENT PURPOSE ONLY !!
        DB_HOSTNAME="equal_db-1"

        # Get the number of directories in /home
        # shellcheck disable=SC2010
        number_of_directories=$(ls -l /home | grep -c ^d)

        # Define DB_PORT with the number of directories in /home
        # shellcheck disable=SC2004
        DB_PORT=$(( 3306 - 1 + $number_of_directories ))

        # Define EQ_PORT with the number of directories in /home
        # shellcheck disable=SC2004
        EQ_PORT=$(( 80 - 1 + $number_of_directories ))

        # Replace the .htaccess file
        print_color "yellow" "Downloading and replacing the .htaccess file..."
        docker exec -ti "$USERNAME" bash -c "
        rm public/.htaccess
        wget -O public/.htaccess https://github.com/eQualPress/equalpress/raw/main/files/public/.htaccess
        "

        # Replace the public/assets/env/config.json file
        # Get the json file from http://$USERNAME/envinfo-temp
        # Modify backend_url value and add '/equal.php'
        print_color "yellow" "Downloading and replacing the public/assets/env/config.json file..."
        print_color "yellow" "Modifying backend_url value and adding '/equal.php'..."
        docker exec -ti "$USERNAME" bash -c "
        rm public/assets/env/config.json
        wget -O public/assets/env/config.json http://$USERNAME:$EQ_PORT/envinfo-temp
        if [ -f public/assets/env/config.json ]; then
            sed -i 's#"backend_url": *"\(.*\)"#"backend_url": "\1/equal.php"#' public/assets/env/config.json
        else
            echo \"Failed to download config.json from http://$USERNAME:$EQ_PORT/envinfo-temp\"
        fi
        "

        # Rename public/index.php to public/equal.php
        print_color "yellow" "Renaming public/index.php to public/equal.php to avoid conflicts with WordPress..."
        docker exec -ti "$USERNAME" bash -c "
        mv public/index.php public/equal.php
        "

        print_color "green" "Downloading, installing and setting up WordPress"
        # 1. Download WP-CLI
        # 2. Make the downloaded WP-CLI executable
        # 3. Create a directory for local binaries if it doesn't exist
        # 4. Move the downloaded WP-CLI to the local binaries directory
        # 5. Download WordPress core files
        # 6. Create a wp-config.php file
        # 7. Create uploads directory
        # 8. Install WordPress
        # 9. Change the owner of the files to www-data
        docker exec -ti "$USERNAME" bash -c "
        curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
        chmod +x wp-cli.phar
        php wp-cli.phar core download --path='public/' --locale='en_US' --version=$WP_VERSION --allow-root
        php wp-cli.phar config create --path='public/' --dbname=$DB_NAME --dbuser=$APP_USERNAME --dbpass=$APP_PASSWORD --dbhost=$DB_HOSTNAME --allow-root
        mkdir -p public/wp-content/uploads
        php wp-cli.phar core install --path='public/' --url=$USERNAME:$EQ_PORT --title=$WP_TITLE --admin_user=$APP_USERNAME --admin_password=$APP_PASSWORD --admin_email=$WP_EMAIL --skip-email --allow-root
        chown -R www-data:www-data .
        "

        # Clone the WordPress package for eQual
        print_color "green" "Cloning wordpress package..."
        docker exec -ti "$USERNAME" bash -c "
        cd packages
        git clone --quiet https://github.com/eQualPress/package-wordpress.git wordpress
        cd ..
        sh equal.run --do=init_package --package=wordpress
        "

        # Clone eq-run eq-menu and eq-auth plugins into public/wp-content/plugins
        print_color "green" "Cloning eQualPress plugins..."
        docker exec -ti "$USERNAME" bash -c "
        cd public/wp-content/plugins
        git clone --quiet https://github.com/eQualPress/eq-run.git eq-run
        git clone --quiet https://github.com/eQualPress/eq-menu.git eq-menu
        git clone --quiet https://github.com/eQualPress/eq-auth.git eq-auth
        cd ../../../
        php wp-cli.phar plugin activate eq-run eq-menu eq-auth --path='public/' --allow-root
        "

        print_color "magenta" "Script setup completed successfully!"

        # little test with wget
        print_color "yellow" "Testing the instance..."
        wget -qO- http://"$USERNAME":$EQ_PORT | grep -q "$WP_TITLE"

        # shellcheck disable=SC2181
        if [ $? -eq 0 ]; then
          print_color "bggreen" "Instance Wordpress OK"
        else
          print_color "bgred" "Instance Wordpress ERROR"
        fi
    fi
else
    print_color "bgred" ".env file is missing"
fi

