#!/bin/bash
set -e

echo "--------------------------------------------"
echo " INSTALLING ANSIBLE CONTROLLER ON UBUNTU"
echo "--------------------------------------------"

# Update system
echo "[1/7] Updating system..."
sudo apt update && sudo apt upgrade -y

# Install dependencies
echo "[2/7] Installing dependencies..."
sudo apt install -y software-properties-common python3 python3-pip unzip

# Install AWS CLI v2
echo "[3/7] Installing AWS CLI v2..."
curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip -q awscliv2.zip
sudo ./aws/install
rm -rf aws awscliv2.zip

# Install Ansible
echo "[4/7] Installing Ansible..."
sudo add-apt-repository --yes --update ppa:ansible/ansible
sudo apt install -y ansible

# Create project folder
echo "[5/7] Creating Ansible project folder..."
mkdir -p ~/ansible
cd ~/ansible

# SSH setup
echo "[6/7] Preparing SSH key directory..."
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# Stop here until user uploads key
if [ "$1" != "continue" ]; then
    exit 0
fi

echo "[INFO] Setting permissions for main.pem..."
chmod 600 ~/ansible/main.pem

echo "Get ansible.cfg and hosts.ini"

echo "Testing Ansible connectivity..."
ansible all -m ping

echo "------------------------------------------------------------"
echo " SETUP COMPLETE!"
echo " You're ready to add db.yml and web.yml playbooks."
echo " Run a test with: ansible all -m ping"
echo "------------------------------------------------------------"
