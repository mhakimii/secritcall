#!/bin/bash

# ============================================================
#  SecritCall - One-Command FreePBX Installer
#  For Ubuntu 24.04 / 26.04 LTS
#  Creates a full-featured VoIP PBX with web panel
# ============================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}"
echo "============================================================"
echo "   SecritCall - Full VoIP System Installer"
echo "   FreePBX + Asterisk + Modern Web Panel"
echo "============================================================"
echo -e "${NC}"

# Check root
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}Please run as root (sudo ./install.sh)${NC}"
  exit 1
fi

# Check Ubuntu
if ! grep -q "Ubuntu" /etc/os-release; then
  echo -e "${RED}This script is designed for Ubuntu.${NC}"
  exit 1
fi

UBUNTU_VERSION=$(grep VERSION_ID /etc/os-release | cut -d '"' -f 2)
echo -e "${GREEN}Detected Ubuntu $UBUNTU_VERSION${NC}"

# Update system
echo -e "\n${YELLOW}[1/10] Updating system...${NC}"
apt update -y
DEBIAN_FRONTEND=noninteractive apt upgrade -y

# Install basic tools
echo -e "\n${YELLOW}[2/10] Installing basic tools...${NC}"
apt install -y curl wget gnupg2 software-properties-common apt-transport-https \
  ca-certificates lsb-release unzip git nano net-tools sox libsox-fmt-all \
  build-essential subversion autoconf automake libxml2-dev libncurses5-dev \
  libsqlite3-dev uuid-dev libjansson-dev libssl-dev openssl libedit-dev

# Install Apache, MariaDB, PHP
echo -e "\n${YELLOW}[3/10] Installing Apache, MariaDB and PHP...${NC}"
apt install -y apache2 mariadb-server mariadb-client

# PHP packages (compatible with FreePBX 17)
apt install -y php php-cli php-common php-curl php-mbstring php-xml php-gd \
  php-mysql php-zip php-intl php-bcmath php-soap php-ldap php-imap php-sqlite3 \
  php-xmlrpc libapache2-mod-php php-json

# Install Node.js (required by FreePBX)
echo -e "\n${YELLOW}[4/10] Installing Node.js...${NC}"
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt install -y nodejs

# Configure MariaDB securely (basic)
echo -e "\n${YELLOW}[5/10] Configuring MariaDB...${NC}"
systemctl start mariadb
systemctl enable mariadb

# Create FreePBX database user
DB_PASS=$(openssl rand -base64 16)
mysql -e "CREATE DATABASE IF NOT EXISTS asterisk;"
mysql -e "CREATE DATABASE IF NOT EXISTS asteriskcdrdb;"
mysql -e "CREATE USER IF NOT EXISTS 'asterisk'@'localhost' IDENTIFIED BY '${DB_PASS}';"
mysql -e "GRANT ALL PRIVILEGES ON asterisk.* TO 'asterisk'@'localhost';"
mysql -e "GRANT ALL PRIVILEGES ON asteriskcdrdb.* TO 'asterisk'@'localhost';"
mysql -e "FLUSH PRIVILEGES;"

echo "DB Password: ${DB_PASS}" > /root/secritcall-db-pass.txt
chmod 600 /root/secritcall-db-pass.txt

# Install Asterisk from source (more reliable on new Ubuntu)
echo -e "\n${YELLOW}[6/10] Downloading and compiling Asterisk 22 LTS (this takes time)...${NC}"
cd /usr/src
wget -q http://downloads.asterisk.org/pub/telephony/asterisk/asterisk-22-current.tar.gz -O asterisk.tar.gz
tar xzf asterisk.tar.gz
cd asterisk-22*

# Install Asterisk dependencies
contrib/scripts/install_prereq install

./configure --with-jansson-bundled
make menuselect.makeopts
menuselect/menuselect --enable app_macro --enable res_config_mysql menuselect.makeopts || true
make -j$(nproc)
make install
make config
make install-logrotate
ldconfig

# Create asterisk user
id -u asterisk &>/dev/null || useradd -m -d /var/lib/asterisk -s /bin/bash asterisk
usermod -aG asterisk,audio,www-data asterisk || true

# Set permissions
chown -R asterisk:asterisk /var/lib/asterisk /var/spool/asterisk /var/log/asterisk /var/run/asterisk /usr/lib/asterisk 2>/dev/null || true

# Start Asterisk
systemctl enable asterisk
systemctl start asterisk || true

# Download and install FreePBX
echo -e "\n${YELLOW}[7/10] Installing FreePBX...${NC}"
cd /usr/src
wget -q http://mirror.freepbx.org/modules/packages/freepbx/freepbx-17.0-latest.tgz -O freepbx.tgz
tar xzf freepbx.tgz
cd freepbx

# Configure Apache
sed -i 's/^\(User\|Group\).*/\1 asterisk/' /etc/apache2/apache2.conf || true
sed -i 's/AllowOverride None/AllowOverride All/g' /etc/apache2/apache2.conf || true

a2enmod rewrite
systemctl restart apache2

# Install FreePBX
./start_asterisk start || true
./install -n --dbuser=asterisk --dbpass="${DB_PASS}" --dbname=asterisk --cdrdbname=asteriskcdrdb

# Final permissions
chown -R asterisk:asterisk /var/www/html /etc/asterisk /var/lib/asterisk /var/spool/asterisk /var/log/asterisk 2>/dev/null || true

# Firewall basics (UFW)
echo -e "\n${YELLOW}[8/10] Configuring firewall...${NC}"
apt install -y ufw
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 5060/udp
ufw allow 5060/tcp
ufw allow 10000:20000/udp
echo "y" | ufw enable || true

# Create a simple info file
echo -e "\n${YELLOW}[9/10] Creating info file...${NC}"
SERVER_IP=$(hostname -I | awk '{print $1}')
cat > /root/secritcall-info.txt <<EOF
============================================================
   SecritCall / FreePBX Installation Complete
============================================================

Web Panel URL : http://${SERVER_IP}/admin
              or http://${SERVER_IP}

First login:
  - Open the URL above
  - Create your admin username and password

Database password saved in: /root/secritcall-db-pass.txt

Important ports opened:
  - 80/443  (Web Panel)
  - 5060    (SIP)
  - 10000-20000 (RTP Media)

Next steps:
  1. Go to the web panel and finish the initial setup
  2. Create Extensions (Applications > Extensions)
  3. Configure your softphone (Zoiper etc.) with the extension

Enjoy your VoIP system!
============================================================
EOF

echo -e "\n${YELLOW}[10/10] Restarting services...${NC}"
systemctl restart apache2
systemctl restart asterisk || true

echo -e "\n${GREEN}"
echo "============================================================"
echo "   Installation Finished Successfully!"
echo "============================================================"
echo -e "${NC}"
cat /root/secritcall-info.txt

echo -e "\n${BLUE}Please reboot the server once:  reboot${NC}"
