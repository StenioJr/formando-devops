terraform {
  required_providers {
    gitlab = {
      source = "gitlabhq/gitlab"
      version = "3.19.0"
    }
  }
}

variable "gitlab_token"{
  type = string
  description = "API token input using environment variable"
}

provider "gitlab" {
  token = var.gitlab_token
  base_url = "https://gitlab.com/api/v4"
}

resource "gitlab_project" "teste" {
  name = "podinfo"
  description = "Repositório do desafio final de DevOps, usando a aplicação podinfo"
  visibility_level = "public"
  import_url  = "https://github.com/stefanprodan/podinfo.git"
}
