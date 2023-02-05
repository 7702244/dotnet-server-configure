#!/usr/bin/env bash

# Stop script on errors
set -e

# Setup some colors to use. These need to work in fairly limited shells, like the Ubuntu Docker container where there are only 8 colors.
# See if stdout is a terminal
if [ -t 1 ] && command -v tput > /dev/null; then
    # see if it supports colors
    ncolors=$(tput colors || echo 0)
    if [ -n "$ncolors" ] && [ $ncolors -ge 8 ]; then
        bold="$(tput bold       || echo)"
        normal="$(tput sgr0     || echo)"
        black="$(tput setaf 0   || echo)"
        red="$(tput setaf 1     || echo)"
        green="$(tput setaf 2   || echo)"
        yellow="$(tput setaf 3  || echo)"
        blue="$(tput setaf 4    || echo)"
        magenta="$(tput setaf 5 || echo)"
        cyan="$(tput setaf 6    || echo)"
        white="$(tput setaf 7   || echo)"
    fi
fi

# Confirm Dialog
function confirm {
    while true; do
        read -p "${bold:-}${yellow:-}Do you want to proceed? (y/n) ${normal:-}" yn
        case $yn in
            [Yy]*) echo "${green:-}proceeding...${normal:-}"; break;;
            [Nn]*) echo "${red:-}exiting...${normal:-}"; exit;;
        esac
    done
}

# ==============================
# START WORK
# ==============================

# Enter diretory name for virtual host
read -p "Enter diretory name for virtual host : " HOSTNAME
echo -e "Virtual host ${bold:-}${cyan:-}$HOSTNAME${normal:-} will be created."

confirm

HOSTDIRECTORY=/var/www/$HOSTNAME
HOSTUSER=www-data

# Create user
echo -e "${cyan:-}Creating folder ${bold:-}$HOSTDIRECTORY${normal:-}"
sudo mkdir -p $HOSTDIRECTORY/www
sudo mkdir -p $HOSTDIRECTORY/nginx
sudo mkdir -p $HOSTDIRECTORY/temp

# Set permissions
echo -e "${cyan:-}Set permissions to ${bold:-}$HOSTDIRECTORY${normal:-}"
sudo chown -R $HOSTUSER:$HOSTUSER $HOSTDIRECTORY
sudo chmod -R 755 $HOSTDIRECTORY

# Download Nginx configs
echo -e "${cyan:-}Downloading Nginx configs${normal:-}"
wget https://raw.githubusercontent.com/7702244/dotnet-server-configure/main/template.config -P $HOSTDIRECTORY/nginx/
wget https://raw.githubusercontent.com/7702244/dotnet-server-configure/main/template.service -P $HOSTDIRECTORY/nginx/

# Copy files
cp template.config $HOSTDIRECTORY/nginx/$HOSTNAME.config
cp template.service $HOSTDIRECTORY/nginx/$HOSTNAME.service

# Link config and service
echo -e "${cyan:-}Linking Nginx files${normal:-}"
sudo ln -s $HOSTDIRECTORY/nginx/$HOSTNAME.config /etc/nginx/sites-available/
sudo ln -s $HOSTDIRECTORY/nginx/$HOSTNAME.config /etc/nginx/sites-enabled/
sudo ln -s $HOSTDIRECTORY/nginx/$HOSTNAME.service /etc/systemd/system/

# Finish
echo -e "${cyan:-}Modify files in $HOSTDIRECTORY/nginx/ directory${normal:-}"