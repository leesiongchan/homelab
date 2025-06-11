local k = import 'ksonnet-util/kausal.libsonnet';

{
  local appName = 'newt',

  _config+:: {
    endpoint: 'https://pangolin.harflix.lol',
    version: 'latest',
  },

  _image+:: 'fosrl/newt:' + $._config.version,

  // ---

  local container = k.core.v1.container,

  container::
    container.new(appName, $._image) +
    // @ref https://www.usememos.com/docs/install/runtime-options
    container.withEnvMap({
      PANGOLIN_ENDPOINT: $._config.endpoint,
      NEWT_ID: 'xailz8nlpd7uf4g',
      NEWT_SECRET: 'uo5zyxee6l2q89xadi4xe6yp5kdhi96n9ht7jh7zu6tphzgh',
    }),

  local deployment = k.apps.v1.deployment,

  deployment:
    deployment.new(appName, 1, [$.container]),
}
