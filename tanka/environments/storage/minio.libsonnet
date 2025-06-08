local fluxcd = import 'github.com/jsonnet-libs/fluxcd-libsonnet/2.5.1/main.libsonnet';

{
  local repository = fluxcd.source.v1.helmRepository,

  repository:
    repository.new('minio-operator') +
    repository.spec.withUrl('https://operator.min.io') +
    repository.spec.withInterval('24h'),

  // ---

  local release = fluxcd.helm.v2.helmRelease,

  operatorRelease:
    release.new('minio-operator') +
    release.spec.chart.spec.withChart('operator') +
    release.spec.chart.spec.sourceRef.withKind($.repository.kind) +
    release.spec.chart.spec.sourceRef.withName($.repository.metadata.name) +
    release.spec.withInterval('1h') +
    // @ref https://github.com/minio/operator/blob/master/helm/operator/values.yaml
    release.spec.withValues({
    }),

  tenantRelease:
    release.new('minio-tenant') +
    release.spec.chart.spec.withChart('tenant') +
    release.spec.chart.spec.sourceRef.withKind($.repository.kind) +
    release.spec.chart.spec.sourceRef.withName($.repository.metadata.name) +
    release.spec.withInterval('1h') +
    // @ref https://github.com/minio/operator/blob/master/helm/tenant/values.yaml
    release.spec.withValues({
      tenant: {
        name: 'minio',
        env: [{
          name: 'MINIO_BROWSER_REDIRECT_URL',
          value: 'https://minio.o5s.lol',
        }],
        pools: [{
          name: 'pool-0',
          servers: 1,
          size: '2Gi',
          volumesPerServer: 2,
        }],
      },
    }),
}
