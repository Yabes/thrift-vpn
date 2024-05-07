data "aws_instance" "thrift_vpn" {
  depends_on = [aws_autoscaling_group.wg_asg]

  instance_tags = {
    Type = "thrift-vpn"
  }
}
