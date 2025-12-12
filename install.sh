#!/bin/bash

################################################################################
# PowerDNS with SQLite + PowerDNS-Admin with MariaDB Installation Script
# For Ubuntu 20.04/22.04 and Debian 11/12
#
# This script automates the complete installation and configuration of:
# - PowerDNS Authoritative Server (with SQLite backend)
# - PowerDNS-Admin Web Interface (with MariaDB backend)
# - Optional: dnsdist for DoH/DoT support
#
# Author: Your Name
# License: MIT
# GitHub: https://github.com/yourusername/powerdns-setup
################################################################################

set -e  # Exit on any error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   log_error "This script must be run as root (use sudo)"
   exit 1
fi

# Get the actual user who ran sudo
ACTUAL_USER=${SUDO_USER:-$USER}

log_info "Starting PowerDNS and PowerDNS-Admin installation..."
echo ""

################################################################################
# CONFIGURATION SECTION - EDIT THESE VALUES
################################################################################

# Database Configuration
DB_NAME="powerdnsadmin"
DB_USER="pdnsadmin"
DB_PASSWORD=""  # Will be generated if empty

# PowerDNS API Configuration
PDNS_API_KEY=""  # Will be generated if empty

# PowerDNS-Admin Configuration
ADMIN_USERNAME="admin"
ADMIN_PASSWORD=""  # Will be prompted if empty
ADMIN_EMAIL="admin@localhost"
ADMIN_FIRSTNAME="Admin"
ADMIN_LASTNAME="User"

# Server Configuration
SERVER_IP=$(hostname -I | awk '{print $1}')
PDNS_ADMIN_PORT="9191"

################################################################################
# FUNCTIONS
################################################################################

generate_password() {
    openssl rand -base64 32 | tr -d "=+/" | cut -c1-25
}

generate_secret() {
    python3 -c "import secrets; print(secrets.token_hex(32))"
}

prompt_yes_no() {
    while true; do
        read -p "$1 [y/n]: " yn
        case $yn in
            [Yy]* ) return 0;;
            [Nn]* ) return 1;;
            * ) echo "Please answer yes or no.";;
        esac
    done
}

check_system() {
    log_info "Checking system requirements..."
    
    # Check OS
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$NAME
        VER=$VERSION_ID
        log_info "Detected OS: $OS $VER"
    else
        log_error "Cannot detect OS. This script supports Ubuntu 20.04/22.04 and Debian 11/12"
        exit 1
    fi
    
    # Check if Ubuntu or Debian
    if [[ ! "$OS" =~ "Ubuntu" ]] && [[ ! "$OS" =~ "Debian" ]]; then
        log_error "This script only supports Ubuntu and Debian"
        exit 1
    fi
    
    log_success "System check passed"
}

install_powerdns() {
    log_info "Installing PowerDNS Authoritative Server with SQLite backend..."
    
    # Update system
    apt update
    apt upgrade -y
    
    # Install PowerDNS and SQLite backend
    DEBIAN_FRONTEND=noninteractive apt install -y pdns-server pdns-backend-sqlite3 sqlite3
    
    # Stop PowerDNS for configuration
    systemctl stop pdns
    
    # Create PowerDNS data directory
    mkdir -p /var/lib/powerdns
    
    # Create SQLite database with schema
    log_info "Creating PowerDNS SQLite database..."
    sqlite3 /var/lib/powerdns/pdns.sqlite3 < /usr/share/doc/pdns-backend-sqlite3/schema.sqlite3.sql
    
    # Set proper permissions
    chown -R pdns:pdns /var/lib/powerdns
    chmod 640 /var/lib/powerdns/pdns.sqlite3
    
    # Generate API key if not set
    if [ -z "$PDNS_API_KEY" ]; then
        PDNS_API_KEY=$(openssl rand -base64 32)
        log_info "Generated PowerDNS API Key: $PDNS_API_KEY"
        echo "$PDNS_API_KEY" > /root/.pdns_api_key
        chmod 600 /root/.pdns_api_key
        log_warning "API key saved to /root/.pdns_api_key - keep this secure!"
    fi
    
    # Configure PowerDNS
    log_info "Configuring PowerDNS..."
    cat > /etc/powerdns/pdns.conf << EOF
# PowerDNS Configuration
# Launch SQLite3 backend
launch=gsqlite3

# SQLite3 database location
gsqlite3-database=/var/lib/powerdns/pdns.sqlite3

# API configuration
api=yes
api-key=$PDNS_API_KEY

# Webserver configuration
webserver=yes
webserver-address=127.0.0.1
webserver-port=8081
webserver-allow-from=127.0.0.1

# Local address to bind to
local-address=0.0.0.0
local-port=53

# Master configuration
master=yes

# Security
disable-axfr=yes

# Logging
log-dns-queries=no
log-dns-details=no
loglevel=4
EOF
    
    # Start and enable PowerDNS
    systemctl start pdns
    systemctl enable pdns
    
    # Test PowerDNS
    sleep 2
    if dig @localhost version.bind chaos txt | grep -q "PowerDNS"; then
        log_success "PowerDNS installed and running successfully"
    else
        log_error "PowerDNS test failed"
        exit 1
    fi
}

install_mariadb() {
    log_info "Installing MariaDB..."
    
    DEBIAN_FRONTEND=noninteractive apt install -y mariadb-server mariadb-client
    
    # Start MariaDB
    systemctl start mariadb
    systemctl enable mariadb
    
    # Generate database password if not set
    if [ -z "$DB_PASSWORD" ]; then
        DB_PASSWORD=$(generate_password)
        log_info "Generated database password: $DB_PASSWORD"
        echo "$DB_PASSWORD" > /root/.pdns_db_password
        chmod 600 /root/.pdns_db_password
        log_warning "Database password saved to /root/.pdns_db_password - keep this secure!"
    fi
    
    # Create database and user
    log_info "Creating database and user..."
    mysql -u root << EOF
CREATE DATABASE IF NOT EXISTS $DB_NAME CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASSWORD';
GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost';
FLUSH PRIVILEGES;
EOF
    
    log_success "MariaDB installed and configured"
}

install_dependencies() {
    log_info "Installing system dependencies..."
    
    # Install Python and build dependencies
    DEBIAN_FRONTEND=noninteractive apt install -y \
        python3-pip python3-dev python3-venv \
        libsasl2-dev libldap2-dev libssl-dev libxml2-dev libxslt1-dev \
        libxmlsec1-dev libffi-dev pkg-config apt-transport-https \
        python3-virtualenv build-essential curl git \
        libmariadb-dev libmariadb-dev-compat default-libmysqlclient-dev \
        libpq-dev
    
    log_success "Dependencies installed"
}

install_nodejs() {
    log_info "Installing Node.js and Yarn..."
    
    # Install Node.js 18.x
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
    apt install -y nodejs
    
    # Install Yarn
    curl -sL https://dl.yarnpkg.com/debian/pubkey.gpg | gpg --dearmor | tee /usr/share/keyrings/yarn-archive-keyring.gpg >/dev/null
    echo "deb [signed-by=/usr/share/keyrings/yarn-archive-keyring.gpg] https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list
    apt update
    apt install -y yarn
    
    log_success "Node.js $(node --version) and Yarn $(yarn --version) installed"
}

install_powerdns_admin() {
    log_info "Installing PowerDNS-Admin..."
    
    # Clone repository
    cd /opt
    if [ -d "powerdns-admin" ]; then
        log_warning "PowerDNS-Admin directory exists, removing..."
        rm -rf powerdns-admin
    fi
    
    git clone https://github.com/PowerDNS-Admin/PowerDNS-Admin.git powerdns-admin
    cd powerdns-admin
    
    # Create virtual environment
    log_info "Creating Python virtual environment..."
    python3 -m venv ./flask
    
    # Install Python dependencies
    log_info "Installing Python dependencies (this may take a while)..."
    source ./flask/bin/activate
    pip install --upgrade pip
    pip install -r requirements.txt --prefer-binary
    pip install gunicorn
    deactivate
    
    # Install frontend dependencies
    log_info "Installing frontend dependencies (this may take a while)..."
    yarn install --pure-lockfile
    
    # Generate secret key
    SECRET_KEY=$(generate_secret)
    
    # Create production configuration
    log_info "Creating production configuration..."
    cat > /opt/powerdns-admin/configs/production.py << EOF
import os
import urllib.parse

basedir = os.path.abspath(os.path.dirname(__file__))

### BASIC APP CONFIG
SALT = '\$2b\$12\$yLUMTIfl21FKJQpTkRQXCu'
SECRET_KEY = '$SECRET_KEY'
BIND_ADDRESS = '0.0.0.0'
PORT = $PDNS_ADMIN_PORT

### DATABASE CONFIG
SQLA_DB_USER = '$DB_USER'
SQLA_DB_PASSWORD = '$DB_PASSWORD'
SQLA_DB_HOST = '127.0.0.1'
SQLA_DB_NAME = '$DB_NAME'

# Build database URI with URL encoding for special characters
SQLALCHEMY_DATABASE_URI = f'mysql://{SQLA_DB_USER}:{urllib.parse.quote_plus(SQLA_DB_PASSWORD)}@{SQLA_DB_HOST}/{SQLA_DB_NAME}'
SQLALCHEMY_TRACK_MODIFICATIONS = False

### PDNS CONFIG
PDNS_STATS_URL = 'http://127.0.0.1:8081'
PDNS_API_KEY = '$PDNS_API_KEY'
PDNS_VERSION = '4.5.3'

### SESSION CONFIG
SESSION_TYPE = 'sqlalchemy'

### LOGGING
LOG_LEVEL = 'INFO'
LOG_FILE = '/opt/powerdns-admin/logs/logfile.log'

### UPLOAD
UPLOAD_DIR = os.path.join(basedir, 'upload')
EOF
    
    # Create log directory
    mkdir -p /opt/powerdns-admin/logs
    
    # Set permissions
    chown -R pdns:pdns /opt/powerdns-admin
    
    # Initialize database
    log_info "Initializing PowerDNS-Admin database..."
    cd /opt/powerdns-admin
    source ./flask/bin/activate
    export FLASK_APP=powerdnsadmin/__init__.py
    export FLASK_CONF=/opt/powerdns-admin/configs/production.py
    flask db upgrade
    deactivate
    
    log_success "PowerDNS-Admin installed"
}

create_admin_user() {
    log_info "Creating admin user..."
    
    # Prompt for admin password if not set
    if [ -z "$ADMIN_PASSWORD" ]; then
        read -s -p "Enter admin password: " ADMIN_PASSWORD
        echo ""
        read -s -p "Confirm admin password: " ADMIN_PASSWORD_CONFIRM
        echo ""
        
        if [ "$ADMIN_PASSWORD" != "$ADMIN_PASSWORD_CONFIRM" ]; then
            log_error "Passwords do not match"
            exit 1
        fi
    fi
    
    cd /opt/powerdns-admin
    source ./flask/bin/activate
    export FLASK_APP=powerdnsadmin/__init__.py
    export FLASK_CONF=/opt/powerdns-admin/configs/production.py
    
    # Create admin user using Python
    python3 << EOF
from powerdnsadmin import create_app
from powerdnsadmin.models.user import User
from powerdnsadmin.models.role import Role
from powerdnsadmin.models import db

app = create_app()

with app.app_context():
    # Get or create Administrator role
    admin_role = Role.query.filter_by(name='Administrator').first()
    if not admin_role:
        admin_role = Role(name='Administrator', description='Administrator')
        db.session.add(admin_role)
        db.session.commit()
    
    # Check if user exists
    existing_user = User.query.filter_by(username='$ADMIN_USERNAME').first()
    if existing_user:
        print("User '$ADMIN_USERNAME' already exists")
    else:
        # Create user
        user = User(
            username='$ADMIN_USERNAME',
            plain_text_password='$ADMIN_PASSWORD',
            email='$ADMIN_EMAIL',
            firstname='$ADMIN_FIRSTNAME',
            lastname='$ADMIN_LASTNAME'
        )
        user.role_id = admin_role.id
        user.create_local_user()
        print("Admin user '$ADMIN_USERNAME' created successfully")
EOF
    
    deactivate
    log_success "Admin user created"
}

add_powerdns_server() {
    log_info "Adding PowerDNS server connection to PowerDNS-Admin..."
    
    cd /opt/powerdns-admin
    source ./flask/bin/activate
    export FLASK_APP=powerdnsadmin/__init__.py
    export FLASK_CONF=/opt/powerdns-admin/configs/production.py
    
    python3 << EOF
from powerdnsadmin import create_app
from powerdnsadmin.models.server import Server
from powerdnsadmin.models import db

app = create_app()

with app.app_context():
    # Check if server exists
    existing_server = Server.query.filter_by(name='localhost').first()
    if existing_server:
        print("PowerDNS server 'localhost' already configured")
    else:
        server = Server(
            name='localhost',
            host='127.0.0.1',
            port='8081',
            api_key='$PDNS_API_KEY'
        )
        db.session.add(server)
        db.session.commit()
        print("PowerDNS server 'localhost' added successfully")
EOF
    
    deactivate
    log_success "PowerDNS server connection configured"
}

create_systemd_service() {
    log_info "Creating systemd service for PowerDNS-Admin..."
    
    cat > /etc/systemd/system/powerdns-admin.service << EOF
[Unit]
Description=PowerDNS-Admin
Requires=mariadb.service
After=network.target mariadb.service

[Service]
Type=simple
User=pdns
Group=pdns
WorkingDirectory=/opt/powerdns-admin
Environment="FLASK_APP=powerdnsadmin/__init__.py"
Environment="FLASK_CONF=/opt/powerdns-admin/configs/production.py"
ExecStart=/opt/powerdns-admin/flask/bin/gunicorn --workers 4 --bind 0.0.0.0:$PDNS_ADMIN_PORT --timeout 120 'powerdnsadmin:create_app()'
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
    
    systemctl daemon-reload
    systemctl start powerdns-admin
    systemctl enable powerdns-admin
    
    sleep 3
    
    if systemctl is-active --quiet powerdns-admin; then
        log_success "PowerDNS-Admin service started"
    else
        log_error "PowerDNS-Admin service failed to start"
        systemctl status powerdns-admin
        exit 1
    fi
}

configure_firewall() {
    log_info "Configuring firewall..."
    
    if command -v ufw &> /dev/null; then
        ufw allow 53/tcp
        ufw allow 53/udp
        ufw allow $PDNS_ADMIN_PORT/tcp
        
        if prompt_yes_no "Do you want to enable UFW firewall?"; then
            ufw --force enable
        fi
        
        log_success "Firewall rules configured"
    else
        log_warning "UFW not installed, skipping firewall configuration"
    fi
}

install_dnsdist() {
    if prompt_yes_no "Do you want to install dnsdist for DoH/DoT support?"; then
        log_info "Installing dnsdist..."
        
        apt install -y dnsdist
        
        # Get server hostname
        read -p "Enter your DNS server hostname (e.g., dns.example.com): " DNS_HOSTNAME
        
        # Check if Let's Encrypt cert exists
        if [ -d "/etc/letsencrypt/live/$DNS_HOSTNAME" ]; then
            CERT_PATH="/etc/letsencrypt/live/$DNS_HOSTNAME/fullchain.pem"
            KEY_PATH="/etc/letsencrypt/live/$DNS_HOSTNAME/privkey.pem"
            log_info "Using existing Let's Encrypt certificate"
        else
            log_warning "No Let's Encrypt certificate found"
            if prompt_yes_no "Do you want to generate a self-signed certificate? (for testing only)"; then
                mkdir -p /etc/dnsdist/certs
                openssl req -x509 -newkey rsa:4096 \
                    -keyout /etc/dnsdist/certs/privkey.pem \
                    -out /etc/dnsdist/certs/fullchain.pem \
                    -days 365 -nodes \
                    -subj "/CN=$DNS_HOSTNAME"
                
                CERT_PATH="/etc/dnsdist/certs/fullchain.pem"
                KEY_PATH="/etc/dnsdist/certs/privkey.pem"
                chmod 600 /etc/dnsdist/certs/privkey.pem
                chmod 644 /etc/dnsdist/certs/fullchain.pem
            else
                log_warning "Skipping dnsdist SSL configuration"
                return
            fi
        fi
        
        # Configure dnsdist
        cat > /etc/dnsdist/dnsdist.conf << EOF
-- Backend PowerDNS server
newServer({address="127.0.0.1:53", name="pdns-local"})

-- Certificate paths
local cert_path = "$CERT_PATH"
local key_path = "$KEY_PATH"

-- DNS over HTTPS on port 8443 (use 443 if available)
addDOHLocal("0.0.0.0:8443", cert_path, key_path, "/dns-query", {
  reusePort=true,
  tcpFastOpenQueueSize=64
})

-- DNS over TLS on port 853
addTLSLocal("0.0.0.0:853", cert_path, key_path, {
  reusePort=true,
  tcpFastOpenQueueSize=64
})

-- Packet Cache
pc = newPacketCache(10000, {maxTTL=86400, minTTL=0})
getPool(""):setCache(pc)

-- Rate limiting: 100 queries per second per IP
addAction(MaxQPSIPRule(100), DropAction())

-- Block ANY queries
addAction(QTypeRule(DNSQType.ANY), DropAction())

-- Console for management
controlSocket("127.0.0.1:5199")
EOF
        
        # Configure firewall for dnsdist
        if command -v ufw &> /dev/null; then
            ufw allow 853/tcp   # DoT
            ufw allow 8443/tcp  # DoH
        fi
        
        systemctl start dnsdist
        systemctl enable dnsdist
        
        log_success "dnsdist installed and configured"
        log_info "DoH endpoint: https://$DNS_HOSTNAME:8443/dns-query"
        log_info "DoT server: $DNS_HOSTNAME:853"
    fi
}

print_summary() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log_success "Installation completed successfully!"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "��� Installation Summary:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "��� PowerDNS Authoritative Server:"
    echo "   • Status: $(systemctl is-active pdns)"
    echo "   • Backend: SQLite (/var/lib/powerdns/pdns.sqlite3)"
    echo "   • API: http://127.0.0.1:8081"
    echo "   • API Key: Saved in /root/.pdns_api_key"
    echo ""
    echo "��� PowerDNS-Admin Web Interface:"
    echo "   • URL: http://$SERVER_IP:$PDNS_ADMIN_PORT"
    echo "   • Username: $ADMIN_USERNAME"
    echo "   • Password: [the password you entered]"
    echo "   • Database: MariaDB ($DB_NAME)"
    echo "   • DB Password: Saved in /root/.pdns_db_password"
    echo ""
    echo "��� Important Files:"
    echo "   • PowerDNS Config: /etc/powerdns/pdns.conf"
    echo "   • PowerDNS-Admin Config: /opt/powerdns-admin/configs/production.py"
    echo "   • API Key: /root/.pdns_api_key"
    echo "   • DB Password: /root/.pdns_db_password"
    echo ""
    echo "��� Next Steps:"
    echo "   1. Access PowerDNS-Admin at http://$SERVER_IP:$PDNS_ADMIN_PORT"
    echo "   2. Login with username '$ADMIN_USERNAME'"
    echo "   3. Create your first DNS zone in the dashboard"
    echo "   4. Add DNS records (A, AAAA, CNAME, MX, etc.)"
    echo "   5. Update your domain registrar to use your nameservers"
    echo ""
    echo "��� Service Status Commands:"
    echo "   • PowerDNS: systemctl status pdns"
    echo "   • PowerDNS-Admin: systemctl status powerdns-admin"
    echo "   • MariaDB: systemctl status mariadb"
    if systemctl is-active --quiet dnsdist 2>/dev/null; then
        echo "   • dnsdist: systemctl status dnsdist"
    fi
    echo ""
    echo "��� Making DNS Public:"
    echo "   1. Ensure port 53 (TCP/UDP) is open on your firewall"
    echo "   2. Create NS records: ns1.yourdomain.com, ns2.yourdomain.com"
    echo "   3. Register nameservers at your domain registrar"
    echo "   4. Point your domains to your nameservers"
    echo ""
    echo "��� Documentation:"
    echo "   • PowerDNS: https://doc.powerdns.com/"
    echo "   • PowerDNS-Admin: https://github.com/PowerDNS-Admin/PowerDNS-Admin"
    echo ""
    echo "⚠️  Security Reminders:"
    echo "   • Keep /root/.pdns_api_key and /root/.pdns_db_password secure"
    echo "   • Change default admin password in PowerDNS-Admin"
    echo "   • Set up SSL/TLS for PowerDNS-Admin (use Nginx reverse proxy)"
    echo "   • Enable firewall and allow only necessary ports"
    echo "   • Keep system and software up to date"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

################################################################################
# MAIN INSTALLATION FLOW
################################################################################

main() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  PowerDNS + PowerDNS-Admin Installation Script"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    check_system
    
    echo ""
    log_warning "This script will install and configure:"
    echo "  • PowerDNS Authoritative Server (SQLite backend)"
    echo "  • PowerDNS-Admin Web Interface (MariaDB backend)"
    echo "  • MariaDB Database Server"
    echo "  • Node.js and Yarn"
    echo "  • Optional: dnsdist for DoH/DoT support"
    echo ""
    
    if ! prompt_yes_no "Do you want to continue?"; then
        log_info "Installation cancelled"
        exit 0
    fi
    
    echo ""
    
    # Installation steps
    install_powerdns
    install_mariadb
    install_dependencies
    install_nodejs
    install_powerdns_admin
    create_admin_user
    add_powerdns_server
    create_systemd_service
    configure_firewall
    install_dnsdist
    
    # Print summary
    print_summary
}

# Run main function
main
