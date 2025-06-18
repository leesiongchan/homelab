local fluxcd = import 'github.com/jsonnet-libs/fluxcd-libsonnet/2.5.1/main.libsonnet';

local repository = import './repository.libsonnet';

{
  local appName = 'k8s-monitoring',

  // ---

  local release = fluxcd.helm.v2.helmRelease,

  release:
    release.new(appName) +
    release.spec.chart.spec.withChart('k8s-monitoring') +
    release.spec.chart.spec.sourceRef.withKind('HelmRepository') +
    release.spec.chart.spec.sourceRef.withName(repository.grafana.metadata.name) +
    release.spec.withInterval('1h') +
    // @ref https://github.com/grafana/k8s-monitoring-helm/blob/main/charts/k8s-monitoring/values.yaml
    release.spec.withValues({
      cluster: {
        name: appName,
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
        logs: { enabled: false },
        metrics: { enabled: false },
        traces: { enabled: true },
      }],

      clusterMetrics: {
        enabled: true,
        controlPlane: {
          enabled: true,
        },
        'node-exporter': {
          enabled: true,
          extraDiscoveryRules: std.toString({
            rule: {
              source_labels: ['__meta_kubernetes_node_name'],
              action: 'replace',
              target_label: 'nodename',
            },
          }),
        },
        'windows-exporter': {
          enabled: false,
        },
      },
      clusterEvents: {
        enabled: true,
      },
      nodeLogs: {
        enabled: true,
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
        enabled: true,
      },
      'alloy-singleton': {
        enabled: true,
      },
      'alloy-logs': {
        enabled: true,
        // Required when using the Kubernetes API to pod logs
        alloy: {
          mounts: {
            varlog: false,
          },
          clustering: {
            enabled: true,
          },
        },
      },
      'alloy-receiver': {
        enabled: true,
        alloy: {
          extraPorts: [{
            name: 'otlp-grpc',
            port: 4317,
            protocol: 'TCP',
            targetPort: 4317,
          }, {
            name: 'otlp-http',
            port: 4318,
            protocol: 'TCP',
            targetPort: 4318,
          }],
        },
      },
      'alloy-profiles': {
        enabled: false,
      },
    }),
}
