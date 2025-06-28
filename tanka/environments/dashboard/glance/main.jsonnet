local k = import 'github.com/grafana/jsonnet-libs/ksonnet-util/kausal.libsonnet';

local util = import 'util.libsonnet';

{
  local appName = 'glance',

  _config+:: {
    domain: 'o5s.lol',
    port: 8080,
    version: 'latest',
  },

  _image+:: 'glanceapp/glance:' + $._config.version,

  local configMap = k.core.v1.configMap,

  configMap:
    configMap.new(appName + '-config') +
    configMap.withDataMixin({
      'glance.yml': importstr 'config/glance.yml',
    }),

  // ---

  local container = k.core.v1.container,

  container::
    container.new(appName, $._image),

  local deployment = k.apps.v1.deployment,
  local volumeMount = k.core.v1.volumeMount,

  deployment:
    deployment.new(appName, 1, [$.container]) +
    k.util.configVolumeMount($.configMap.metadata.name, '/app/config/glance.yml', volumeMount.withSubPath('glance.yml')),

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

  // ---

  httpRoute:
    util.httpRouteFor($.service.metadata.name, $._config.domain, $._config.port),
}
