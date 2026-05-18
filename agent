#!/bin/bash

# =========================================================
# ArcGIS Monitor Agent Installation Script
# =========================================================

set -e

echo "=================================================="
echo "Starting sysstat installation..."
echo "=================================================="

cd /

sudo apt-get update
sudo apt-get install -y sysstat git build-essential

echo "=================================================="
echo "Enabling sysstat..."
echo "=================================================="

# Enable sysstat automatically
sudo sed -i 's/ENABLED="false"/ENABLED="true"/g' /etc/default/sysstat || true
sudo systemctl enable sysstat
sudo systemctl restart sysstat

echo "=================================================="
echo "Cloning sysstat repository..."
echo "=================================================="

if [ ! -d "/sysstat" ]; then
    sudo git clone https://github.com/sysstat/sysstat.git
fi

cd /sysstat

echo "=================================================="
echo "Configuring and installing sysstat..."
echo "=================================================="

sudo ./configure
sudo ./configure --enable-install-cron
sudo make
sudo make install

echo "=================================================="
echo "Installing ArcGIS Monitor Agent..."
echo "=================================================="

cd /mount/netapp-stage/arcgis_repo/setups/Monitor_Agent/Agent


./Setup.sh -l yes

echo "=================================================="
echo "Creating ArcGIS Monitor Agent service..."
echo "=================================================="

sudo /home/arcgisservice/arcgis/monitor/agent/framework/etc/scripts/create_Monitor_Agent_service.sh

echo "=================================================="
echo "Starting ArcGIS Monitor Agent service..."
echo "=================================================="

sudo systemctl start arcgis-monitor-agent
sudo systemctl enable arcgis-monitor-agent

echo "=================================================="
echo "Registering ArcGIS Monitor Agent..."
echo "=================================================="

cd /home/arcgisservice/arcgis/monitor/agent/bin

./arcgis-monitor-agent admin:system:register \
  --server-url https://vm-gis-mgt-prd-usc-01.gis.esscompanies.com:30443/arcgis \
  --username monitoradmin \
  --password 'Macs#2026'

echo "=================================================="
echo "ArcGIS Monitor Agent setup completed successfully!"
echo "=================================================="