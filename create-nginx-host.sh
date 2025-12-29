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

# Enter name for virtual host
read -p "Enter name for virtual host : " HOSTNAME

# Enter port for virtual host
echo -e "${cyan:-}Used NGINX ports:${normal:-}"
nginx -T | grep proxy_pass
read -p "Enter port for virtual host : " HOSTPORT
echo -e "Virtual host ${bold:-}${cyan:-}$HOSTNAME${normal:-} with port ${bold:-}${red:-}$HOSTPORT${normal:-} will be created."

confirm

HOSTDIRECTORY=/var/www/$HOSTNAME
HOSTUSER=www-data
CONFIGPATH=$HOSTDIRECTORY/nginx/$HOSTNAME.config
SERVICEPATH=$HOSTDIRECTORY/nginx/$HOSTNAME.service

# Replace '.' with '-' for SyslogIdentifier
LOGID=${HOSTNAME/\./-}

# Create host folder
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
wget https://raw.githubusercontent.com/7702244/dotnet-server-configure/main/template.config -O $CONFIGPATH && echo -e "${green:-}Downloaded: ${bold:-}$CONFIGPATH${normal:-}" || echo -e "${red:-}Error downloading: ${bold:-}$CONFIGPATH${normal:-}"
wget https://raw.githubusercontent.com/7702244/dotnet-server-configure/main/template.service -O $SERVICEPATH && echo -e "${green:-}Downloaded: ${bold:-}$SERVICEPATH${normal:-}" || echo -e "${red:-}Error downloading: ${bold:-}$SERVICEPATH${normal:-}"

# Replace variables in configs
sed -i "s/example\.com/$HOSTNAME/g" $CONFIGPATH
sed -i "s/5000/$HOSTPORT/g" $CONFIGPATH
sed -i "s/example\.com/$HOSTNAME/g" $SERVICEPATH
sed -i "s/5000/$HOSTPORT/g" $SERVICEPATH
sed -i "s/example\-com/$LOGID/g" $SERVICEPATH

# Link config and service
echo -e "${cyan:-}Linking Nginx files${normal:-}"
sudo ln -s $CONFIGPATH /etc/nginx/sites-available/
sudo ln -s $CONFIGPATH /etc/nginx/sites-enabled/
sudo ln -s $SERVICEPATH /etc/systemd/system/

# Generate SSL
echo -e "${cyan:-}Creating SSL${normal:-}"
sudo openssl req -x509 -subj "/CN=*.$HOSTNAME" -nodes -days 3650 -newkey rsa:2048 -keyout /etc/ssl/private/$HOSTNAME.key -out /etc/ssl/certs/$HOSTNAME.crt
echo -e "${green:-}Created SSL:\n /etc/ssl/private/$HOSTNAME.key \n /etc/ssl/certs/$HOSTNAME.crt${normal:-}"

# Enable service
sudo systemctl enable $HOSTNAME.service

# Finish
echo -e "${green:-}FINISH${normal:-}"
echo -e "${cyan:-}1. Check config files in $HOSTDIRECTORY/nginx/ directory${normal:-}"
echo -e "${cyan:-}2. Upload website to $HOSTDIRECTORY/www/ directory${normal:-}"
echo -e "${cyan:-}3. Set permissions to $HOSTDIRECTORY/www/ directory${normal:-}"
