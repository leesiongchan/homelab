local mimir = import "github.com/grafana/mimir/operations/mimir/mimir.libsonnet";

mimir {
  _config+:: {
    namespace: "default",
    storage_backend: 'gcs',

    blocks_storage_bucket_name: 'example-bucket',
    node_selector: {
      workload: 'mimir',
    },
  },
}
