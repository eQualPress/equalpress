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

if [ -z "$USERNAME" ]
then
    print_color "bgred" "A file named .env is expected and should contain following vars definition:"
    print_color "bgred" "USERNAME={domain-name-as-user-name}"
    print_color "bgred" "APP_USERNAME={user-login}"
    print_color "bgred" "APP_PASSWORD={user-password}"
    print_color "bgred" "WP_VERSION={WordPress version}"
    print_color "bgred" "WP_EMAIL={WordPress admin email}"
    print_color "bgred" "WP_TITLE={WordPress site title}"
    print_color "bgred" "DB_HOSTNAME={Database hostname}"
    print_color "bgred" "EQ_PORT={Equal Port}"
else
    cd /home/"$USERNAME"/www || exit

    # Replace the .htaccess file
    print_color "yellow" "Downloading and replacing the .htaccess file..."
    docker exec "$USERNAME" bash -c "
    rm public/.htaccess
    wget https://raw.githubusercontent.com/eQualPress/equalpress/main/files/public/.htaccess -O public/.htaccess
    "

    print_color "yellow" "Renaming public/index.php to public/equal.php to avoid conflicts with WordPress..."
    docker exec "$USERNAME" bash -c "
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
    docker exec "$USERNAME" bash -c "
    curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
    chmod +x wp-cli.phar
    php wp-cli.phar core download --path='public/' --locale='en_US' --version=$WP_VERSION --allow-root
    php wp-cli.phar config create --path='public/' --dbname=equal --dbuser=$APP_USERNAME --dbpass=$APP_PASSWORD --dbhost=$DB_HOSTNAME --allow-root
    mkdir -p public/wp-content/uploads
    php wp-cli.phar core install --path='public/' --url=$USERNAME:$EQ_PORT --title=$WP_TITLE --admin_user=$APP_USERNAME --admin_password=$APP_PASSWORD --admin_email=$WP_EMAIL --skip-email --allow-root
    chown -R www-data:www-data .
    "

    print_color "green" "Cloning wordpress package..."
    docker exec "$USERNAME" bash -c "
    cd packages
    yes | git clone --quiet https://github.com/eQualPress/package-wordpress.git wordpress
    cd ..
    sh equal.run --do=init_package --package=wordpress --import=true
    "
    
    print_color "green" "Cloning eQualPress plugins..."
    docker exec "$USERNAME" bash -c "
    cd public/wp-content/plugins
    yes | git clone --quiet https://github.com/eQualPress/eq-run.git eq-run
    yes | git clone --quiet https://github.com/eQualPress/eq-menu.git eq-menu
    yes | git clone --quiet https://github.com/eQualPress/eq-auth.git eq-auth
    cd ../../../
    php wp-cli.phar plugin activate eq-run eq-menu eq-auth --path='public/' --allow-root
    "

    print_color "magenta" "Script setup completed successfully!"

    print_color "yellow" "Testing the instance..."
    wget -qO- http://"$USERNAME":$EQ_PORT | grep -q "$WP_TITLE"

    # shellcheck disable=SC2181
    if [ $? -eq 0 ]; then
      print_color "bggreen" "Instance Wordpress OK"
    else
      print_color "bgred" "Instance Wordpress ERROR"
    fi
fi
