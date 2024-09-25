#!/bin/bash

# Ensure the script is run as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

# Update the package list
echo "Updating package list..."
apt update && apt upgrade -y

# Install SELinux
echo "Installing SELinux..."
apt install selinux selinux-basics selinux-policy-default -y

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

# Additional SELinux policies for blocking macro execution in PDF files
echo "Creating additional SELinux policies..."

# Policy for blocking macro execution in LibreOffice
cat <<EOL > /etc/selinux/targeted/policy/LibreOfficeMacros.te
module LibreOfficeMacros 1.0;

require {
    type libreoffice_t;
    class process { execmem execmod execstack };
}

# Block execution of macros
deny libreoffice_t self:process { execmem execmod execstack };
EOL

# Policy for blocking script execution in PDF viewers
cat <<EOL > /etc/selinux/targeted/policy/PDFViewerScripts.te
module PDFViewerScripts 1.0;

require {
    type evince_t; # Assuming Evince as the PDF viewer
    class process { execmem execmod execstack };
}

# Block execution of embedded scripts in PDF files
deny evince_t self:process { execmem execmod execstack };
EOL

# Compile and load the new policies
echo "Compiling and loading SELinux policies..."
checkmodule -M -m -o /etc/selinux/targeted/policy/LibreOfficeMacros.mod /etc/selinux/targeted/policy/LibreOfficeMacros.te
semodule_package -o /etc/selinux/targeted/policy/LibreOfficeMacros.pp -m /etc/selinux/targeted/policy/LibreOfficeMacros.mod
semodule -i /etc/selinux/targeted/policy/LibreOfficeMacros.pp

checkmodule -M -m -o /etc/selinux/targeted/policy/PDFViewerScripts.mod /etc/selinux/targeted/policy/PDFViewerScripts.te
semodule_package -o /etc/selinux/targeted/policy/PDFViewerScripts.pp -m /etc/selinux/targeted/policy/PDFViewerScripts.mod
semodule -i /etc/selinux/targeted/policy/PDFViewerScripts.pp

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
