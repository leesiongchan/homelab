local k = import 'github.com/grafana/jsonnet-libs/ksonnet-util/kausal.libsonnet';
local tanka = import 'github.com/grafana/jsonnet-libs/tanka-util/main.libsonnet';
local helm = tanka.helm.new(std.thisFile);

(import 'config.libsonnet')
+ (import 'deploy.libsonnet')
  {
  gpuOperator: helm.template('amd-gpu-operator', '../../charts/gpu-operator-charts', {
    namespace: 'kube-system',
    values: {

    },
  }),

  withDeviceConfig():: {
    deviceConfig: (import 'device-config.libsonnet'),
  },

  // device_config: (import 'device-config.libsonnet'),

  // prometheus: {
  //   deployment: deployment.new(
  //     name='prometheus',
  //     replicas=1,
  //     containers=[
  //       container.new('prometheus', 'prom/prometheus')
  //       + container.withPorts([port.new('api', 9090)]),
  //     ],
  //   ),
  //   service: k.util.serviceFor(self.deployment),
  // },
}
