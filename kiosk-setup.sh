#!/bin/bash

# Get IP addr from command args
if [ -z "$1" ]; then
  echo "Usage: $0 <URL>"
  exit 1
fi

DESTINATION_URL=$1

# Remove potentially included unnecessary packages
# ======================================================================
echo "[Kiosk-Setup]: Removing unnecessary packages..."

sudo apt purge wolfram-engine scratch scratch2 nuscratch sonic-pi idle3 smartsim java-common minecraft-pi libreoffice* firefox* -y
sudo apt clean
sudo apt autoremove -y

echo "[Kiosk-Setup]: Unnecessary packages removed."
# ======================================================================

# Update remaining packages
# ======================================================================
echo "[Kiosk-Setup]: Updating dependencies..."

sudo apt update && sudo apt upgrade -y

# Ensure SED is installed for automated file config
sudo apt install -y sed

echo "[Kiosk-Setup]: Dependencies updated."
# ======================================================================

# Create zero-perm kiosk user (username=kiosk pwd=kiosk)
# ======================================================================
echo "[Kiosk-Setup]: Creating user: kiosk..."

sudo adduser --disabled-password --gecos "" kiosk
echo "kiosk:kiosk" | sudo chpasswd

# Create .config dir if it doesn't exist
if [ ! -d /home/kiosk/.config ]; then
  sudo mkdir -p /home/kiosk/.config
fi

# Give kiosk permission to their config directory
sudo chown -R kiosk:kiosk /home/kiosk/.config

echo "[Kiosk-Setup]: Created user: kiosk."

# Configure auto-login for kiosk user
sudo sed -i 's/^autologin-user=.*/autologin-user=kiosk/' /etc/lightdm/lightdm.conf

echo "[Kiosk-Setup]: Configured kiosk user auto-login."
# ======================================================================

# Configure wayfire window-manager
# - Launches process-manager upon startup
# - Disables built in window commands
# ======================================================================
echo "[Kiosk-Setup]: Configuring window-manager..."

# Copy default wayfire.ini to kiosk user
sudo cp /home/admin/.config/wayfire.ini /home/kiosk/.config/wayfire.ini
sudo chown kiosk:kiosk /home/kiosk/.config/wayfire.ini

# Append autostart config
echo "

[autostart]
xdg-autostart = lexsession-xdg-autostart
process_manager = ~/process-manager.sh
screensaver = false
dpms = false" >> /home/kiosk/.config/wayfire.ini

# Disable wayfire command bindings that may allow kiosk users to exit chromium or open windows they shouldn't
sudo sed -i '/^binding_/s/^/# /' /home/kiosk/.config/wayfire.ini


echo "[Kiosk-Setup]: Configured window-manager."
# ======================================================================

# Setup Chromium process manager
# - Relaunches Chromium browser if closed
# - Routes std-out to log file
# ======================================================================
echo "[Kiosk-Setup]: Setting up process-manager..."

sudo touch /home/kiosk/process-manager.sh

echo "#!/bin/bash

# redirect std-out to logfile
exec >> ~/kiosk-pm-logs.log 2>&1

# Disable flags that raise error dialogs when Chromium crashes or closes unexpectedly
sed -i 's/\"exited_cleanly\":false/\"exited_cleanly\":true/' /home/kiosk/.config/chromium/Default/Preferences
sed -i 's/\"exit_type\":\"Crashed/\"exit_type\":\"Normal/' /home/kiosk/.config/chromium/Default/Preferences

# Extract Chromium browser process ID
chromium_pid=\$(pgrep chromium | head -1)

# Monitor Chromium process and restart if it ever closes
while true; do
  if ! pgrep chromium > /dev/null; then
    echo \"Chromium browser process not detected. Launching...\"
    /usr/bin/chromium-browser $DESTINATION_URL --kiosk --noerrdialogs --disable-infobars --no-first-run --ozone-platform=wayland --enable-features=OverlayScrollbar --start-maximized --no-sandbox
    # Short sleep to ensure Chromium is launched before resetting PID
    sleep 5
    chromium_pid=\$(pgrep chromium | head -1)
    echo \"Chromium browser launched with process ID: \$chromium_pid\"
  fi
  sleep 2
done
" > /home/kiosk/process-manager.sh


sudo chmod +x /home/kiosk/process-manager.sh

echo "[Kiosk-Setup]: Completed process-manager setup."

# ======================================================================

echo "[Kiosk-Setup]: Kiosk setup complete. Restarting in 5..."
sleep 5
sudo reboot