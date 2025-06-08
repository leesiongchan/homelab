local k = import 'ksonnet-util/kausal.libsonnet';

{
  _config+:: {
    port: 5656,
    version: '0.14',
  },

  _image+:: 'ghcr.io/unpackerr/unpackerr:' + $._config.version,

  // ---

  local pvc = k.core.v1.persistentVolumeClaim,

  pvc:
    pvc.new('unpackerr-config-pvc') +
    pvc.spec.withAccessModes('ReadWriteOnce') +
    pvc.spec.withStorageClassName('local-path') +
    pvc.spec.resources.withRequests({ storage: '1Gi' }),

  // ---

  local container = k.core.v1.container,
  local envVar = k.core.v1.envVar,
  local volumeMount = k.core.v1.volumeMount,

  container::
    container.new('unpackerr', $._image) +
    container.withEnvMap({
      // TZ: 'America/New_York',
      UN_WEBSERVER_METRICS: 'true',
      // UN_WEBSERVER_LOG_FILE: '/logs/webserver.log',
      UN_ACTIVITY: 'true',
      UN_SONARR_0_URL: 'http://sonarr.media.svc.cluster.local:8989/sonarr',
      UN_SONARR_0_PATHS_0: '/Media/Downloads/bt/complete/tv-sonarr',
      UN_RADARR_0_URL: 'http://radarr.media.svc.cluster.local:7878/radarr',
      UN_RADARR_0_PATHS_0: '/Media/Downloads/bt/complete/radarr',
    }) +
    container.withEnvMixin([
      envVar.fromSecretRef('UN_RADARR_0_API_KEY', 'media-secret', 'RADARR__AUTH__APIKEY'),
      envVar.fromSecretRef('UN_SONARR_0_API_KEY', 'media-secret', 'SONARR__AUTH__APIKEY'),
    ]) +
    container.withResourcesLimits('1', '512Mi') +
    container.withResourcesRequests('100m', '256Mi') +
    container.withVolumeMounts([
      volumeMount.new('media', '/Media/Downloads/bt/complete/radarr') +
      volumeMount.withSubPath('Downloads/bt/complete/radarr'),
      volumeMount.new('media', '/Media/Downloads/bt/complete/tv-sonarr') +
      volumeMount.withSubPath('Downloads/bt/complete/tv-sonarr'),
    ]),

  local deployment = k.apps.v1.deployment,
  local volume = k.core.v1.volume,

  deployment:
    deployment.new('unpackerr', 1, [$.container]) +
    k.util.pvcVolumeMount($.pvc.metadata.name, '/config') +
    deployment.spec.template.spec.withVolumesMixin([
      volume.fromPersistentVolumeClaim('media', 'media-nfs'),
    ]),

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
}
