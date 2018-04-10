# DOWNLOAD-LINK

URL : https://c.1und1.de/@546352221680304673/RNoFs7J8Rxqvse4P_XNESg

URL : https://1drv.ms/f/s!ApyxE0hJ28jihRKRWEe1mmbHD4F9

# Spectre-OS

Spectre-OS ist ein Betriebssytem geschrieben von Simon Rieger.

Es benutzt den Arch-Linux-Kernel als grundbasis.

Ein Betriebssystem ist eine Menge von grundlegenden Programmen, die Ihr Rechner zum Arbeiten benötigt.

Der wichtigste Teil eines Betriebssystems ist der Kernel. Der Kernel ist das Programm, das für alle Basisaufgaben und das Starten von anderen Programmen zuständig ist.

# WICHTIG BEFEHLE

ZUGANGSDATEN : root = root
               user1 = user1
               
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

sudo qemu-system-x86_64 -enable-kvm -cdrom out/arch-*.iso -hdb /dev/sdd -boot d -m 2048M

qemu-system-x86_64 -enable-kvm -hdb /dev/sdd -m 8092

oder

qemu-img create -f qcow2 arch.img 64G

qemu-system-x86_64 -enable-kvm -cdrom out/arch-*.iso -hda arch.img -boot d -m 8092

qemu-system-x86_64 -enable-kvm -hda arch.img -m 8092

# Zugriff über VNC 5901

sudo qemu-system-x86_64 -enable-kvm -cdrom out/arch-*.iso -hda arch.img -boot d -m 4G -vnc :1

# rsync

rsync -P -e ssh out/arch-*.iso masters4k@frs.sourceforge.net:/home/frs/project/SpectreOS/

# Für eine SSH-VPN verbindung

ssh -w 0:0 1.2.3.4
