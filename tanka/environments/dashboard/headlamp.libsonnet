local k = import 'github.com/grafana/jsonnet-libs/ksonnet-util/kausal.libsonnet';
local fluxcd = import 'github.com/jsonnet-libs/fluxcd-libsonnet/2.5.1/main.libsonnet';

local util = import 'util.libsonnet';

{
  local appName = 'headlamp',

  _config+:: {
    domain: 'k8s.o5s.lol',
  },

  // ---

  local clusterRoleBinding = k.rbac.v1.clusterRoleBinding,
  local subject = k.rbac.v1.subject,

  clusterRoleBinding:
    clusterRoleBinding.new('headlamp-admin') +
    clusterRoleBinding.roleRef.withKind('ClusterRole') +
    clusterRoleBinding.roleRef.withName('cluster-admin') +
    clusterRoleBinding.roleRef.withApiGroup('rbac.authorization.k8s.io') +
    clusterRoleBinding.withSubjects([
      subject.withKind('Group') +
      subject.withName('admin') +
      subject.withApiGroup('rbac.authorization.k8s.io'),
    ]),

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
        pluginsDir: '/build/plugins',
        oidc: {
          clientID: '14c2579d-25b9-4dbb-b6fa-daf546d87518',
          clientSecret: 'Ryh9lpojjgYjBBxCO3aKq4sHoNC2hRyh',
          issuerURL: 'https://auth.harflix.lol',
          scopes: 'openid,profile,email,groups',
        },
      },
      serviceAccount: {
        create: false,
      },
      clusterRoleBinding: {
        create: false,
      },
      initContainers: [{
        command: [
          '/bin/sh',
          '-c',
          'mkdir -p /build/plugins && cp -r /plugins/* /build/plugins/',
        ],
        image: 'ghcr.io/headlamp-k8s/headlamp-plugin-flux:latest',
        name: 'headlamp-plugin-flux',
        volumeMounts: [{
          mountPath: '/build/plugins',
          name: 'headlamp-plugins',
        }],
      }, {
        command: [
          '/bin/sh',
          '-c',
          'mkdir -p /build/plugins && cp -r /plugins/* /build/plugins/',
        ],
        image: 'ghcr.io/headlamp-k8s/headlamp-plugin-cert-manager:latest',
        name: 'headlamp-plugin-cert-manager',
        volumeMounts: [{
          mountPath: '/build/plugins',
          name: 'headlamp-plugins',
        }],
      }],
      persistentVolumeClaim: {
        accessModes: ['ReadWriteOnce'],
        enabled: true,
        size: '1Gi',
      },
      volumeMounts: [{
        mountPath: '/build/plugins',
        name: 'headlamp-plugins',
      }],
      volumes: [{
        name: 'headlamp-plugins',
        persistentVolumeClaim: {
          claimName: 'headlamp',
        },
      }],
    }),

  // ---

  httpRoute:
    util.httpRouteFor($.release.metadata.name, $._config.domain, 80),
}
