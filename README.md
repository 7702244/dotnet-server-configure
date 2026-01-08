# Readme
**First steps for setup Ubuntu .NET Server.**

## Configure server environment

1. Upload setup script

Upload setup script to the server by command:
```
$ wget https://raw.githubusercontent.com/7702244/dotnet-server-configure/main/ubuntu-configure.sh
```

2. Run script and follow instructions

```
$ bash ubuntu-configure.sh
```
It will install `Nginx`, `Webmin`, `.NET`, `SQL Server` and configure firewall.

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

When no `server_name` matches, Nginx uses the default server. If no default server is defined, the first server in the configuration file is the default server. As a best practice, add a specific default server that returns a status code of 444 in your `/etc/nginx/sites-available/default` configuration file. A default server configuration example is:
```
server {
    listen   80 default_server;
    # listen [::]:80 default_server deferred;
    return   444;
}
```

Go to `/etc/logrotate.d/nginx` and replace content with file `logrotate.nginx`.

## Check server environment

1. Check Nginx

Open the server IP in your browser and make sure that the standard Nginx page appears.

2. Check Webmin

Open the server IP with port `10000` in your browser and make sure that you can login in Webmin.

3. Check SQL Server connection

Check the remote connection to the SQL server with `sa` login.

## Setup SSH keys

1. Creating the Key Pair (if not created) on local machine.

```
$ ssh-keygen
```

2. Copying the Public Key to Your Ubuntu Server

```
$ ssh-copy-id user@host
```

or

```
$ ssh-copy-id -i ~/.ssh/mykey user@host
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
$ wget https://raw.githubusercontent.com/7702244/dotnet-server-configure/main/create-nginx-host.sh
```

2. Run script and follow instructions

```
$ sudo bash create-nginx-host.sh
```
It will create host directory, upload and link nginx config and service for host and generate Self-Figned SSL for host.

3. Upload website files

4. Check Website

Check Nginx config:
```
$ sudo sudo nginx -t
```
Restart Nginx service:
```
$ sudo systemctl restart nginx
```
Enable Website service:
```
$ sudo systemctl enable example.com.service
```
Restart Website service:
```
$ sudo systemctl restart example.com.service
```

5. Configure `/etc/hosts` file:
```
127.0.0.1 example.com
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

## Managing Website Process

Reload systemd manager configuration. This will rerun all generators, reload all unit files, and recreate the entire dependency tree.
```
$ sudo systemctl daemon-reload
```

To stop your website, type:
```
$ sudo systemctl stop example.com.service
```

To start the website when it is stopped, type:
```
$ sudo systemctl start example.com.service
```

To stop and then start the service again, type:
```
$ sudo systemctl restart example.com.service
```

To disable the service, type:
```
$ sudo systemctl disable example.com.service
```

To enable the service, type:
```
$ sudo systemctl enable example.com.service
```

To view service status:
```
$ sudo systemctl status example.com.service
```

To view logs, type:
```
$ sudo journalctl -fu example.com.service
```

To view all running services:
```
$ sudo systemctl --type=service --state=running
```

## Run Scheduled Tasks

Timers cannot run commands, so oneshot services are used to run commands:
```
[Unit]
Description=One shot service

[Service]
Type=oneshot
ExecStart=/usr/bin/systemctl restart my-service.service

[Install]
WantedBy=multi-user.target
```

Timer code:
```
[Unit]
Description=Run oneshot service periodically

[Timer]
Unit=oneshot.service
OnCalendar=Mon..Fri 10:30

[Install]
WantedBy=timers.target
```

Enable and starts timer:
```
$ sudo systemctl enable --now my-service.timer
```

List only enabled timers:
```
$ sudo systemctl list-timers
```

List all timers:
```
$ sudo systemctl list-timers --all
```

Analyze calendar for timer:
```
$ systemd-analyze calendar --iterations=2 "Sat,Tue 2022-11,12-* 23:55:00"
$ systemd-analyze calendar --iterations=2 "Mon..Fri 10:30"
```
