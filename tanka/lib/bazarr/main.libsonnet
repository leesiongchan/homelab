local k = import 'ksonnet-util/kausal.libsonnet';

{
  _config+:: {
    port: 6767,
    version: 'latest',
  },

  _image+:: 'lscr.io/linuxserver/bazarr:' + $._config.version,

  // ---

  local pvc = k.core.v1.persistentVolumeClaim,

  pvc:
    pvc.new('bazarr-config-pvc') +
    pvc.spec.withAccessModes('ReadWriteOnce') +
    pvc.spec.withStorageClassName('local-path') +
    pvc.spec.resources.withRequests({ storage: '1Gi' }),

  // ---

  local container = k.core.v1.container,
  local envVar = k.core.v1.envVar,
  local volumeMount = k.core.v1.volumeMount,
  local httpHeader = k.core.v1.httpHeader,

  container::
    container.new('bazarr', $._image) +
    container.livenessProbe.httpGet.withPath('/api/system/health') +
    container.livenessProbe.httpGet.withPort($._config.port) +
    container.livenessProbe.httpGet.withHttpHeadersMixin(
      httpHeader.withName('X-API-KEY') +
      httpHeader.withValue('$BAZARR__AUTH__APIKEY')
    ) +
    container.readinessProbe.httpGet.withPath('/api/system/health') +
    container.readinessProbe.httpGet.withPort($._config.port) +
    container.readinessProbe.httpGet.withHttpHeadersMixin(
      httpHeader.withName('X-API-KEY') +
      httpHeader.withValue('$BAZARR__AUTH__APIKEY')
    ) +
    container.withEnvMap({
      BAZARR__SERVER__URLBASE: '/bazarr',
    }) +
    container.withEnvMixin([
      envVar.fromSecretRef('BAZARR__AUTH__APIKEY', 'media-secret', 'BAZARR__AUTH__APIKEY'),
    ]) +
    container.withResourcesLimits('1', '512Mi') +
    container.withResourcesRequests('100m', '256Mi'),

  local deployment = k.apps.v1.deployment,
  local volume = k.core.v1.volume,

  deployment:
    deployment.new('bazarr', 1, [$.container]) +
    k.util.pvcVolumeMount($.pvc.metadata.name, '/config') +
    k.util.pvcVolumeMount('media-nfs', '/Media'),

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
