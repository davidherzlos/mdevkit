#!/bin/bash

echo "Running script $0 in process ID: $$"

# NOTE: variables are scoped to the process that creates them
# however if we want variables with a greater scope, we can
# export them as enviroment variables.

# TODO: add variables for Installing specific versions of sofware.
# TODO: improve idempotemcy.
# TODO: install more packages required by Neovim.
# TODO: restart sysctl correctly.
# TODO: cleanup installation.

# Version variables - update these to use newer versions
NEOVIM_VERSION="0.11.7"
NVM_VERSION="0.40.5"

echo "Updating the system-------------------------------------------------------------OK?"
apt update -y
apt upgrade -y

echo "Installing package dependencies-------------------------------------------------OK?"
apt install sudo -y
sudo apt install cmake make gcc python3 python3-pip python3-venv libtool fd-find wget luarocks curl ripgrep postgresql-client watchman -y

echo "Install and enable xdebug php pecl extension------------------------------------OK?"
pecl install xdebug-3.1.6 > /dev/null
xdebug_ini="
xdebug.mode=debug
xdebug.discover_client_host=1
xdebug.start_with_request=yes"
echo "$xdebug_ini" > /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini
cat /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini
docker-php-ext-enable xdebug
sed -i 's/^; zend_extension=/zend_extension=/' /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini
php --version

echo "Copy moodle-dotfiles------------------------------------------------------------OK?"
# Application helper files.
cp /dotfiles/moodle-psysh.php /var/www/html/
cp /dotfiles/psysh.php /var/www/html/.psysh.php
cp /dotfiles/phpstan.neon /var/www/html/

# config.php if it's not there(new installation).
if [ ! -f /var/www/html/config.php ]; then
    wget -O /var/www/html/config.php https://raw.githubusercontent.com/moodlehq/moodle-docker/refs/heads/main/config.docker-template.php
fi

# gitconfig if it's not there(new installation).
if [ ! -f ~/.config/git/config ]; then
    wget -O ~/.config/git/config https://github.com/davidherzlos/dotfiles/blob/master/git/.config/git/config
fi

echo "Install composer and dependencies for Moodle------------------------------------OK?"
wget -P ~/ https://getcomposer.org/installer
php ~/installer --install-dir=/usr/local/bin --filename=composer
composer global config allow-plugins true
composer global config minimum-stability dev
composer require moodlehq/moodle-cs --working-dir=/var/www/html
composer require --dev micaherne/phpstan-moodle --working-dir=/var/www/html
composer require --dev psy/psysh:@stable --working-dir=/var/www/html

echo "Install  node version manager and dependencies for Javascript-------------------OK?"
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v${NVM_VERSION}/install.sh | bash
export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" --no-use # This loads nvm, without auto-using the default version
cd /var/www/html
nvm install
nvm use
npm install
npm install -g grunt-cli

echo "Install cli AI tools------------------------------------------------------------OK?"
npm install -g opencode-ai
npm install -g @anthropic-ai/claude-code
npm install -g tree-sitter-cli
npm install -g @augmentcode/auggie

echo "Install Neovim and load custom config for MoodleDevelopment---------------------OK?"
# Remove any previos downloaded file.
rm ~/nvim-linux-x86_64.tar.gz
wget -P ~/ https://github.com/neovim/neovim/releases/download/v${NEOVIM_VERSION}/nvim-linux-x86_64.tar.gz
rm -rf /opt/nvim
tar -xzf ~/nvim-linux-x86_64.tar.gz -C /opt

# Only add if not already present
if ! grep -q "/opt/nvim-linux-x86_64/bin" ~/.bashrc; then
    echo 'export PATH="$PATH:/opt/nvim-linux-x86_64/bin"' >> ~/.bashrc
fi
rm -rf ~/.config/nvim
rm -rf ~/.local/share/nvim
git clone https://github.com/davidherzlos/moodle-nvim ~/.config/nvim
. ~/.bashrc

echo "Tweak number of files to be watched---------------------------------------------TODO"
# sudo bash -c 'echo "fs.inotify.max_user_watches=524288" > /etc/sysctl.d/60-inotify.conf && sysctl -p /etc/sysctl.d/60-inotify.conf'

echo "Setup completed. Exited with code $?"
