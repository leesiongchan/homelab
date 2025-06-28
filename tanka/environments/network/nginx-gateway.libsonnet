local fluxcd = import 'github.com/jsonnet-libs/fluxcd-libsonnet/2.5.1/main.libsonnet';

local repository = import './repository.libsonnet';

{
  local appName = 'nginx-gateway',

  // ---

  local release = fluxcd.helm.v2.helmRelease,

  release:
    release.new(appName) +
    release.spec.chart.spec.withChart('nginx-gateway-fabric') +
    release.spec.chart.spec.sourceRef.withKind('HelmRepository') +
    release.spec.chart.spec.sourceRef.withName(repository.ngf.metadata.name) +
    release.spec.withInterval('1h') +
    release.spec.withValues({
    }),

  // ---

  local gatewayApi = import 'github.com/jsonnet-libs/gateway-api-libsonnet/1.1/main.libsonnet',
  local gateway = gatewayApi.gateway.v1.gateway,

  local httpsListener =
    gateway.spec.listeners.withPort(443) +
    gateway.spec.listeners.withProtocol('HTTPS') +
    gateway.spec.listeners.allowedRoutes.namespaces.withFrom('All') +
    gateway.spec.listeners.tls.withMode('Terminate') +
    gateway.spec.listeners.tls.withCertificateRefs([
      gateway.spec.listeners.tls.certificateRefs.withName('o5s-lol-ca'),
    ]),

  gateway:
    gateway.new(appName) +
    gateway.metadata.withAnnotations({
      'cert-manager.io/cluster-issuer': 'o5s-issuer',
    }) +
    gateway.spec.withGatewayClassName('nginx') +
    gateway.spec.withListeners([
      httpsListener +
      gateway.spec.listeners.withName('https-root') +
      gateway.spec.listeners.withHostname('o5s.lol'),
      httpsListener +
      gateway.spec.listeners.withName('https') +
      gateway.spec.listeners.withHostname('*.o5s.lol'),
    ]),
}
