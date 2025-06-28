local k = import 'github.com/grafana/jsonnet-libs/ksonnet-util/kausal.libsonnet';
local fluxcd = import 'github.com/jsonnet-libs/fluxcd-libsonnet/2.5.1/main.libsonnet';

{
  local appName = 'dragonfly',

  // ---

  local secret = k.core.v1.secret,

  authSecret:
    secret.new('%s-auth' % appName, {}) +
    secret.withStringData({
      password: 'dragonfly',
    }),

  // ---

  repository: (import './repository.libsonnet'),

  local release = fluxcd.helm.v2.helmRelease,

  release:
    release.new(appName) +
    release.spec.chart.spec.withChart('dragonfly') +
    release.spec.chart.spec.withVersion('v1.31.0') +
    release.spec.chart.spec.sourceRef.withKind('HelmRepository') +
    release.spec.chart.spec.sourceRef.withName($.repository.dragonfly.metadata.name) +
    release.spec.withInterval('1h') +
    release.spec.withValues(std.parseYaml(importstr 'helm-values.yml')),
}
