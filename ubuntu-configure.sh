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

# Print Ubuntu info
hostnamectl

# Enter name for superuser
read -p "Enter name for superuser : " USERNAME
echo -e "User ${bold:-}${cyan:-}$USERNAME${normal:-} will be created."

confirm

# Create user
echo -e "${cyan:-}Creating user ${bold:-}$USERNAME${normal:-}"
sudo adduser $USERNAME

# Grant root privileges
echo -e "${cyan:-}Grant root privileges to ${bold:-}$USERNAME${normal:-}"
sudo usermod -aG sudo $USERNAME

# Install Nginx
echo -e "${cyan:-}Installing Nginx${normal:-}"
sudo apt update
sudo apt install -y nginx
sudo systemctl status nginx

# Install Webmin
# https://webmin.com/download/
echo -e "${cyan:-}Installing Webmin${normal:-}"
wget https://raw.githubusercontent.com/webmin/webmin/master/webmin-setup-repo.sh
sudo sh webmin-setup-repo.sh
rm webmin-setup-repo.sh
sudo apt-get install webmin --install-recommends
sudo systemctl status webmin

# Create Diffie-Hellman (DH) group
# https://www.digitalocean.com/community/tutorials/how-to-create-a-self-signed-ssl-certificate-for-nginx-in-ubuntu-20-04-1
echo -e "${cyan:-}Creating Diffie-Hellman (DH) group${normal:-}"
sudo openssl dhparam -dsaparam -out /etc/nginx/dhparam.pem 2048

# Install .NET
# https://learn.microsoft.com/en-us/dotnet/core/install/linux-ubuntu
echo -e "${cyan:-}Installing .NET${normal:-}"
sudo add-apt-repository ppa:dotnet/backports
sudo apt-get update
sudo apt-get install -y aspnetcore-runtime-10.0
dotnet --info

# ARM Install
#wget https://dot.net/v1/dotnet-install.sh -O dotnet-install.sh
#sudo bash dotnet-install.sh --channel 7.0 --version latest --runtime aspnetcore
#rm dotnet-install.sh
#export DOTNET_ROOT=$HOME/.dotnet
#export PATH=$PATH:$HOME/.dotnet:$HOME/.dotnet/tools

# Install SQL Server
# https://learn.microsoft.com/en-us/sql/linux/quickstart-install-connect-ubuntu?view=sql-server-ver16
echo -e "${cyan:-}Installing SQL Server${normal:-}"
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | sudo apt-key add -
sudo add-apt-repository "$(wget -qO- https://packages.microsoft.com/config/ubuntu/20.04/mssql-server-2019.list)"
sudo apt update
sudo apt install -y mssql-server
sudo /opt/mssql/bin/mssql-conf setup
sudo /opt/mssql/bin/mssql-conf set sqlagent.enabled true
sudo systemctl restart mssql-server
systemctl status mssql-server --no-pager

# Setting Up a Basic Firewall
if ! type ufw > /dev/null; then
    echo -e "${cyan:-}Installing Firewall${normal:-}"
    sudo apt install -y ufw
fi
echo -e "${cyan:-}Setting Up Firewall${normal:-}"
sudo ufw app list
sudo ufw allow OpenSSH
sudo ufw allow 'Nginx Full'
sudo ufw allow 10000 # Webmin
sudo ufw allow 1433 # SQL Server
sudo ufw enable
sudo ufw status
