# !/bin/bash

function main() {
  # Copy the installation script to the container.
  podman cp /home/davidoc/repos/moodledev/scripts/ moodle_webserver_1:/root/
  podman cp /home/davidoc/intelephense moodle_webserver_1:/root/

  # Run the installation script.
  podman exec moodle_webserver_1 bash /root/scripts/install.sh

  # Restart the webserver and open neovim.
  ~/repos/moodle-docker/bin/moodle-docker-compose restart webserver
}

main "$@"
