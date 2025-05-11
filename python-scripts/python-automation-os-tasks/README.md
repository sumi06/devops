# 🐍 Python Automation Script for Linux User and Directory Management

## 📜 Description

- This Python script automates the following Linux administrative tasks:

- Creates users if they do not exist

- Adds a group called science if not already present

- Adds users to the science group

- Creates a directory /opt/science_dir if missing

- Assigns the group to the directory and sets permissions

## 🛠️ Requirements

- Python 3.x

- Linux system

- Root/sudo privileges to add users, groups, and change permissions

## 🚀 How to Run

```bash
sudo python3 user_group_dir_setup.py
```

## 📂 Script: user_group_dir_setup.py

```python
#!/usr/bin/python3
import os

userlist = ["alpha", "beta", "gamma"]

print("Adding users to system")
print("################################################################")

# Loop to add users from userlist
for user in userlist:
    exitcode = os.system("id {}".format(user))
    if exitcode != 0:
        print("User {} does not exist. Adding it.".format(user))
        print("########################################################")
        print()
        os.system("useradd {}".format(user))
    else:
        print("User already exists, skipping it.")
        print("########################################################")
        print()

# Condition to check if group exists or not, add if not exists.
exitcode = os.system("grep science /etc/group")
if exitcode != 0:
    print("Group science does not exist. Adding it.")
    print("####################################################")
    print()
    os.system("groupadd science")
else:
    print("Group already exists, skipping it.")
    print("###################################################")
    print()

for user in userlist:
    print("Adding user {} in the science group".format(user))
    print("###################################################")
    print()
    os.system("usermod -G science {}".format(user))

print("Adding directory")
print("#################################################")
print()

if os.path.isdir("/opt/science_dir"):
    print("Directory already exists, skipping it.")
else:
    os.mkdir("/opt/science_dir")

print("Assigning permission and ownership to the directory")
print("########################################################")
print()

os.system("chown :science /opt/science_dir")
os.system("chmod 770 /opt/science_dir")
```

## ✅ Tasks Performed

✅ Add users: alpha, beta, gamma

✅ Create group science

✅ Assign users to group

✅ Create directory /opt/science_dir

✅ Assign group ownership and set 770 permissions
