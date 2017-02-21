# Arch-Install-Script
Scripte für das installieren von Arch Linux auf PC und PI

wget https://raw.githubusercontent.com/simono41/Arch-Install-Script/master/arch-install

chmod +x arch-install

./arch-install

# Zum Starten einer VM zur Überprüfung mit Qemu

qemu-system-x86_64 -enable-kvm -cdrom out/arch-*.iso -boot d -m 4096

oder

qemu-system-x86_64 -enable-kvm -hdb /dev/sdd -m 4096

oder

qemu-img create -f qcow2 arch.img 16G

qemu-system-x86_64 -enable-kvm -cdrom out/arch-*.iso -hda arch.img -boot d -m 4096

qemu-system-x86_64 -enable-kvm -hda arch.img -m 4096

# Für eine Costum-Image für Arch-Linux

wget https://raw.githubusercontent.com/simono41/Arch-Install-Script/master/make_mksquashfs.sh

chmod +x make_mksquashfs.sh

./make_mksquashfs.sh
