local k = import 'ksonnet-util/kausal.libsonnet';

{
  local appName = 'glance',

  _config+:: {
    domain: 'o5s.lol',
    port: 8080,
    version: 'latest',
  },

  _image+:: 'glanceapp/glance:' + $._config.version,

  local configMap = k.core.v1.configMap,

  configMap:
    configMap.new(appName + '-config') +
    configMap.withDataMixin({
      'glance.yml': importstr 'configs/glance.glance.yml',
    }),

  // ---

  local container = k.core.v1.container,

  container::
    container.new(appName, $._image),

  local deployment = k.apps.v1.deployment,
  local volumeMount = k.core.v1.volumeMount,

  deployment:
    deployment.new(appName, 1, [$.container]) +
    k.util.configVolumeMount($.configMap.metadata.name, '/app/config/glance.yml', volumeMount.withSubPath('glance.yml')),

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
