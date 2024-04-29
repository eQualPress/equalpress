# eQualPress

eQualPress is the WordPress integration of the Equal framework. It provides a set of plugins that allow you to interact
with the Equal framework from within WordPress.

Plugins provide a way to provide integration with the eQual framework for user authentication and management. It allows
users to log in to WordPress using eQual credentials and synchronizes user data between WordPress and eQual.

## Features

- **Seamless User Login:**
  Integration with eQual framework enables users to log in to WordPress using their eQual credentials, enhancing user
  experience.

- **User Data Synchronization:**
  The plugin synchronized user data between WordPress and eQual, ensuring consistency and accuracy across platforms.

- **New User Registration:**
  Automatically syncs new user registrations with eQual to maintain a unified user database.

- **Password Reset Integration:**
  Allows users to reset their passwords in WordPress, updating the changes in eQual for enhanced security.

- **Profile Update Sync:**
  Updates user profiles in eQual when changes are made in WordPress, ensuring data integrity and consistency.

- **Smooth Logout Process:**
  Clears access token cookies upon user logout from WordPress, enhancing security and privacy.

## Script explanation ``install.sh``

This script automates the setup process for eQualpress instances. It configures WordPress installation and integrates necessary plugins and configurations.

### Notes
No additional notes provided.

### Prerequisite
Ensure that the `.env` file containing required variables is properly configured before executing the script.

The script need these variables:

```env
# Customer directoy created in /home
# Linux user created with the same name
# Docker container created with the same name
USERNAME=test.yb.run

# Applications credentials used for eQual, database and eQualPress
APP_USERNAME=root
APP_PASSWORD=test

# Wordpress version
WP_VERSION=6.4

#Wordpress admin email
WP_EMAIL=root@equal.local
```

### Progress Task

1. **Checking .env File:** Verifies the existence of the `.env` file and prints variable definitions in case of absence.

2. **WordPress Setup:**
   - Replaces the `.htaccess` file to enhance security.
   - Renames `index.php` to `equal.php` to avoid conflicts with WordPress.
   - Downloads, installs, and sets up WordPress with specified configurations with ``wp-cli.phar``.
   - Clones the WordPress package and initializes it using `equal.run`.
   - Clones eQualPress plugins and activates them within WordPress.
   - Displays a success message upon completion.

3. **Testing Instance:**
   - Tests the instance by querying the WordPress site and checking for the presence of the specified title.
   - Prints a success or error message based on the test result.

### Usage

1. Upload the script ``install.sh`` in your eQual project.
2. Run the following command:

```bash
  ./install.sh
```
