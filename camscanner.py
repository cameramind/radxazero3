import socket
import ipaddress
import concurrent.futures
import subprocess
from typing import List, Dict

def get_local_network() -> str:
    """Get the local network address range"""
    # Get local IP address by creating a temporary socket
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        s.connect(('8.8.8.8', 80))
        local_ip = s.getsockname()[0]
    except Exception:
        local_ip = '127.0.0.1'
    finally:
        s.close()
    
    # Return network in CIDR notation (assuming /24 subnet)
    return '.'.join(local_ip.split('.')[:-1]) + '.0/24'

def ping_host(ip: str) -> bool:
    """Ping a host to check if it's online"""
    try:
        # Using subprocess.run instead of os.system for better security
        result = subprocess.run(
            ['ping', '-c', '1', '-W', '1', ip],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL
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
        9000   # Alternative HTTP
    ]
    
    device_info = {
        'ip': ip,
        'is_online': False,
        'open_ports': [],
        'possible_camera': False
    }
    
    # Check if host is online
    device_info['is_online'] = ping_host(ip)
    
    if device_info['is_online']:
        # Scan common camera ports
        for port in camera_ports:
            if scan_port(ip, port):
                device_info['open_ports'].append(port)
        
        # If device has any of these ports open, it might be a camera
        device_info['possible_camera'] = len(device_info['open_ports']) > 0
    
    return device_info

def scan_network() -> List[Dict]:
    """Scan the local network for potential cameras"""
    network = get_local_network()
    ip_list = [str(ip) for ip in ipaddress.IPv4Network(network)]
    results = []
    
    # Use ThreadPoolExecutor for parallel scanning
    with concurrent.futures.ThreadPoolExecutor(max_workers=50) as executor:
        future_to_ip = {executor.submit(identify_device, ip): ip for ip in ip_list}
        for future in concurrent.futures.as_completed(future_to_ip):
            result = future.result()
            if result['is_online']:
                results.append(result)
    
    return results

def main():
    print("Starting network scan for cameras...")
    results = scan_network()
    
    # Print results
    print("\nScan Results:")
    print("-" * 50)
    for device in results:
        if device['possible_camera']:
            print(f"\nPotential camera found:")
            print(f"IP Address: {device['ip']}")
            print(f"Open ports: {', '.join(map(str, device['open_ports']))}")
    
    print("\nScan complete!")

if __name__ == "__main__":
    main()
