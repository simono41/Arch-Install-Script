echo `date "+%Y%m%d-%H%M%S"` > /run/btrfs-root/__current/ROOT/SNAPSHOT
echo "Fresh install" >> /run/btrfs-root/__current/ROOT/SNAPSHOT

btrfs subvolume snapshot -r /run/btrfs-root/__current/ROOT
                            /run/btrfs-root/__snapshot/ROOT@`head -n 1 /run/btrfs-root/__current/ROOT/SNAPSHOT`

rm /run/btrfs-root/__current/ROOT/SNAPSHOT


mv /run/btrfs-root/__current/ROOT /run/btrfs-root/__current/ROOT.old
btrfs subvolume snapshot /run/btrf-root/__snapshot/ROOT@20121227-163413 /run/btrfs-root/__current/ROOT
reboot
