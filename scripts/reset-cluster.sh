#!/bin/sh

set -eux

sh /run/current-system/sw/bin/k3s-killall.sh

sudo rm -rf /etc/rancher/{k3s,node}
sudo rm -rf /var/lib/{rancher/k3s,kubelet,longhorn,etcd,cni}

sudo nixos-rebuild switch --flake ~/.config/nixos
