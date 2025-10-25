# Architecture

This document describes the architecture of the Raspberry Pi Print Server.

## Overview

The print server is built on a containerized architecture using Docker, with automated deployment via Ansible.

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                     Client Devices                               │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐        │
│  │ Windows  │  │  macOS   │  │  Linux   │  │  Mobile  │        │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └────┬─────┘        │
│       │             │              │             │               │
│       └─────────────┴──────────────┴─────────────┘               │
│                          │                                       │
│                     IPP Protocol                                 │
│                     (Port 631)                                   │
└──────────────────────────┼──────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────────┐
│                   Raspberry Pi Host                              │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │              Docker Container (CUPS)                        │ │
│  │  ┌──────────────────────────────────────────────────────┐  │ │
│  │  │              CUPS Web Interface                       │  │ │
│  │  │              (Port 631)                               │  │ │
│  │  └──────────────────────────────────────────────────────┘  │ │
│  │  ┌──────────────────────────────────────────────────────┐  │ │
│  │  │              CUPS Print Spooler                       │  │ │
│  │  │  - Job Queue Management                              │  │ │
│  │  │  - Print Job Processing                              │  │ │
│  │  │  - Printer Discovery                                 │  │ │
│  │  └──────────────────────────────────────────────────────┘  │ │
│  │  ┌──────────────────────────────────────────────────────┐  │ │
│  │  │              Printer Drivers                          │  │ │
│  │  │  - HP drivers (HPLIP)                                │  │ │
│  │  │  - Generic PostScript/PCL                            │  │ │
│  │  │  - Foomatic filters                                  │  │ │
│  │  │  - OpenPrinting PPDs                                 │  │ │
│  │  └──────────────────────────────────────────────────────┘  │ │
│  │                                                              │ │
│  │  Volumes:                                                    │ │
│  │  - cups-data (Print queue storage)                          │ │
│  │  - cups-cache (Temporary files)                             │ │
│  │  - cups-logs (Logging)                                      │ │
│  └────────────────────┼─────────────────────────────────────────┘ │
│                       │                                           │
│                       │ USB Pass-through                          │
│                       ▼                                           │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │              USB Printers                                   │  │
│  │  - HP LaserJet                                             │  │
│  │  - Epson Inkjet                                            │  │
│  │  - Canon Pixma                                             │  │
│  │  - Brother MFC                                             │  │
│  └────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

## Components

### 1. CUPS Container

**Base Image**: Debian Bookworm Slim
- Lightweight Linux distribution
- Optimized for ARM architecture
- Security updates from Debian stable

**Key Services**:
- CUPS daemon (cupsd)
- Web interface (HTTP server)
- IPP server
- Avahi/mDNS for network discovery

### 2. Storage Volumes

**Persistent Volumes**:
- `cups-data`: Print job queue and spool files
- `cups-cache`: Temporary cache files
- `cups-logs`: System and access logs

**Bind Mounts**:
- Configuration files (read-only)
- Ensures configuration persistence

### 3. Networking

**Network Mode**: Host
- Direct access to network stack
- Enables mDNS/Avahi discovery
- Simplifies firewall configuration
- Port 631 exposed for IPP/HTTP

### 4. USB Device Access

**Privileged Mode**: Enabled
- Full USB device access
- Direct printer communication
- Real-time device detection

## Data Flow

### Print Job Processing

1. **Client submits print job**
   - Via IPP protocol on port 631
   - Authentication with CUPS credentials

2. **CUPS receives job**
   - Validates user permissions
   - Queues job in spool directory

3. **Job processing**
   - Applies printer-specific filters
   - Converts to printer language (PostScript, PCL, etc.)
   - Applies page formatting

4. **Job transmission**
   - Sends to USB printer
   - Monitors job status
   - Updates job queue

5. **Completion**
   - Logs job completion
   - Notifies client
   - Cleans up spool files

## Deployment Architecture

### Manual Deployment

```
User's Computer
      │
      ├─ Clone Repository
      │
      ▼
Raspberry Pi
      ├─ Docker Compose
      │   └─ Build Image
      │       └─ Pull Base Image
      │       └─ Install Packages
      │       └─ Configure CUPS
      │
      └─ Start Container
          └─ Mount Volumes
          └─ Bind USB Devices
          └─ Start CUPS Service
```

### Ansible Deployment

```
Control Machine
      │
      ├─ Ansible Playbook
      │
      ▼
Raspberry Pi(s)
      ├─ System Update
      ├─ Install Docker
      ├─ Configure Docker
      ├─ Transfer Files
      │   ├─ docker-compose.yml
      │   ├─ Dockerfile
      │   └─ CUPS configs
      │
      └─ Deploy Container
          ├─ Build Image
          └─ Start Services
```

## Security Architecture

### Access Control Layers

1. **Network Level**
   - Firewall rules (ufw/iptables)
   - Network segmentation (VLANs)

2. **CUPS Level**
   - HTTP Basic Authentication
   - Policy-based access control
   - User/group permissions

3. **Container Level**
   - Isolated filesystem
   - Resource limits (optional)
   - Read-only configuration mounts

4. **System Level**
   - SSH key authentication
   - Sudo password protection
   - User group memberships

### Authentication Flow

```
User Request → Network Firewall → CUPS Auth → Policy Check → Printer Access
```

## Scalability

### Horizontal Scaling

Deploy multiple print servers:
```
Ansible Inventory:
  - printserver1 (Office A)
  - printserver2 (Office B)
  - printserver3 (Office C)
```

Each server:
- Independent CUPS instance
- Local printer management
- Centralized configuration via Ansible

### Vertical Scaling

For high-volume printing:
- Use Raspberry Pi 4 (4GB+ RAM)
- Add SSD for spool storage
- Optimize CUPS worker threads

## Monitoring

### Container Health

- Docker healthcheck (lpstat)
- Container restart policy
- Resource usage monitoring

### CUPS Metrics

- Print job success/failure rates
- Queue depth
- Printer status
- Error logs

## Backup and Recovery

### Configuration Backup

```bash
make backup
```

Creates timestamped archive:
- CUPS configuration
- Printer definitions
- User settings

### Recovery

```bash
make restore FILE=backup.tar.gz
```

Restores:
- All CUPS settings
- Printer configurations
- Maintains job history

## Updates and Maintenance

### Container Updates

```bash
# Pull latest base image
make pull

# Rebuild with updates
make build

# Deploy updated version
make deploy
```

### System Updates

Ansible playbook handles:
- System package updates
- Docker updates
- Security patches

## Performance Considerations

### Resource Requirements

**Minimum**:
- Raspberry Pi 2B
- 512MB RAM
- 2GB disk space

**Recommended**:
- Raspberry Pi 3B+ or 4
- 1GB+ RAM
- 8GB+ disk space
- Ethernet connection

### Optimization Tips

1. Use local DNS for faster discovery
2. Enable print job caching
3. Limit concurrent print jobs
4. Use SSD for heavy workloads
5. Monitor resource usage

## Troubleshooting Architecture

### Diagnostic Layers

1. **Container Level**
   ```bash
   docker compose ps
   docker compose logs
   ```

2. **CUPS Level**
   ```bash
   lpstat -t
   cupsctl --debug-logging
   ```

3. **System Level**
   ```bash
   lsusb
   dmesg | grep usb
   ```

4. **Network Level**
   ```bash
   netstat -tuln
   nmap localhost
   ```

## Future Enhancements

Potential architecture improvements:
- SSL/TLS encryption
- LDAP/Active Directory integration
- Cloud printing gateway
- Prometheus metrics export
- Grafana dashboards
- Multi-container setup (separate web UI)
- Redis for job queue
- PostgreSQL for job history
