output "instances" {
  description = "List of EC2 instances with their details"
  value = [for i in range(2) : {
    id         = aws_instance.main[i].id
    private_ip = aws_instance.main[i].private_ip
    public_ip  = aws_eip.main[i].public_ip
  }]
}

output "instance_ids" {
  description = "List of EC2 instance IDs"
  value       = aws_instance.main[*].id
} 