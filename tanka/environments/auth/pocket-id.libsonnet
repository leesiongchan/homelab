local k = import 'github.com/grafana/jsonnet-libs/ksonnet-util/kausal.libsonnet';

{
  local appName = 'pocket-id',

  _config+:: {
    domain: 'auth.o5s.lol',
    port: 1411,
    version: 'v1',
  },

  _image+:: 'ghcr.io/pocket-id/pocket-id:' + $._config.version,

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
    container.livenessProbe.withInitialDelaySeconds(10) +
    container.livenessProbe.httpGet.withPath('/healthz') +
    container.livenessProbe.httpGet.withPort($._config.port) +
    container.readinessProbe.withInitialDelaySeconds(10) +
    container.readinessProbe.httpGet.withPath('/healthz') +
    container.readinessProbe.httpGet.withPort($._config.port) +
    // @ref https://pocket-id.org/docs/configuration/environment-variables
    container.withEnvMap({
      ANALYTICS_DISABLED: 'true',
      APP_URL: 'https://auth.harflix.lol',
      PGID: '1000',
      PUID: '1000',
      TRUST_PROXY: 'true',
    }) +
    container.withResourcesLimits('1', '128Mi') +
    container.withResourcesRequests('10m', '64Mi') +
    container.securityContext.withRunAsUser(1000) +
    container.securityContext.withRunAsGroup(1000),

  local statefulSet = k.apps.v1.statefulSet,

  statefulSet:
    statefulSet.new(appName, 1, [$.container]) +
    statefulSet.spec.withVolumeClaimTemplates([$.dataPvc]) +
    k.util.pvcVolumeMount($.dataPvc.metadata.name, '/app/data'),

  // ---

  local service = k.core.v1.service,

  service:
    k.util.serviceFor($.statefulSet) +
    service.mixin.spec.withPortsMixin([
      service.mixin.spec.portsType.newNamed(
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
