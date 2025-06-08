{
  // API version of the resource
  apiVersion: 'amd.com/v1alpha1',

  // Kind of the resource
  kind: 'DeviceConfig',

  metadata: {
    // Name of the DeviceConfig CR. Note that the name of device plugin, node-labeller, and metric-explorer pods will be prefixed with this name
    name: 'gpu-operator',

    // Namespace for the GPU Operator and its components
    namespace: 'kube-amd-gpu',
  },

  spec: {
    // AMD GPU Driver Configuration
    driver: {
      // Set to false to skip driver installation to use inbox or pre-installed driver on worker nodes
      // Set to true to enable the operator to install the out-of-tree amdgpu kernel module
      enable: false,

      // Set to true to blacklist the amdgpu kernel module, which is required for installing the out-of-tree driver
      blacklist: false,

      // Specify your repository to host the driver image
      // DO NOT include the image tag as AMD GPU Operator will automatically manage the image tag for you
      image: 'docker.io/username/repo',

      // (Optional) Specify the credential for your private registry if it requires credential to get pull/push access
      imageRegistrySecret: {
        name: 'mysecret',
      },
    },

    imageRegistryTLS: {
      // If true, check for the container image using plain HTTP
      insecure: false,

      // If true, skip any TLS server certificate validation (useful for self-signed certificates)
      InsecureSkipTLSVerify: false,
    },

    // Specify the driver version you would like to be installed that coincides with a ROCm version number
    version: '6.3',

    upgradePolicy: {
      // Enable or disable upgrades
      enable: true,

      // (Optional) Number of nodes that will be upgraded in parallel. Default is 1
      maxParallelUpgrades: 3,
    },

    // AMD K8s Device Plugin Configuration
    commonConfig: {
      // (Optional) Specify common values used by all components
      initContainerImage: 'busybox:1.36',  // Specify the InitContainerImage to use for all component pods

      utilsContainer: {
        // Image to use for the utils container
        image: 'docker.io/amdpsdo/gpu-operator-utils:latest',

        // Image pull policy for the utils container. Either `Always`, `IfNotPresent`, or `Never`
        imagePullPolicy: 'IfNotPresent',

        // (Optional) Specify the credential for your private registry if it requires credential to get pull/push access
        imageRegistrySecret: {
          name: 'mysecret',
        },
      },
    },

    devicePlugin: {
      // Enable or disable the node labeller
      enableNodeLabeller: true,

      // (Optional) Specifying image names is optional. Default image names are shown here if not specified.
      devicePluginImage: 'rocm/k8s-device-plugin:latest',

      // Image pull policy for the device plugin. Either `Always`, `IfNotPresent`, or `Never`
      devicePluginImagePullPolicy: 'IfNotPresent',

      devicePluginTolerations: [
        {
          // Key is the taint key that the toleration applies to. Empty means match all taint keys.
          key: 'key1',

          // Operator represents a key's relationship to the value. Valid operators are Exists and Equal.
          operator: 'Equal',

          // Value is the taint value the toleration matches to.
          value: 'value1',

          // Effect indicates the taint effect to match. Allowed values are "NoSchedule", "PreferNoSchedule", and "NoExecute".
          effect: 'NoSchedule',
        },
      ],

      nodeLabellerImage: 'rocm/k8s-device-plugin:labeller-latest',
      nodeLabellerImagePullPolicy: 'IfNotPresent',

      nodeLabellerTolerations: [
        {
          key: 'key1',
          operator: 'Equal',
          value: 'value1',
          effect: 'NoSchedule',
        },
      ],

      imageRegistrySecret: {
        name: 'mysecret',
      },

      upgradePolicy: {
        // (Optional) Can be either `RollingUpdate` or `OnDelete`
        upgradeStrategy: 'RollingUpdate',

        // (Optional) Number of pods that can be unavailable during the upgrade process. Default is 1
        maxUnavailable: 1,
      },
    },

    // AMD GPU Metrics Exporter Configuration
    metricsExporter: {
      // false by Default. Set to true to enable the Metrics Exporter
      enable: false,

      // ServiceType used to expose the Metrics Exporter endpoint. Can be either `ClusterIp` or `NodePort`.
      serviceType: 'ClusterIP',

      // Note if specifying NodePort as the serviceType use `32500` as the port number must be between 30000-32767
      port: 5000,

      // (Optional) Specifying metrics exporter image is optional. Default image name shown here if not specified.
      image: 'rocm/device-metrics-exporter:v1.2.0',

      // Image pull policy for the metrics exporter container. Either `Always`, `IfNotPresent`, or `Never`
      imagePullPolicy: 'IfNotPresent',

      config: {
        // Name of the ConfigMap that contains the metrics exporter configuration.
        name: 'gpu-config',
      },

      upgradePolicy: {
        upgradeStrategy: 'RollingUpdate',
        maxUnavailable: 1,
      },

      tolerations: [
        {
          key: 'key1',
          operator: 'Equal',
          value: 'value1',
          effect: 'NoSchedule',
        },
      ],

      imageRegistrySecret: {
        name: 'mysecret',
      },

      selector: {
        // To label all nodes in your cluster use `kubectl label nodes --all amd.com/device-test-runner=true`
        'amd.com/metrics-exporter': 'true',

        // This is needed or else the metrics exporter will run on non-GPU nodes as well
        'feature.node.kubernetes.io/amd-gpu': 'true',
      },
    },

    // AMD GPU Device Test Runner Configuration
    testRunner: {
      enable: true,
      serviceType: 'ClusterIP',
      port: 5000,
      image: 'docker.io/rocm/test-runner:v1.2.0-beta.0',
      imagePullPolicy: 'IfNotPresent',

      config: {
        // Name of the configmap to customize the config for the test runner. If not specified, the default test config will be applied
        name: 'test-config',
      },

      logsLocation: {
        mountPath: '/var/log/amd-test-runner',
        hostPath: '/var/log/amd-test-runner',
      },

      upgradePolicy: {
        upgradeStrategy: 'RollingUpdate',
        maxUnavailable: 1,
      },

      tolerations: [
        {
          key: 'key1',
          operator: 'Equal',
          value: 'value1',
          effect: 'NoSchedule',
        },
      ],

      imageRegistrySecret: {
        name: 'mysecret',
      },

      selector: {
        'amd.com/test-runner': 'true',
        'feature.node.kubernetes.io/amd-gpu': 'true',
      },
    },

    // Specify the nodes to be managed by this DeviceConfig Custom Resource
    // This will be applied to all components unless a selector is specified in the component configuration
    'feature.node.kubernetes.io/amd-gpu': 'true',
  },
}
