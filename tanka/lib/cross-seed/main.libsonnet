local externalSecrets = import 'github.com/jsonnet-libs/external-secrets-libsonnet/0.9/main.libsonnet';
local k = import 'ksonnet-util/kausal.libsonnet';

{
  _config+:: {
    port: 2468,
    version: '6',
  },

  _image+:: 'ghcr.io/cross-seed/cross-seed:' + $._config.version,

  // ---

  local externalSecret = externalSecrets.nogroup.v1beta1.externalSecret,

  externalSecret:
    externalSecret.new('cross-seed-config-secret') +
    externalSecret.spec.secretStoreRef.withKind('ClusterSecretStore') +
    externalSecret.spec.secretStoreRef.withName('bitwarden-secret-store') +
    externalSecret.spec.withRefreshInterval('1h') +
    externalSecret.spec.withDataMixin([
      externalSecret.spec.data.withSecretKey('CROSS_SEED_API_KEY') +
      externalSecret.spec.data.remoteRef.withKey('cb298359-d993-493c-b6fd-b23900c6a7ed'),
      externalSecret.spec.data.withSecretKey('PROWLARR_API_KEY') +
      externalSecret.spec.data.remoteRef.withKey('a102c463-5673-4bd5-b6f6-b22000e8e5ea'),
      externalSecret.spec.data.withSecretKey('RADARR_API_KEY') +
      externalSecret.spec.data.remoteRef.withKey('f4a9a4b8-f09b-4b6f-9838-b22000c535ff'),
      externalSecret.spec.data.withSecretKey('SONARR_API_KEY') +
      externalSecret.spec.data.remoteRef.withKey('31715aa4-aa79-49e7-bd98-b22000c51a4b'),
    ]) +
    externalSecret.spec.target.template.withEngineVersion('v2') +
    externalSecret.spec.target.template.withDataMixin({
      'config.js': importstr 'config.js',
    }),

  // ---

  local pvc = k.core.v1.persistentVolumeClaim,

  pvc:
    pvc.new('cross-seed-config-pvc') +
    pvc.spec.withAccessModes('ReadWriteOnce') +
    pvc.spec.withStorageClassName('local-path') +
    pvc.spec.resources.withRequests({ storage: '1Gi' }),

  // ---

  local container = k.core.v1.container,
  local envVar = k.core.v1.envVar,

  container::
    container.new('cross-seed', $._image) +
    container.withArgs('daemon') +
    container.livenessProbe.httpGet.withPath('/api/ping') +
    container.livenessProbe.httpGet.withPort($._config.port) +
    container.readinessProbe.httpGet.withPath('/api/ping') +
    container.readinessProbe.httpGet.withPort($._config.port) +
    container.withResourcesLimits('1', '128Mi') +
    container.withResourcesRequests('10m', '64Mi') +
    container.securityContext.withRunAsUser(1000) +
    container.securityContext.withRunAsGroup(1000),

  local deployment = k.apps.v1.deployment,
  local volumeMount = k.core.v1.volumeMount,

  deployment:
    deployment.new('cross-seed', 1, [$.container]) +
    k.util.pvcVolumeMount($.pvc.metadata.name, '/config') +
    k.util.secretVolumeMount($.externalSecret.metadata.name, '/config/config.js', 420, volumeMount.withSubPath('config.js')) +
    k.util.pvcVolumeMount('media-nfs', '/Media/Downloads/bt/complete', false, volumeMount.withSubPath('Downloads/bt/complete')),

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
}
