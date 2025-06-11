local k = import 'ksonnet-util/kausal.libsonnet';

{
  local appName = 'synology',

  _config+:: {
    domain: 'nas.o5s.lol',
    ip: '192.168.0.200',
    port: 5000,
  },

  // ---

  local endpoints = k.core.v1.endpoints,
  local endpointSubset = k.core.v1.endpointSubset,
  local endpointAddress = k.core.v1.endpointAddress,
  local endpointPort = k.core.v1.endpointPort,

  endpoints:
    endpoints.new(appName) +
    endpoints.withSubsets([
      endpointSubset.withAddresses([
        endpointAddress.withIp($._config.ip),
      ]) + endpointSubset.withPorts([
        endpointPort.withPort($._config.port),
      ]),
    ]),

  // ---

  local service = k.core.v1.service,

  service:
    service.new(appName, { name: $.endpoints.metadata.name }, [
      service.spec.portsType.newNamed(
        name='http',
        port=$._config.port,
        targetPort=$._config.port,
      ),
    ]) +
    service.metadata.withLabels({ name: $.endpoints.metadata.name }),

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
