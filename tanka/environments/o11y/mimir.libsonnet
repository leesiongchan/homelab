local fluxcd = import 'github.com/jsonnet-libs/fluxcd-libsonnet/2.5.1/main.libsonnet';

local repository = import './repository.libsonnet';

{
  local appName = 'mimir',

  // ---

  local release = fluxcd.helm.v2.helmRelease,

  release:
    release.new(appName) +
    release.spec.chart.spec.withChart('mimir-distributed') +
    release.spec.chart.spec.sourceRef.withKind('HelmRepository') +
    release.spec.chart.spec.sourceRef.withName(repository.grafana.metadata.name) +
    release.spec.withInterval('1h') +
    release.spec.withValues(std.parseYaml(importstr 'configs/mimir-values.yaml')),
}
