local k = import 'github.com/grafana/jsonnet-libs/ksonnet-util/kausal.libsonnet';

{
  local appName = 'rtorrent',

  _config+:: {
    domain: 'rt.o5s.lol',
    port: 8080,
    version: 'latest',
  },

  _image+:: 'crazymax/rtorrent-rutorrent:' + $._config.version,

  // ---

  local pvc = k.core.v1.persistentVolumeClaim,

  dataPvc:
    pvc.new(appName + '-data') +
    pvc.spec.withAccessModes('ReadWriteOnce') +
    pvc.spec.withStorageClassName('local-path') +
    pvc.spec.resources.withRequests({ storage: '1Gi' }),

  // ---

  local container = k.core.v1.container,
  local envVar = k.core.v1.envVar,
  local httpHeader = k.core.v1.httpHeader,

  local healthCheckCommand = ['/usr/local/bin/healthcheck'],

  container::
    container.new(appName, $._image) +
    container.livenessProbe.exec.withCommand(healthCheckCommand) +
    container.readinessProbe.exec.withCommand(healthCheckCommand) +
    container.startupProbe.exec.withCommand(healthCheckCommand) +
    container.withEnvMap({
      RUTORRENT_PORT: std.toString($._config.port),
    }) +
    container.withResourcesLimits('1', '512Mi') +
    container.withResourcesRequests('100m', '256Mi'),

  gluetunContainer::
    container.new('gluetun', 'qmcgaw/gluetun:latest') +
    container.withEnvMap({
      VPN_SERVICE_PROVIDER: 'private internet access',
      // ---
      BLOCK_ADS: 'off',
      BLOCK_MALICIOUS: 'off',
      BLOCK_SURVEILLANCE: 'off',
      DOT: 'off',
    }) +
    container.withEnvMixin([
      envVar.fromSecretRef('OPENVPN_USER', 'media-secret', 'PIA__USERNAME'),
      envVar.fromSecretRef('OPENVPN_PASSWORD', 'media-secret', 'PIA__PASSWORD'),
    ]) +
    container.securityContext.capabilities.withAdd(['NET_ADMIN']),

  local deployment = k.apps.v1.deployment,

  deployment:
    deployment.new(appName, 1, [$.container, $.gluetunContainer]) +
    k.util.pvcVolumeMount($.dataPvc.metadata.name, '/data') +
    k.util.pvcVolumeMount('media-nfs', '/Media'),

  // ---

  local service = k.core.v1.service,

  service:
    k.util.serviceFor($.deployment) +
    service.spec.withPortsMixin([
      service.spec.portsType.newNamed(
        name='http',
        port=$._config.port,
        targetPort=$._config.port,
      ),
    ]),

  // ---

  local gatewayApi = import 'github.com/jsonnet-libs/gateway-api-libsonnet/1.1/main.libsonnet',
  local httpRoute = gatewayApi.gateway.v1.httpRoute,

  httpRoute:
    httpRoute.new(appName) +
    httpRoute.spec.withHostnames($._config.domain) +
    httpRoute.spec.withParentRefs([
      httpRoute.spec.parentRefs.withName('traefik-gateway') +
      httpRoute.spec.parentRefs.withNamespace('network'),
    ]) +
    httpRoute.spec.withRules([
      httpRoute.spec.rules.withMatches([
        httpRoute.spec.rules.matches.path.withValue('/'),
      ]) +
      httpRoute.spec.rules.withBackendRefs([
        httpRoute.spec.rules.backendRefs.withName($.service.metadata.name) +
        httpRoute.spec.rules.backendRefs.withPort($._config.port),
      ]),
    ]),
}
