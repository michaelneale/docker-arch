FROM scratch
MAINTAINER Josh VanderLinden <codekoala@gmail.com>

ENV container docker
ADD arch-rootfs-2014.05.07.tar.xz /

CMD ["/usr/bin/init"]

# vim:ft=Dockerfile:
