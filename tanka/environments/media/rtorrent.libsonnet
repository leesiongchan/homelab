local k = import 'github.com/grafana/jsonnet-libs/ksonnet-util/kausal.libsonnet';

local gluetun = import 'gluetun.libsonnet';
local util = import 'util.libsonnet';

{
  local appName = 'rtorrent',

  _config+:: {
    domain: 'rt.o5s.lol',
    port: 8080,
    version: 'latest',
  },

  _image+:: 'crazymax/rtorrent-rutorrent:' + $._config.version,

  // ---

  local pvc = k.core.v1.persistentVolumeClaim,

  dataPvc:
    pvc.new(appName + '-data') +
    pvc.spec.withAccessModes('ReadWriteOnce') +
    pvc.spec.withStorageClassName('local-path') +
    pvc.spec.resources.withRequests({ storage: '1Gi' }),

  // ---

  local container = k.core.v1.container,
  local containerPort = k.core.v1.containerPort,

  local healthCheckCommand = ['/usr/local/bin/healthcheck'],

  container::
    container.new(appName, $._image) +
    container.livenessProbe.exec.withCommand(healthCheckCommand) +
    container.readinessProbe.exec.withCommand(healthCheckCommand) +
    container.startupProbe.exec.withCommand(healthCheckCommand) +
    container.withEnvMap({
      RUTORRENT_PORT: std.toString($._config.port),
    }) +
    container.withResourcesLimits('1', '512Mi') +
    container.withResourcesRequests('100m', '256Mi') +
    container.withPorts(
      containerPort.new('http', $._config.port),
    ),

  local deployment = k.apps.v1.deployment,

  deployment:
    deployment.new(appName, 1, [$.container, gluetun.container]) +
    deployment.pvcVolumeMount($.dataPvc.metadata.name, '/data') +
    deployment.pvcVolumeMount('media-nfs', '/Media'),

  // ---

  local service = k.core.v1.service,

  service:
    k.util.serviceFor($.deployment),

  // ---

  httpRoute: util.httpRouteFor($.service.metadata.name, $._config.domain, $._config.port),
}
