# DOWNLOAD-LINK

URL : http://137.74.140.105:81/

# Spectre-OS

Spectre-OS ist ein Betriebssytem geschrieben von Simon Rieger.

Es benutzt den Arch-Linux-Kernel als grundbasis.

Ein Betriebssystem ist eine Menge von grundlegenden Programmen, die Ihr Rechner zum Arbeiten benötigt.

Der wichtigste Teil eines Betriebssystems ist der Kernel. Der Kernel ist das Programm, das für alle Basisaufgaben und das Starten von anderen Programmen zuständig ist.

# WICHTIG BEFEHLE

ZUGANGSDATEN : root = root
               user = user
               
Installieren auf Festplatte: "arch-install" in einem Terminal eingeben

Starten der Grafischen Oberfläche "startx" eingeben

# Scripte

# make_mksquashfs

Damit erstellst du ein komplett neues ISO von Spectre-OS.

Du kannst das ISO frei modifizieren.

Es verwendet dabei den arch-graphical-install Script.

# arch-install

Hier wird eine HDD installation ausgeführt.

Das Script partioniert das System komplett selbständig ob verschlüsselt oder uefi. 

Es verwendet dabei den arch-graphical-install Script.

# arch-graphical-install

Damit kannst du das System komplett nach deinen willen modifizieren und verändern.

Es richtet sogar eine komplette graphische Oberfläche ein.

# Zum Starten einer VM zur Überprüfung mit Qemu

qemu-system-x86_64 -enable-kvm -cdrom out/arch-*.iso -boot d -m 8092

oder

sudo qemu-system-x86_64 -enable-kvm -cdrom out/arch-spectre-os-17.08.10-x86_64.iso -hdb /dev/sdd -boot d -m 2048M

qemu-system-x86_64 -enable-kvm -hdb /dev/sdd -m 8092

oder

qemu-img create -f qcow2 arch.img 64G

qemu-system-x86_64 -enable-kvm -cdrom out/arch-*.iso -hda arch.img -boot d -m 8092

qemu-system-x86_64 -enable-kvm -hda arch.img -m 8092

# Zugriff über VNC 5901

sudo qemu-system-x86_64 -enable-kvm -cdrom out/arch-spectre-os-17.11.02-x86_64.iso -hda arch.img -boot d -m 4G -vnc :1

# Für eine Costum-Image für Arch-Linux

wget https://raw.githubusercontent.com/simono41/Simon-OS/master/make_mksquashfs.sh

chmod +x make_mksquashfs.sh

./make_mksquashfs.sh

# rsync

rsync -P -e ssh arch-simon-os-17.05.06-x86_64.iso masters4k@frs.sourceforge.net:/home/frs/project/simon-os/

# Für eine SSH-VPN verbindung

ssh -w 0:0 1.2.3.4
