# radxazero3

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

