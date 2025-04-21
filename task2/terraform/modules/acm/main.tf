# Import existing certificate
resource "aws_acm_certificate" "imported" {
  private_key       = file("/home/akshat/Desktop/cloudzenia-task/task2/terraform/certs/fullchain.pem")
  certificate_body  = file("../../certs/cert.pem")
  certificate_chain = file("/home/akshat/Desktop/cloudzenia-task/task2/terraform/certs/fullchain.pem")

  tags = {
    Name        = "${var.project}-${var.environment}-certificate"
    Environment = var.environment
  }

  lifecycle {
    create_before_destroy = true
  }
} 