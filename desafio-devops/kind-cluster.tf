terraform {
  required_providers {
    kind = {
      source = "tehcyx/kind"
      version = "0.0.15"
    }
  }
}

provider "kind" {}

resource "kind_cluster" "default" {
  name = "meu-cluster"
  node_image = "kindest/node:v1.25.3"

  kind_config {
    kind = "Cluster"
    api_version = "kind.x-k8s.io/v1alpha4"

    node {
      role = "control-plane"
    }

    node{
      role = "worker"

      extra_port_mappings {
        container_port = 31900
        host_port = 31900
      }

      extra_port_mappings {
        container_port = 32000
        host_port = 32000
      }
    }
  }
}
