terraform {
  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "KrisCo"
    workspaces {
      prefix = "Lab-"
    }
  }
}