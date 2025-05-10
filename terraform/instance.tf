resource "aws_instance" "web" {
  ami                    = var.ami_id[var.region]
  instance_type          = "t3.micro"
  key_name               = aws_key_pair.dove-key.key_name
  vpc_security_group_ids = [aws_security_group.dove_sg.id]
  availability_zone      = var.zone1

  tags = {
    Name    = "Dove_web"
    Project = "Dove"
  }

  provisioner "file" {
    source      = "web.sh"
    destination = "/tmp/web.sh"
  }

  connection {
    type        = "ssh"
    user        = var.web_user
    private_key = file("dovekey")
    host        = self.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/web.sh",
      "sudo /tmp/web.sh"
    ]
  }

  provisioner "local-exec" {
    command = "echo ${self.private_ip} >> private_ips.txt"
  }
}

resource "aws_ec2_instance_state" "web_state" {
  instance_id = aws_instance.web.id
  state       = "running"
}

output "web_public_ip" {
  value = aws_instance.web.public_ip
}

output "web_private_ip" {
  value = aws_instance.web.private_ip
}