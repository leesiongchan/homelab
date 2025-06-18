local fluxcd = import 'github.com/jsonnet-libs/fluxcd-libsonnet/2.5.1/main.libsonnet';
local repository = fluxcd.source.v1.helmRepository;

{
  grafana:
    repository.new('grafana') +
    repository.spec.withUrl('https://grafana.github.io/helm-charts') +
    repository.spec.withInterval('24h'),
}
