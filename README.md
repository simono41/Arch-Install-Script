# Finale Release am 27.03.17

URL : https://sourceforge.net/projects/simon-os/?source=directory

# WICHTIG

ZUGANGSDATEN : root = root
               user = user
               
Installieren auf Festplatte: "arch-install" in einem Terminal eingeben

Starten der Grafischen Oberfläche "startx" eingeben

# Arch-Install-Script
Scripte für das installieren von Arch Linux auf PC und PI

wget https://raw.githubusercontent.com/simono41/Simon-OS/master/arch-install

chmod +x arch-install

./arch-install

# Zum Starten einer VM zur Überprüfung mit Qemu

qemu-system-x86_64 -enable-kvm -cdrom out/arch-*.iso -boot d -m 8092

oder

sudo qemu-system-x86_64 -enable-kvm -cdrom out/arch-spectre-os-17.08.10-x86_64.iso -hdb /dev/sdd -boot d -m 2048M

qemu-system-x86_64 -enable-kvm -hdb /dev/sdd -m 8092

oder

qemu-img create -f qcow2 arch.img 64G

qemu-system-x86_64 -enable-kvm -cdrom out/arch-*.iso -hda arch.img -boot d -m 8092

qemu-system-x86_64 -enable-kvm -hda arch.img -m 8092

# Für eine Costum-Image für Arch-Linux

wget https://raw.githubusercontent.com/simono41/Simon-OS/master/make_mksquashfs.sh

chmod +x make_mksquashfs.sh

./make_mksquashfs.sh

# rsync

rsync -P -e ssh arch-simon-os-17.05.06-x86_64.iso masters4k@frs.sourceforge.net:/home/frs/project/simon-os/
