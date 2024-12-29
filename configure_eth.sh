#!/bin/bash

# Skrypt konfiguruje przekierowanie ruchu sieciowego dla kamery IP używając nftables
# Użycie: ./configure_camera.sh <interfejs_USB_ETH>

if [ "$EUID" -ne 0 ]; then 
    echo "Uruchom skrypt z uprawnieniami roota (sudo)"
    exit 1
fi

if [ "$#" -ne 1 ]; then
    echo "Użycie: $0 <interfejs_USB_ETH>"
    exit 1
fi

USB_INTERFACE=$1
WIFI_INTERFACE="wlan0"
CAMERA_SUBNET="192.168.1.0/24"
CAMERA_GATEWAY="192.168.1.1"
CAMERA_IP="192.168.1.64"
PUBLIC_CAMERA_IP="192.168.188.240"

# Pobierz adres IP WiFi
WIFI_IP=$(ip -4 addr show $WIFI_INTERFACE | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
if [ -z "$WIFI_IP" ]; then
    echo "Nie można znaleźć adresu IP dla interfejsu $WIFI_INTERFACE"
    exit 1
fi

echo "Konfiguracja interfejsów..."

# Konfiguracja USB-ETH
ip addr flush dev $USB_INTERFACE
ip addr add $CAMERA_GATEWAY/24 dev $USB_INTERFACE
ip link set $USB_INTERFACE up

# Włącz forwarding
echo 1 > /proc/sys/net/ipv4/ip_forward

# Konfiguracja nftables
echo "Konfiguracja nftables..."

# Usuń istniejące reguły
nft flush ruleset

# Podstawowa konfiguracja
nft -f - << EOF
table ip nat {
    chain prerouting {
        type nat hook prerouting priority 0;
        ip daddr $PUBLIC_CAMERA_IP dnat to $CAMERA_IP
    }
    chain postrouting {
        type nat hook postrouting priority 100;
        ip saddr $CAMERA_SUBNET snat to $WIFI_IP
    }
}

table ip filter {
    chain forward {
        type filter hook forward priority 0;
        iif $WIFI_INTERFACE oif $USB_INTERFACE accept
        iif $USB_INTERFACE oif $WIFI_INTERFACE accept
    }
}
EOF

# Zapisz konfigurację nftables
nft list ruleset > /etc/nftables.conf

# Konfiguracja interfejsu
cat << EOF > /etc/network/interfaces.d/camera-config
auto $USB_INTERFACE
iface $USB_INTERFACE inet static
    address $CAMERA_GATEWAY
    netmask 255.255.255.0
EOF

# Dodaj uruchamianie nftables przy starcie
systemctl enable nftables
systemctl restart nftables

echo "Konfiguracja zakończona!"
echo "-----------------------------------"
echo "Podsumowanie:"
echo "USB-ETH: $USB_INTERFACE"
echo "WiFi: $WIFI_INTERFACE ($WIFI_IP)"
echo "Kamera (wewnętrzny): $CAMERA_IP"
echo "Kamera (zewnętrzny): $PUBLIC_CAMERA_IP"
echo "Brama: $CAMERA_GATEWAY"
echo ""
echo "Sprawdź połączenie:"
echo "ping $PUBLIC_CAMERA_IP"

# Dodaj routing dla sieci kamery
ip route add $CAMERA_SUBNET via $CAMERA_GATEWAY dev $USB_INTERFACE
