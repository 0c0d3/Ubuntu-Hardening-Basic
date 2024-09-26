#!/bin/bash

# Ensure the script is run as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

# Update the package list
echo "Updating package list..."
apt update && apt upgrade -y

# Stop and disable AppArmor
echo "Stopping and disabling AppArmor..."
systemctl stop apparmor
systemctl disable apparmor

# Install SELinux
echo "Installing SELinux..."
apt install policycoreutils selinux-basics selinux-utils -y

# Enable SELinux
echo "Enabling SELinux..."
selinux-config-enforcing

# Check SELinux status
echo "Current SELinux status:"
sestatus

# Set SELinux to enforcing mode
echo "Setting SELinux to enforcing mode..."
setenforce 1

# Enable SELinux at boot
echo "Configuring SELinux to boot in enforcing mode..."
sed -i 's/^SELINUX=.*/SELINUX=enforcing/' /etc/selinux/config

# Install Firejail
echo "Installing Firejail..."
apt install firejail -y

# Install UFW
echo "Installing UFW..."
apt install ufw -y

# Set UFW default policies
echo "Setting default UFW policies..."
ufw default deny incoming
ufw default allow outgoing

# Allow specific services (SSH, HTTP, HTTPS)
echo "Allowing SSH, HTTP, and HTTPS through UFW..."
ufw allow ssh
ufw allow http
ufw allow https

# Enable UFW
echo "Enabling UFW..."
ufw enable

# Create Firejail profiles for popular applications
echo "Creating Firejail profiles for popular applications..."

# Profile for Firefox
cat <<EOL > /etc/firejail/firefox.profile
# Firejail profile for Firefox
include /etc/firejail/disable-common.inc
include /etc/firejail/firefox-common.inc

private
netfilter
nodbus
nonewprivs
caps.drop all
# Block JavaScript execution
whitelist ${HOME}/.mozilla/firefox
EOL

# Profile for Chromium
cat <<EOL > /etc/firejail/chromium.profile
# Firejail profile for Chromium
include /etc/firejail/disable-common.inc
include /etc/firejail/chromium-common.inc

private
netfilter
nodbus
nonewprivs
caps.drop all
# Block JavaScript execution
whitelist ${HOME}/.config/chromium
EOL

# Profile for LibreOffice
cat <<EOL > /etc/firejail/libreoffice.profile
# Firejail profile for LibreOffice
include /etc/firejail/disable-common.inc
include /etc/firejail/libreoffice-common.inc

private
netfilter
nodbus
nonewprivs
caps.drop all
# Block macros
seccomp
EOL

# Profile for PDF Viewer (Evince)
cat <<EOL > /etc/firejail/evince.profile
# Firejail profile for Evince (PDF Viewer)
include /etc/firejail/disable-common.inc

private
netfilter
nodbus
nonewprivs
caps.drop all
# Block execution of embedded scripts
seccomp
EOL

# Enable automatic updates for security packages
echo "Setting up automatic updates..."
apt install unattended-upgrades -y
dpkg-reconfigure --priority=low unattended-upgrades

# Final status messages
echo "Final status of UFW:"
ufw status verbose

echo "SELinux status:"
sestatus

echo "Installation and configuration complete!"
echo "Reboot your system to apply all changes."
