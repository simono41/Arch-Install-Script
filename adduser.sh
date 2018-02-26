!/bin/bash
#
set -ex

if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root" 1>&2
    sudo $0
    exit 0
fi
echo "Als root Angemeldet"
#
function adduser() {
    useradd -m -g users -G wheel,audio,video,sys,optical -s /bin/bash $username
    passwd ${username} <<EOT
${userpass}
${userpass}
EOT
    mkdir -p /home/"$username"/
    userrechte
}

function copyconfig() {
    cp -aRv /root/. /home/"$username"/
    #links
    userrechte
}

function userrechte() {
    #user
    chown -cR -v "$username":users /home/"$username"
    chmod 750 -Rv /home/"$username"
    #ssh
    chmod 755 /home/"$username"/
    if [ -d /home/"$username"/.ssh ]; then
        chmod 700 /home/"$username"/.ssh
    fi
    if [ -f /home/"$username"/.ssh/id_rsa ]; then
        chmod 600 /home/"$username"/.ssh/id_rsa
    fi
    if [ -f /home/"$username"/.ssh/authorized_keys ]; then
        chmod 600 /home/"$username"/.ssh/authorized_keys
    fi
   
    #root
    chmod 750 -Rv /root
    #ssh-root
    chmod 755 /root/
    if [ -d /root/.ssh ]; then
        chmod 700 /root/.ssh
    fi
    if [ -f /root/.ssh/id_rsa ]; then
        chmod 600 /root/.ssh/id_rsa
    fi
    if [ -f /root/.ssh/authorized_key ]; then
        chmod 600 /root/.ssh/authorized_keys
    fi

}

username="$1"
userpass="$2"
adduser
copyconfig

echo "Fertig!!!"
