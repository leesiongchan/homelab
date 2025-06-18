local k = import 'github.com/grafana/jsonnet-libs/ksonnet-util/kausal.libsonnet';

{
  local appName = 'memos',

  _config+:: {
    domain: 'memos.o5s.lol',
    port: 5230,
    version: 'stable',
  },

  _image+:: 'neosmemo/memos:' + $._config.version,

  // ---

  local pvc = k.core.v1.persistentVolumeClaim,

  dataPvc:
    pvc.new(appName + '-data') +
    pvc.spec.withAccessModes('ReadWriteOnce') +
    pvc.spec.withStorageClassName('local-path') +
    pvc.spec.resources.withRequests({ storage: '1Gi' }),

  // ---

  local container = k.core.v1.container,

  container::
    container.new(appName, $._image) +
    container.livenessProbe.withInitialDelaySeconds(5) +
    container.livenessProbe.httpGet.withPath('/healthz') +
    container.livenessProbe.httpGet.withPort($._config.port) +
    container.readinessProbe.withInitialDelaySeconds(5) +
    container.readinessProbe.httpGet.withPath('/healthz') +
    container.readinessProbe.httpGet.withPort($._config.port) +
    // @ref https://www.usememos.com/docs/install/runtime-options
    container.withEnvMap({
      MEMOS_PORT: std.toString($._config.port),
    }),

  local deployment = k.apps.v1.deployment,

  deployment:
    deployment.new(appName, 1, [$.container]) +
    k.util.pvcVolumeMount($.dataPvc.metadata.name, '/var/opt/memos'),

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
