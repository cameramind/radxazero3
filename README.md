# radxazero3

## Install debian

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





