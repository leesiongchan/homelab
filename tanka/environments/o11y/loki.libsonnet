local fluxcd = import 'github.com/jsonnet-libs/fluxcd-libsonnet/2.5.1/main.libsonnet';

{
  //   local repository = fluxcd.source.v1.helmRepository,

  //   repository:
  //     repository.new('minio-operator') +
  //     repository.spec.withUrl('https://operator.min.io') +
  //     repository.spec.withInterval('24h'),

  // ---

  local release = fluxcd.helm.v2.helmRelease,

  release:
    release.new('loki') +
    release.spec.chart.spec.withChart('loki') +
    release.spec.chart.spec.sourceRef.withKind('HelmRepository') +
    release.spec.chart.spec.sourceRef.withName('grafana') +
    release.spec.chart.spec.sourceRef.withNamespace('flux-system') +
    release.spec.withInterval('1h') +
    release.spec.withValues(std.parseYaml(importstr './configs/loki-values.yaml')),
}
