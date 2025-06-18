local fluxcd = import 'github.com/jsonnet-libs/fluxcd-libsonnet/2.5.1/main.libsonnet';

local repository = import './repository.libsonnet';

{
  local appName = 'tempo',

  // ---

  local release = fluxcd.helm.v2.helmRelease,

  release:
    release.new(appName) +
    release.spec.chart.spec.withChart('tempo') +
    release.spec.chart.spec.sourceRef.withKind('HelmRepository') +
    release.spec.chart.spec.sourceRef.withName(repository.grafana.metadata.name) +
    release.spec.withInterval('1h') +
    // @ref https://github.com/grafana/helm-charts/blob/main/charts/tempo/values.yaml
    release.spec.withValues({
      tempo: {
        reportingEnabled: false,
        metricsGenerator: {
          enabled: true,
          remoteWriteUrl: 'http://mimir-nginx.o11y.svc.cluster.local/api/v1/push',
        },
        storage: {
          trace: {
            backend: 's3',
            s3: {
              bucket: 'tempo',
              endpoint: 'minio.storage.svc.cluster.local',
              access_key: 'minio',
              secret_key: 'minio123',
              tls_insecure_skip_verify: true,
            },
          },
        },
      },
    }),
}
