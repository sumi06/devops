# Ansible Project

This repository contains Ansible playbooks and related configuration files for provisioning, configuring, and deploying infrastructure and applications.

## 📦 Project Structure

```css
.
├── inventory/
│ └── hosts # Inventory file (static or dynamic)
├── playbooks/
│ └── provisioning.yml # Playbook for provisioning servers
├── roles/
│ └── post-install/ # Ansible roles
│ ├── defaults/
│ │ └── main.yml # Default variable definitions
│ ├── files/
│ │ └── myfile.txt # Static file(s) to copy
│ ├── handlers/
│ │ └── main.yml # Handlers (e.g., restart service)
│ ├── tasks/
│ │ └── main.yml # Main tasks for the role
│ ├── templates/
│ │ └── ntpconf_ubuntu.j2 # Jinja2 template for NTP config
│ └── vars/
│ └── main.yml # Role-specific variables
├── ansible.cfg # Ansible configuration file
└── README.md # This file
```

## ✅ Requirements

- Python 3.6+
- Ansible 2.9+ (preferably latest)
- SSH access to target servers
- Properly configured inventory file

## Install Ansible:

```bash
pip install ansible
```

## 🔧 Common Commands

### Check syntax:

```bash
ansible-playbook playbooks/provisioning.yml --syntax-check
```

### Dry run (check mode):

```bash
ansible-playbook playbooks/provisioning.yml --C
```

### Run a playbook:

```bash
ansible-playbook playbooks/provisioning.yml
```

### Run ad-hoc command:

```bash
ansible all -i inventory -m ping
```
