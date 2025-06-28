local k = import 'github.com/grafana/jsonnet-libs/ksonnet-util/kausal.libsonnet';

{
  local appName = 'actual',

  _config+:: {
    domain: 'budget.o5s.lol',
    port: 5006,
    version: 'latest-alpine',
  },

  _image+:: 'actualbudget/actual-server:' + $._config.version,

  // ---

  local pvc = k.core.v1.persistentVolumeClaim,

  dataPvc:
    pvc.new(appName + '-data') +
    pvc.spec.withAccessModes('ReadWriteOnce') +
    pvc.spec.withStorageClassName('local-path') +
    pvc.spec.resources.withRequests({ storage: '1Gi' }),

  // ---

  local configMap = k.core.v1.configMap,

  configMap:
    configMap.new(appName + '-config') +
    configMap.withDataMixin({
      'config.json': importstr 'config/config.json',
    }),

  // ---

  local container = k.core.v1.container,

  container::
    container.new(appName, $._image) +
    // @ref https://actualbudget.org/docs/config/
    container.withEnvMap({
      ACTUAL_PORT: std.toString($._config.port),
    }),

  local deployment = k.apps.v1.deployment,
  local volumeMount = k.core.v1.volumeMount,

  deployment:
    deployment.new(appName, 1, [$.container]) +
    k.util.pvcVolumeMount($.dataPvc.metadata.name, '/data') +
    k.util.configVolumeMount($.configMap.metadata.name, '/data/config.json', volumeMount.withSubPath('config.json')),

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
      httpRoute.spec.parentRefs.withName('nginx-gateway') +
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
