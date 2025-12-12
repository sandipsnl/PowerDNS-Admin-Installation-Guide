# PowerDNS + PowerDNS-Admin Automated Installation Script

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![PowerDNS](https://img.shields.io/badge/PowerDNS-4.5+-blue.svg)](https://www.powerdns.com/)
[![Ubuntu](https://img.shields.io/badge/Ubuntu-20.04%20%7C%2022.04-orange.svg)](https://ubuntu.com/)
[![Debian](https://img.shields.io/badge/Debian-11%20%7C%2012-red.svg)](https://www.debian.org/)

This script automates the complete installation and configuration of PowerDNS Authoritative Server with PowerDNS-Admin web interface on Ubuntu/Debian systems.

## 📋 Table of Contents

- [Features](#features)
- [Requirements](#requirements)
- [What Gets Installed](#what-gets-installed)
- [Quick Start](#quick-start)
- [Installation](#installation)
- [Post-Installation](#post-installation)
- [Configuration](#configuration)
- [Usage Guide](#usage-guide)
- [Optional: DoH/DoT Setup](#optional-dohdot-setup)
- [Troubleshooting](#troubleshooting)
- [Security Best Practices](#security-best-practices)
- [Uninstallation](#uninstallation)
- [FAQ](#faq)
- [Contributing](#contributing)
- [License](#license)

---

## ✨ Features

- ✅ **Fully Automated**: One-command installation with minimal user interaction
- ✅ **PowerDNS Authoritative Server**: Latest stable version with SQLite backend
- ✅ **PowerDNS-Admin**: Modern web interface for DNS management
- ✅ **MariaDB Backend**: Separate database for PowerDNS-Admin
- ✅ **Secure by Default**: Auto-generated API keys and passwords
- ✅ **Systemd Integration**: Automatic service management
- ✅ **Optional dnsdist**: DNS over HTTPS (DoH) and DNS over TLS (DoT) support
- ✅ **Firewall Configuration**: Automatic UFW setup
- ✅ **Production Ready**: Gunicorn WSGI server with proper configuration
- ✅ **Issue-Tested**: Fixes common installation pitfalls

---

## 📦 Requirements

### System Requirements
- **OS**: Ubuntu 20.04/22.04 or Debian 11/12
- **RAM**: Minimum 1GB (2GB recommended)
- **Disk**: Minimum 10GB free space
- **CPU**: 1 core minimum (2+ recommended)
- **Root Access**: Required (via sudo)

### Network Requirements
- Static IP address (recommended for production)
- Port 53 (TCP/UDP) available
- Port 8081 (PowerDNS API) - internal only
- Port 9191 (PowerDNS-Admin) - configurable
- Port 443/8443 (DoH) - optional
- Port 853 (DoT) - optional

---

## 🔧 What Gets Installed

### Core Components

1. **PowerDNS Authoritative Server 4.5+**
   - SQLite backend for DNS records
   - Built-in API enabled
   - Web server for monitoring

2. **PowerDNS-Admin**
   - Latest version from GitHub
   - Python Flask application
   - Gunicorn WSGI server
   - MariaDB database backend

3. **MariaDB Database Server**
   - Dedicated database for PowerDNS-Admin
   - Secure configuration

4. **System Dependencies**
   - Python 3.10+ with virtual environment
   - Node.js 18.x
   - Yarn package manager
   - Development libraries

### Optional Components

5. **dnsdist** (if selected)
   - DNS over HTTPS (DoH)
   - DNS over TLS (DoT)
   - Advanced load balancing
   - DDoS protection features

---

## 🚀 Quick Start

### One-Line Installation

```bash
wget https://raw.githubusercontent.com/sandipsnl/powerdns-setup/main/install.sh
sudo bash install.sh
```

Or with curl:

```bash
curl -sSL https://raw.githubusercontent.com/sandipsnl/powerdns-setup/main/install.sh | sudo bash
```

### Manual Download and Run

```bash
# Download the script
git clone https://github.com/sandipsnl/powerdns-setup.git
cd powerdns-setup

# Make executable
chmod +x install.sh

# Run with sudo
sudo ./install.sh
```

---

## 📝 Installation

### Step-by-Step Guide

#### 1. Prepare Your Server

```bash
# Update system packages
sudo apt update && sudo apt upgrade -y

# Ensure you have sudo privileges
sudo -v
```

#### 2. Download the Script

```bash
# Option A: Git clone
git clone https://github.com/sandipsnl/powerdns-setup.git
cd powerdns-setup

# Option B: Direct download
wget https://raw.githubusercontent.com/sandipsnl/powerdns-setup/main/install.sh
chmod +x install.sh
```

#### 3. Review Configuration (Optional)

Edit the script to customize default values:

```bash
nano install.sh
```

Configurable variables:
```bash
# Database Configuration
DB_NAME="powerdnsadmin"
DB_USER="pdnsadmin"
DB_PASSWORD=""  # Auto-generated if empty

# Admin Configuration
ADMIN_USERNAME="admin"
ADMIN_PASSWORD=""  # Prompted during installation
ADMIN_EMAIL="admin@localhost"

# Server Configuration
PDNS_ADMIN_PORT="9191"
```

#### 4. Run the Installation

```bash
sudo ./install.sh
```

#### 5. Follow the Prompts

The script will ask:
- Confirmation to proceed with installation
- Admin password for PowerDNS-Admin
- Whether to install dnsdist (optional)
- Firewall configuration preferences

#### 6. Installation Progress

The script will:
1. ✅ Check system compatibility
2. ✅ Install PowerDNS with SQLite
3. ✅ Install and configure MariaDB
4. ✅ Install system dependencies
5. ✅ Install Node.js and Yarn
6. ✅ Clone and setup PowerDNS-Admin
7. ✅ Create admin user
8. ✅ Configure systemd services
9. ✅ Setup firewall rules
10. ✅ Optionally install dnsdist

### Installation Time

- **Typical installation**: 5-10 minutes
- **With dnsdist**: 10-15 minutes
- *Time varies based on server speed and internet connection*

---

## 🎯 Post-Installation

### Access PowerDNS-Admin

1. **Open your web browser**
2. **Navigate to**: `http://YOUR_SERVER_IP:9191`
3. **Login with**:
   - Username: `admin` (or your configured username)
   - Password: The password you set during installation

### Initial Setup

#### 1. Verify PowerDNS Server Connection

1. Login to PowerDNS-Admin
2. The PowerDNS server should already be configured as "localhost"
3. Check the dashboard for green status indicator

#### 2. Create Your First Domain

1. Click **Dashboard** → **New Domain**
2. Enter domain name: `example.com`
3. Select type: **Native** or **Master**
4. Click **Create**

#### 3. Add DNS Records

Click on your domain, then add records:

**Example A Record:**
```
Name: @
Type: A
Content: 203.0.113.50
TTL: 3600
```

**Example WWW Record:**
```
Name: www
Type: A
Content: 203.0.113.50
TTL: 3600
```

**Example MX Record:**
```
Name: @
Type: MX
Priority: 10
Content: mail.example.com.
TTL: 3600
```

#### 4. Test DNS Resolution

```bash
# Test from your server
dig @localhost example.com

# Test from another machine
dig @YOUR_SERVER_IP example.com
```

---

## ⚙️ Configuration

### Important File Locations

| Component | Configuration File |
|-----------|-------------------|
| PowerDNS | `/etc/powerdns/pdns.conf` |
| PowerDNS-Admin | `/opt/powerdns-admin/configs/production.py` |
| dnsdist | `/etc/dnsdist/dnsdist.conf` |
| Database | `/var/lib/powerdns/pdns.sqlite3` |
| Service | `/etc/systemd/system/powerdns-admin.service` |

### Credential Files

**⚠️ Keep these files secure!**

- **PowerDNS API Key**: `/root/.pdns_api_key`
- **Database Password**: `/root/.pdns_db_password`

```bash
# View API key
sudo cat /root/.pdns_api_key

# View database password
sudo cat /root/.pdns_db_password
```

### Service Management

```bash
# PowerDNS
sudo systemctl status pdns
sudo systemctl restart pdns
sudo systemctl stop pdns
sudo journalctl -u pdns -f

# PowerDNS-Admin
sudo systemctl status powerdns-admin
sudo systemctl restart powerdns-admin
sudo systemctl stop powerdns-admin
sudo journalctl -u powerdns-admin -f

# MariaDB
sudo systemctl status mariadb
sudo systemctl restart mariadb

# dnsdist (if installed)
sudo systemctl status dnsdist
sudo systemctl restart dnsdist
sudo journalctl -u dnsdist -f
```

### Firewall Configuration

```bash
# View firewall status
sudo ufw status

# Allow additional ports
sudo ufw allow 80/tcp    # HTTP
sudo ufw allow 443/tcp   # HTTPS

# Reload firewall
sudo ufw reload
```

---

## 📖 Usage Guide

### Making DNS Public

To make your DNS server authoritative for your domains:

#### 1. Prerequisites
- Own a domain (e.g., `yourdomain.com`)
- Have a static public IP
- Port 53 is accessible from the internet

#### 2. Create Nameserver Records

In PowerDNS-Admin, create domain `yourdomain.com`:

```
Name: ns1.yourdomain.com
Type: A
Content: YOUR_PUBLIC_IP

Name: ns2.yourdomain.com
Type: A
Content: YOUR_PUBLIC_IP

Name: @
Type: NS
Content: ns1.yourdomain.com.

Name: @
Type: NS
Content: ns2.yourdomain.com.
```

**Important**: Note the trailing dot (`.`) in NS records!

#### 3. Register Nameservers at Registrar

At your domain registrar (GoDaddy, Namecheap, etc.):

**A. Register Glue Records:**
- Nameserver: `ns1.yourdomain.com` → IP: `YOUR_PUBLIC_IP`
- Nameserver: `ns2.yourdomain.com` → IP: `YOUR_PUBLIC_IP`

**B. Set Domain Nameservers:**
- Primary: `ns1.yourdomain.com`
- Secondary: `ns2.yourdomain.com`

#### 4. Wait for DNS Propagation

DNS changes take 1-48 hours to propagate globally.

#### 5. Verify

```bash
# Check nameservers
dig yourdomain.com NS

# Check resolution
dig yourdomain.com @8.8.8.8

# Check propagation
# Visit: https://www.whatsmydns.net/
```

### Common DNS Records

#### A Record (IPv4)
```
Name: www
Type: A
Content: 203.0.113.50
```

#### AAAA Record (IPv6)
```
Name: www
Type: AAAA
Content: 2001:db8::1
```

#### CNAME Record (Alias)
```
Name: blog
Type: CNAME
Content: www.yourdomain.com.
```

#### MX Record (Mail)
```
Name: @
Type: MX
Priority: 10
Content: mail.yourdomain.com.
```

#### TXT Record (SPF, DKIM, etc.)
```
Name: @
Type: TXT
Content: "v=spf1 mx ~all"
```

#### SRV Record (Services)
```
Name: _service._tcp
Type: SRV
Priority: 10
Weight: 60
Port: 5060
Content: sipserver.yourdomain.com.
```

---

## 🔐 Optional: DoH/DoT Setup

If you installed dnsdist, configure DNS over HTTPS and DNS over TLS.

### Prerequisites

1. **Domain pointing to your server**: `dns.yourdomain.com`
2. **SSL Certificate**: Let's Encrypt recommended

### Get SSL Certificate

```bash
# Install Certbot
sudo apt install certbot -y

# Stop services using port 80
sudo systemctl stop powerdns-admin

# Get certificate
sudo certbot certonly --standalone -d dns.yourdomain.com

# Restart services
sudo systemctl start powerdns-admin
```

### Configure dnsdist

The script configures dnsdist automatically if you select it during installation.

**Default ports:**
- **DoH**: 8443 (or 443 if available)
- **DoT**: 853

### Test DoH/DoT

#### Test DoT
```bash
# Using kdig
kdig -d @dns.yourdomain.com +tls example.com

# Using dig with OpenSSL
echo -e "example.com A\n" | openssl s_client -connect dns.yourdomain.com:853
```

#### Test DoH
```bash
# Using curl
curl -H 'accept: application/dns-json' \
  'https://dns.yourdomain.com:8443/dns-query?name=example.com&type=A'
```

### Client Configuration

#### Firefox
1. Settings → Privacy & Security
2. DNS over HTTPS → Custom
3. Enter: `https://dns.yourdomain.com:8443/dns-query`

#### Android 9+
1. Settings → Network & Internet → Private DNS
2. Enter: `dns.yourdomain.com`

#### Linux (systemd-resolved)
```bash
sudo nano /etc/systemd/resolved.conf
```

Add:
```ini
[Resolve]
DNS=YOUR_IP#dns.yourdomain.com
DNSOverTLS=yes
```

```bash
sudo systemctl restart systemd-resolved
```

---

## 🔧 Troubleshooting

### PowerDNS Won't Start

```bash
# Check logs
sudo journalctl -u pdns -n 50

# Common issues:
# 1. Port 53 already in use
sudo lsof -i :53

# 2. Database permissions
sudo chown pdns:pdns /var/lib/powerdns/pdns.sqlite3
sudo chmod 640 /var/lib/powerdns/pdns.sqlite3

# 3. Configuration errors
sudo pdns_server --config-dir=/etc/powerdns --daemon=no
```

### PowerDNS-Admin Won't Start

```bash
# Check logs
sudo journalctl -u powerdns-admin -n 50

# Common issues:
# 1. Database connection
mysql -u pdnsadmin -p powerdnsadmin

# 2. Permission issues
sudo chown -R pdns:pdns /opt/powerdns-admin

# 3. Python dependencies
cd /opt/powerdns-admin
source flask/bin/activate
pip install -r requirements.txt
```

### Can't Access Web Interface

```bash
# Check if service is running
sudo systemctl status powerdns-admin

# Check if port is listening
sudo netstat -tulpn | grep 9191

# Check firewall
sudo ufw status

# Allow port
sudo ufw allow 9191/tcp
```

### DNS Not Resolving Externally

```bash
# Test locally first
dig @localhost example.com

# Test from server IP
dig @YOUR_SERVER_IP example.com

# Check if port 53 is open
sudo ufw status | grep 53

# Check if PowerDNS is listening on all interfaces
sudo netstat -tulpn | grep :53
```

### Certificate Permission Errors (dnsdist)

```bash
# Fix Let's Encrypt permissions
sudo chmod 755 /etc/letsencrypt/live
sudo chmod 755 /etc/letsencrypt/archive
sudo chmod 644 /etc/letsencrypt/live/*/fullchain.pem
sudo chmod 644 /etc/letsencrypt/live/*/privkey.pem

# Restart dnsdist
sudo systemctl restart dnsdist
```

### Port 443 Already in Use

```bash
# Find what's using port 443
sudo lsof -i :443

# Options:
# 1. Use different port for DoH (8443)
# 2. Stop the conflicting service
# 3. Use Nginx as reverse proxy
```

### Database Issues

```bash
# Check MariaDB status
sudo systemctl status mariadb

# Access database
mysql -u pdnsadmin -p powerdnsadmin

# Check tables
SHOW TABLES;

# Reinitialize if needed
cd /opt/powerdns-admin
source flask/bin/activate
export FLASK_APP=powerdnsadmin/__init__.py
export FLASK_CONF=/opt/powerdns-admin/configs/production.py
flask db upgrade
```

---

## 🛡️ Security Best Practices

### 1. Change Default Passwords

```bash
# Change admin password in PowerDNS-Admin web interface
# Settings → Profile → Change Password
```

### 2. Restrict API Access

```bash
sudo nano /etc/powerdns/pdns.conf
```

```ini
# Only allow localhost
webserver-address=127.0.0.1
webserver-allow-from=127.0.0.1
```

### 3. Enable HTTPS for PowerDNS-Admin

Use Nginx as reverse proxy:

```bash
sudo apt install nginx certbot python3-certbot-nginx

# Get SSL certificate
sudo certbot --nginx -d admin.yourdomain.com

# Configure Nginx
sudo nano /etc/nginx/sites-available/powerdns-admin
```

```nginx
server {
    listen 80;
    server_name admin.yourdomain.com;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name admin.yourdomain.com;

    ssl_certificate /etc/letsencrypt/live/admin.yourdomain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/admin.yourdomain.com/privkey.pem;

    location / {
        proxy_pass http://127.0.0.1:9191;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

```bash
sudo ln -s /etc/nginx/sites-available/powerdns-admin /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

### 4. Regular Updates

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Update PowerDNS-Admin
cd /opt/powerdns-admin
git pull
source flask/bin/activate
pip install -r requirements.txt --upgrade
yarn install
sudo systemctl restart powerdns-admin
```

### 5. Backup Strategy

```bash
# Backup script
#!/bin/bash
BACKUP_DIR="/root/backups"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p $BACKUP_DIR

# Backup PowerDNS database
sqlite3 /var/lib/powerdns/pdns.sqlite3 ".backup $BACKUP_DIR/pdns_$DATE.sqlite3"

# Backup PowerDNS-Admin database
mysqldump -u pdnsadmin -p powerdnsadmin > $BACKUP_DIR/pdnsadmin_$DATE.sql

# Backup configurations
tar -czf $BACKUP_DIR/configs_$DATE.tar.gz \
    /etc/powerdns/pdns.conf \
    /opt/powerdns-admin/configs/production.py \
    /etc/dnsdist/dnsdist.conf
```

### 6. Monitor Logs

```bash
# Setup log monitoring
sudo apt install logwatch

# Or use real-time monitoring
sudo journalctl -u pdns -u powerdns-admin -f
```

### 7. Fail2ban for DDoS Protection

```bash
# Install fail2ban
sudo apt install fail2ban

# Configure for DNS
sudo nano /etc/fail2ban/jail.local
```

```ini
[pdns]
enabled = true
port = 53
protocol = udp
filter = pdns
logpath = /var/log/syslog
maxretry = 10
bantime = 3600
```

---

## 🗑️ Uninstallation

To completely remove all components:

```bash
# Stop services
sudo systemctl stop powerdns-admin
sudo systemctl stop pdns
sudo systemctl stop dnsdist
sudo systemctl stop mariadb

# Disable services
sudo systemctl disable powerdns-admin
sudo systemctl disable pdns
sudo systemctl disable dnsdist

# Remove packages
sudo apt remove --purge pdns-server pdns-backend-sqlite3 mariadb-server dnsdist

# Remove PowerDNS-Admin
sudo rm -rf /opt/powerdns-admin

# Remove databases
sudo rm -rf /var/lib/powerdns
sudo rm -rf /var/lib/mysql/powerdnsadmin

# Remove configurations
sudo rm /etc/systemd/system/powerdns-admin.service
sudo rm -rf /etc/powerdns
sudo rm -rf /etc/dnsdist

# Remove credential files
sudo rm /root/.pdns_api_key
sudo rm /root/.pdns_db_password

# Reload systemd
sudo systemctl daemon-reload

# Clean up packages
sudo apt autoremove -y
```

---

## ❓ FAQ

### Q: Can I use MySQL instead of MariaDB?
**A:** Yes, MariaDB is a drop-in replacement. If you prefer MySQL, install it before running the script and it should work.

### Q: Can I use PostgreSQL instead of SQLite for PowerDNS?
**A:** Yes, but you'll need to modify the script. Change the backend in `/etc/powerdns/pdns.conf` and install the appropriate backend package.

### Q: How do I add more admin users?
**A:** Login to PowerDNS-Admin → Administration → Users → New User

### Q: Can I run this on CentOS/RHEL?
**A:** Not directly. This script is designed for Debian-based systems. You would need to adapt it for RPM-based systems.

### Q: How do I enable DNSSEC?
**A:** DNSSEC setup is beyond this script's scope. See [PowerDNS DNSSEC documentation](https://doc.powerdns.com/authoritative/dnssec/index.html).

### Q: What's the difference between Native, Master, and Slave zone types?
**A:** 
- **Native**: Standalone zone, no replication
- **Master**: Primary zone, can replicate to slaves
- **Slave**: Secondary zone, receives updates from master

### Q: How do I set up secondary DNS servers?
**A:** Configure zone transfers in PowerDNS and set up a second server as Slave.

### Q: Can I migrate from BIND to PowerDNS?
**A:** Yes, PowerDNS can import BIND zone files. Use the `zone2sql` utility.

### Q: How do I enable query logging?
**A:** Edit `/etc/powerdns/pdns.conf` and set `log-dns-queries=yes`, then restart PowerDNS.

### Q: Is this script production-ready?
**A:** Yes, but additional hardening is recommended (HTTPS, fail2ban, monitoring, backups).

---

## 🤝 Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

### Reporting Issues

Open an issue with:
- Operating system version
- Error messages
- Steps to reproduce
- Log outputs

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- [PowerDNS](https://www.powerdns.com/) - Authoritative DNS server
- [PowerDNS-Admin](https://github.com/PowerDNS-Admin/PowerDNS-Admin) - Web interface
- Community contributors and testers

---

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/sandipsnl/powerdns-setup/issues)
- **Documentation**: [PowerDNS Docs](https://doc.powerdns.com/)
- **Community**: [PowerDNS Forums](https://community.powerdns.com/)

---

## 📊 Changelog

### Version 1.0.0 (2025-12-12)
- Initial release
- PowerDNS 4.5+ support
- PowerDNS-Admin latest version
- dnsdist DoH/DoT support
- Automated installation
- Comprehensive documentation

---

**Made with ❤️ for the DNS community**
