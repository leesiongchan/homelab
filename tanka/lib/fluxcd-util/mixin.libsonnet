local fluxcd = import 'github.com/jsonnet-libs/fluxcd-libsonnet/2.5.1/main.libsonnet';
local ks = fluxcd.kustomize.v1.kustomization;

{
  kustomizeFor(name, namespace, path)::
    ks.new(name) +
    ks.metadata.withNamespace(namespace) +
    ks.spec.decryption.withProvider('sops') +
    ks.spec.decryption.secretRef.withName('sops-age') +
    ks.spec.withInterval('1h') +
    ks.spec.withPath(path) +
    ks.spec.withPrune(true) +
    ks.spec.sourceRef.withKind('GitRepository') +
    ks.spec.sourceRef.withName('flux-system') +
    ks.spec.withTimeout('3m'),
}
