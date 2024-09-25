#!/bin/bash

# Ensure the script is run as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

# Update the package list
echo "Updating package list..."
apt update && apt upgrade -y

# Install Firejail
echo "Installing Firejail..."
apt install firejail -y

# Install AppArmor (usually pre-installed on Ubuntu)
echo "Ensuring AppArmor is installed and active..."
apt install apparmor apparmor-utils -y
systemctl start apparmor
systemctl enable apparmor

# Check AppArmor status
echo "AppArmor status:"
aa-status

# Install UFW
echo "Installing UFW..."
apt install ufw -y

# Set UFW default policies
echo "Setting default UFW policies..."
ufw default deny incoming
ufw default allow outgoing

# Allow specific services (SSH, HTTP, HTTPS)
echo "Allowing SSH, HTTP, and HTTPS through UFW..."
ufw block ssh
ufw allow http
ufw allow https

# Enable UFW
echo "Enabling UFW..."
ufw enable

# Create a strict AppArmor profile for Firejail
echo "Creating a strict AppArmor profile for Firejail..."
cat <<EOL > /etc/apparmor.d/usr.bin.firejail
#include <tunables/global>

/usr/bin/firejail {
    # Allow execution of the firejail binary
    /usr/bin/firejail ix,

    # Allow access to specific directories
    /home/** r,
    /etc/passwd r,
    /etc/group r,
    /etc/shadow r,

    # Deny all other access
    deny /**,
    
    # Deny network access (optional, uncomment if needed)
    # deny network,
    
    # Deny loading of additional libraries
    deny /lib/**,
    deny /usr/lib/**,
    deny /usr/libexec/**,
    
    # Deny access to certain files
    deny /dev/**,
    deny /proc/**,
    deny /sys/**,
    deny /tmp/**,
}
EOL

# Load the new AppArmor profile
echo "Loading the new AppArmor profile..."
apparmor_parser -r /etc/apparmor.d/usr.bin.firejail

# Enforce the Firejail profile
echo "Enforcing the Firejail profile..."
aa-enforce /etc/apparmor.d/usr.bin.firejail

# Enable automatic updates for security packages
echo "Setting up automatic updates..."
apt install unattended-upgrades -y
dpkg-reconfigure --priority=low unattended-upgrades

# Final status messages
echo "Final status of UFW:"
ufw status verbose

echo "AppArmor status:"
aa-status

echo "Installation and configuration complete!"
echo "Reboot your system to apply all changes."
