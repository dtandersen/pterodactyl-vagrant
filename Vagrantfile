# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "centos/7"
  config.ssh.forward_agent = true
  # config.vm.box_check_update = false

  config.vm.network "forwarded_port", guest: 443, host: 443

  # config.vm.network "forwarded_port", guest: 80, host: 8080, host_ip: "127.0.0.1"

  # config.vm.network "private_network", ip: "192.168.33.10"

  # config.vm.network "public_network"

  # config.vm.synced_folder "../data", "/vagrant_data"

  # config.vm.provider "virtualbox" do |vb|
  #   # Display the VirtualBox GUI when booting the machine
  #   vb.gui = true
  #
  #   # Customize the amount of memory on the VM:
  #   vb.memory = "1024"
  # end

  config.vm.provision "shell", inline: <<-SHELL
      ## Install Repos
    yum install -y epel-release https://centos7.iuscommunity.org/ius-release.rpm

    ## Get yum updates
    yum update -y

    ## Install PHP 7.2
    yum install -y nano
    yum install -y php72u-php php72u-common php72u-fpm php72u-cli php72u-json php72u-mysqlnd php72u-mcrypt php72u-gd php72u-mbstring php72u-pdo php72u-zip php72u-bcmath php72u-dom php72u-opcache

    ## Install Repos
    cp /vagrant/mariadb.repo /etc/yum.repos.d/mariadb.repo

    ## Get yum updates
    yum update -y

    ## Install MariaDB 10.2
    yum install -y MariaDB-common MariaDB-server

    ## Start maraidb
    systemctl start mariadb
    systemctl enable mariadb

    yum install -y nginx

    yum install -y firewalld
    systemctl start firewalld
    systemctl enable firewalld
    firewall-cmd --add-service=http --permanent
    firewall-cmd --add-service=https --permanent
    firewall-cmd --add-service=http
    firewall-cmd --add-service=https

    yum install -y redis40u

    systemctl start redis
    systemctl enable redis

    curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

    yum -y install certbot

    #Stop NGINX if its running
    systemctl stop nginx

    #Get our Cert
    sudo certbot certonly --non-interactive --agree-tos --email test@example.com --standalone --preferred-challenges http -d panel.example.com

    #The cert should be now located under /etc/letsencrypt/live/panel.example.com/cert.pem
    cp /vagrant/nginx.conf /etc/nginx/conf.d/pterodactyl.conf
    sed -i 's/^SELINUX=.*/SELINUX=disabled/g' /etc/selinux/config
    setenforce 0
    mkdir -p /etc/letsencrypt/live/localhost
    openssl req -x509 -out /etc/letsencrypt/live/localhost/fullchain.pem -keyout /etc/letsencrypt/live/localhost/privkey.pem \
      -newkey rsa:2048 -nodes -sha256 \
      -subj '/CN=localhost' -extensions EXT -config <( \
      printf "[dn]\nCN=localhost\n[req]\ndistinguished_name = dn\n[EXT]\nsubjectAltName=DNS:localhost\nkeyUsage=digitalSignature\nextendedKeyUsage=serverAuth")
    systemctl enable nginx
    systemctl start nginx
    exit
    #mysql_secure_installation
    export DATABASE_PASS=changeme
    mysqladmin -u root password "$DATABASE_PASS"
    mysql -u root -p"$DATABASE_PASS" -e "UPDATE mysql.user SET Password=PASSWORD('$DATABASE_PASS') WHERE User='root'"
    mysql -u root -p"$DATABASE_PASS" -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1')"
    mysql -u root -p"$DATABASE_PASS" -e "DELETE FROM mysql.user WHERE User=''"
    mysql -u root -p"$DATABASE_PASS" -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\_%'"
    mysql -u root -p"$DATABASE_PASS" -e "FLUSH PRIVILEGES"
    mysql -u root -p"$DATABASE_PASS" -e "CREATE DATABASE panel /*\!40100 DEFAULT CHARACTER SET utf8 */;"
    mysql -u root -p"$DATABASE_PASS" -e "CREATE USER pterodactyl@'127.0.0.1' IDENTIFIED BY 'bird';"
    mysql -u root -p"$DATABASE_PASS" -e "GRANT ALL PRIVILEGES ON panel.* TO 'pterodactyl'@'127.0.0.1';"
    mysql -u root -p"$DATABASE_PASS" -e "FLUSH PRIVILEGES;"

    cp /vagrant/www-pterodactyl.conf /etc/php-fpm.d/www-pterodactyl.conf
    systemctl enable php-fpm
    systemctl start php-fpm

    systemctl start redis
    systemctl enable redis

    mkdir -p /var/www/pterodactyl
    cd /var/www/pterodactyl

    curl -Lo panel.tar.gz https://github.com/Pterodactyl/Panel/releases/download/v0.7.10/panel.tar.gz
    tar --strip-components=1 -xzvf panel.tar.gz
    chmod -R 755 storage/* bootstrap/cache

    cp .env.example .env
    /usr/local/bin/composer install --no-dev

    php artisan key:generate --force
    php artisan p:environment:setup --author=test@example.com --url=http://localhost --timezone=America/Los_Angeles --cache=redis --session=redis --queue=redis --disable-settings-ui --redis-host=localhost --redis-pass= --redis-port=6379
    php artisan p:environment:database --host=127.0.0.1 --port=3306 --database=panel --username=pterodactyl --password=bird
    php artisan p:environment:mail --driver=smtp --host=localhost --port=2525 -n
    php artisan migrate --no-interaction --force
    php artisan db:seed -n --force
    php artisan p:user:make --admin=1  --email=test@example.com --username=admin  --password=test --name-first=admin --name-last=user
    chown -R nginx:nginx $(pwd)
    semanage fcontext -a -t httpd_sys_rw_content_t "/var/www/pterodactyl/storage(/.*)?"
    restorecon -R /var/www/pterodactyl
    cp /vagrant/pteroq.service /etc/systemd/system
    sudo systemctl daemon-reload
    sudo systemctl enable pteroq.service
    sudo systemctl start pteroq

    yum install -y yum-utils device-mapper-persistent-data lvm2

    yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

    yum install -y docker-ce

    systemctl enable docker
    systemctl start docker
    curl --silent --location https://rpm.nodesource.com/setup_8.x | bash -
    yum install -y tar unzip make gcc gcc-c++ python
    yum install -y nodejs
    firewall-cmd --add-port 8080/tcp --permanent
    firewall-cmd --add-port 2022/tcp --permanent
    firewall-cmd --permanent --zone=trusted --change-interface=docker0
    firewall-cmd --reload
    mkdir -p /srv/daemon /srv/daemon-data
    cd /srv/daemon
    curl -Lo daemon.tar.gz https://github.com/Pterodactyl/Daemon/releases/download/v0.5.6/daemon.tar.gz
    tar --strip-components=1 -xzvf daemon.tar.gz
    npm install --only=production
    cp /vagrant/wings.service /etc/systemd/system/wings.service
    systemctl daemon-reload
    systemctl enable wings
    systemctl start wings
  SHELL
end