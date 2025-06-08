{
  local d = (import 'doc-util/main.libsonnet'),
  '#':: d.pkg(name='minio-operator', url='github.com/jsonnet-libs/minio-operator-libsonnet/v6.0.0/main.libsonnet', help=''),
  job:: (import '_gen/job/main.libsonnet'),
  minio:: (import '_gen/minio/main.libsonnet'),
}
