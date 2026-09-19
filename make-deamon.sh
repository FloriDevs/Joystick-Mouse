#!/bin/bash

# Exit on errors
set -e

if [ "$EUID" -ne 0 ]; then
  echo "[-] Please run with sudo!"
  exit 1
fi

# Determine target user (who invoked sudo)
TARGET_USER="${SUDO_USER:-florian}"
USER_HOME=$(eval echo "~$TARGET_USER")
SCRIPT_PATH="$USER_HOME/mouse.py"

echo "[+] Installing Python dependencies (serial, evdev)..."
apt update
apt install -y python3-serial python3-evdev

echo "[+] Configuring uinput and user permissions..."
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
ExecStart=/usr/bin/python3 $SCRIPT_PATH
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable joystick-mouse.service
systemctl start joystick-mouse.service

echo "[+] Done! The service is running and will start automatically on every boot."
echo "[*] Check status with: sudo systemctl status joystick-mouse.service"
