# Readme
**First steps for setup Ubuntu .NET Server.**

## Configure server environment

1. Upload setup script
Upload setup script to the server by command:
```
$ https://raw.githubusercontent.com/7702244/dotnet-server-configure/main/ubuntu-configure.sh
```

2. Run script and follow instructions
```
$ bash ubuntu-configure.sh
```
It will install `Nginx`, `Webmin`, `Certbot`, `.NET`, `SQL Server`.

3. Configure Nginx
To avoid a possible hash bucket memory problem that can arise from adding additional server names, it is necessary to adjust a single value in the `/etc/nginx/nginx.conf` file. Open the file and modify:
```
...
http {
    ...
    server_names_hash_bucket_size 64;
    ...
}
...
```

## Check server environment

1. Check Nginx
Open the server IP in your browser and make sure that the standard Nginx page appears.

2. Check Webmin
Open the server IP with port `10000` in your browser and make sure that you can login in Webmin.

3. Check SQL Server connection
Check the remote connection to the SQL server with `sa` login.

## Setup SSH keys

1. Creating the Key Pair (if not created)
```
$ ssh-keygen
```

2. Copying the Public Key to Your Ubuntu Server
```
$ ssh-copy-id username@remote_host
```
Repeat this step for each user.

3. Disabling Password Authentication on Your Server
Inside the file `/etc/ssh/sshd_config`, search for a directive called `PasswordAuthentication`. This line may be commented out with a `#` at the beginning of the line. Uncomment the line by removing the `#`, and set the value to `no`. This will disable your ability to log in via SSH using account passwords:
```
. . .
PasswordAuthentication no
. . .
```

To actually activate these changes, we need to restart the sshd service:
```
$ sudo systemctl restart ssh
```
As a precaution, open up a new terminal window and test that the SSH service is functioning correctly before closing your current session.

## Setup Website

1. Upload setup script
Upload setup script to the server by command:
```
$ https://raw.githubusercontent.com/7702244/dotnet-server-configure/main/create-nginx-host.sh
```

2. Run script and follow instructions
```
$ bash create-nginx-host.sh
```

3. Obtaining an SSL Certificate by Certbot
```
$ sudo certbot --nginx -d example.com -d www.example.com
```

4. Verifying Certbot Auto-Renewal
```
$ sudo systemctl status certbot.timer
```
To test the renewal process, you can do a dry run with certbot:
```
$ sudo certbot renew --dry-run
```

5. Check Website
Check Nginx config:
```
$ sudo sudo nginx -t
```
Restart Nginx service:
```
$ sudo systemctl restart nginx
```
Restart Website service:
```
$ sudo systemctl restart example.com.service
```

## Important Files and Directories

### Server Configuration

- `/etc/nginx`: The Nginx configuration directory. All of the Nginx configuration files reside here.
- `/etc/nginx/nginx.conf`: The main Nginx configuration file. This can be modified to make changes to the Nginx global configuration.
- `/etc/nginx/sites-available/`: The directory where per-site server blocks can be stored. Nginx will not use the configuration files found in this directory unless they are linked to the sites-enabled directory. Typically, all server block configuration is done in this directory, and then enabled by linking to the other directory.
- `/etc/nginx/sites-enabled/`: The directory where enabled per-site server blocks are stored. Typically, these are created by linking to configuration files found in the sites-available directory.
- `/etc/nginx/snippets/`: This directory contains configuration fragments that can be included elsewhere in the Nginx configuration. Potentially repeatable configuration segments are good candidates for refactoring into snippets.

### Server Logs

- `/var/log/nginx/access.log`: Every request to your web server is recorded in this log file unless Nginx is configured to do otherwise.
- `/var/log/nginx/error.log`: Any Nginx errors will be recorded in this log.

### System services

- `/etc/systemd/system/`: Background services that run with the system.