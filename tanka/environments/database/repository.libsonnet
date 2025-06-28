local fluxcd = import 'github.com/jsonnet-libs/fluxcd-libsonnet/2.5.1/main.libsonnet';
local repository = fluxcd.source.v1.helmRepository;

{
  dragonfly:
    repository.new('dragonfly') +
    repository.spec.withUrl('oci://ghcr.io/dragonflydb/dragonfly/helm') +
    repository.spec.withType('oci') +
    repository.spec.withInterval('24h'),
}
