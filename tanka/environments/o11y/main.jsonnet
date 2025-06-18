local k = import 'github.com/grafana/jsonnet-libs/ksonnet-util/kausal.libsonnet';

(import './repository.libsonnet') +
{
  namespace: k.core.v1.namespace.new('o11y'),

  // ---

  grafana: import 'grafana.libsonnet',
  k8sMonitoring: import 'k8s-monitoring.libsonnet',
  loki: import 'loki.libsonnet',
  mimir: import 'mimir.libsonnet',
  tempo: import 'tempo.libsonnet',
}
