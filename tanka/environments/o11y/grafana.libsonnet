local fluxcd = import 'github.com/jsonnet-libs/fluxcd-libsonnet/2.5.1/main.libsonnet';
local k = import 'github.com/grafana/jsonnet-libs/ksonnet-util/kausal.libsonnet';

local repository = import './repository.libsonnet';

{
  local appName = 'grafana',

  _config+:: {
    domain: 'o11y.o5s.lol',
  },

  // ---

  local secret = k.core.v1.secret,

  oauthSecret:
    secret.new(appName + '-generic-oauth', {}) +
    secret.withStringData({
      client_id: '5e5add90-d124-4a5f-a96d-30866fa20fe3',
      client_secret: 'LYmGEAuD2W7n2JAni7TUgzNhyr81linL',
    }),

  // ---

  local release = fluxcd.helm.v2.helmRelease,

  release:
    release.new(appName) +
    release.spec.chart.spec.withChart('grafana') +
    release.spec.chart.spec.sourceRef.withKind('HelmRepository') +
    release.spec.chart.spec.sourceRef.withName(repository.grafana.metadata.name) +
    release.spec.withInterval('1h') +
    // @ref https://github.com/grafana/helm-charts/blob/main/charts/grafana/values.yaml
    release.spec.withValues({
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

      dashboardProviders: {
        'dashboardproviders.yaml': {
          apiVersion: 1,
          providers: [
            {
              name: 'kubernetes',
              orgId: 1,
              folder: 'Kubernetes',
              type: 'file',
              disableDeletion: true,
              editable: true,
              options: {
                path: '/var/lib/grafana/dashboards/kubernetes',
              },
            },
          ],
        },
      },
      dashboards: {
        kubernetes: {
          'k8s-system-api-server.json': {
            url: 'https://raw.githubusercontent.com/dotdc/grafana-dashboards-kubernetes/master/dashboards/k8s-system-api-server.json',
          },
          'k8s-system-coredns.json': {
            url: 'https://raw.githubusercontent.com/dotdc/grafana-dashboards-kubernetes/master/dashboards/k8s-system-coredns.json',
          },
          'k8s-views-global.json': {
            url: 'https://raw.githubusercontent.com/dotdc/grafana-dashboards-kubernetes/master/dashboards/k8s-views-global.json',
          },
          'k8s-views-namespaces.json': {
            url: 'https://raw.githubusercontent.com/dotdc/grafana-dashboards-kubernetes/master/dashboards/k8s-views-namespaces.json',
          },
          'k8s-views-nodes.json': {
            url: 'https://raw.githubusercontent.com/dotdc/grafana-dashboards-kubernetes/master/dashboards/k8s-views-nodes.json',
          },
          'k8s-views-pods.json': {
            url: 'https://raw.githubusercontent.com/dotdc/grafana-dashboards-kubernetes/master/dashboards/k8s-views-pods.json',
          },
        },
      },

      'grafana.ini': {
        server: {
          domain: $._config.domain,
          root_url: 'https://%(domain)s/',
        },
        // Pocket ID Guide https://pocket-id.org/docs/client-examples/grafana#grafana-app-setup
        'auth.generic_oauth': {
          enabled: true,
          name: 'Pocket ID',
          client_id: '$__file{/etc/secrets/oauth/client_id}',
          client_secret: '$__file{/etc/secrets/oauth/client_secret}',
          scopes: 'openid email profile groups',
          api_url: 'https://auth.harflix.lol/api/oidc/userinfo',
          auth_url: 'https://auth.harflix.lol/authorize',
          token_url: 'https://auth.harflix.lol/api/oidc/token',
          // ---
          allow_assign_grafana_admin: true,
          allow_sign_up: true,
          auto_login: false,
          login_attribute_path: 'preferred_username',
          role_attribute_path: "contains(groups[*], 'admin') && 'GrafanaAdmin' || 'Viewer'",
          skip_org_role_sync: false,
          use_pkce: true,
          use_refresh_token: true,
        },
      },

      extraSecretMounts: [
        {
          name: 'oauth-secret-mount',
          defaultMode: '0440',
          mountPath: '/etc/secrets/oauth',
          readOnly: true,
          secretName: $.oauthSecret.metadata.name,
        },
      ],
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
