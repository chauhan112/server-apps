curl -s http://192.168.178.21:8082/bootstrap | sudo sh


curl -sfL "http://192.168.178.21:8082/bootstrap?role=agent" | sudo sh

curl -sfL "http://192.168.178.21:8082/bootstrap?role=server" | sudo sh


# 1. Clean up any leftover configuration from the failed installation
sudo /usr/local/bin/k3s-uninstall.sh

# 2. Run your bootstrap script using the local LAN IP (port 8082)
curl -sfL "http://192.168.178.21:8082/bootstrap?role=server" | sudo sh


cgroup_memory=1 cgroup_enable=memory


console=serial0,115200 console=tty1 root=PARTUUID=8519183c-02 rootfstype=ext4 fsck.repair=yes rootwait quiet splash plymouth.ignore-serial-consoles cfg80211.ieee80211_regdom=DE cgroup_memory=1 cgroup_enable=memory