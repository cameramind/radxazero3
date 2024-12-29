#!/usr/bin/env python3
import socket
import ipaddress
import concurrent.futures
import subprocess
import netifaces
import sys
from typing import List, Dict

def get_network_interfaces() -> Dict[str, Dict]:
    """Get all network interfaces and their IP addresses"""
    interfaces = {}
    
    for iface in netifaces.interfaces():
        addrs = netifaces.ifaddresses(iface)
        if netifaces.AF_INET in addrs:  # If interface has IPv4
            for addr in addrs[netifaces.AF_INET]:
                if 'addr' in addr and 'netmask' in addr:
                    interfaces[iface] = {
                        'ip': addr['addr'],
                        'netmask': addr['netmask']
                    }
    return interfaces

def ip_to_network(ip: str, netmask: str) -> str:
    """Convert IP and netmask to CIDR notation"""
    network = ipaddress.IPv4Network(f"{ip}/{netmask}", strict=False)
    return str(network)

def ping_host(ip: str) -> bool:
    """Ping a host to check if it's online"""
    try:
        # Dostosowanie komendy ping dla różnych systemów
        param = '-n' if sys.platform.lower() == 'windows' else '-c'
        result = subprocess.run(
            ['ping', param, '1', ip],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            timeout=1
        )
        return result.returncode == 0
    except Exception:
        return False

def scan_port(ip: str, port: int, timeout: float = 1.0) -> bool:
    """Scan a specific port on a host"""
    try:
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
            s.settimeout(timeout)
            result = s.connect_ex((ip, port))
            return result == 0
    except Exception:
        return False

def identify_device(ip: str) -> Dict:
    """Identify if a device might be a camera by checking common camera ports"""
    camera_ports = [
        80,    # HTTP
        443,   # HTTPS
        554,   # RTSP
        8000,  # Alternative HTTP
        8080,  # Alternative HTTP
        9000,  # Alternative HTTP
        37777, # Dahua
        34567  # HikVision
    ]
    
    device_info = {
        'ip': ip,
        'is_online': False,
        'open_ports': [],
        'possible_camera': False
    }
    
    device_info['is_online'] = ping_host(ip)
    
    if device_info['is_online']:
        for port in camera_ports:
            if scan_port(ip, port):
                device_info['open_ports'].append(port)
        device_info['possible_camera'] = len(device_info['open_ports']) > 0
    
    return device_info

def scan_network(network: str, max_workers: int = 50) -> List[Dict]:
    """Scan the network for potential cameras"""
    try:
        ip_list = [str(ip) for ip in ipaddress.IPv4Network(network)]
    except ValueError as e:
        print(f"Błąd: Nieprawidłowy format sieci: {e}")
        return []
    
    results = []
    print(f"\nRozpoczynam skanowanie sieci {network}")
    print("To może potrwać kilka minut...")
    
    with concurrent.futures.ThreadPoolExecutor(max_workers=max_workers) as executor:
        future_to_ip = {executor.submit(identify_device, ip): ip for ip in ip_list}
        total = len(ip_list)
        completed = 0
        
        for future in concurrent.futures.as_completed(future_to_ip):
            completed += 1
            if completed % 10 == 0:  # Update progress every 10 IPs
                print(f"Postęp: {completed}/{total} ({(completed/total*100):.1f}%)")
            
            result = future.result()
            if result['is_online']:
                results.append(result)
    
    return results

def display_menu(interfaces: Dict[str, Dict]) -> None:
    """Display interactive menu"""
    print("\n=== Scanner Kamer IP ===")
    print("\nDostępne interfejsy sieciowe:")
    
    for i, (iface, data) in enumerate(interfaces.items(), 1):
        network = ip_to_network(data['ip'], data['netmask'])
        print(f"{i}. {iface}: {data['ip']} ({network})")
    
    print("\n0. Skanuj własną podsieć")
    print("q. Wyjście")

def main():
    while True:
        interfaces = get_network_interfaces()
        display_menu(interfaces)
        
        choice = input("\nWybierz opcję: ").strip().lower()
        
        if choice == 'q':
            print("Do widzenia!")
            break
        
        network_to_scan = None
        
        if choice == '0':
            custom_network = input("Podaj podsieć do skanowania (np. 192.168.1.0/24): ").strip()
            try:
                # Validate network format
                ipaddress.IPv4Network(custom_network)
                network_to_scan = custom_network
            except ValueError:
                print("Błędny format sieci! Użyj formatu CIDR (np. 192.168.1.0/24)")
                continue
        elif choice.isdigit() and 1 <= int(choice) <= len(interfaces):
            iface = list(interfaces.keys())[int(choice)-1]
            network_to_scan = ip_to_network(
                interfaces[iface]['ip'],
                interfaces[iface]['netmask']
            )
        else:
            print("Nieprawidłowa opcja!")
            continue
        
        if network_to_scan:
            results = scan_network(network_to_scan)
            
            print("\nWyniki skanowania:")
            print("-" * 50)
            
            if not results:
                print("Nie znaleziono potencjalnych kamer w sieci.")
            else:
                for device in results:
                    if device['possible_camera']:
                        print(f"\nZnaleziono potencjalną kamerę:")
                        print(f"Adres IP: {device['ip']}")
                        print(f"Otwarte porty: {', '.join(map(str, device['open_ports']))}")
            
            input("\nNaciśnij Enter, aby kontynuować...")

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\nPrzerwano przez użytkownika. Do widzenia!")
    except Exception as e:
        print(f"\nWystąpił błąd: {e}")
