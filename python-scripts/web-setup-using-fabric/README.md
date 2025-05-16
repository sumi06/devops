# ⚙️ Web Server Automation using Fabric

## 📜 Overview

This project uses Fabric to automate remote web server setup and deployment of a static website. It:

- Installs system packages

- Starts and enables httpd web server

- Downloads a website from a URL

- Deploys it to a remote server (e.g., web01) running on Linux (Amazon Linux / RHEL)

- Can also display local and remote system info

## 🧰 Prerequisites

- Python 3.x

- pip package manager

- SSH access to the remote server (web01) as devops user

- Remote server should allow passwordless sudo for automation

## 📦 Installation Steps

### 1. Install pip (if not already installed)

```bash
sudo apt update && sudo apt install python3-pip -y   # for Debian/Ubuntu
# OR
sudo yum install python3-pip -y                      # for RHEL/Amazon Linux
```

### 2. Install Fabric

```bash
pip3 install fabric
```

### 3. Create fabfile.py

Save the following code as fabfile.py:

```python
from fabric.api import *

env.hosts = ["devops@web01"]
env.warn_only = True

def system_info():
    print("Disk space.")
    local("df -h")

    print("Memory info.")
    local("free -m")

    print("System uptime")
    local("uptime")

def remote_exec():
    run("hostname")
    run("uptime")
    run("df -h")
    run("free -m")

    sudo("yum install unzip zip wget -y")

def web_setup(WEBURL, DIRNAME):
    print("############################################################################")
    print("Installing dependencies")
    print("############################################################################")
    sudo("yum install httpd wget unzip -y")

    print("############################################################################")
    print("Start & enable service")
    print("############################################################################")
    sudo("systemctl start httpd")
    sudo("systemctl enable httpd")

    print("############################################################################")
    local("apt install unzip zip -y")

    print("############################################################################")
    print("Downloading & pushing website to webservers")
    print("############################################################################")
    local(("wget -O website.zip %s") % WEBURL)
    local("unzip -o website.zip")

    print("############################################################################")
    with lcd(DIRNAME):
        local("zip -r tooplate.zip * ")
        put("tooplate.zip", "/var/www/html/", use_sudo=True)

    with cd("/var/www/html/"):
        sudo("unzip -o tooplate.zip")

    sudo("systemctl restart httpd")

    print("Website setup is done")
```

## 🖥️ Remote Server Setup

### 1. Update /etc/hosts (if using hostname like web01)

```bash
sudo nano /etc/hosts
# Add entry like:
192.168.56.10   web01
```

### 2. Ensure SSH connectivity:

```bash
ssh devops@web01
```

Use SSH keys or ensure passwordless sudo for automation to succeed.

## 🚀 How to Run

### 1. Test connection and run remote commands:

```bash
fab remote_exec
```

### 2. Deploy website (replace placeholders):

```bash
fab web_setup:WEBURL="http://example.com/template.zip",DIRNAME="unzipped_folder"
```

### 3. Get local system info:

```bash
fab system_info
```

## 📁 Directory Structure Example

```css
.
├── fabfile.py
├── website.zip # downloaded from URL
└── unzipped_folder/ # extracted folder (used in DIRNAME)
```

## ✅ Summary

Automates Apache setup and website deployment

Uses Fabric to execute commands locally and remotely

Supports dynamic website ZIP URLs and directories
