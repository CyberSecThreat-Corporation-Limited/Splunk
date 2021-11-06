# Splunk
Splunk configuration, apps or use cases

The file splunk-universalforwarder-daemonset.yaml is sample configuration files to deploy Splunk Universal Forwarder to Kubernetes. It will ensure every node should have one copy using DaemonSet and also ensure the master node will run it. The primary use case is you want to control the behaviour of Splunk Universal Forwarder using Splunk deployment server instead of configure Kubernetes.
