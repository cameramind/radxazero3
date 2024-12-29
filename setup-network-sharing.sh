#!/bin/bash

# Sprawdź czy skrypt jest uruchomiony z prawami roota
if [ "$EUID" -ne 0 ]; then 
    echo "Ten skrypt wymaga uprawnień roota. Uruchom z sudo."
    exit 1
fi

# Funkcja do wyświetlania dostępnych interfejsów
show_interfaces() {
    echo "Dostępne interfejsy sieciowe:"
    ip -br link show | grep -v "lo" | awk '{print $1}'
}

# Funkcja do sprawdzania poprawności interfejsu
check_interface() {
    ip link show $1 > /dev/null 2>&1
    return $?
}

# Pokaż dostępne interfejsy
echo "=== Konfiguracja udostępniania internetu ==="
show_interfaces
echo ""

# Pobierz nazwę interfejsu WiFi
while true; do
    read -p "Podaj nazwę interfejsu z internetem (WiFi, np. wlan0): " WIFI_IF
    if check_interface $WIFI_IF; then
        break
    else
        echo "Nieprawidłowy interfejs. Spróbuj ponownie."
    fi
done

# Pobierz nazwę interfejsu USB
while true; do
    read -p "Podaj nazwę interfejsu USB do udostępnienia internetu: " USB_IF
    if check_interface $USB_IF; then
        break
    else
        echo "Nieprawidłowy interfejs. Spróbuj ponownie."
    fi
done

echo "Konfigurowanie przekazywania pakietów..."
# Włącz przekazywanie pakietów
sysctl -w net.ipv4.ip_forward=1
echo "net.ipv4.ip_forward=1" > /etc/sysctl.d/99-network-sharing.conf

# Konfiguracja iptables
echo "Konfigurowanie iptables..."
iptables -F
iptables -t nat -F
iptables -t nat -A POSTROUTING -o $WIFI_IF -j MASQUERADE
iptables -A FORWARD -i $WIFI_IF -o $USB_IF -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i $USB_IF -o $WIFI_IF -j ACCEPT

# Zapisz reguły iptables
echo "Zapisywanie reguł iptables..."
apt-get install -y iptables-persistent
netfilter-persistent save

# Konfiguracja interfejsu USB
echo "Konfigurowanie interfejsu USB..."
ip addr flush dev $USB_IF
ip addr add 192.168.2.1/24 dev $USB_IF
ip link set $USB_IF up

# Instalacja i konfiguracja dnsmasq
echo "Konfigurowanie serwera DHCP (dnsmasq)..."
apt-get install -y dnsmasq

# Tworzenie kopii zapasowej oryginalnej konfiguracji dnsmasq
if [ -f /etc/dnsmasq.conf ]; then
    mv /etc/dnsmasq.conf /etc/dnsmasq.conf.backup
fi

# Tworzenie nowej konfiguracji dnsmasq
cat > /etc/dnsmasq.conf << EOF
interface=$USB_IF
dhcp-range=192.168.2.2,192.168.2.10,255.255.255.0,24h
EOF

# Restart dnsmasq
systemctl restart dnsmasq

# Tworzenie skryptu do przywracania konfiguracji po reboocie
cat > /usr/local/bin/restore-network-sharing.sh << EOF
#!/bin/bash
ip addr add 192.168.2.1/24 dev $USB_IF
ip link set $USB_IF up
EOF

chmod +x /usr/local/bin/restore-network-sharing.sh

# Dodanie skryptu do autostartu
cat > /etc/systemd/system/network-sharing.service << EOF
[Unit]
Description=Restore Network Sharing Configuration
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/restore-network-sharing.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

# Włączenie serwisu
systemctl enable network-sharing.service

echo "====================================="
echo "Konfiguracja zakończona pomyślnie!"
echo "Interfejs WiFi: $WIFI_IF"
echo "Interfejs USB: $USB_IF"
echo "IP interfejsu USB: 192.168.2.1"
echo "Zakres DHCP: 192.168.2.2 - 192.168.2.10"
echo "====================================="
