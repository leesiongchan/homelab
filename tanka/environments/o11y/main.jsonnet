{
  repository: import 'repository.libsonnet',

  // ---

  grafana: import 'grafana.libsonnet',
  k8sMonitoring: import 'k8s-monitoring.libsonnet',
  loki: import 'loki.libsonnet',
  mimir: import 'mimir.libsonnet',
  tempo: import 'tempo.libsonnet',
}
