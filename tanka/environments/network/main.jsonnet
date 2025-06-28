local k = import 'github.com/grafana/jsonnet-libs/ksonnet-util/kausal.libsonnet';
local tk = import 'tk';

{
  repo: import 'repository.libsonnet',
  namespace: k.core.v1.namespace.new(tk.env.spec.namespace),

  // ---

  blocky: import 'blocky.libsonnet',
  newt: import 'newt.libsonnet',
  nginxGateway: import 'nginx-gateway.libsonnet',
  unbound: import 'unbound.libsonnet',
}
