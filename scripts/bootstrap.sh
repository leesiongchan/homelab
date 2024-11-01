#!/bin/sh

set -eux

nix shell nixpkgs#ssh-to-age --command ssh-to-age -private-key -i $HOME/.ssh/id_ed25519 > age.agekey \
    && kubectl create namespace flux-system \
    && kubectl create secret generic sops-age \
        --namespace=flux-system \
        --from-file=age.agekey \
    && rm age.agekey

flux bootstrap github \
    --owner=leesiongchan \
    --repository=homelab \
    --branch=main \
    --path=./cluster \
    --personal
