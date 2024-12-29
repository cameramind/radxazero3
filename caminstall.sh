#!/bin/bash

# Kolory do komunikatów
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}=== Instalator Skanera Kamer ===${NC}"

# Sprawdź czy Python jest zainstalowany
if ! command -v python3 &> /dev/null; then
    echo -e "${YELLOW}Python 3 nie jest zainstalowany. Instaluję...${NC}"
    if command -v apt &> /dev/null; then
        sudo apt update
        sudo apt install -y python3 python3-pip python3-venv
    elif command -v dnf &> /dev/null; then
        sudo dnf install -y python3 python3-pip python3-venv
    elif command -v pacman &> /dev/null; then
        sudo pacman -Sy python python-pip
    else
        echo "Nie można zainstalować Pythona. Zainstaluj ręcznie Python 3."
        exit 1
    fi
fi


# Utwórz plik requirements.txt
cat > requirements.txt << EOL
netifaces==0.11.0
EOL

# Utwórz środowisko wirtualne
echo -e "${GREEN}Tworzę środowisko wirtualne...${NC}"
python3 -m venv venv

# Aktywuj środowisko wirtualne
source venv/bin/activate

# Zainstaluj zależności
echo -e "${GREEN}Instaluję wymagane pakiety...${NC}"
pip install -r requirements.txt

# Utwórz skrypt uruchomieniowy
cat > camscanner.sh << 'EOL'
#!/bin/bash
source venv/bin/activate
python3 camscanner.py
deactivate
EOL

# Nadaj uprawnienia wykonywania
chmod +x camscanner.py camscanner.sh

echo -e "${GREEN}Instalacja zakończona!${NC}"
echo -e "Aby uruchomić skaner, użyj polecenia: ${YELLOW}./camscanner.sh${NC}"

# Aktywuj środowisko i uruchom skaner
echo -e "${GREEN}Uruchamiam skaner...${NC}"
./camscanner.sh
