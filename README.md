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
