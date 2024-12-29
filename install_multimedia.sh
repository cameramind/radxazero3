#!/bin/bash

# Funkcja do logowania
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

# Funkcja do sprawdzania błędów
check_error() {
    if [ $? -ne 0 ]; then
        log "BŁĄD: $1"
        exit 1
    fi
}

# Funkcja do sprawdzania czy jesteśmy na Debian
check_debian() {
    if ! grep -q 'Debian' /etc/os-release; then
        log "To nie jest system Debian. Skrypt jest przeznaczony tylko dla Debian."
        exit 1
    fi
}

# Funkcja do sprawdzania architektury
check_architecture() {
    architecture=$(dpkg --print-architecture)
    log "Wykryto architekturę: $architecture"
    if [[ $architecture != "arm64" && $architecture != "armhf" ]]; then
        log "OSTRZEŻENIE: Ten skrypt był testowany na architekturach ARM. Wykryto: $architecture"
    fi
}

# Funkcja do testowania zainstalowanych komponentów
test_installation() {
    local package=$1
    local test_cmd=$2
    
    if ! command -v $test_cmd &> /dev/null; then
        log "Test nieudany dla $package (komenda $test_cmd nie znaleziona)"
        return 1
    fi
    
    log "Test udany dla $package"
    return 0
}

# Główna funkcja instalacyjna
install_multimedia() {
    # Aktualizacja systemu
    log "Aktualizacja list pakietów..."
    apt-get update
    check_error "Nie udało się zaktualizować list pakietów"
    
    # Instalacja niezbędnych narzędzi
    log "Instalacja niezbędnych narzędzi..."
    apt-get install -y \
        apt-transport-https \
        ca-certificates \
        curl \
        software-properties-common
    check_error "Nie udało się zainstalować niezbędnych narzędzi"

    # Instalacja GStreamer
    log "Instalacja GStreamer..."
    apt-get install -y \
        gstreamer1.0-tools \
        gstreamer1.0-plugins-base \
        gstreamer1.0-plugins-good \
        gstreamer1.0-plugins-bad \
        gstreamer1.0-plugins-ugly \
        gstreamer1.0-libav \
        gstreamer1.0-alsa
    check_error "Nie udało się zainstalować GStreamer"

    # Instalacja FFmpeg
    log "Instalacja FFmpeg..."
    apt-get install -y ffmpeg
    check_error "Nie udało się zainstalować FFmpeg"

    # Instalacja VLC
    log "Instalacja VLC..."
    apt-get install -y vlc
    check_error "Nie udało się zainstalować VLC"

    # Instalacja dodatkowych kodeków
    log "Instalacja dodatkowych kodeków..."
    apt-get install -y \
        libavcodec-extra \
        libdvd-pkg \
        libmpeg2-4 \
        libxvidcore4 \
        x264 \
        libmp3lame0 \
        libass9 \
        libvpx6 \
        libvorbis0a \
        libtheora0 \
        libx265-192 \
        libaom0 \
        libopus0 \
        libva2 \
        va-driver-all \
        vdpau-driver-all \
        mesa-va-drivers \
        mesa-vdpau-drivers
    check_error "Nie udało się zainstalować dodatkowych kodeków"

    # Konfiguracja libdvd-pkg
    dpkg-reconfigure libdvd-pkg

    # Czyszczenie
    apt-get clean
    apt-get autoremove -y
}

# Funkcja do testowania wszystkich komponentów
test_all_components() {
    log "Rozpoczynanie testów zainstalowanych komponentów..."

    # Test GStreamer
    if gst-launch-1.0 --version &> /dev/null; then
        log "GStreamer działa poprawnie"
        gst-launch-1.0 --version
    else
        log "BŁĄD: GStreamer nie działa poprawnie"
    fi

    # Test FFmpeg
    if ffmpeg -version &> /dev/null; then
        log "FFmpeg działa poprawnie"
        ffmpeg -version | head -n1
    else
        log "BŁĄD: FFmpeg nie działa poprawnie"
    fi

    # Test VLC
    if vlc --version &> /dev/null; then
        log "VLC działa poprawnie"
        vlc --version | head -n1
    else
        log "BŁĄD: VLC nie działa poprawnie"
    fi

    # Test odtwarzania przykładowego strumienia
    log "Test odtwarzania przykładowego strumienia (5 sekund)..."
    if timeout 5 gst-launch-1.0 videotestsrc ! autovideosink -v &> /dev/null; then
        log "Test odtwarzania przebiegł pomyślnie"
    elif [ $? -eq 124 ]; then
        # Timeout exit code is 124
        log "Test odtwarzania zakończony po 5 sekundach (OK)"
    else
        log "BŁĄD: Test odtwarzania nie powiódł się"
    fi
}

# Funkcja do zbierania informacji o systemie
gather_system_info() {
    log "Zbieranie informacji o systemie..."
    
    echo "=== Informacje o systemie ==="
    uname -a
    echo "=== Wersja Debian ==="
    cat /etc/debian_version
    echo "=== Informacje o CPU ==="
    lscpu
    echo "=== Informacje o pamięci ==="
    free -h
    echo "=== Informacje o dysku ==="
    df -h
    echo "=== Zainstalowane sterowniki graficzne ==="
    lspci | grep -i vga
    echo "=== Sterowniki dźwięku ==="
    aplay -l
}

# Obsługa SIGINT (Ctrl+C)
trap 'echo "Przerwano działanie skryptu"; exit 1' INT

# Główna funkcja
main() {
    # Sprawdzenie czy skrypt jest uruchomiony jako root
    if [ "$EUID" -ne 0 ]; then 
        log "Proszę uruchomić skrypt jako root (sudo)"
        exit 1
    fi

    # Sprawdzenie systemu i architektury
    check_debian
    check_architecture
    
    # Zbieranie informacji o systemie
    gather_system_info
    
    # Instalacja komponentów
    install_multimedia
    
    # Testowanie komponentów
    test_all_components
    
    log "Instalacja zakończona. Sprawdź logi powyżej pod kątem ewentualnych błędów."
}

# Uruchomienie głównej funkcji
main
