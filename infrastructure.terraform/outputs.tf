
output "recorder_instance_public_ip" {
  value       = aws_eip.recorder_eip.public_ip
  description = "Публичный IP-адрес сервера"
}

output "ssh_user" {
  value = "ubuntu"
  description = "Пользователь, под которым следует подключаться к серверу"
}
