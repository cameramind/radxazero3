# radxazero3

## Install debian

+ [Radxa ZERO 3W](https://radxa.com/products/zeros/zero3w#downloads)
+ [Radxa Docs](https://docs.radxa.com/en/zero/zero3/getting-started/download)
+ Download: [https://github.com/radxa-build/radxa-zero3/releases/download/b6/radxa-zero3_debian_bullseye_xfce_b6.img.xz](https://github.com/radxa-build/radxa-zero3/releases/download/b6/radxa-zero3_debian_bullseye_xfce_b6.img.xz)


## Clone
If you want to force a git pull and replace all local changes, here are the safest approaches:

1. Method 1 - Fetch and reset (Safest):
```bash
git fetch origin
git reset --hard origin/main  # or origin/master, depending on your branch name
```

2. Method 2 - Clean and pull:
```bash
git reset --hard HEAD
git clean -fd
git pull
```

3. Method 3 - Most aggressive (use with caution):
```bash
git fetch origin
git reset --hard origin/main
git clean -fd
```

4. If you have local commits you want to discard:
```bash
git reset --hard @{u}
```

Important notes:
- `--hard` will delete all local changes
- `clean -fd` removes untracked files and directories
- Always make sure to backup important changes before using these commands
- Replace `main` with your branch name if different

If you want to create a one-line alias for this in your `.bashrc` or `.zshrc`:
```bash
alias git-force-pull='git fetch origin && git reset --hard origin/main && git clean -fd'
```


## Aliasy

Aby aliasy działały po restarcie systemu, należy je dodać do odpowiedniego pliku konfiguracyjnego powłoki. 

2. Nadaj uprawnienia do wykonywania:
```bash
chmod +x setup_aliases.sh
```
3. Uruchom skrypt:
```bash
./setup_aliases.sh
```

Skrypt:
1. Wykrywa używaną powłokę (bash lub zsh)
2. Tworzy odpowiednie pliki konfiguracyjne jeśli nie istnieją
3. Konfiguruje ładowanie aliasów przy starcie powłoki
4. Dodaje przykładowe aliasy

Aby dodać własny alias, możesz użyć:
```bash
add_alias "bash" "twoj_alias" "twoja_komenda"
```

Po wykonaniu skryptu, aby aktywować aliasy w bieżącej sesji, wykonaj:
```bash
source ~/.bashrc  # dla bash
# lub
source ~/.zshrc   # dla zsh
```

Wszystkie dodane aliasy będą działały po ponownym uruchomieniu systemu.



## Run


Make it executable:
```bash
chmod +x install_docker.sh
```

3. Run it as root:
```bash
sudo ./install_docker.sh
```

The script:
- Removes any old Docker installations
- Updates the system
- Installs prerequisites
- Adds Docker's GPG key and repository
- Installs Docker and Docker Compose
- Configures Docker to start on boot
- Adds your user to the docker group
- Installs additional development packages
- Verifies all installations
- Runs a test container

Features:
- Color-coded output for better readability
- Error checking at each step
- Detailed logging
- Automatic cleanup of old installations
- User-friendly output with version information
- Final verification test

After running the script, you'll need to log out and back in for the docker group changes to take effect.


![obraz](https://github.com/user-attachments/assets/f748b920-02fd-4214-9ac4-bd62f682d015)


## Setup network



### Nadaj uprawnienia do wykonywania:
```bash
sudo chmod +x setup-network-sharing.sh
```

### Uruchom skrypt:
```bash
sudo ./setup-network-sharing.sh
```

Skrypt:
- Pokazuje listę dostępnych interfejsów
- Pozwala wybrać interfejs z internetem (WiFi)
- Pozwala wybrać interfejs USB do udostępnienia
- Automatycznie konfiguruje wszystkie potrzebne ustawienia
- Tworzy usługę systemową, która przywraca konfigurację po restarcie
- Instaluje potrzebne pakiety (dnsmasq, iptables-persistent)

Po uruchomieniu skryptu i podłączeniu urządzenia do portu USB, powinno ono automatycznie otrzymać adres IP z zakresu 192.168.2.2 - 192.168.2.10 i mieć dostęp do internetu.

## bridge

install 
```bash    
sudo apt-get install bridge-utils
sudo apt-get install --reinstall bridge-utils
echo $PATH
which brctl
```

config

```bash    
ip link show type bridge
sudo ip addr add 192.168.1.100/24 dev bridge0
ip link show
```

test

```bash    
ip link show
```


Jeśli chcesz skonfigurować most od nowa, możesz

Sprawdźmy do którego mostu jest aktualnie przypisany:
```bash
ip link show enx0c0e764be017
```


Usunąć obecny most:
```bash
sudo ip link set bridge0 down
sudo ip link delete bridge0
```

Jeśli chcesz przenieść interfejs do bridge0, musisz najpierw usunąć go z obecnego mostu:
```bash
sudo ip link set enx0c0e764be017 nomaster
```


Stworzyć nowy z właściwą konfiguracją:
```bash
sudo ip link add name bridge0 type bridge
sudo ip link set bridge0 up
sudo ip addr add 192.168.188.251/24 dev bridge0
```


A następnie dodać do bridge0:
```bash
sudo brctl addif bridge0 enx0c0e764be017
```


## Prosty routing zamiast mostu

 

Aby kamera miała adres z zakresu 192.168.188.* (np. 192.168.188.251) i maskę 255.255.255.0
powinna być podłączona przez adapter USB-ETH (enx0c0e764be017) 
by była widoczna w sieci WiFi (192.168.188.0/24), 
najlepiej będzie skonfigurować prosty routing zamiast mostu. 

1. Najpierw przypisz stały adres IP do interfejsu USB-ETH, żeby kamera była widoczna bezpośrednio w sieci WiFi 192.168.188.0/24. W tym przypadku powinna mieć adres z tej samej puli.

```bash
sudo ip addr add 192.168.188.240/32 dev enx0c0e764be017
```

2. Włącz forwarding IP w systemie:
```bash
sudo sysctl -w net.ipv4.ip_forward=1
```

3. Dodaj reguły NAT, aby ruch z sieci kamery mógł przechodzić do sieci WiFi:
```bash
sudo iptables -t nat -A POSTROUTING -o wlan0 -j MASQUERADE
sudo iptables -A FORWARD -i wlan0 -o enx0c0e764be017 -m state --state RELATED,ESTABLISHED -j ACCEPT
sudo iptables -A FORWARD -i enx0c0e764be017 -o wlan0 -j ACCEPT
```


3. Dodaj do /etc/network/interfaces dla trwałej konfiguracji:
```bash
sudo nano /etc/network/interfaces
```

```
auto enx0c0e764be017
iface enx0c0e764be017 inet static
    address 192.168.188.240
    netmask 255.255.255.0
```

W tej konfiguracji:
+ Radxa WiFi: 192.168.188.203 
+ Interfejs USB-ETH i kamera: 192.168.188.240

Czyli kamera będzie dostępna pod adresem 192.168.188.240

Wszystkie urządzenia będą w tej samej sieci i będą mogły się bezpośrednio komunikować bez potrzeby routingu czy NAT.

```bash
sudo apt-get install -y nmap netcat nftables tcpdump
sudo systemctl enable nftables
sudo systemctl start nftables
```
  
Możemy sprawdzić dostępność kamery Reolink na kilka sposobów:

1. Najpierw podstawowy test łączności:
```bash
ping 192.168.188.240
```

2. Sprawdź czy kamera odpowiada na portach, które Reolink standardowo używa:
```bash
nc -zv 192.168.188.240 80    # sprawdza port HTTP
nc -zv 192.168.188.240 443   # sprawdza port HTTPS
nc -zv 192.168.188.240 9000  # typowy port RTSP dla Reolink
```

3. Możesz też użyć nmap do sprawdzenia otwartych portów:
```bash
sudo nmap -p- 192.168.188.240
```

4. W przeglądarce możesz spróbować otworzyć:
```
http://192.168.188.240
```

Jeśli którykolwiek z tych testów się nie powiedzie, sprawdźmy:
- Czy kamera jest zasilona
- Czy kabel sieciowy jest dobrze podłączony
- Czy interfejs enx0c0e764be017 ma poprawnie przypisany adres IP (możemy sprawdzić przez `ip addr show enx0c0e764be017`)


## configure_eth

Wyjaśnienie jak działa to rozwiązanie:

1. Architektura sieci:
   - Sieć WiFi (zewnętrzna): 192.168.188.0/24
   - Sieć kamery (wewnętrzna): 192.168.1.0/24
   - Radxa działa jako router między tymi sieciami

2. Konfiguracja IP:
   - Kamera w sieci wewnętrznej: 192.168.1.64
   - Interfejs USB-ETH (brama dla kamery): 192.168.1.1
   - Publiczny adres kamery w sieci WiFi: 192.168.188.240

3. Jak działa przekierowanie:
   - Gdy ktoś próbuje połączyć się z 192.168.188.240:
     * DNAT zmienia adres docelowy na 192.168.1.64 (kamera)
     * Pakiet trafia do kamery
   - Gdy kamera odpowiada:
     * SNAT zmienia adres źródłowy na adres WiFi Radxy
     * Odpowiedź wraca do klienta

2. Nadaj uprawnienia do wykonania:
```bash
chmod +x configure_eth.sh
```
3. Uruchom z sudo podając nazwę interfejsu USB-ETH:
```bash
sudo ./configure_eth.sh enx0c0e764be017
```

Skrypt automatycznie:
- Konfiguruje interfejsy
- Ustawia przekierowanie
- Zapisuje trwałą konfigurację
- Wyświetla podsumowanie

Dzięki temu rozwiązaniu:
- Nie tracimy połączenia SSH
- Kamera ma stały, przewidywalny adres w sieci WiFi
- Konfiguracja jest trwała (przetrwa restart)
