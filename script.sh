#!/bin/bash

# Ce script doit être exécuté avec sudo ou en tant que root
if [[ $EUID -ne 0 ]]; then
  echo "❌ Veuillez exécuter ce script avec sudo ou en tant que root."
  exit 1
fi

echo "🔄 Mise à jour du système..."
apt update && apt upgrade -y

echo "📦 Installation d'Apache, MariaDB, PHP et extensions..."
apt install -y apache2 mariadb-server php libapache2-mod-php php-mysql php-cli php-curl php-gd php-mbstring php-xml php-zip unzip curl

echo "🔄 Activation des services..."
systemctl enable apache2
systemctl start apache2

systemctl enable mariadb
systemctl start mariadb

echo "🔐 Configuration sécurisée de MariaDB..."
mysql_secure_installation <<EOF

y
$(openssl rand -base64 16)
$(openssl rand -base64 16)
y
y
y
y
EOF

echo "🌐 Création du fichier PHP info.php..."
cat <<EOF > /var/www/html/info.php
<?php
phpinfo();
?>
EOF

echo "📁 Droits sur /var/www/html..."
chown -R www-data:www-data /var/www/html
chmod -R 755 /var/www/html

echo "📦 Installation automatique de phpMyAdmin..."

# Définir un mot de passe aléatoire pour l'utilisateur phpmyadmin
PHPMYADMIN_PASS=$(openssl rand -base64 12)
echo "Mot de passe phpmyadmin: $PHPMYADMIN_PASS"

# Préconfigurer les réponses pour phpmyadmin
echo "phpmyadmin phpmyadmin/dbconfig-install boolean true" | debconf-set-selections
echo "phpmyadmin phpmyadmin/app-password-confirm password $PHPMYADMIN_PASS" | debconf-set-selections
echo "phpmyadmin phpmyadmin/mysql/admin-pass password $PHPMYADMIN_PASS" | debconf-set-selections
echo "phpmyadmin phpmyadmin/mysql/app-pass password $PHPMYADMIN_PASS" | debconf-set-selections
echo "phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2" | debconf-set-selections

# Installer phpMyAdmin sans prompt
apt install -y phpmyadmin

echo "🔗 Lien symbolique vers /var/www/html/phpmyadmin..."
ln -s /usr/share/phpmyadmin /var/www/html/phpmyadmin

echo "🔄 Création d'un utilisateur MariaDB pour phpMyAdmin..."
DBUSER="adminuser"
DBPASS=$(openssl rand -base64 12)

mysql -u root <<EOF
CREATE USER '$DBUSER'@'localhost' IDENTIFIED BY '$DBPASS';
GRANT ALL PRIVILEGES ON *.* TO '$DBUSER'@'localhost' WITH GRANT OPTION;
FLUSH PRIVILEGES;
EOF

echo "👤 Utilisateur créé : $DBUSER"
echo "🔑 Mot de passe : $DBPASS"

echo "✅ phpMyAdmin installé. Accédez à http://<votre_ip>/phpmyadmin"

echo "🌍 IP publique du serveur :"
curl -s http://checkip.amazonaws.com
