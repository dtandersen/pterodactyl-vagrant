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
