# Security Best Practices

This guide outlines security best practices for deploying and maintaining the Raspberry Pi Print Server.

## Initial Setup Security

### 1. Change Default Credentials

**Immediately** change default CUPS admin credentials:

Edit `.env`:
```env
CUPS_ADMIN_USER=your_secure_username
CUPS_ADMIN_PASSWORD=your_strong_password
```

Use strong passwords:
- Minimum 12 characters
- Mix of letters, numbers, symbols
- Not based on dictionary words
- Unique to this service

### 2. Secure SSH Access

**Use SSH keys** instead of passwords:
```bash
# On your computer, generate key
ssh-keygen -t ed25519 -C "your_email@example.com"

# Copy to Raspberry Pi
ssh-copy-id pi@raspberrypi.local

# Disable password authentication
ssh pi@raspberrypi.local
sudo nano /etc/ssh/sshd_config
```

Set:
```
PasswordAuthentication no
PubkeyAuthentication yes
```

Restart SSH:
```bash
sudo systemctl restart sshd
```

### 3. Enable Firewall

Configure UFW (Uncomplicated Firewall):
```bash
# Enable firewall
sudo ufw enable

# Allow SSH
sudo ufw allow 22/tcp

# Allow CUPS only from local network
sudo ufw allow from 192.168.1.0/24 to any port 631

# Check status
sudo ufw status
```

### 4. Update System

Before deployment:
```bash
sudo apt update
sudo apt upgrade -y
sudo reboot
```

## Network Security

### Isolate Print Server

**Option 1: VLAN Isolation**
- Place print server on separate VLAN
- Configure firewall rules between VLANs
- Allow only printing ports (631)

**Option 2: Network Segmentation**
- Use separate subnet for IoT devices
- Implement network ACLs
- Limit inter-subnet communication

### Restrict Access by IP

In `cups/cupsd.conf`, restrict access:
```conf
<Location />
  Order deny,allow
  Deny from all
  Allow from 192.168.1.0/24
  Allow from localhost
</Location>
```

### Use Private Network Only

**Never expose to public internet** without:
- VPN access
- Reverse proxy with authentication
- SSL/TLS encryption
- Rate limiting
- Intrusion detection

## Container Security

### Run with Minimal Privileges

Current setup requires privileged mode for USB access. To improve:

1. **Use specific capabilities** instead of full privileged:
```yaml
cap_add:
  - CAP_DAC_OVERRIDE
  - CAP_SYS_ADMIN
cap_drop:
  - ALL
privileged: false
```

2. **Create device rules** for specific printers:
```yaml
devices:
  - /dev/usb/lp0:/dev/usb/lp0
```

### Read-Only Filesystems

Configuration files are already read-only:
```yaml
volumes:
  - ./cups/cupsd.conf:/etc/cups/cupsd.conf:ro
```

### Resource Limits

Add resource constraints in `docker-compose.yml`:
```yaml
services:
  cups:
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 512M
        reservations:
          memory: 256M
```

### Regular Image Updates

Rebuild image monthly:
```bash
git pull
make build
make deploy
```

Updates base image and security patches.

## CUPS Security

### Authentication Settings

In `cups/cupsd.conf`:
```conf
# Require authentication for admin
<Location /admin>
  AuthType Basic
  Require user @SYSTEM
</Location>

# Require authentication for config
<Location /admin/conf>
  AuthType Basic
  Require user @SYSTEM
</Location>
```

### Disable Unnecessary Features

If not using web interface:
```conf
WebInterface No
```

If not using network browsing:
```conf
Browsing Off
```

### Job Privacy

Prevent users from viewing others' jobs:
```conf
<Policy default>
  JobPrivateAccess default
  JobPrivateValues default
</Policy>
```

### Limit Job Size

Prevent DOS attacks via large jobs:
```conf
MaxJobSize 100m  # 100 MB limit
```

## SSL/TLS Encryption

### Generate SSL Certificate

```bash
# Generate self-signed certificate
sudo openssl req -new -x509 -keyout server.key -out server.crt -days 365 -nodes

# Or use Let's Encrypt for valid certificate
```

### Configure CUPS for SSL

In `cups/cupsd.conf`:
```conf
DefaultEncryption Required

ServerCertificate /etc/cups/ssl/server.crt
ServerKey /etc/cups/ssl/server.key
```

Update `docker-compose.yml`:
```yaml
volumes:
  - ./ssl/server.crt:/etc/cups/ssl/server.crt:ro
  - ./ssl/server.key:/etc/cups/ssl/server.key:ro
```

## Monitoring and Auditing

### Enable Detailed Logging

Temporarily for debugging:
```conf
LogLevel debug
```

For production:
```conf
LogLevel warn
```

### Monitor Logs

```bash
# Watch logs in real-time
docker compose logs -f cups

# Search for failed authentication
docker compose logs cups | grep -i "authentication failed"

# Check for suspicious activity
docker compose logs cups | grep -i "denied"
```

### Automated Log Monitoring

Use logwatch or similar:
```bash
sudo apt install logwatch
```

Configure to email alerts on suspicious activity.

### Log Rotation

Docker handles log rotation, but configure limits:
```yaml
services:
  cups:
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
```

## System Hardening

### Automatic Security Updates

```bash
sudo apt install unattended-upgrades
sudo dpkg-reconfigure unattended-upgrades
```

Edit `/etc/apt/apt.conf.d/50unattended-upgrades`:
```
Unattended-Upgrade::Automatic-Reboot "false";
Unattended-Upgrade::Mail "your@email.com";
```

### Disable Unnecessary Services

```bash
# List running services
systemctl list-units --type=service --state=running

# Disable unused services
sudo systemctl disable bluetooth
sudo systemctl disable avahi-daemon  # if not using mDNS
```

### Harden SSH Further

In `/etc/ssh/sshd_config`:
```
PermitRootLogin no
MaxAuthTries 3
MaxSessions 2
ClientAliveInterval 300
ClientAliveCountMax 2
```

### Fail2Ban

Install to prevent brute force:
```bash
sudo apt install fail2ban

# Configure for SSH
sudo nano /etc/fail2ban/jail.local
```

Add:
```ini
[sshd]
enabled = true
port = 22
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 3600
```

## Backup Security

### Encrypt Backups

```bash
# Create encrypted backup
make backup
gpg -c backups/cups_config_*.tar.gz

# Decrypt when needed
gpg -d cups_config_encrypted.tar.gz.gpg > cups_config.tar.gz
```

### Secure Backup Storage

- Store backups off-device
- Use encrypted storage
- Limit access permissions
- Test restore regularly

### Backup Credentials

Store `.env` file securely:
```bash
# Encrypt credentials
gpg -c .env

# Store encrypted version only
rm .env
```

## Incident Response

### If Compromised

1. **Disconnect from network**
   ```bash
   sudo ifconfig eth0 down
   ```

2. **Stop containers**
   ```bash
   docker compose down
   ```

3. **Analyze logs**
   ```bash
   docker compose logs cups > incident_logs.txt
   ```

4. **Check for unauthorized changes**
   ```bash
   git status
   git diff
   ```

5. **Restore from backup**
   ```bash
   make restore FILE=last_good_backup.tar.gz
   ```

6. **Change all credentials**

7. **Update system**
   ```bash
   sudo apt update && sudo apt upgrade
   ```

8. **Rebuild container**
   ```bash
   make build
   ```

## Compliance Considerations

### GDPR Compliance

- Minimize data collection
- Implement data retention policies
- Provide user data access
- Enable data deletion

### HIPAA Compliance

If printing sensitive health information:
- Enable encryption (SSL/TLS)
- Implement audit logging
- Restrict physical access
- Use encrypted storage

### PCI DSS Compliance

Never print credit card information:
- Violates PCI DSS requirements
- Use secure payment processing instead

## Security Checklist

Before going live:

- [ ] Changed default CUPS credentials
- [ ] Configured firewall (UFW)
- [ ] Enabled SSH key authentication
- [ ] Disabled SSH password authentication
- [ ] Updated system packages
- [ ] Configured network isolation
- [ ] Enabled automatic security updates
- [ ] Set up log monitoring
- [ ] Created backup strategy
- [ ] Tested disaster recovery
- [ ] Documented security procedures
- [ ] Reviewed CUPS access policies
- [ ] Limited network exposure
- [ ] Configured resource limits
- [ ] Enabled SSL/TLS (if needed)

## Regular Security Maintenance

### Weekly
- Review logs for anomalies
- Check failed login attempts
- Monitor resource usage

### Monthly
- Apply system updates
- Rebuild Docker image
- Test backups
- Review firewall rules

### Quarterly
- Rotate credentials
- Security audit
- Review access logs
- Update documentation

### Annually
- Full security assessment
- Penetration testing (if critical)
- Review and update policies
- Train users on security

## Reporting Security Issues

If you find a security vulnerability:

1. **Do NOT** open a public issue
2. Email: security@example.com (replace with your configured email)
3. Or open a GitHub Security Advisory in the repository
4. Include:
   - Description of vulnerability
   - Steps to reproduce
   - Potential impact
   - Suggested fix (if any)

## Additional Resources

- [CUPS Security](https://www.cups.org/doc/security.html)
- [Docker Security Best Practices](https://docs.docker.com/engine/security/)
- [Raspberry Pi Security](https://www.raspberrypi.org/documentation/configuration/security.md)
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)

## Disclaimer

This guide provides recommendations for improving security but cannot guarantee complete protection. Security is an ongoing process requiring vigilance and regular updates.
