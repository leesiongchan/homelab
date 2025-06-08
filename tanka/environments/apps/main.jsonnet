local k = import 'ksonnet-util/kausal.libsonnet';

local memos = import 'memos.libsonnet';

{
  namespace: k.core.v1.namespace.new('apps'),

  // ---

  memos: memos,
}
