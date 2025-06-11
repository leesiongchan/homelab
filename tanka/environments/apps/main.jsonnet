local k = import 'ksonnet-util/kausal.libsonnet';

{
  namespace: k.core.v1.namespace.new('apps'),

  // ---

  actual: import 'actual.libsonnet',
  memos: import 'memos.libsonnet',
  newt: import 'newt.libsonnet',
  synology: import 'synology.libsonnet',
}
