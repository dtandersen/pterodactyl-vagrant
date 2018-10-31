# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "centos/7"
  config.ssh.forward_agent = true
  # config.vm.box_check_update = false

  #config.vm.network "forwarded_port", guest: 443, host: 443
  config.vm.network "forwarded_port", guest: 80, host: 80
  config.vm.network "forwarded_port", guest: 8080, host: 8080
  config.vm.network "forwarded_port", guest: 5555, host: 5555 # the game

  # config.vm.network "forwarded_port", guest: 80, host: 8080, host_ip: "127.0.0.1"

  # config.vm.network "private_network", ip: "192.168.33.10"

  # config.vm.network "public_network"

  # config.vm.synced_folder "../data", "/vagrant_data"

  config.vm.provider "virtualbox" do |vb|
  #   # Display the VirtualBox GUI when booting the machine
  #   vb.gui = true
  #
    vb.memory = 4096
    vb.cpus = 2
  end

  config.vm.provision "shell", inline: <<-SHELL
    # who needs security}
    sed -i 's/^SELINUX=.*/SELINUX=disabled/g' /etc/selinux/config
    setenforce 0

    yum install -y epel-release https://centos7.iuscommunity.org/ius-release.rpm
    yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

    yum update -y -q

    yum install -y -q nano nginx \
      firewalld \
      certbot \
      php72u-common php72u-fpm php72u-cli php72u-json php72u-mysqlnd php72u-gd php72u-mbstring php72u-pdo php72u-zip php72u-bcmath php72u-dom php72u-opcache \
      yum-utils device-mapper-persistent-data lvm2 \
      docker-ce \
      tar unzip make gcc gcc-c++ python \
      nodejs

    systemctl enable docker
    systemctl start docker

    docker run --name mariadb \
      -d --restart unless-stopped \
      -e MYSQL_ROOT_PASSWORD=changeme \
      -e MYSQL_DATABASE=panel \
      -e MYSQL_USER=pterodactyl \
      -e MYSQL_PASSWORD=bird \
      -v /var/lib/mysql:/var/lib/mysql \
      -p 3306:3306 \
      mariadb

    docker run --name redis \
      -d --restart unless-stopped \
      -v /var/lib/redis:/data \
      -p 6379:6379 \
      redis \
      redis-server --appendonly yes

    systemctl start firewalld
    systemctl enable firewalld
    firewall-cmd --add-service=http --permanent
    firewall-cmd --add-service=https --permanent
    firewall-cmd --add-service=http
    firewall-cmd --add-service=https

    curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/bin --filename=composer

    systemctl stop nginx

    #certbot certonly --non-interactive --agree-tos --email test@example.com --standalone --preferred-challenges http -d panel.example.com

    cp /vagrant/nginx.conf /etc/nginx/conf.d/pterodactyl.conf
    systemctl enable nginx
    systemctl start nginx

    cp /vagrant/www-pterodactyl.conf /etc/php-fpm.d/www-pterodactyl.conf
    systemctl enable php-fpm
    systemctl start php-fpm

    mkdir -p /var/www/pterodactyl
    cd /var/www/pterodactyl

    curl -Lso panel.tar.gz https://github.com/Pterodactyl/Panel/releases/download/v0.7.10/panel.tar.gz
    tar --strip-components=1 -xzvf panel.tar.gz
    chmod -R 755 storage/* bootstrap/cache

    cp .env.example .env
    composer install -q --no-dev --optimize-autoloader

    php artisan key:generate --force
    php artisan p:environment:setup --author=test@example.com --url=http://localhost --timezone=America/Los_Angeles --cache=redis --session=redis --queue=redis --disable-settings-ui --redis-host=localhost --redis-pass= --redis-port=6379
    php artisan p:environment:database --host=127.0.0.1 --port=3306 --database=panel --username=pterodactyl --password=bird
    php artisan p:environment:mail --driver=smtp --host=localhost --port=2525 -n --encryption=
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

    firewall-cmd --add-port 8080/tcp --permanent
    firewall-cmd --add-port 2022/tcp --permanent
    firewall-cmd --permanent --zone=trusted --change-interface=docker0
    firewall-cmd --reload
    mkdir -p /srv/daemon /srv/daemon-data
    cd /srv/daemon
    curl -Lo daemon.tar.gz https://github.com/Pterodactyl/Daemon/releases/download/v0.6.7/daemon.tar.gz
    tar --strip-components=1 -xzvf daemon.tar.gz
    npm install --only=production
    cp /vagrant/wings.service /etc/systemd/system/wings.service
    systemctl daemon-reload
    systemctl enable wings
    systemctl start wings
    cp /vagrant/ptero /etc/cron.d
  SHELL
end
