#!/bin/bash
#
set -ex

echo "Wifi wird eingerichtet!"
    ip link
    read -p "Wie heisst das wlan-modul?: " modul
    ip link set dev "$modul" up
    sleep 5
    iw dev "$modul" scan > scan.txt
    nano scan.txt
    read -p "Wie heisst das Netzwerk?: " network
    read -p "Wie heisst das Passwort?: " passwort
    wpa_passphrase  "$network"  "$passwort"  > /etc/wpa_supplicant/wpa_supplicant-"$modul".conf
    wpa_supplicant -B -i "$modul" -c /etc/wpa_supplicant/wpa_supplicant-"$modul".conf
    dhcpcd "$modul"

systemctl enable wpa_supplicant@"$modul".service
systemctl enable dhcpcd@"$modul"

echo "Fertig!!!"
