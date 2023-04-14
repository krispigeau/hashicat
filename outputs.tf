# Outputs file
output "load_balancer_url" {
  value = "http://${aws_lb.alb.arn.dns_name}"
}
