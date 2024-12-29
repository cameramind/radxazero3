#!/bin/bash

# Skrypt konfiguruje przekierowanie ruchu sieciowego dla kamery IP
# Użycie: ./configure_camera.sh <interfejs_USB_ETH>
# Przykład: ./configure_camera.sh enx0c0e764be017

# Sprawdzanie czy skrypt jest uruchomiony z uprawnieniami roota
if [ "$EUID" -ne 0 ]; then 
    echo "Uruchom skrypt z uprawnieniami roota (sudo)"
    exit 1
fi

# Sprawdzanie czy podano argument
if [ "$#" -ne 1 ]; then
    echo "Użycie: $0 <interfejs_USB_ETH>"
    echo "Przykład: $0 enx0c0e764be017"
    exit 1
fi

USB_INTERFACE=$1
WIFI_INTERFACE="wlan0"

# Domyślne adresy IP
CAMERA_SUBNET="192.168.1.0/24"
CAMERA_GATEWAY="192.168.1.1"
CAMERA_IP="192.168.1.64"
PUBLIC_CAMERA_IP="192.168.188.240"

echo "Konfiguracja interfejsów sieciowych..."

# Pobierz aktualny adres IP interfejsu WiFi
WIFI_IP=$(ip -4 addr show $WIFI_INTERFACE | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
if [ -z "$WIFI_IP" ]; then
    echo "Nie można znaleźć adresu IP dla interfejsu $WIFI_INTERFACE"
    exit 1
fi

echo "Adres WiFi: $WIFI_IP"

# Konfiguracja interfejsu USB-ETH
echo "Konfiguracja interfejsu $USB_INTERFACE..."
ip addr flush dev $USB_INTERFACE
ip addr add $CAMERA_GATEWAY/24 dev $USB_INTERFACE
ip link set $USB_INTERFACE up

# Włączenie przekazywania pakietów
echo 1 > /proc/sys/net/ipv4/ip_forward

# Czyszczenie starych reguł iptables dla naszych adresów
iptables -t nat -F  # Czyszczenie tablicy NAT

# Konfiguracja przekierowania
echo "Konfiguracja przekierowania ruchu..."
iptables -t nat -A PREROUTING -d $PUBLIC_CAMERA_IP -j DNAT --to-destination $CAMERA_IP
iptables -t nat -A POSTROUTING -s $CAMERA_SUBNET -j SNAT --to-source $WIFI_IP

# Dodanie konfiguracji do /etc/network/interfaces
echo "Zapisywanie trwałej konfiguracji..."
cat << EOF > /etc/network/interfaces.d/camera-config
# Konfiguracja interfejsu kamery
auto $USB_INTERFACE
iface $USB_INTERFACE inet static
    address $CAMERA_GATEWAY
    netmask 255.255.255.0
EOF

echo "Konfiguracja zakończona!"
echo "-----------------------------------"
echo "Podsumowanie konfiguracji:"
echo "Interfejs USB-ETH: $USB_INTERFACE"
echo "Interfejs WiFi: $WIFI_INTERFACE"
echo "Adres IP kamery w sieci wewnętrznej: $CAMERA_IP"
echo "Adres IP kamery w sieci WiFi: $PUBLIC_CAMERA_IP"
echo "Brama dla kamery: $CAMERA_GATEWAY"
echo ""
echo "Aby sprawdzić dostępność kamery, użyj:"
echo "ping $PUBLIC_CAMERA_IP"
