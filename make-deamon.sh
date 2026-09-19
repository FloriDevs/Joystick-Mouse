#!/bin/bash

# Exit on errors
set -e

if [ "$EUID" -ne 0 ]; then
  echo "[-] Please run with sudo!"
  exit 1
fi

# Dynamically determine the real user and install paths
TARGET_USER="${SUDO_USER:-$(logname 2>/dev/null || echo root)}"
INSTALL_DIR="/opt/joystick-mouse"

echo "[+] Setting up installation directory at $INSTALL_DIR..."
mkdir -p "$INSTALL_DIR"

if [ -f "driver.py" ]; then
  cp driver.py "$INSTALL_DIR/driver.py"
else
  echo "[-] Error: driver.py not found in the current directory!"
  exit 1
fi

chown -R "$TARGET_USER:$TARGET_USER" "$INSTALL_DIR"

echo "[+] Installing Python dependencies (serial, evdev)..."
apt update
apt install -y python3-serial python3-evdev

echo "[+] Configuring uinput and user permissions for '$TARGET_USER'..."
usermod -aG input "$TARGET_USER"
modprobe uinput
echo "uinput" > /etc/modules-load.d/uinput.conf

echo "[+] Creating systemd service..."
SERVICE_FILE="/etc/systemd/system/joystick-mouse.service"

cat << EOF > "$SERVICE_FILE"
[Unit]
Description=Arduino Joystick Mouse Daemon
After=multi-user.target graphical.target

[Service]
Type=simple
User=$TARGET_USER
ExecStart=/usr/bin/python3 $INSTALL_DIR/driver.py
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable joystick-mouse.service
systemctl start joystick-mouse.service

echo "[+] Done! driver.py installed to $INSTALL_DIR and running as user '$TARGET_USER'."
echo "[*] Check status with: sudo systemctl status joystick-mouse.service"
