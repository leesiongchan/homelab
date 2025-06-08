local fluxcd = import 'github.com/jsonnet-libs/fluxcd-libsonnet/2.5.1/main.libsonnet';

{
  local ks = fluxcd.kustomize.v1.kustomization,

  withTemplate(name, namespace, path)::
    ks.new(name) +
    ks.metadata.withNamespace(namespace) +
    ks.spec.withInterval('30m') +
    ks.spec.withPath(path) +
    ks.spec.withPrune(true) +
    ks.spec.withRetryInterval('1m') +
    ks.spec.sourceRef.withKind('GitRepository') +
    ks.spec.sourceRef.withName('flux-system'),

}
