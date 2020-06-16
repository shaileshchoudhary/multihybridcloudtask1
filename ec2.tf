provider "aws" {
  region = "ap-south-1"
  profile = "terrauser"
}

//Generating Key pair
resource "tls_private_key" "key-pair" {
algorithm = "RSA"
}

resource "aws_key_pair" "webkey" {

depends_on = [ tls_private_key.key-pair ,]

key_name = "accesskey"
public_key = tls_private_key.key-pair.public_key_openssh


}

//create aws security groups
resource "aws_security_group" "allow_web" {
  name        = "allow_web"

  ingress {
    description = "Allow Web Service"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Allow Web Service"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "allow_web"
  }
}

//launch instance with above security_groups and key-pair
resource "aws_instance" "webconf" {
  depends_on = [ aws_key_pair.webkey,]
  ami      = "ami-0447a12f28fddb066"
  instance_type = "t2.micro"
  key_name = aws_key_pair.webkey.key_name
  security_groups = ["allow_web"]

  connection {
    type = "ssh"
    user = "ec2-user"
    private_key = tls_private_key.key-pair.private_key_pem
    host  = aws_instance.webconf.public_ip
  }
  provisioner "remote-exec" {
    inline = [
      "sudo yum install httpd  php git -y",
      "sudo systemctl restart httpd",
      "sudo systemctl enable httpd",
    ]
  }
  
  tags = {
    Name = "webos1"
  } 

}
resource "aws_ebs_volume" "ebsvol" {
  availability_zone = aws_instance.webconf.availability_zone
  size              = 1
  tags = {
    Name = "ebsvol"
  }
}


resource "aws_volume_attachment" "ebs_att" {
  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.ebsvol.id
  instance_id = aws_instance.webconf.id
  force_detach = true
}


resource "null_resource" "nullremote3"  {
depends_on = [
    aws_volume_attachment.ebs_att,
  ]
  connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key = tls_private_key.key-pair.private_key_pem
    host     = aws_instance.webconf.public_ip
  }

provisioner "remote-exec" {
    inline = [
      "sudo mkfs.ext4  /dev/xvdh",
      "sudo mount  /dev/xvdh  /var/www/html",
      "sudo rm -rf /var/www/html/*",
      "sudo git clone https://github.com/shaileshchoudhary/multihybridtask1code.git /var/www/html/"
    ]
  }
}
