local k = import 'github.com/grafana/jsonnet-libs/ksonnet-util/kausal.libsonnet';

local ns = k.core.v1.namespace;

{
  app: ns.new('app'),
  auth: ns.new('auth'),
  dashboard: ns.new('dashboard'),
  database: ns.new('database'),
  game: ns.new('game'),
  media: ns.new('media'),
  network: ns.new('network'),
  o11y: ns.new('o11y'),
  storage: ns.new('storage'),
}
