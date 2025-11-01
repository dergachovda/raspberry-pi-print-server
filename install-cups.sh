#!/bin/bash
# CUPS Print Server Setup for Raspberry Pi Zero W
# Supports USB + Network Printers (Bonjour/IPP)
# Safe to run multiple times

set -e

echo "=== Updating system packages ==="
sudo apt update && sudo apt upgrade -y

echo "=== Installing CUPS and required dependencies ==="
sudo apt install -y cups cups-client cups-bsd avahi-daemon dbus avahi-utils printer-driver-all sudo

echo "=== Ensuring lpadmin group exists and adding user ($USER) ==="
if ! getent group lpadmin >/dev/null; then
    sudo groupadd lpadmin
fi
sudo usermod -aG lpadmin "$USER"

echo "=== Configuring CUPS for remote access and sharing ==="
sudo cupsctl --remote-admin --remote-any --share-printers

CUPS_CONF="/etc/cups/cupsd.conf"
if [ ! -f "$CUPS_CONF.bak" ]; then
    echo "Backing up $CUPS_CONF..."
    sudo cp "$CUPS_CONF" "$CUPS_CONF.bak"
fi

# Ensure proper permissions for remote access
sudo sed -i 's/Listen localhost:631/Port 631/' "$CUPS_CONF"

# Guarantee these blocks exist
sudo tee "$CUPS_CONF" >/dev/null <<'EOF'
# CUPS Configuration - Auto-generated for Raspberry Pi Print Server

LogLevel warn
PageLogFormat

Port 631
Listen /var/run/cups/cups.sock

Browsing On
BrowseLocalProtocols dnssd

DefaultAuthType Basic

<Location />
  Order allow,deny
  Allow all
  Require all granted
</Location>

<Location /admin>
  AuthType Default
  Require all granted
</Location>

<Location /admin/conf>
  AuthType Default
  Require all granted
</Location>

<Location /printers>
  Require all granted
</Location>

# Share printers on the local network
<Policy default>
  <Limit All>
    Order allow,deny
    Allow all
    Require user @OWNER @SYSTEM
  </Limit>
</Policy>
EOF

echo "=== Enabling and starting CUPS service ==="
sudo systemctl enable cups
sudo systemctl restart cups

sleep 5

# --- USB Printers ---
echo "=== Detecting USB printers ==="
USB_PRINTERS=$(lpinfo -v | grep usb | awk '{print $2}')

if [ -z "$USB_PRINTERS" ]; then
    echo "No USB printers detected."
else
    for printer in $USB_PRINTERS; do
        PRINTER_NAME=$(echo "$printer" | sed 's/[:\/]/_/g')
        if lpstat -p "$PRINTER_NAME" &>/dev/null; then
            echo "USB printer $PRINTER_NAME already exists. Skipping."
        else
            echo "Adding USB printer $PRINTER_NAME ($printer)..."
            sudo lpadmin -p "$PRINTER_NAME" -v "$printer" -E -m everywhere
            sudo cupsenable "$PRINTER_NAME"
            sudo cupsaccept "$PRINTER_NAME"
        fi
    done
fi

# --- Network Printers via Bonjour/IPP ---
echo "=== Scanning network for IPP/Bonjour printers ==="
IPP_PRINTERS=$(avahi-browse -rt _ipp._tcp | grep "hostname" | awk -F';' '{print $7}' | sort -u)

if [ -z "$IPP_PRINTERS" ]; then
    echo "No network printers detected."
else
    for printer_host in $IPP_PRINTERS; do
        PRINTER_URI="ipp://$printer_host/ipp/print"
        PRINTER_NAME=$(echo "$printer_host" | sed 's/[:\/]/_/g')
        if lpstat -p "$PRINTER_NAME" &>/dev/null; then
            echo "Network printer $PRINTER_NAME already exists. Skipping."
        else
            echo "Adding network printer $PRINTER_NAME ($PRINTER_URI)..."
            sudo lpadmin -p "$PRINTER_NAME" -v "$PRINTER_URI" -E -m everywhere
            sudo cupsenable "$PRINTER_NAME"
            sudo cupsaccept "$PRINTER_NAME"
        fi
    done
fi

echo
echo "✅ CUPS setup complete!"
echo "Access your print server at:  http://$(hostname -I | awk '{print $1}'):631"
echo "or via Bonjour at:            http://raspberrypi.local:631"
echo
echo "Login using your Raspberry Pi username and password."
echo "You may need to log out and back in for lpadmin group changes to take effect."
