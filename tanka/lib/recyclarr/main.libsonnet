local k = import 'ksonnet-util/kausal.libsonnet';

{
  _config+:: {
    version: '7',
  },

  _image+:: 'ghcr.io/recyclarr/recyclarr:' + $._config.version,

  // ---

  local pvc = k.core.v1.persistentVolumeClaim,

  pvc:
    pvc.new('recyclarr-config-pvc') +
    pvc.spec.withAccessModes('ReadWriteOnce') +
    pvc.spec.withStorageClassName('local-path') +
    pvc.spec.resources.withRequests({ storage: '1Gi' }),

  // ---

  local configMap = k.core.v1.configMap,

  configMap:
    configMap.new('recyclarr-config') +
    configMap.withDataMixin({
      'recyclarr.yml': importstr 'config.yaml',
    }),

  // ---

  local container = k.core.v1.container,
  local envVar = k.core.v1.envVar,

  container::
    container.new('recyclarr', $._image) +
    container.withEnvMap({
      CRON_SCHEDULE: '@daily',
    }) +
    container.withEnvMixin([
      envVar.fromSecretRef('RADARR__AUTH__APIKEY', 'media-secret', 'RADARR__AUTH__APIKEY'),
      envVar.fromSecretRef('RADARR4k__AUTH__APIKEY', 'media-secret', 'RADARR4k__AUTH__APIKEY'),
      envVar.fromSecretRef('SONARR__AUTH__APIKEY', 'media-secret', 'SONARR__AUTH__APIKEY'),
      envVar.fromSecretRef('SONARR4k__AUTH__APIKEY', 'media-secret', 'SONARR4k__AUTH__APIKEY'),
    ]) +
    container.withResourcesLimits('1', '128Mi') +
    container.withResourcesRequests('10m', '64Mi'),

  local deployment = k.apps.v1.deployment,
  local volumeMount = k.core.v1.volumeMount,

  deployment:
    deployment.new('recyclarr', 1, [$.container]) +
    k.util.pvcVolumeMount($.pvc.metadata.name, '/config') +
    k.util.configVolumeMount($.configMap.metadata.name, '/config/recyclarr.yml', volumeMount.withSubPath('recyclarr.yml')),
}
