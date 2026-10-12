output "instance_id" {
  value = aws_instance.jenkins.id
}

output "public_ip" {
  value = aws_instance.jenkins.public_ip
}

output "jenkins_url" {
  value = "http://${aws_instance.jenkins.public_ip}:8080"
}

output "app_url" {
  value = "http://${aws_instance.jenkins.public_ip}:8000"
}

output "green_preview_url" {
  value = "http://${aws_instance.jenkins.public_ip}:8001"
}

output "ansible_ssm_bucket" {
  value = aws_s3_bucket.ansible_ssm.bucket
}
