# Oumuamua Homelab

## Bootstrapping

```bash
$ export GITHUB_TOKEN=<your-token>
$ sh ./scripts/bootstrap.sh
```

## Create secret and encrypt with sops

```bash
$ sh ./scripts/create-sops-secret.sh <secret-key> <secret-value> <secret-name> <namespace>
```

## Reset cluster

```bash
$ sh ./scripts/reset-cluster.sh
```

More info refer to k3s [cluster upkeep](https://github.com/NixOS/nixpkgs/blob/master/pkgs/applications/networking/cluster/k3s/docs/CLUSTER_UPKEEP.md) section.

## TODOs:

- oauth for weave, grafana, portainer
- suggestarr (https://github.com/giuseppe99barchetta/SuggestArr)
- Maybe (https://github.com/maybe-finance/maybe)
- Minio
- Immich
- Home Assistant
- huginn
- rocket.chat
- novu
- logseq
- changedetection
- borg
- unbound
- janitorr
- unpackerr
- Frigate 
- OpenBB
- Homarr
- tinyauth
- n8n
- backrest
- pingvin-share
- linkding
- Ghostfolio
- AFFiNE
- FreshRSS
- Infisical
- Syncthing
- readeck
- ntfy.sh
- donetick
- kubero
- Vikunja
