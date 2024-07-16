# !/bin/bash

echo "Running script $0 with PID: $$"

# NOTE: variables are scoped to the process that creates them
# however if we want variables with a greater scope, we can
# export them as enviroment variables.

# Install some missing os packages that could be missing.
apt update
apt install sudo systemctl wget python3 fd-find -y
source ~/.bashrc
#sudo apt upgrade -y


# Install xdebug extension.
echo "Install xdebug php pecl extension"
pecl install xdebug-3.1.6 > /dev/null

# This is the minimal config for step debugging.
xdebug_ini="
xdebug.mode=debug
xdebug.discover_client_host=1
xdebug.start_with_request=yes"
echo "$xdebug_ini" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini

# Enable the extension, after this, restart is needed.
docker-php-ext-enable xdebug
sed -i 's/^; zend_extension=/zend_extension=/' /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini
php --version

# Composer
echo "Install and enable composer"
wget -P /home https://getcomposer.org/installer
php /home/installer --install-dir=/usr/local/bin --filename=composer
composer install --working-dir=/var/www/html
cd /var/www/html
composer config minimum-stability dev
composer require moodlehq/moodle-cs -y

# Node package manager and tools.
wget -P /home https://raw.githubusercontent.com/nvm-sh/nvm/v0.37.2/install.sh
bash /home/install.sh
bash /root/.nvm/nvm.sh
source /root/.bashrc
cd /var/www/html
nvm install
npm install -g grunt-cli

# Neovim
curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux64.tar.gz
rm -rf /opt/nvim
tar -C /opt -xzf nvim-linux64.tar.gz
echo 'export PATH="$PATH:/opt/nvim-linux64/bin"' >> /root/.bashrc
curl -LO https://github.com/BurntSushi/ripgrep/releases/download/13.0.0/ripgrep_13.0.0_amd64.deb
dpkg -i ripgrep_13.0.0_amd64.deb
git clone https://github.com/davidherzlos/moodle-nvim /root/.config/nvim
cd /var/www/html
source /root/.bashrc

sudo apt install python3-pip python3-venv -y

