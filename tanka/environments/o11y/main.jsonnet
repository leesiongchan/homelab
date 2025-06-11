local k = import 'ksonnet-util/kausal.libsonnet';

{
  namespace: k.core.v1.namespace.new('o11y'),

  // ---

  grafana: import 'grafana.libsonnet',
  k8sMonitoring: import 'k8s-monitoring.libsonnet',
  loki: import 'loki.libsonnet',
  mimir: import 'mimir.libsonnet',
  tempo: import 'tempo.libsonnet',
}
