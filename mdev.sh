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
    git submodule update --init
    cp "$src"./dotfiles/local.yml moodle-docker/
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
  "restart_webserver")
    echo "Restarting moodle webserver"
    "$mdocker"/bin/moodle-docker-compose restart webserver
    ;;
  "setup")
    echo "Setup Development environment"
    docker cp "$src"./install.sh "$COMPOSE_PROJECT_NAME"-webserver-1:/
    docker cp "$src"./dotfiles "$COMPOSE_PROJECT_NAME"-webserver-1:/
    "$mdocker"/bin/moodle-docker-compose exec webserver sh /install.sh
    ;;
  "install")
    echo "Setup Development environment"
    "$mdocker"/bin/moodle-docker-compose exec webserver php admin/cli/install_database.php --adminpass=admin --agree-license --adminemail=admin@mailinator.com --fullname=DevSite --shortname=devsite
    ;;
  "nvim_refresh")
    echo "Refreshing neovim config"
    "$mdocker"/bin/moodle-docker-compose exec webserver bash -c "rm -rf /root/.local/share/nvim && rm -rf /root/.config/nvim"
    docker cp ~/.config/nvim/ "$COMPOSE_PROJECT_NAME"-webserver-1:/root/.config/
    ;;
  *)
    echo "Usage: {up|down|start|stop|restart_webserver|setup|install|refresh_nvim}"
    exit 1
    ;;
esac

