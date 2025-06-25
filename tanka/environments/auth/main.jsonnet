local k = import 'github.com/grafana/jsonnet-libs/ksonnet-util/kausal.libsonnet';

{ namespace: k.core.v1.namespace.new('auth') } +
import 'pocket-id.libsonnet'
