#!/bin/bash
 
SHARE="//IP/arcgis_repo"
MOUNT_POINT="/mnt/arcgis_repo"
 
echo "Installing CIFS utilities..."
 
# Detect distro and install cifs-utils
if command -v apt >/dev/null 2>&1; then
    sudo apt update -y
    sudo apt install -y cifs-utils
elif command -v yum >/dev/null 2>&1; then
    sudo yum install -y cifs-utils
elif command -v dnf >/dev/null 2>&1; then
    sudo dnf install -y cifs-utils
else
    echo "Unsupported package manager. Install cifs-utils manually."
    exit 1
fi
 
echo "Creating mount directory..."
sudo mkdir -p $MOUNT_POINT
 
echo "Adding entry to /etc/fstab..."
 
FSTAB_ENTRY="$SHARE  $MOUNT_POINT  cifs  credentials=/root/.smbcred,vers=3.0,_netdev  0  0"
# ArcGIS Repo
if ! grep -qs "$SHARE" /etc/fstab; then
    echo "$FSTAB_ENTRY" | sudo tee -a /etc/fstab
else
    echo "Entry already exists in fstab."
fi
 
echo "Mounting share..."
sudo mount -a
 
echo "Done. Verifying..."
df -h | grep arcgis_repo
