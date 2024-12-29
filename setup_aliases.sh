#!/bin/bash

# Funkcja do wykrywania używanej powłoki
detect_shell() {
    current_shell=$(basename "$SHELL")
    echo "Wykryto powłokę: $current_shell"
    return 0
}

# Funkcja do dodawania aliasów do odpowiedniego pliku konfiguracyjnego
setup_aliases() {
    local shell_type="$1"
    local config_file=""
    local aliases_file=""

    case "$shell_type" in
        "bash")
            config_file="$HOME/.bashrc"
            aliases_file="$HOME/.bash_aliases"
            ;;
        "zsh")
            config_file="$HOME/.zshrc"
            aliases_file="$HOME/.zsh_aliases"
            ;;
        *)
            echo "Nieobsługiwana powłoka: $shell_type"
            return 1
            ;;
    esac

    # Tworzenie pliku z aliasami jeśli nie istnieje
    if [ ! -f "$aliases_file" ]; then
        touch "$aliases_file"
        echo "Utworzono plik aliasów: $aliases_file"
    fi

    # Sprawdzenie czy plik konfiguracyjny istnieje
    if [ ! -f "$config_file" ]; then
        touch "$config_file"
        echo "Utworzono plik konfiguracyjny: $config_file"
    fi

    # Dodanie źródłowania pliku aliasów do pliku konfiguracyjnego
    if ! grep -q "source.*$aliases_file" "$config_file"; then
        echo "" >> "$config_file"
        echo "# Ładowanie aliasów" >> "$config_file"
        echo "if [ -f $aliases_file ]; then" >> "$config_file"
        echo "    . $aliases_file" >> "$config_file"
        echo "fi" >> "$config_file"
        echo "Dodano ładowanie aliasów do $config_file"
    fi

    return 0
}

# Funkcja do dodawania nowego aliasu
add_alias() {
    local shell_type="$1"
    local alias_name="$2"
    local alias_command="$3"
    local aliases_file=""

    case "$shell_type" in
        "bash")
            aliases_file="$HOME/.bash_aliases"
            ;;
        "zsh")
            aliases_file="$HOME/.zsh_aliases"
            ;;
        *)
            echo "Nieobsługiwana powłoka: $shell_type"
            return 1
            ;;
    esac

    # Sprawdzenie czy alias już istnieje
    if grep -q "alias $alias_name=" "$aliases_file" 2>/dev/null; then
        echo "Alias '$alias_name' już istnieje. Aktualizuję..."
        sed -i "/alias $alias_name=/c\alias $alias_name='$alias_command'" "$aliases_file"
    else
        echo "alias $alias_name='$alias_command'" >> "$aliases_file"
    fi

    echo "Dodano alias: $alias_name='$alias_command'"
    return 0
}

# Funkcja do wyświetlania wszystkich aliasów
show_aliases() {
    local shell_type="$1"
    local aliases_file=""

    case "$shell_type" in
        "bash")
            aliases_file="$HOME/.bash_aliases"
            ;;
        "zsh")
            aliases_file="$HOME/.zsh_aliases"
            ;;
        *)
            echo "Nieobsługiwana powłoka: $shell_type"
            return 1
            ;;
    esac

    if [ -f "$aliases_file" ]; then
        echo "Aktualnie zdefiniowane aliasy:"
        cat "$aliases_file"
    else
        echo "Brak zdefiniowanych aliasów."
    fi
}

# Główna funkcja
main() {
    local shell_type
    shell_type=$(detect_shell)

    # Konfiguracja podstawowych plików
    setup_aliases "$shell_type"

    # Przykład użycia - dodanie kilku przykładowych aliasów
    add_alias "$shell_type" "ll" "ls -la"
    add_alias "$shell_type" "update" "sudo apt update && sudo apt upgrade -y"
    add_alias "$shell_type" "cls" "clear"

    echo ""
    echo "Aby aktywować nowe aliasy, wykonaj:"
    echo "source ~/.${shell_type}rc"
    
    # Wyświetl wszystkie aliasy
    echo ""
    show_aliases "$shell_type"
}

# Uruchomienie skryptu
main
