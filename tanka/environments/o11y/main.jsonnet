local grafana = import 'grafana.libsonnet';
local k8sMonitoring = import 'k8s-monitoring.libsonnet';
local loki = import 'loki.libsonnet';
local mimir = import 'mimir.libsonnet';
local tempo = import 'tempo.libsonnet';

{
  grafana: grafana,
  k8sMonitoring: k8sMonitoring,
  loki: loki,
  mimir: mimir,
  tempo: tempo,
}
