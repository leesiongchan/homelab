local fluxcd = import 'github.com/jsonnet-libs/fluxcd-libsonnet/2.5.1/main.libsonnet';
local k = import 'ksonnet-util/kausal.libsonnet';

{
  _config+:: {
    domain: 'o11y.o5s.lol',
  },

  // ---

  local secret = k.core.v1.secret,

  genericOauthSecret:
    secret.new('grafana-generic-oauth', {}) +
    secret.withStringData({
      client_id: '5cd3a2a4-fd53-46b0-bb7a-f5bbaa4d5814',
      client_secret: 'vbVltlNMp0VVbiVh6QnlYPTLiumqwEbv',
    }),

  // ---

  //   local repository = fluxcd.source.v1.helmRepository,

  //   repository:
  //     repository.new('minio-operator') +
  //     repository.spec.withUrl('https://operator.min.io') +
  //     repository.spec.withInterval('24h'),

  // ---

  local release = fluxcd.helm.v2.helmRelease,

  release:
    release.new('grafana') +
    release.spec.chart.spec.withChart('grafana') +
    release.spec.chart.spec.sourceRef.withKind('HelmRepository') +
    release.spec.chart.spec.sourceRef.withName('grafana') +
    release.spec.chart.spec.sourceRef.withNamespace('flux-system') +
    release.spec.withInterval('1h') +
    // @ref https://github.com/grafana/helm-charts/blob/main/charts/grafana/values.yaml
    release.spec.withValues({
      adminUser: 'admin',
      adminPassword: 'testadmin',

      datasources: {
        'datasources.yaml': {
          apiVersion: 1,
          datasources: [
            {
              name: 'Mimir',
              type: 'prometheus',
              uid: 'prom',
              access: 'proxy',
              url: 'http://mimir-nginx.o11y.svc.cluster.local/prometheus',
              isDefault: true,
            },
            {
              name: 'Loki',
              type: 'loki',
              uid: 'loki',
              access: 'proxy',
              url: 'http://loki-gateway.o11y.svc.cluster.local',
            },
            {
              name: 'Tempo',
              type: 'tempo',
              uid: 'tempo',
              access: 'proxy',
              url: 'http://tempo.o11y.svc.cluster.local:3100',
              jsonData: {
                tracesToLogsV2: { datasourceUid: 'loki' },
                lokiSearch: { datasourceUid: 'loki' },
                tracesToMetrics: { datasourceUid: 'prom' },
                serviceMap: { datasourceUid: 'prom' },
              },
            },
          ],
        },
      },

      // 'grafana.ini': {
      //   'auth.generic_oauth': {
      //     enabled: true,
      //     name: 'Pocket ID',
      //     allow_sign_up: false,
      //     auth_url: 'https://auth.o5s.lol/authorize',
      //     auto_login: true,
      //     client_id: '$__file{/etc/secrets/generic_oauth/client_id}',
      //     client_secret: '$__file{/etc/secrets/generic_oauth/client_secret}',
      //     email_attribute_name: 'email:primary',
      //     scopes: 'openid email profile groups',
      //     skip_org_role_sync: true,
      //     token_url: 'https://auth.o5s.lol/api/oidc/token',
      //   },
      // },

      extraSecretMounts: [
        {
          name: 'generic-oauth-secret-mount',
          defaultMode: '0440',
          mountPath: '/etc/secrets/generic_oauth',
          readOnly: true,
          secretName: $.genericOauthSecret.metadata.name,
        },
      ],
    }),

  // ---

  local gatewayApi = import 'github.com/jsonnet-libs/gateway-api-libsonnet/1.1/main.libsonnet',
  local httpRoute = gatewayApi.gateway.v1.httpRoute,

  httpRoute:
    httpRoute.new('grafana') +
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
