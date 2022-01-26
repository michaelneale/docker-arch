ArchLinux Container

[![Git](https://app.soluble.cloud/api/v1/public/badges/a8ce8ae9-b5b5-4b33-893e-50990ed74e48.svg?orgId=451115019187)](https://app.soluble.cloud/repos/details/github.com/michaelneale/docker-arch?orgId=451115019187)  
===================

Docker build for a basic Arch Linux image with sudo and my custom repository
(http://instarch.codekoala.com/). I update the container regularly.

systemd
-------

It's possible to use systemd with this container if you enable services in your
Dockerfile and run your container with something like:

    docker run --privileged -v /sys/fs/cgroup:/sys/fs/cgroup:ro codekoala/arch
