#!/usr/bin/env bash
# Generate a minimal filesystem for archlinux (requires root)

set -e

hash pacstrap &>/dev/null || {
    echo "Could not find pacstrap. Run pacman -S arch-install-scripts"
    exit 1
}

hash expect &>/dev/null || {
    echo "Could not find expect. Run pacman -S expect"
    exit 1
}

DATE=$1

echo Building Arch Linux container for ${DATE}...

ROOTFS=$(mktemp -d /tmp/rootfs-archlinux-XXXXXXXXXX)
chmod 755 $ROOTFS

# packages to ignore for space savings
PKGIGNORE=linux,jfsutils,lvm2,groff,man-db,man-pages,mdadm,pciutils,pcmciautils,reiserfsprogs,s-nail,xfsprogs

expect <<EOF
  set timeout 60
  set send_slow {1 1}
  spawn pacstrap -C ./mkimage-arch-pacman.conf -c -d -G -i $ROOTFS base sudo haveged --ignore $PKGIGNORE
  expect {
    "Install anyway?" { send n\r; exp_continue }
    "(default=all)" { send \r; exp_continue }
    "Proceed with installation?" { send "\r"; exp_continue }
    "skip the above package" {send "y\r"; exp_continue }
    "checking" { exp_continue }
    "loading" { exp_continue }
    "installing" { exp_continue }
  }
EOF

arch-chroot $ROOTFS /bin/sh -c "haveged -w 1024; pacman-key --init; pkill haveged; pacman -Rs --noconfirm haveged; pacman-key --populate archlinux"
arch-chroot $ROOTFS /bin/sh -c "ln -s /usr/share/zoneinfo/UTC /etc/localtime"
echo 'en_US.UTF-8 UTF-8' > $ROOTFS/etc/locale.gen
arch-chroot $ROOTFS locale-gen
arch-chroot $ROOTFS /bin/sh -c 'echo "Server = https://mirrors.kernel.org/archlinux/\$repo/os/\$arch" > /etc/pacman.d/mirrorlist'

# clean up downloaded packages
rm -rf $ROOTFS/var/cache/pacman/pkg/*

# udev doesn't work in containers, rebuild /dev
DEV=$ROOTFS/dev
rm -rf $DEV
mkdir -p $DEV
mknod -m 666 $DEV/null c 1 3
mknod -m 666 $DEV/zero c 1 5
mknod -m 666 $DEV/random c 1 8
mknod -m 666 $DEV/urandom c 1 9
mkdir -m 755 $DEV/pts
mkdir -m 1777 $DEV/shm
mknod -m 666 $DEV/tty c 5 0
mknod -m 600 $DEV/console c 5 1
mknod -m 666 $DEV/tty0 c 4 0
mknod -m 666 $DEV/full c 1 7
mknod -m 600 $DEV/initctl p
mknod -m 666 $DEV/ptmx c 5 2
ln -sf /proc/self/fd $DEV/fd

# make systemd a bit happier (disable everything except journald)
find $ROOTFS -type l -iwholename "*.wants*" -delete
SYSD=/usr/lib/systemd/system
ln -sf $SYSD/systemd-journald.socket $SYSD/sockets.target.wants/
ln -sf $SYSD/systemd-journald.service $SYSD/sysinit.target.wants/

echo "Compressing filesystem..."
UNTEST=arch-rootfs-untested.tar.xz
tar --xz -f $UNTEST --numeric-owner -C $ROOTFS -c .
rm -rf $ROOTFS

echo "Testing filesystem..."
cat $UNTEST | docker import - archtest:${DATE}
docker run -ti --rm archtest:${DATE} echo Success.

echo "Approving filesystem..."
mv $UNTEST arch-rootfs-${DATE}.tar.xz
