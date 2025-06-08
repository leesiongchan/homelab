local fluxcd = import 'github.com/jsonnet-libs/fluxcd-libsonnet/2.5.1/main.libsonnet';

{
  local fluxcdExt = import 'fluxcd-ext/main.libsonnet',

  media:
    fluxcdExt.withTemplate('media', 'media', './generated/media')
}
