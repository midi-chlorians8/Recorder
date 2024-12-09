output "recorder_instance_public_ip" {
  value = aws_instance.recorder_instance.public_ip
  description = "Публичный IP-адрес сервера"
}

output "ssh_user" {
  value = "ubuntu"
  description = "Пользователь, под которым следует подключаться к серверу"
}
