local k = import 'ksonnet-util/kausal.libsonnet';

{
  _config+:: {
    domain: 'memos.o5s.lol',
    port: 5230,
    version: 'stable',
  },

  _image+:: 'neosmemo/memos:' + $._config.version,

  // ---

  local container = k.core.v1.container,

  container::
    container.new('memos', $._image) +
    // @ref https://www.usememos.com/docs/install/runtime-options
    container.withEnvMap({
      MEMOS_PORT: std.toString($._config.port),
    }),

  local deployment = k.apps.v1.deployment,

  deployment:
    deployment.new('memos', 1, [$.container]),

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
    httpRoute.new('memos') +
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
