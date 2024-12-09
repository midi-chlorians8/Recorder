data "aws_vpc" "default" {
  default = true
}

resource "aws_security_group" "allow_all_inbound" {
  name        = "recorder-allow-all-inbound"
  description = "Allow all inbound traffic"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] # Разрешаем всем, не безопасно
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}