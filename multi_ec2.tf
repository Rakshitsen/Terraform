resource "aws_instance" "aws_multi_instance" {
  ami = "ami-071226ecf16aa7d96"
  count = 3
  key_name        = "us-east-1"
  instance_type = "t2.micro"
  vpc_security_group_ids = ["default","launch-wizard-7"]
  tags = {
    Name = "demoinstnce-${count.index}"
  }
}
