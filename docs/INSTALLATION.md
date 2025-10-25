# Installation Guide

This guide provides detailed installation instructions for deploying the Raspberry Pi Print Server.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Raspberry Pi Setup](#raspberry-pi-setup)
3. [Manual Installation](#manual-installation)
4. [Ansible Installation](#ansible-installation)
5. [Post-Installation](#post-installation)

## Prerequisites

### Hardware Requirements

- Raspberry Pi (Model 2B or newer recommended)
  - Raspberry Pi 3B/3B+ (recommended)
  - Raspberry Pi 4 (best performance)
  - Raspberry Pi Zero W (minimal, but works)
- MicroSD card (8GB minimum, 16GB+ recommended)
- USB printer(s)
- Power supply appropriate for your Pi model
- Network connection (Ethernet or WiFi)

### Software Requirements

- Raspberry Pi OS (Debian Bookworm or newer)
- At least 2GB free disk space
- Internet connection for initial setup

## Raspberry Pi Setup

### 1. Install Raspberry Pi OS

1. Download Raspberry Pi Imager: https://www.raspberrypi.org/software/
2. Insert MicroSD card into your computer
3. Open Raspberry Pi Imager
4. Choose OS: Raspberry Pi OS (64-bit recommended)
5. Choose Storage: Your MicroSD card
6. Click Settings (gear icon):
   - Enable SSH
   - Set username and password
   - Configure WiFi (if using wireless)
   - Set hostname (e.g., printserver)
7. Write the image to the card
8. Insert card into Raspberry Pi and power on

### 2. Initial Raspberry Pi Configuration

Connect to your Raspberry Pi via SSH:

```bash
ssh pi@raspberrypi.local
# or use the IP address
ssh pi@192.168.1.100
```

Update the system:

```bash
sudo apt update
sudo apt upgrade -y
sudo reboot
```

### 3. Enable USB

Ensure USB support is enabled (usually is by default):

```bash
lsusb
```

You should see a list of USB devices.

## Manual Installation

### Step 1: Install Docker

```bash
# Install dependencies
sudo apt install -y apt-transport-https ca-certificates curl gnupg lsb-release

# Add Docker's official GPG key
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Set up the stable repository
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker Engine
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Add your user to the docker group
sudo usermod -aG docker $USER

# Log out and back in for group changes to take effect
exit
```

Log back in:
```bash
ssh pi@raspberrypi.local
```

Verify Docker installation:
```bash
docker --version
docker compose version
```

### Step 2: Clone Repository

```bash
cd ~
git clone https://github.com/dergachovda/raspberry-pi-print-server.git
cd raspberry-pi-print-server
```

### Step 3: Configure Environment

```bash
cp .env.example .env
nano .env
```

Edit the credentials:
```env
CUPS_ADMIN_USER=yourusername
CUPS_ADMIN_PASSWORD=yourpassword
```

Save and exit (Ctrl+X, Y, Enter).

### Step 4: Deploy

Using the deployment script:
```bash
chmod +x deploy.sh
./deploy.sh deploy
```

Or using Docker Compose directly:
```bash
docker compose build
docker compose up -d
```

### Step 5: Verify Installation

Check container status:
```bash
docker compose ps
```

View logs:
```bash
docker compose logs cups
```

## Ansible Installation

### Step 1: Install Ansible (on your control machine)

On Ubuntu/Debian:
```bash
sudo apt update
sudo apt install -y ansible
```

On macOS:
```bash
brew install ansible
```

On other systems, see: https://docs.ansible.com/ansible/latest/installation_guide/

### Step 2: Configure SSH Access

Ensure you can SSH to your Raspberry Pi without password:

```bash
ssh-copy-id pi@raspberrypi.local
```

Test connection:
```bash
ssh pi@raspberrypi.local
exit
```

### Step 3: Clone Repository (on control machine)

```bash
git clone https://github.com/dergachovda/raspberry-pi-print-server.git
cd raspberry-pi-print-server
```

### Step 4: Configure Inventory

Edit the inventory file:
```bash
cd ansible
nano inventory.ini
```

Add your Raspberry Pi:
```ini
[print_servers]
raspberrypi ansible_host=192.168.1.100 ansible_user=pi

[print_servers:vars]
cups_admin_user=admin
cups_admin_password=SecurePassword123
```

Save and exit.

### Step 5: Run Ansible Playbook

Test connection:
```bash
ansible -i inventory.ini print_servers -m ping
```

Run the playbook:
```bash
ansible-playbook -i inventory.ini playbook.yml
```

Watch the deployment progress. When complete, you'll see the access information.

### Step 6: Verify Installation

SSH to your Raspberry Pi:
```bash
ssh pi@raspberrypi.local
cd /opt/print-server
docker compose ps
```

## Post-Installation

### 1. Access Web Interface

Open a web browser and navigate to:
- `http://raspberrypi.local:631` (if mDNS is working)
- `http://192.168.1.100:631` (replace with your Pi's IP)

You should see the CUPS web interface.

### 2. Add Printers

1. Click "Administration" tab
2. Click "Add Printer"
3. Log in with your configured credentials
4. Select your USB printer from the list
5. Continue through the wizard
6. Choose the appropriate printer driver
7. Set printer options
8. Print a test page

### 3. Configure Firewall (if enabled)

If you have a firewall enabled on your Pi:

```bash
sudo ufw allow 631/tcp
sudo ufw reload
```

### 4. Set Static IP (recommended)

Edit dhcpcd configuration:
```bash
sudo nano /etc/dhcpcd.conf
```

Add at the end:
```
interface eth0
static ip_address=192.168.1.100/24
static routers=192.168.1.1
static domain_name_servers=192.168.1.1 8.8.8.8
```

For WiFi, use `interface wlan0` instead.

Reboot to apply:
```bash
sudo reboot
```

### 5. Enable Automatic Updates (optional)

To keep your system secure:

```bash
sudo apt install -y unattended-upgrades
sudo dpkg-reconfigure -plow unattended-upgrades
```

## Troubleshooting

### Docker installation fails

If Docker installation fails, try the convenience script:
```bash
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
```

### Cannot access web interface

Check if the container is running:
```bash
docker compose ps
```

Check logs:
```bash
docker compose logs cups
```

Verify port is listening:
```bash
sudo netstat -tulpn | grep 631
```

### Printer not showing up

Check USB connections:
```bash
lsusb
```

Restart the container:
```bash
docker compose restart cups
```

Check CUPS logs:
```bash
docker compose logs cups | grep -i usb
```

### Permission denied errors

Ensure your user is in the docker group:
```bash
groups
```

If not, add yourself:
```bash
sudo usermod -aG docker $USER
```

Log out and back in.

## Next Steps

- Read the [User Guide](USER_GUIDE.md) for printer configuration
- Check [Troubleshooting Guide](../README.md#troubleshooting)

## Support

For additional help:
- Check the main [README](../README.md)
- Open an issue on GitHub
- CUPS documentation: https://www.cups.org/doc/
