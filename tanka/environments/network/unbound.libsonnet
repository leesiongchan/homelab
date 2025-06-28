local k = import 'github.com/grafana/jsonnet-libs/ksonnet-util/kausal.libsonnet';

{
  local appName = 'unbound',

  _config+:: {
    version: 'main',
  },

  _image+:: 'klutchell/unbound:%s' % $._config.version,

  // ---

  local configMap = k.core.v1.configMap,

  configMap:
    configMap.new('%s-config' % appName) +
    configMap.withDataMixin({
      'unbound.conf': importstr 'configs/unbound/unbound.conf',
    }),

  // ---

  local container = k.core.v1.container,
  local containerPort = k.core.v1.containerPort,

  local healthCheckCommand = ['drill-hc', '@127.0.0.1', 'dnssec.works'],

  container::
    container.new(appName, $._image) +
    container.livenessProbe.exec.withCommand(healthCheckCommand) +
    container.readinessProbe.exec.withCommand(healthCheckCommand) +
    container.startupProbe.exec.withCommand(healthCheckCommand) +
    container.withPorts([
      containerPort.new('dns-tcp', 53),
      containerPort.newUDP('dns-udp', 53),
    ]) +
    container.withResourcesRequests(1, '64Mi') +
    container.withResourcesLimits(2, '128Mi'),

  local deployment = k.apps.v1.deployment,
  local volumeMount = k.core.v1.volumeMount,

  deployment:
    deployment.new(appName, 1, [$.container]),
  // deployment.configVolumeMount($.configMap.metadata.name, '/etc/unbound/unbound.conf', volumeMount.withSubPath('unbound.conf')),

  // ---

  local horizontalPodAutoscaler = k.autoscaling.v2.horizontalPodAutoscaler,
  local metricSpec = k.autoscaling.v2.metricSpec,

  horizontalPodAutoscaler:
    horizontalPodAutoscaler.new(appName) +
    horizontalPodAutoscaler.spec.scaleTargetRef.withApiVersion('apps/v1') +
    horizontalPodAutoscaler.spec.scaleTargetRef.withKind('Deployment') +
    horizontalPodAutoscaler.spec.scaleTargetRef.withName($.deployment.metadata.name) +
    horizontalPodAutoscaler.spec.withMinReplicas(2) +
    horizontalPodAutoscaler.spec.withMaxReplicas(4) +
    horizontalPodAutoscaler.spec.withMetrics([
      metricSpec.withType('Resource') +
      metricSpec.resource.withName('cpu') +
      metricSpec.resource.target.withType('Utilization') +
      metricSpec.resource.target.withAverageUtilization(50),
      metricSpec.withType('Resource') +
      metricSpec.resource.withName('memory') +
      metricSpec.resource.target.withType('AverageValue') +
      metricSpec.resource.target.withAverageValue('110Mi'),
    ]),

  // ---

  local service = k.core.v1.service,

  service:
    k.util.serviceFor($.deployment),
}
