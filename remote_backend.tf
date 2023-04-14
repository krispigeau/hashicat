terraform {
  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "KrisCo"
    workspaces {
      name = "Lab-production"
    }
  }
}