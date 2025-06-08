local k = import 'ksonnet-util/kausal.libsonnet';

{
  _config+:: {
    domain: 'auth.o5s.lol',
    port: 80,
    version: 'latest',
  },

  _image+:: 'ghcr.io/pocket-id/pocket-id:' + $._config.version,

  // ---

  local pvc = k.core.v1.persistentVolumeClaim,

  dataPvc:
    pvc.new('pocket-id-data') +
    pvc.spec.withAccessModes('ReadWriteOnce') +
    pvc.spec.withStorageClassName('local-path') +
    pvc.spec.resources.withRequests({ storage: '1Gi' }),

  // ---

  local container = k.core.v1.container,

  container::
    container.new('pocket-id', $._image) +
    container.livenessProbe.withInitialDelaySeconds(60) +
    container.livenessProbe.httpGet.withPath('/health') +
    container.livenessProbe.httpGet.withPort($._config.port) +
    container.readinessProbe.withInitialDelaySeconds(60) +
    container.readinessProbe.httpGet.withPath('/health') +
    container.readinessProbe.httpGet.withPort($._config.port) +
    // @ref https://pocket-id.org/docs/configuration/environment-variables
    container.withEnvMap({
      PUBLIC_APP_URL: 'https://' + $._config.domain,
      TRUST_PROXY: 'false',
      PUID: '1000',
      PGID: '1000',
    }) +
    container.withResourcesLimits('1', '128Mi') +
    container.withResourcesRequests('10m', '64Mi') +
    container.securityContext.withRunAsUser(1000) +
    container.securityContext.withRunAsGroup(1000),

  local deployment = k.apps.v1.deployment,

  deployment:
    deployment.new('pocket-id', 1, [$.container]) +
    k.util.pvcVolumeMount($.dataPvc.metadata.name, '/app/backend/data'),

  // ---

  local service = k.core.v1.service,

  service:
    k.util.serviceFor($.deployment) +
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
    httpRoute.new('pocket-id') +
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
