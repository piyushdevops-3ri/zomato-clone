output "jenkins_server_public_ip" {
  description = "Public IP of Jenkins server"
  value       = aws_instance.jenkins_server.public_ip
}

output "jenkins_url" {
  description = "Jenkins dashboard URL"
  value       = "http://${aws_instance.jenkins_server.public_ip}:8080"
}

output "sonarqube_url" {
  description = "SonarQube dashboard URL"
  value       = "http://${aws_instance.jenkins_server.public_ip}:9000"
}

output "zomato_app_url" {
  description = "Zomato app URL (after pipeline runs)"
  value       = "http://${aws_instance.jenkins_server.public_ip}:3000"
}

output "ssh_command" {
  description = "SSH command to connect to Jenkins server"
  value       = "ssh -i ${var.key_name}.pem ubuntu@${aws_instance.jenkins_server.public_ip}"
}
