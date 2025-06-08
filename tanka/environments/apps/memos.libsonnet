local k = import 'ksonnet-util/kausal.libsonnet';

{
  _config+:: {
    port: 5230,
    version: 'latest',
  },

  _image+:: 'usememos/memos:' + $._config.version,

  // ---
    
  local container = k.core.v1.container,

  container::
    container.new('memos', $._image),

  local deployment = k.apps.v1.deployment,

  deployment:
    deployment.new('memos', 1, [$.container]),

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