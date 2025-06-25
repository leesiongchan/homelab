local k = import 'github.com/grafana/jsonnet-libs/ksonnet-util/kausal.libsonnet';

{
  local appName = 'gluetun',

  _config+:: {
    port: 8080,
    version: 'latest',
  },

  _image+:: 'qmcgaw/gluetun:' + $._config.version,

  local container = k.core.v1.container,
  local envVar = k.core.v1.envVar,

  container::
    container.new(appName, 'qmcgaw/gluetun:latest') +
    // @ref https://github.com/qdm12/gluetun-wiki/tree/main/setup/options
    container.withEnvMap({
      VPN_SERVICE_PROVIDER: 'private internet access',
      VPN_PORT_FORWARDING: 'on',
      SERVER_NAMES: 'malaysia401,malaysia402,singapore401,singapore402,singapore403,singapore404',
      // --- Control server
      HTTP_CONTROL_SERVER_ADDRESS: ':8088',
      // --- DNS
      BLOCK_ADS: 'off',
      BLOCK_MALICIOUS: 'off',
      BLOCK_SURVEILLANCE: 'off',
      // DNS_ADDRESS: '52.223.41.243',  // PIA DNS
      DOT: 'off',
      // --- Firewall
      FIREWALL_INPUT_PORTS: std.toString($._config.port),
      // FIREWALL_OUTBOUND_SUBNETS: '52.223.41.243/28',
      // --- HTTP proxy
      HTTPPROXY: 'on',
    }) +
    container.withEnvMixin([
      envVar.fromSecretRef('OPENVPN_USER', 'media-secret', 'PIA__USERNAME'),
      envVar.fromSecretRef('OPENVPN_PASSWORD', 'media-secret', 'PIA__PASSWORD'),
    ]) +
    // container.securityContext.withRunAsUser(1000) +
    // container.securityContext.withRunAsGroup(1000) +
    container.securityContext.capabilities.withAdd(['NET_ADMIN']),
}
