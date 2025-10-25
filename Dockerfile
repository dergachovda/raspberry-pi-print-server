FROM debian:bookworm-slim

# Install CUPS and common printer drivers
RUN apt-get update && apt-get install -y \
    cups \
    cups-bsd \
    cups-client \
    cups-filters \
    foomatic-db-compressed-ppds \
    printer-driver-all \
    openprinting-ppds \
    hpijs-ppds \
    hp-ppd \
    hplip \
    samba-client \
    avahi-daemon \
    avahi-discover \
    libnss-mdns \
    inotify-tools \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Add print user
RUN useradd -r -G lpadmin -M printadmin

# Expose CUPS web interface and IPP ports
EXPOSE 631

# Copy CUPS configuration
COPY cups/cupsd.conf /etc/cups/cupsd.conf
COPY cups/cups-files.conf /etc/cups/cups-files.conf

# Create necessary directories
RUN mkdir -p /var/spool/cups /var/cache/cups /var/log/cups

# Set permissions
RUN chown -R root:lpadmin /etc/cups /var/spool/cups /var/cache/cups /var/log/cups

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD lpstat -r || exit 1

# Start CUPS in foreground
CMD ["/usr/sbin/cupsd", "-f"]
