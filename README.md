# CUPS Print Server install script for Raspberry Pi Zero W

## 💡 Usage

1. Make it executable:

```shell
chmod +x install-cups.sh
```


2. Run it:

```shell
./install-cups.sh
```


3. After installation, open in your browser:

http://raspberrypi.local:631

or http://<your Pi IP>:631

## ✅ Features Recap

- Auto-installs CUPS + printer drivers + Avahi (Bonjour)
- Configures remote web admin access (no “Forbidden”)
- Adds USB and network printers automatically
- Idempotent (safe to rerun — no duplicates)
- Backs up original configuration on first run
- Enables network sharing