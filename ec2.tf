resource "aws_instance" "dev" {
  ami             = "ami-084568db4383264d4"
  instance_type   = "t2.micro"
  key_name        = "us-east-1"
  count          = 3

  vpc_security_group_ids = ["launch-wizard-7", "default"]

  tags = {
    Name = "test-vm"
  }
}

