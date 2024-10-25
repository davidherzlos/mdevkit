# !/bin/bash

# This script is used to manage the moodle containers.

# Get the current directory of the script.
src="$(dirname "$(realpath "$0")")"

# Get the moodle-docker directory.
mdocker="$src"/moodle-docker/

# Load env variables for containers.
source "$src"/.env
moodledir="$MOODLE_DOCKER_WWWROOT"

export COMPOSE_PROJECT_NAME
export MOODLE_DOCKER_WWWROOT="$src"/"$moodledir"
export MOODLE_DOCKER_PHP_VERSION
export MOODLE_DOCKER_DB
export MOODLE_DOCKER_WEB_PORT

# Commands:
case "$1" in
  "up")
    echo "Creating and starting moodle containers"
    "$mdocker"/bin/moodle-docker-compose up -d
    ;;
  "down")
    echo "Stopping and removing moodle containers"
    "$mdocker"/bin/moodle-docker-compose down
    ;;
  "start")
    echo "Starting moodle containers"
    "$mdocker"/bin/moodle-docker-compose start
    ;;
  "stop")
    echo "Stopping moodle containers"
    "$mdocker"/bin/moodle-docker-compose stop
    ;;
  "restart")
    echo "Restarting moodle containers"
    "$mdocker"/bin/moodle-docker-compose stop
    "$mdocker"/bin/moodle-docker-compose start
    ;;
  "install_db")
    echo "Installing moodle database"
    "$mdocker"/bin/moodle-docker-compose exec webserver php admin/cli/install_database.php --adminpass=admin --agree-license --adminemail=admin@mailinator.com --fullname=DevSite --shortname=devsite
    ;;
  "upgrade")
    echo "Upgrading moodle"
    "$mdocker"/bin/moodle-docker-compose exec webserver php admin/cli/upgrade.php --non-interactive "$2"
    ;;
  "purge_caches")
    echo "Purging moodle caches"
    "$mdocker"/bin/moodle-docker-compose exec webserver php admin/cli/purge_caches.php --non-interactive
    ;;
  "cron")
    echo "Running moodle cron"
    "$mdocker"/bin/moodle-docker-compose exec webserver php admin/cli/cron.php
    ;;
  "phpunit_init")
    echo "Initialising phpunit"
    "$mdocker"/bin/moodle-docker-compose exec webserver php admin/tool/phpunit/cli/init.php
    ;;
  "phpunit_run")
    echo "Running phpunit"
    "$mdocker"/bin/moodle-docker-compose exec webserver vendor/bin/phpunit --color=always "$2" "$3"
    ;;
  "behat_init")
    echo "Initialising behat"
    "$mdocker"/bin/moodle-docker-compose exec webserver php admin/tool/behat/cli/init.php
    ;;
  "behat_run")
    echo "Running behat"
    "$mdocker"/bin/moodle-docker-compose exec webserver php admin/tool/behat/cli/run.php
    ;;
  "setup")
    echo "Getting submodules"
    git submodule update --init
    git --git-dir="$src"/moodle-dotfiles/.git checkout master
    git --git-dir="$src"/moodle-dotfiles/.git pull
    echo "Setting up Development Environment"
    docker cp "$src"/moodle-dotfiles/ "$COMPOSE_PROJECT_NAME"_webserver_1:/
    "$mdocker"/bin/moodle-docker-compose exec webserver bash /root/moodle-dotfiles/install.sh
    "$mdocker"/bin/moodle-docker-compose restart webserver

    #echo "Installing moodle database"
    #"$mdocker"/bin/moodle-docker-compose exec webserver php admin/cli/install_database.php --adminpass=admin --agree-license --adminemail=admin@mailinator.com --fullname=DevSite --shortname=devsite
    ;;
  "refresh_nvim")
    echo "Refreshing neovim config"
    "$mdocker"/bin/moodle-docker-compose exec webserver bash -c "rm -rf /root/.local/share/nvim && rm -rf /root/.config/nvim"
    docker cp ~/.config/nvim/ "$COMPOSE_PROJECT_NAME"_webserver_1:/root/.config/
    ;;
  *)
    echo "Usage: {up|down|start|stop|restart|install_db|upgrade|purge_caches|cron|phpunit_init|phpunit_run|behat_init|behat|run|setup|refresh_nvim}"
    exit 1
    ;;
esac

