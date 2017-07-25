if [ "make" == "$1" ]; then

echo `date "+%Y%m%d-%H%M%S"` > /run/btrfs-root/__current/ROOT/SNAPSHOT
echo "Fresh install" >> /run/btrfs-root/__current/ROOT/SNAPSHOT

btrfs subvolume snapshot -r /run/btrfs-root/__current/ROOT
                            /run/btrfs-root/__snapshot/ROOT@`head -n 1 /run/btrfs-root/__current/ROOT/SNAPSHOT`

rm /run/btrfs-root/__current/ROOT/SNAPSHOT

fi

if [ "restore" == "$1" ]; then

echo "Heutiges datum $(date "+%Y%m%d-%H%M%S")"
ls /run/btrfs-root/__snapshot
read -p "Welches datum hat das Image? : " datum

mv /run/btrfs-root/__current/ROOT /run/btrfs-root/__current/ROOT.old
btrfs subvolume snapshot /run/btrfs-root/__snapshot/ROOT@${datum} /run/btrfs-root/__current/ROOT
reboot

fi
