data "aws_ami" "centos8" {
  # See http://cavaliercoder.com/blog/finding-the-latest-centos-ami.html
  # https://wiki.centos.org/Cloud/AWS
  most_recent = true

  filter {
    name   = "name"
    values = ["CentOS 8.*"]
  }

  filter {
    name = "architecture"
    values = ["x86_64"]
  }

  owners = ["125523088429"]
}

locals {
  mgmt_hostname = "mgmt"
}

resource "aws_instance" "mgmt" {
  ami           = data.aws_ami.centos8.id
  instance_type = var.management_shape
  vpc_security_group_ids = [aws_security_group.mgmt.id]
  subnet_id = aws_subnet.vpc_subnetwork.id
  associate_public_ip_address = true
  iam_instance_profile = aws_iam_instance_profile.describe_tags.id

  user_data = data.template_file.bootstrap-script.rendered
  key_name = aws_key_pair.ec2-user.key_name

  depends_on = [aws_efs_mount_target.shared, aws_key_pair.ec2-user, aws_route53_record.shared, aws_route.internet_route]

  connection {
    type        = "ssh"
    user        = "centos"
    private_key = file("${path.module}/../../.ssh/id_rsa")
    host        = self.public_ip
  }

  provisioner "file" {
    destination = "/tmp/startnode.yaml"
    content     = data.template_file.startnode-yaml.rendered
  }

  provisioner "file" {
    destination = "/tmp/cluster_control"
    source      = var.cluster_control_dir
  }

  provisioner "file" {
    destination = "/home/centos/aws-credentials.csv"
    content     = <<EOF
[default]
aws_access_key_id = ${aws_iam_access_key.mgmt_sa.id}
aws_secret_access_key = ${aws_iam_access_key.mgmt_sa.secret}
EOF
  }

  tags = {
    Name = local.mgmt_hostname
    cluster = local.cluster_id
  }

  provisioner "remote-exec" {
    when = destroy
    inline = [
      "echo Terminating any remaining compute nodes",
      "if systemctl status slurmctld >> /dev/null; then",
      "sudo -u slurm /usr/local/bin/stopnode \"$(sinfo --noheader --Format=nodelist:10000 | tr -d '[:space:]')\" || true",
      "fi",
      "sleep 5",
      "echo Node termination request completed",
    ]
  }
}

resource "aws_key_pair" "ec2-user" {
  key_name   = "ec2-user-${local.cluster_id}"
  public_key = data.local_file.ssh_public_key.content
}

resource "aws_route53_record" "mgmt" {
  zone_id = aws_route53_zone.cluster.zone_id
  name    = "${local.mgmt_hostname}.${aws_route53_zone.cluster.name}"
  type    = "A"
  ttl     = "300"
  records = [aws_instance.mgmt.private_ip]
}
