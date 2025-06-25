local k = import 'github.com/grafana/jsonnet-libs/ksonnet-util/kausal.libsonnet';

{
  httpRouteFor(name, domain, port)::
    local gatewayApi = import 'github.com/jsonnet-libs/gateway-api-libsonnet/1.1/main.libsonnet';
    local httpRoute = gatewayApi.gateway.v1.httpRoute;

    httpRoute.new(name) +
    httpRoute.spec.withHostnames(domain) +
    httpRoute.spec.withParentRefsMixin([
      httpRoute.spec.parentRefs.withName('nginx-gateway') +
      httpRoute.spec.parentRefs.withNamespace('network'),
    ]) +
    httpRoute.spec.withRulesMixin([
      httpRoute.spec.rules.withMatchesMixin([
        httpRoute.spec.rules.matches.path.withValue('/'),
      ]) +
      httpRoute.spec.rules.withBackendRefsMixin([
        httpRoute.spec.rules.backendRefs.withName(name) +
        httpRoute.spec.rules.backendRefs.withPort(port),
      ]),
    ]),
}
