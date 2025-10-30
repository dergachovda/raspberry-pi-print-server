# Raspberry Pi Print Server

A complete, ready-to-deploy CUPS print server for Raspberry Pi using Docker Compose and Ansible.

## Features

- 🖨️ **CUPS Print Server** - Industry-standard printing system
- 🐳 **Docker-based** - Easy deployment and management
- 🤖 **Ansible automation** - Automated deployment on Raspberry Pi
- 🌐 **Network printing** - Share printers across your network
- 📱 **Web interface** - Easy printer management through browser
- 🔧 **Multiple printer support** - HP, Epson, Canon, Brother, and more
- 🔄 **Auto-restart** - Container automatically restarts on failure

## Prerequisites

### For Manual Deployment (Docker Compose)

- Raspberry Pi (any model with network connectivity)
- Raspberry Pi OS (Debian-based)
- Docker and Docker Compose installed
- USB printer(s) connected to Raspberry Pi

### For Automated Deployment (Ansible)

- Ansible installed on your control machine
- SSH access to Raspberry Pi
- Raspberry Pi with network connectivity

## Quick Start

### Option 1: Manual Deployment with Docker Compose

1. **Clone this repository:**
   ```bash
   git clone https://github.com/dergachovda/raspberry-pi-print-server.git
   cd raspberry-pi-print-server
   ```

2. **Create environment file:**
   ```bash
   cp .env.example .env
   # Edit .env to set your admin credentials
   nano .env
   ```

3. **Deploy using the script:**
   ```bash
   ./deploy.sh deploy
   ```

4. **Access CUPS web interface:**
   - Open browser: `http://raspberry-pi-ip:631`
   - Login with credentials from `.env` file
   - Add your printers through the web interface

### Option 2: Automated Deployment with Ansible

1. **Configure inventory:**
   ```bash
   cd ansible
   nano inventory.ini
   ```
   
   Add your Raspberry Pi:
   ```ini
   [print_servers]
   raspberrypi ansible_host=192.168.1.100 ansible_user=pi
   ```

2. **Run Ansible playbook:**
   ```bash
   cd ansible
   ansible-playbook -i inventory.ini playbook.yml
   ```

3. **Access CUPS web interface:**
   - Open browser: `http://raspberry-pi-ip:631`
   - Login with admin/admin (or your configured credentials)

## Configuration

### Environment Variables

Edit `.env` file to customize:

```env
CUPS_ADMIN_USER=admin
CUPS_ADMIN_PASSWORD=admin
COMPOSE_PROJECT_NAME=raspberry-pi-print-server
```

### CUPS Configuration

Configuration files are located in `cups/` directory:
- `cupsd.conf` - Main CUPS configuration
- `cups-files.conf` - File system configuration
- `printers.conf` - Printer definitions (auto-generated)

## Usage

### Managing the Print Server

**Using the deploy script:**
```bash
./deploy.sh deploy   # Build and start
./deploy.sh stop     # Stop containers
./deploy.sh restart  # Restart containers
./deploy.sh logs     # View logs
./deploy.sh status   # Check status
```

**Using Docker Compose directly:**
```bash
docker compose up -d      # Start
docker compose down       # Stop
docker compose logs -f    # View logs
docker compose restart    # Restart
```

### Adding Printers

1. Open CUPS web interface: `http://raspberry-pi-ip:631`
2. Navigate to "Administration" tab
3. Click "Add Printer"
4. Select your USB printer
5. Choose appropriate driver
6. Configure printer settings
7. Print test page

### Accessing from Client Devices

#### Windows
1. Open "Devices and Printers"
2. Click "Add a printer"
3. Select "The printer that I want isn't listed"
4. Choose "Select a shared printer by name"
5. Enter: `http://raspberry-pi-ip:631/printers/PrinterName`

#### macOS
1. Open "System Preferences" → "Printers & Scanners"
2. Click "+" to add printer
3. Select "IP" tab
4. Enter Raspberry Pi IP address
5. Protocol: "Internet Printing Protocol - IPP"
6. Queue: `printers/PrinterName`

#### Linux
1. Open printer settings
2. Add → Network Printer → Internet Printing Protocol (ipp)
3. Enter: `ipp://raspberry-pi-ip:631/printers/PrinterName`

#### Mobile Devices
- iOS: Use AirPrint (printers will appear automatically)
- Android: Use "Google Cloud Print" or "Mopria Print Service"

## Ansible Deployment Details

The Ansible playbook performs the following tasks:

1. Updates system packages
2. Installs Docker and Docker Compose
3. Configures Docker service
4. Deploys print server files
5. Builds and starts containers
6. Displays access information

### Ansible Tags

Run specific parts of the playbook:

```bash
# Only install Docker
ansible-playbook -i inventory.ini playbook.yml --tags docker

# Only deploy the print server
ansible-playbook -i inventory.ini playbook.yml --tags deploy

# Skip system updates
ansible-playbook -i inventory.ini playbook.yml --skip-tags system
```

### Variables

Override default variables in inventory or command line:

```bash
ansible-playbook -i inventory.ini playbook.yml \
  -e "cups_admin_user=myadmin" \
  -e "cups_admin_password=securepass"
```

## Troubleshooting

### Container won't start
```bash
# Check logs
docker compose logs cups

# Check if port 631 is available
sudo netstat -tulpn | grep 631

# Verify USB devices
lsusb
```

### Printer not detected
```bash
# Check USB connections
lsusb

# Restart container
docker compose restart cups

# Check CUPS logs
docker compose logs cups | grep -i error
```

### Cannot access web interface
```bash
# Check if container is running
docker compose ps

# Verify firewall settings
sudo ufw status
sudo ufw allow 631/tcp

# Check container networking
docker compose exec cups netstat -tulpn
```

### Permission issues
```bash
# Ensure proper permissions
sudo chmod -R 755 cups/
sudo chown -R $USER:$USER cups/
```

## Security Considerations

1. **Change default credentials** - Always change default admin password
2. **Firewall** - Configure firewall to restrict access to port 631
3. **HTTPS** - Consider setting up SSL/TLS for encrypted connections
4. **Network isolation** - Keep print server on isolated VLAN if possible
5. **Updates** - Regularly update Docker images and system packages

## Advanced Configuration

### Enable SSL/TLS

1. Generate SSL certificate
2. Update `cupsd.conf` to enable encryption
3. Mount certificate volumes in docker-compose.yml

### Network Scanning

To enable network scanning (if printer supports it), additional configuration may be required in CUPS.

### Print Quotas

Configure print quotas by editing `cupsd.conf`:
```conf
<Policy default>
  PageLimit 1000
  KLimit 10000
</Policy>
```

## File Structure

```
raspberry-pi-print-server/
├── ansible/
│   ├── ansible.cfg          # Ansible configuration
│   ├── inventory.ini        # Host inventory
│   └── playbook.yml         # Deployment playbook
├── cups/
│   ├── cupsd.conf          # Main CUPS config
│   ├── cups-files.conf     # Files config
│   └── printers.conf       # Printer definitions
├── docker-compose.yml       # Docker Compose config
├── Dockerfile              # CUPS container image
├── deploy.sh               # Deployment script
├── .env.example            # Environment template
├── .gitignore             # Git ignore rules
└── README.md              # This file
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

MIT License - feel free to use this project for any purpose.

## Support

For issues and questions:
- Open an issue on GitHub
- Check CUPS documentation: https://www.cups.org/doc/
- Raspberry Pi forums: https://forums.raspberrypi.com/

## Acknowledgments

- CUPS (Common UNIX Printing System) - https://www.cups.org/
- Docker - https://www.docker.com/
- Ansible - https://www.ansible.com/
- Raspberry Pi Foundation - https://www.raspberrypi.org/