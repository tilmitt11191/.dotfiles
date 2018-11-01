#!/usr/bin/env bash

echo "$0 is incomplete code. skip with exit 1."
exit 1
#http://ubuntuhandbook.org/index.php/2018/05/add-hibernate-option-ubuntu-18-04/


: <<'#__CO__'
INITIALDIR=`sudo pwd`
cd `dirname $0`

TARGETDIR=/etc/polkit-1/localauthority/10-vendor.d/
sudo mkdir -p $TARGETDIR

echo "[Enable hibernate by default in upower]
Identity=unix-user:*
Action=org.freedesktop.upower.hibernate
ResultActive=yes

[Enable hibernate by default in logind]
Identity=unix-user:*
Action=org.freedesktop.login1.hibernate;org.freedesktop.login1.handle-hibernate-key;org.freedesktop.login1;org.freedesktop.login1.hibernate-multiple-sessions;org.freedesktop.login1.hibernate-ignore-inhibit
ResultActive=yes" | sudo tee -a /etc/polkit-1/localauthority/10-vendor.d/com.ubuntu.desktop.pkla 2>&1 >/dev/null

#https://ask.fedoraproject.org/en/question/93769/fedora-24-hibernation-error-sleep-verb-not-supported/
sudo sed -i -e 's|^\(GRUB_DISABLE_RECOVERY="\)true"|\1false"|' /etc/default/grub
SWAPDEVICE=`grep -e '^[^#].*swap' /etc/fstab | head -n 1 | cut -d ' ' -f 1`
sudo echo "Using SWAPDEVICE=${SWAPDEVICE} for hibernation"
sudo sed -i -e "s|^\(GRUB_CMDLINE_LINUX=\".*\)\"|\1 resume=${SWAPDEVICE}\"|" /etc/default/grub
sudo update-grub


cd $INITIALDIR
true

#__CO__
