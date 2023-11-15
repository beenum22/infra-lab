resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"
  }
}

//module "homepage" {
//  source = "./modules/homepage"
//  namespace = "monitoring"
//  domains = [
//    "homepage.k3s.tail15637.ts.net",
//    "homepage.k3s.home"
//  ]
//  ingress_class = "nginx"
//  depends_on = [kubernetes_namespace.monitoring]
//}
