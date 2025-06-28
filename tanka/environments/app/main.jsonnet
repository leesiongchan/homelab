local k = import 'github.com/grafana/jsonnet-libs/ksonnet-util/kausal.libsonnet';
local tk = import 'tk';

{
  namespace: k.core.v1.namespace.new(tk.env.spec.namespace),

  // ---

  actual: import 'actual.libsonnet',
  memos: import 'memos.libsonnet',
  pingvinShare: import 'pingvin-share/main.jsonnet',
}
