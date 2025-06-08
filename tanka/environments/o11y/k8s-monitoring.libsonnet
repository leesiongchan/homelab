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
    release.new('k8s-monitoring') +
    release.spec.chart.spec.withChart('k8s-monitoring') +
    release.spec.chart.spec.sourceRef.withKind('HelmRepository') +
    release.spec.chart.spec.sourceRef.withName('grafana') +
    release.spec.chart.spec.sourceRef.withNamespace('flux-system') +
    release.spec.withInterval('1h') +
    // @ref https://github.com/grafana/k8s-monitoring-helm/blob/main/charts/k8s-monitoring/values.yaml
    release.spec.withValues({
      cluster: {
        name: 'k8s-monitoring',
      },

      destinations: [{
        name: 'mimir',
        type: 'prometheus',
        url: 'http://mimir-nginx.o11y.svc.cluster.local/api/v1/push',
      }, {
        name: 'loki',
        type: 'loki',
        url: 'http://loki-gateway.o11y.svc.cluster.local/loki/api/v1/push',
      }, {
        name: 'tempo',
        type: 'otlp',
        url: 'http://tempo.o11y.svc.cluster.local:4317',
      }],

      clusterMetrics: {
        enabled: false,
      },
      clusterEvents: {
        enabled: false,
      },
      nodeLogs: {
        enabled: false,
      },
      podLogs: {
        enabled: true,
      },
      applicationObservability: {
        enabled: false,
        receivers: {
          otlp: {
            grpc: { enabled: true },
          },
        },
      },
      autoInstrumentation: {
        enabled: false,
      },


      'alloy-metrics': {
        enabled: false,
      },
      'alloy-singleton': {
        enabled: true,
      },
      'alloy-logs': {
        enabled: true,
      },
      'alloy-receiver': {
        enabled: false,
        alloy: {
          extraPorts: [{
            name: 'otlp-grpc',
            port: 4317,
            protocol: 'TCP',
            targetPort: 4317,
          }],
        },
      },
    }),
}
