local k = import 'github.com/grafana/jsonnet-libs/ksonnet-util/kausal.libsonnet';
local fluxcd = import 'github.com/jsonnet-libs/fluxcd-libsonnet/2.5.1/main.libsonnet';

{
  local appName = 'factorio',

  _config+:: {
    version: '2.0.55',
  },

  _image+:: 'factoriotools/factorio:%s' % $._config.version,

  // ---

  local configMap = k.core.v1.configMap,

  configMap:
    configMap.new('%s-config' % appName, {
      'server-settings.json': importstr 'config/server-settings.json',
    }),

  // ---

  local pvc = k.core.v1.persistentVolumeClaim,

  dataPvc:
    pvc.new('%s-data' % appName) +
    pvc.spec.withAccessModes('ReadWriteOnce') +
    pvc.spec.withStorageClassName('local-path') +
    pvc.spec.resources.withRequests({ storage: '1Gi' }),

  // ---

  local container = k.core.v1.container,
  local containerPort = k.core.v1.containerPort,

  container::
    container.new(appName, $._image) +
    container.withPorts([
      containerPort.new('tcp', 27015),
      containerPort.newUDP('udp', 34197),
    ]) +
    container.securityContext.withRunAsUser(845) +
    container.securityContext.withRunAsGroup(845),

  local deployment = k.apps.v1.deployment,
  local volumeMount = k.core.v1.volumeMount,
  local volume = k.core.v1.volume,

  deployment:
    deployment.new(appName, 1, [$.container]) +
    deployment.spec.template.spec.securityContext.withFsGroup(845) +
    deployment.pvcVolumeMount($.dataPvc.metadata.name, '/factorio') +
    deployment.configMapVolumeMount($.configMap, '/factorio/config/server-settings.json', volumeMount.withSubPath('server-settings.json')),

  // ---

  local service = k.core.v1.service,

  service:
    k.util.serviceFor($.deployment),
}
