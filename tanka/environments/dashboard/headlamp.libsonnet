local fluxcd = import 'github.com/jsonnet-libs/fluxcd-libsonnet/2.5.1/main.libsonnet';
local k = import 'github.com/grafana/jsonnet-libs/ksonnet-util/kausal.libsonnet';

{
  local appName = 'headlamp',

  _config+:: {
    domain: 'k8s.o5s.lol',
  },

  // ---

  local clusterRoleBinding = k.rbac.v1.clusterRoleBinding,
  local subject = k.rbac.v1.subject,

  clusterRoleBinding:
    clusterRoleBinding.new('headlamp-admin-user') +
    clusterRoleBinding.roleRef.withKind('ClusterRole') +
    clusterRoleBinding.roleRef.withName('cluster-admin') +
    clusterRoleBinding.roleRef.withApiGroup('rbac.authorization.k8s.io') +
    clusterRoleBinding.withSubjects(
      subject.withKind('User') +
      subject.withName('leesiongchan') +
      subject.withNamespace('dashboard') +
      subject.withApiGroup('rbac.authorization.k8s.io')
    ),

  // ---

  local repository = fluxcd.source.v1.helmRepository,

  repository:
    repository.new(appName) +
    repository.spec.withUrl('https://kubernetes-sigs.github.io/headlamp') +
    repository.spec.withInterval('24h'),

  // ---

  local release = fluxcd.helm.v2.helmRelease,

  release:
    release.new(appName) +
    release.spec.chart.spec.withChart('headlamp') +
    release.spec.chart.spec.sourceRef.withKind('HelmRepository') +
    release.spec.chart.spec.sourceRef.withName('headlamp') +
    release.spec.withInterval('1h') +
    // @ref https://github.com/kubernetes-sigs/headlamp/blob/main/charts/headlamp/values.yaml
    release.spec.withValues({
      config: {
        oidc: {
          clientID: 'dd7cb89b-ea2a-41de-a336-db8b624dbc9b',
          clientSecret: 'X9kwu7FOcEHJqS4RRMkJVIdgUgjb0X9k',
          issuerURL: 'https://auth.o5s.lol',
        },
      },
    }),

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
        httpRoute.spec.rules.backendRefs.withName($.release.metadata.name) +
        httpRoute.spec.rules.backendRefs.withPort(80),
      ]),
    ]),
}
