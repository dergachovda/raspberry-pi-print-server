# Quick Start Guide

Get your Raspberry Pi print server up and running in minutes!

## Prerequisites

- Raspberry Pi with Raspberry Pi OS installed
- Network connection
- USB printer(s)

## Option 1: One-Line Installation (Recommended for beginners)

On your Raspberry Pi, run:

```bash
curl -fsSL https://raw.githubusercontent.com/dergachovda/raspberry-pi-print-server/main/deploy.sh | bash -s deploy
```

That's it! Access CUPS at `http://your-pi-ip:631`

## Option 2: Manual Installation

### Step 1: Install Docker

```bash
curl -fsSL https://get.docker.com | sudo sh
sudo usermod -aG docker $USER
```

Log out and back in, then:

### Step 2: Clone and Deploy

```bash
git clone https://github.com/dergachovda/raspberry-pi-print-server.git
cd raspberry-pi-print-server
cp .env.example .env
# Edit .env if needed: nano .env
./deploy.sh deploy
```

## Option 3: Ansible (For multiple Raspberry Pis)

On your computer (not Raspberry Pi):

```bash
# Install Ansible
sudo apt install ansible  # Ubuntu/Debian
# OR
brew install ansible       # macOS

# Clone repo
git clone https://github.com/dergachovda/raspberry-pi-print-server.git
cd raspberry-pi-print-server/ansible

# Edit inventory
nano inventory.ini
# Add your Pi: raspberrypi ansible_host=192.168.1.100 ansible_user=pi

# Deploy
ansible-playbook -i inventory.ini playbook.yml
```

## Adding Your First Printer

1. Open browser: `http://your-raspberry-pi:631`
2. Click "Administration" → "Add Printer"
3. Login with admin/admin (or your credentials from .env)
4. Select your USB printer
5. Choose driver
6. Done!

## Accessing from Other Devices

### Windows
1. Settings → Devices → Printers & scanners
2. Add printer → "The printer that I want isn't listed"
3. Enter: `http://your-raspberry-pi:631/printers/PrinterName`

### macOS
1. System Preferences → Printers & Scanners
2. Click "+" → IP
3. Address: `your-raspberry-pi`, Protocol: IPP
4. Queue: `printers/PrinterName`

### Linux
```bash
lpadmin -p MyPrinter -E -v ipp://your-raspberry-pi:631/printers/PrinterName -m everywhere
```

### Mobile
- **iOS**: Works automatically with AirPrint
- **Android**: Use Mopria Print Service from Play Store

## Troubleshooting

### Container not starting?
```bash
docker compose logs cups
```

### Can't access web interface?
```bash
# Check if running
docker compose ps

# Allow firewall
sudo ufw allow 631/tcp
```

### Printer not detected?
```bash
# Check USB
lsusb

# Restart container
docker compose restart cups
```

## Common Commands

```bash
# View status
docker compose ps

# View logs
docker compose logs -f cups

# Restart
docker compose restart cups

# Stop
docker compose down

# Start
docker compose up -d
```

## Next Steps

- Read the full [README](README.md)
- Check [Installation Guide](docs/INSTALLATION.md)
- Review [Contributing](CONTRIBUTING.md)

## Getting Help

- Check [README troubleshooting section](README.md#troubleshooting)
- Open an issue on GitHub
- CUPS documentation: https://www.cups.org/doc/

## Security Notes

⚠️ **Important**: Change default password!

Edit `.env`:
```
CUPS_ADMIN_USER=myadmin
CUPS_ADMIN_PASSWORD=securepassword123
```

Then restart:
```bash
docker compose down
docker compose up -d
```
