#!/bin/bash
set -e

# Notify user
headphone_count=$(amixer scontrols | grep "Headphone" | wc -l)
if [ $headphone_count -gt 0 ];
then
    amixer sset 'Headphone' 80%
fi
espeak-ng "Hello friend! I'll be right there, just a second."

# Start CLEXI
cd ~/clexi
is_clexi_running=0
case "$(ps aux | grep clexi)" in *clexi-server.js*) is_clexi_running=1;; *) is_clexi_running=0;; esac
if [ "$is_clexi_running" -eq "1" ]; then
    echo "Restarting CLEXI server"
    pkill -f "clexi-server.js"
    sleep 2
else
    echo "Starting CLEXI server"
fi
nohup node --title=clexi-server.js server.js &> log.out&
sleep 2

# Start Chromium in kiosk mode
is_headless=1
chromedatadir=~/sepia-client/chromium
if [ -f "$chromedatadir/Default/Preferences" ]; then
    sed -i 's/"exited_cleanly":false/"exited_cleanly":true/' $chromedatadir/'Local State'
    sed -i 's/"exited_cleanly":false/"exited_cleanly":true/; s/"exit_type":"[^"]\+"/"exit_type":"Normal"/' $chromedatadir/Default/Preferences
    sed -i 's/"notifications":{}/"notifications":{"http:\/\/localhost:8080,*":{"last_modified":"13224291659276737","setting":1}}/' $chromedatadir/Default/Preferences
    sed -i 's/"geolocation":{}/"geolocation":{"http:\/\/localhost:8080,http:\/\/localhost:8080":{"last_modified":"13224291716729005","setting":1}}/' $chromedatadir/Default/Preferences
    sed -i 's/"media_stream_mic":{}/"media_stream_mic":{"http:\/\/localhost:8080,*":{"last_modified":"13224291643099497","setting":1}}/' $chromedatadir/Default/Preferences
fi
# headless or with display:
pi_model=$(tr -d '\0' </proc/device-tree/model)
is_pi4=0
case "$pi_model" in *"Pi 4"*) is_pi4=1;; *) is_pi4=0;; esac
echo "RPi model: $pi_model - Is Pi4: $is_pi4"
if [ "$is_headless" -eq "0" ]; then
	echo "Running SEPIA-Client in 'display' mode. Use SEPIA Control-HUB to connect and control via remote terminal, default URL is: ws://[IP]:9090/clexi"
    chromium-browser --user-data-dir=$chromedatadir --alsa-output-device=default --allow-insecure-localhost --autoplay-policy=no-user-gesture-required --disable-infobars --enable-features=OverlayScrollbar --hide-scrollbars --kiosk 'http://localhost:8080/sepia/index.html?isApp=true' >/dev/null 2>&1
elif [ "$is_headless" -eq "2" ]; then
	echo "Running SEPIA-Client in 'pseudo-headless' mode. Use SEPIA Control-HUB to connect and control via remote terminal, default URL is: ws://[IP]:9090/clexi"
    chromium-browser --user-data-dir=$chromedatadir --alsa-output-device=default --allow-insecure-localhost --autoplay-policy=no-user-gesture-required --disable-infobars --enable-features=OverlayScrollbar --hide-scrollbars --kiosk 'http://localhost:8080/sepia/index.html?isApp=true&isHeadless=true' >/dev/null 2>&1
elif [ "$is_pi4" = "1" ]; then
	echo "Running SEPIA-Client in 'headless Pi4' mode. Use SEPIA Control-HUB to connect and control via remote terminal, default URL is: ws://[IP]:9090/clexi"
    xvfb-run -n 2072 --server-args="-screen 0 500x800x24" chromium-browser --disable-features=VizDisplayCompositor --user-data-dir=$chromedatadir --alsa-output-device=default --allow-insecure-localhost --autoplay-policy=no-user-gesture-required --disable-infobars --enable-features=OverlayScrollbar --hide-scrollbars --kiosk 'http://localhost:8080/sepia/index.html?isApp=true&isHeadless=true' >/dev/null 2>&1
else
	echo "Running SEPIA-Client in 'headless' mode. Use SEPIA Control-HUB to connect and control via remote terminal, default URL is: ws://[IP]:9090/clexi"
    xvfb-run -n 2072 --server-args="-screen 0 320x480x16" chromium-browser --user-data-dir=$chromedatadir --alsa-output-device=default --allow-insecure-localhost --autoplay-policy=no-user-gesture-required --disable-infobars --enable-features=OverlayScrollbar --hide-scrollbars --kiosk 'http://localhost:8080/sepia/index.html?isApp=true&isHeadless=true' >/dev/null 2>&1
fi
