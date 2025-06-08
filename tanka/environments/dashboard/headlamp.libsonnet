local fluxcd = import 'github.com/jsonnet-libs/fluxcd-libsonnet/2.5.1/main.libsonnet';
local k = import 'ksonnet-util/kausal.libsonnet';

{
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
      subject.withKind('Group') +
      subject.withName('harflix') +
      subject.withNamespace('dashboard') +
      subject.withApiGroup('rbac.authorization.k8s.io')
    ),

  // ---

  local repository = fluxcd.source.v1.helmRepository,

  repository:
    repository.new('headlamp') +
    repository.spec.withUrl('https://kubernetes-sigs.github.io/headlamp') +
    repository.spec.withInterval('24h'),

  // ---

  local release = fluxcd.helm.v2.helmRelease,

  release:
    release.new('headlamp') +
    release.spec.chart.spec.withChart('headlamp') +
    release.spec.chart.spec.sourceRef.withKind('HelmRepository') +
    release.spec.chart.spec.sourceRef.withName('headlamp') +
    release.spec.withInterval('1h') +
    // @ref https://github.com/kubernetes-sigs/headlamp/blob/main/charts/headlamp/values.yaml
    release.spec.withValues({
      config: {
        oidc: {
          clientID: '35626ae4-0a0d-420a-8739-263c6c77784f',
          clientSecret: 'vD8Ev7Mh8CfULOInDcnp6hZHKjH0e3WJ',
          issuerURL: 'https://auth.o5s.lol',
          scopes: 'email,profile,groups',
        },
      },
    }),

  // ---

  local gatewayApi = import 'github.com/jsonnet-libs/gateway-api-libsonnet/1.1/main.libsonnet',
  local httpRoute = gatewayApi.gateway.v1.httpRoute,

  httpRoute:
    httpRoute.new('headlamp') +
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
