# Raspberry Pi Kiosk
A black box bash script for configuring Raspberry Pis into single-webpage kiosks.

## Requirements:
- Raspberry Pi 4 or 5 running Raspian OS.
- Shared connected between controlling device and Pi.

## OS Config:
- When burning the OS onto the flashdrive or during initial boot, ensure the following:
    - hostname = `pi-kiosk`
    - password = `admin`
    - SSH enabled = `true`

## How to use:
1) Ensure controlling machine and raspberry pi are on the same network.
2) Download `kiosk-setup.sh` to controlling machine
    - Make sure kiosk-setup script uses Unix LF for EOL
3) Port setup script to the pi: \
    `scp <path_to_kiosk-setup.sh> admin@pi-kiosk:/home/admin`
4) SSH into the pi: \
    `ssh admin@pi-kiosk`
5) Run the setup script:
    `sudo sh kiosk-setup.sh <webpage_url>`
6) Grab a coffee.

## View Kiosk Logs:
`sudo cat /home/kiosk/kiosk-pm-logs.log` \
OR \
`sudo tail -f /home/kiosk/kiosk-pm-logs.log`