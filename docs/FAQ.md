# Frequently Asked Questions (FAQ)

## General Questions

### What is this project?

A ready-to-deploy CUPS print server for Raspberry Pi that enables network printing from any device. Deploy with Docker Compose or Ansible.

### Why use a Raspberry Pi as a print server?

- **Low power consumption**: ~2-5W vs 50-100W for a desktop PC
- **Silent operation**: No fans, no noise
- **24/7 availability**: Designed for continuous operation
- **Cost-effective**: $35-75 vs $200+ for commercial print servers
- **Space-saving**: Compact form factor
- **Network flexibility**: WiFi or Ethernet connectivity

### Which Raspberry Pi models are supported?

All models with network connectivity:
- **Recommended**: Raspberry Pi 3B+, 4, or 5
- **Supported**: Raspberry Pi 2B, 3B, Zero W/2W
- **Not recommended**: Raspberry Pi 1, Zero (without W)

### What printers are supported?

Most USB printers work out of the box:
- **HP**: Full support via HPLIP drivers
- **Epson**: Good support with ESC/P and ESC/P2
- **Canon**: Via Foomatic and Gutenprint
- **Brother**: PostScript and PCL models
- **Generic**: Any PostScript or PCL compatible printer

Check: https://www.openprinting.org/printers

## Installation Questions

### Do I need technical knowledge?

Basic knowledge helps, but the automated deployment is beginner-friendly:
- **Easy**: Use the deployment script
- **Moderate**: Manual Docker Compose setup
- **Advanced**: Ansible for multiple servers

### Can I run this on other devices?

Yes! While optimized for Raspberry Pi, it works on:
- Any Linux system with Docker
- Intel/AMD x86_64 systems
- ARM-based devices

May require Dockerfile adjustments for non-ARM architectures.

### How long does installation take?

- **Deployment script**: 10-15 minutes
- **Manual setup**: 20-30 minutes
- **Ansible**: 15-20 minutes (per server)

Mostly waiting for package downloads and Docker builds.

### I don't have a Raspberry Pi yet. Which should I buy?

**Best value**: Raspberry Pi 4 (4GB RAM)
- Great performance
- USB 3.0 ports
- Gigabit Ethernet
- Widely available

**Budget option**: Raspberry Pi 3B+
- Still very capable
- Lower power consumption

### Can I use Raspberry Pi OS Lite?

Yes! Lite is actually recommended:
- Smaller footprint
- Faster boot
- Less resource usage
- No desktop environment needed

## Network and Connectivity

### Can clients print over WiFi?

Yes! The print server and clients can use:
- Both on WiFi
- Both on Ethernet
- Mixed WiFi/Ethernet
- Across VLANs (with proper routing)

### Does it work with VPNs?

Yes, but with caveats:
- **Server on VPN**: Clients need VPN access
- **Client on VPN**: May need route configuration
- **Both on VPN**: Usually works fine

### Can I access it from the internet?

Possible but **not recommended** for security:
- Exposes your network
- Potential security risks
- Better: Use VPN to access home network

### How do I set a static IP?

Edit `/etc/dhcpcd.conf`:
```bash
interface eth0
static ip_address=192.168.1.100/24
static routers=192.168.1.1
static domain_name_servers=192.168.1.1
```

## Printer Configuration

### How many printers can I connect?

Limited by USB ports:
- Raspberry Pi 4: Up to 4 USB ports
- Use USB hub for more printers
- Powered USB hub recommended for >2 printers

### Can I share multiple printers?

Yes! CUPS supports unlimited printers:
- Each printer gets unique name
- All accessible via network
- Independent queues

### My printer isn't detected. What do I do?

1. Check USB connection: `lsusb`
2. Restart container: `docker compose restart`
3. Check CUPS logs: `docker compose logs cups`
4. Try different USB port
5. Check printer power

### Can I use network printers?

Not directly with this setup, but:
- This makes USB printers network printers
- Network printers can be added to CUPS
- Requires additional configuration

### How do I update printer drivers?

Drivers are in the Docker image:
```bash
make build  # Rebuild with latest drivers
make deploy # Deploy updated image
```

## Security Questions

### Is it secure?

With proper configuration, yes:
- Change default password ✓
- Use firewall rules ✓
- Keep system updated ✓
- Isolate on VLAN (optional)
- Use SSL/TLS (optional)

### What are the default credentials?

**Username**: admin  
**Password**: admin

**⚠️ CHANGE THESE IMMEDIATELY** in `.env` file!

### How do I enable HTTPS?

Requires additional setup:
1. Generate SSL certificate
2. Configure CUPS for SSL
3. Update docker-compose volumes
4. Restart container

See CUPS SSL documentation.

### Can I integrate with Active Directory?

Yes, but requires additional configuration:
- Install Kerberos support
- Configure CUPS for AD auth
- May need custom Dockerfile

## Performance Questions

### Can it handle high-volume printing?

Depends on:
- **Low volume** (< 50 pages/day): Any Pi works
- **Medium volume** (50-200 pages/day): Pi 3B+ or 4
- **High volume** (> 200 pages/day): Pi 4 with SSD

### Will it slow down my network?

No, minimal impact:
- Print jobs: Typically < 10MB
- Network usage: Negligible
- No streaming or heavy I/O

### How much disk space do I need?

- **Minimum**: 2GB free
- **Recommended**: 8GB free
- **High volume**: 16GB+ (for job history)

### Does it affect other services on the Pi?

Minimal impact:
- RAM usage: ~100-200MB
- CPU: Spikes during printing
- Can coexist with other Docker containers

## Troubleshooting

### Container won't start

```bash
# Check logs
docker compose logs cups

# Verify port availability
sudo netstat -tuln | grep 631

# Check Docker service
sudo systemctl status docker
```

### Can't access web interface

1. Verify container running: `docker compose ps`
2. Check firewall: `sudo ufw status`
3. Test locally: `curl http://localhost:631`
4. Check network connection

### Print jobs stuck in queue

1. Check printer: `lpstat -p`
2. Enable printer: `cupsenable PrinterName`
3. Check USB: `lsusb`
4. Restart: `docker compose restart`

### "Permission denied" errors

Common causes:
- Not in docker group: `sudo usermod -aG docker $USER`
- File permissions: `chmod 755 deploy.sh`
- USB access: Container runs in privileged mode

## Usage Questions

### How do I add a printer?

1. Open: `http://raspberry-pi:631`
2. Administration → Add Printer
3. Login with credentials
4. Select USB printer
5. Choose driver
6. Configure options

### Can I print from my phone?

Yes!
- **iOS**: Use AirPrint (automatic)
- **Android**: Install Mopria Print Service

### How do I remove a printer?

1. Web interface → Administration
2. Select printer → Delete Printer
3. Confirm deletion

### Can I set default printer?

Yes, in CUPS web interface:
- Administration → Manage Printers
- Select printer → Set as Default

## Ansible Questions

### Do I need Ansible for one Raspberry Pi?

No, use Docker Compose instead:
- Simpler setup
- Faster deployment
- Less overhead

Ansible is great for multiple servers.

### Can I use Ansible from Windows?

Use WSL2 (Windows Subsystem for Linux):
```bash
wsl --install
sudo apt install ansible
```

### How do I deploy to multiple Pis?

Add to `ansible/inventory.ini`:
```ini
[print_servers]
pi1 ansible_host=192.168.1.100 ansible_user=pi
pi2 ansible_host=192.168.1.101 ansible_user=pi
pi3 ansible_host=192.168.1.102 ansible_user=pi
```

Run: `ansible-playbook -i inventory.ini playbook.yml`

## Maintenance Questions

### How do I update the system?

**System updates**:
```bash
ssh pi@raspberrypi
sudo apt update && sudo apt upgrade
```

**Container updates**:
```bash
cd raspberry-pi-print-server
git pull
make build
make deploy
```

### How often should I update?

- **Security updates**: Weekly
- **System updates**: Monthly
- **Container rebuild**: Quarterly

### How do I backup configuration?

```bash
make backup
```

Stores in `backups/cups_config_TIMESTAMP.tar.gz`

### How do I restore from backup?

```bash
make restore FILE=backups/cups_config_20250101_120000.tar.gz
```

### Can I automate backups?

Yes, create a cron job:
```bash
crontab -e
# Add: 0 2 * * 0 cd /path/to/project && make backup
```

Runs weekly at 2 AM Sunday.

## Advanced Questions

### Can I customize the Docker image?

Yes! Edit `Dockerfile`:
```dockerfile
# Add your custom packages
RUN apt-get install -y your-package
```

Then rebuild: `make build`

### Can I run multiple CUPS instances?

Not recommended on same host:
- Port conflicts (631)
- USB device exclusivity
- Resource contention

Use multiple Raspberry Pis instead.

### How do I enable debug logging?

Edit `cups/cupsd.conf`:
```
LogLevel debug
```

Restart: `docker compose restart`

### Can I use PostgreSQL for job history?

CUPS uses its own job storage:
- SQLite-based
- Built into CUPS
- No external DB needed

For analytics, export logs.

### How do I monitor with Prometheus?

Requires custom exporter:
- Parse CUPS logs
- Expose metrics endpoint
- Configure Prometheus scraping

Not included by default.

## Still Have Questions?

- Check [README](../README.md)
- Review [Installation Guide](INSTALLATION.md)
- Search [GitHub Issues](https://github.com/dergachovda/raspberry-pi-print-server/issues)
- Open new issue if needed
