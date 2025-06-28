local k = import 'github.com/grafana/jsonnet-libs/ksonnet-util/kausal.libsonnet';

local util = import 'util.libsonnet';

{
  local appName = 'pingvin-share',

  _config+:: {
    domain: 'transfer.o5s.lol',
    port: 3000,
    version: 'latest',
  },

  _image+:: 'stonith404/pingvin-share:%s' % $._config.version,

  // ---

  local pvc = k.core.v1.persistentVolumeClaim,

  dataPvc:
    pvc.new('%s-data' % appName) +
    pvc.spec.withAccessModes('ReadWriteOnce') +
    pvc.spec.withStorageClassName('local-path') +
    pvc.spec.resources.withRequests({ storage: '50Gi' }),

  // ---

  local container = k.core.v1.container,
  local containerPort = k.core.v1.containerPort,

  container::
    container.new(appName, $._image) +
    container.withPorts([
      containerPort.new('http', 3000),
    ]),

  local deployment = k.apps.v1.deployment,
  local volumeMount = k.core.v1.volumeMount,
  local volume = k.core.v1.volume,

  deployment:
    deployment.new(appName, 1, [$.container]) +
    deployment.pvcVolumeMount($.dataPvc.metadata.name, '/opt/app/backend/data'),

  // ---

  local service = k.core.v1.service,

  service:
    k.util.serviceFor($.deployment),

  // ---

  httpRoute:
    util.httpRouteFor($.service.metadata.name, $._config.domain, $._config.port),
}
