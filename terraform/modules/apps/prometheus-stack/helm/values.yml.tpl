# Windows monitoring configuration
windowsMonitoring:
  # Deploys the windows-exporter and Windows-specific dashboards and rules (job name must be 'windows-exporter')
  enabled: false

prometheus-windows-exporter:
  # Enable ServiceMonitor and set Kubernetes label to use as a job label
  prometheus:
    monitor:
      enabled: false

# Alertmanager configuration
alertmanager:
  enabled: false

# Grafana configuration
grafana:
  enabled: true
  defaultDashboardsEnabled: true
  adminPassword: ${ grafana_password }
  serviceMonitor:
    labels:
      release: kube-prometheus-stack
    relabelings:
      # Replace job value
      - sourceLabels:
          - __address__
        action: replace
        targetLabel: job
        replacement: grafana
  ingress:
    enabled: true
    ingressClassName: ${ ingress_class }
%{ if length(grafana_annotations) > 0 ~}
    annotations:
%{ for key, value in grafana_annotations ~}
      ${key}: ${value}
%{ endfor ~}
%{ else ~}
    annotations: {}
%{ endif ~}
  
%{~ if length(grafana_domains) > 0 ~}
    hosts:
%{ for value in grafana_domains ~}
      - ${ value }
%{ endfor ~}
%{ else}
    hosts: []
%{~ endif ~}
    tls:
      - secretName: ${ grafana_tls_secret }
%{ if length(grafana_domains) > 0 ~}
        hosts:
%{ for value in grafana_domains ~}
          - ${ value }
%{ endfor ~}
%{ else}
        hosts: []
%{~ endif ~}

# Prometheus configuration
prometheus:
  enabled: true
  prometheusSpec:
    disableCompaction: false
    retention: ${ retention_period }
    ruleSelectorNilUsesHelmValues: false
    serviceMonitorSelectorNilUsesHelmValues: false
    podMonitorSelectorNilUsesHelmValues: false
    probeSelectorNilUsesHelmValues: false
    resources:
      requests:
        memory: "500Mi"
      limits:
        memory: "1Gi"
    storageSpec:
      volumeClaimTemplate:
        spec:
          storageClassName: ${ storage_class }
          accessModes: ["ReadWriteOnce"]
          resources:
            requests:
              storage: ${ prometheus_storage_size }
  serviceMonitor:
    relabelings:
      # Replace job value
      - sourceLabels:
          - __address__
        action: replace
        targetLabel: job
        replacement: prometheus
  ingress:
    enabled: true
    ingressClassName: ${ ingress_class }
%{ if length(prometheus_annotations) > 0 ~}
    annotations:
%{ for key, value in prometheus_annotations ~}
      ${key}: ${value}
%{ endfor ~}
%{ else ~}
    annotations: {}
%{ endif ~}
  
%{~ if length(prometheus_domains) > 0 ~}
    hosts:
%{ for value in prometheus_domains ~}
      - ${ value }
%{ endfor ~}
%{ else}
    hosts: []
%{~ endif ~}
    tls:
      - secretName: ${ prometheus_tls_secret }
%{ if length(prometheus_domains) > 0 ~}
        hosts:
%{ for value in prometheus_domains ~}
          - ${ value }
%{ endfor ~}
%{ else}
        hosts: []
%{~ endif ~}

# Prometheus Operator configuration
prometheusOperator:
  enabled: true
  kubeletService:
    enabled: true
  serviceMonitor:
    relabelings:
      # Replace job value
      - sourceLabels:
          - __address__
        action: replace
        targetLabel: job
        replacement: prometheus-operator

cleanPrometheusOperatorObjectNames: true

# Thanos configuration
thanosRuler:
  enabled: false

# Exporters configuration
nodeExporter:
  enabled: false
kubeApiServer:
  enabled: false
kubelet:
  enabled: true
kubeControllerManager:
  enabled: false
coreDns:
  enabled: false
kubeEtcd:
  enabled: false
kubeDns:
  enabled: false
kubeScheduler:
  enabled: false
kubeProxy:
  enabled: false
kubeStateMetrics:
  enabled: false

# Default rules configuration
defaultRules:
  create: true
  rules:
    alertmanager: false
    etcd: false
    configReloaders: false
    general: false
    k8sContainerCpuUsageSecondsTotal: false
    k8sContainerMemoryCache: false
    k8sContainerMemoryRss: false
    k8sContainerMemorySwap: false
    k8sContainerResource: false
    k8sContainerMemoryWorkingSetBytes: false
    k8sPodOwner: false
    kubeApiserverAvailability: false
    kubeApiserverBurnrate: false
    kubeApiserverHistogram: false
    kubeApiserverSlos: false
    kubeControllerManager: false
    kubelet: true
    kubeProxy: false
    kubePrometheusGeneral: false
    kubePrometheusNodeRecording: false
    kubernetesApps: false
    kubernetesResources: false
    kubernetesStorage: false
    kubernetesSystem: false
    kubeSchedulerAlerting: false
    kubeSchedulerRecording: false
    kubeStateMetrics: false
    network: false
    node: false
    nodeExporterAlerting: false
    nodeExporterRecording: false
    prometheus: false
    prometheusOperator: false
    windows: false