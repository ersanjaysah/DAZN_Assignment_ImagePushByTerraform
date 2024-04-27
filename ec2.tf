provider "aws" {
  region = "eu-north-1"
}

# create default vpc if one does not exist
resource "aws_default_vpc" "default_vpc" {
  tags = {
    Name = "default vpc"
  }
}

# used here data source to get all availablity zone in region
data "aws_availability_zones" "available_zones" {}

# create default subnet if one does not exist

resource "aws_default_subnet" "default_az1" {
  availability_zone = data.aws_availability_zones.available_zones.names[0]

  tags = {
    Name = "default subnet"
  }
}

# security gp
resource "aws_security_group" "ec2_SG" {
  name        = "docker server sg"
  description = "Allow access port 80 and 22"
  vpc_id      = aws_default_vpc.default_vpc.id

  ingress {
    description = "allow port 22"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "allow port 80"
    from_port   = 80
    to_port     = 80
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
    Name = "docker server sg"
  }
}

# use data source to get a registered ubuntu machine
# Find the latest available AMI that is tagged with Component = ubuntu
# to see all details of amiId
# aws ec2 describe-images --region <eu-west-2> --image-ids <imageId from cattlog>

data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }
}

output "ami_id" {
  value = data.aws_ami.amazon_linux_2
}

# launch the ec2 instance 
resource "aws_instance" "ec2_instance" {
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = "t3.micro"
  subnet_id              = aws_default_subnet.default_az1.id
  vpc_security_group_ids = [aws_security_group.ec2_SG.id]
  key_name               = "mykey"

  tags = {
    Name = "docker server"
  }
}

# an empty resource block
resource "null_resource" "name" {
  # ssh into the ec2 instance
  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file("~/Downloads/mykey.pem")
    host        = aws_instance.ec2_instance.public_ip
  }

  # copying the "dockerhub-password file" for our docker hub account
  # from our computer to ec2 instance 
  provisioner "file" {
    source      = "~/Downloads/my_password.txt"
    destination = "/home/ec2-user/my_password.txt"
  }

  # copy the "Dockerfile" from our computer to ec2 instance 
  provisioner "file" {
    source      = "Dockerfile"
    destination = "/home/ec2-user/Dockerfile"
  }

  provisioner "file" {
    source      = "Day43_HTMLPagePracticeProblem"
    destination = "/home/ec2-user/Day43_HTMLPagePracticeProblem"
  }

  # copy the "build_docker_image.sh" file from our computer to ec2 instance 
  provisioner "file" {
    source      = "build_docker_image.sh"
    destination = "/home/ec2-user/build_docker_image.sh"
  }



  # set permission and run the build_docker_image.sh file
  provisioner "remote-exec" {
    inline = [
      "sudo chmod +x /home/ec2-user/build_docker_image.sh",
      "sh /home/ec2-user/build_docker_image.sh",
    ]
  }

  # wait for ec2 to be created
  depends_on = [aws_instance.ec2_instance]
}

# print the url of the container server
output "container_url" {
  value = join("", ["http://", aws_instance.ec2_instance.public_dns])
}

