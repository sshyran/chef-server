module "chef_server" {
  source = "../../modules/aws_instance"

  aws_profile       = "${var.aws_profile}"
  aws_region        = "${var.aws_region}"
  aws_vpc_name      = "${var.aws_vpc_name}"
  aws_department    = "${var.aws_department}"
  aws_contact       = "${var.aws_contact}"
  aws_ssh_key_id    = "${var.aws_ssh_key_id}"
  aws_instance_type = "${var.aws_instance_type}"
  enable_ipv6       = "${var.enable_ipv6}"
  platform          = "${var.platform}"
  build_prefix      = "${var.build_prefix}"
  name              = "${var.scenario}-${var.enable_ipv6 ? "ipv6" : "ipv4"}-${var.platform}"
}

resource "null_resource" "chef_server_fips" {
  connection {
    type = "ssh"
    user = "${module.chef_server.ssh_username}"
    host = "${module.chef_server.public_ipv4_dns}"
  }

  # enable fips mode
  provisioner "remote-exec" {
    inline = [
      "set -evx",
      "echo -e '\nFIPS STATUS:\n'",
      "sudo sysctl crypto.fips_enabled",
      "echo -e '\nBEGIN ENABLING FIPS MODE\n'",
      "sudo yum install -y dracut-fips",
      "sudo dracut -f",
      "if [ -f /etc/default/grub ]; then sudo sed -i '/GRUB_CMDLINE_LINUX/{s/=\"/=\"fips=1 /;}' /etc/default/grub; sudo grub2-mkconfig -o /boot/grub2/grub.cfg; else sudo sed -i '/^\t.*kernel.*boot/{s/$/ fips=1/;}' /boot/grub/grub.conf; fi",
      "echo -e '\nEND ENABLING FIPS MODE\n'",
    ]
  }

  # reboot instance for fips to take effect
  provisioner "local-exec" {
    command = "AWS_PROFILE=${var.aws_profile} AWS_DEFAULT_REGION=${var.aws_region} aws ec2 reboot-instances --instance-ids ${module.chef_server.id}; sleep 60;"
  }
}

resource "null_resource" "chef_server_config" {
  depends_on = ["null_resource.chef_server_fips"]

  connection {
    type = "ssh"
    user = "${module.chef_server.ssh_username}"
    host = "${module.chef_server.public_ipv4_dns}"
  }

  provisioner "file" {
    source      = "${path.module}/files/chef-server.rb"
    destination = "/tmp/chef-server.rb"
  }

  provisioner "file" {
    source      = "${path.module}/../../../common/files/dhparam.pem"
    destination = "/tmp/dhparam.pem"
  }

  # install chef-server
  provisioner "remote-exec" {
    inline = [
      "set -evx",
      "echo -e '\nFIPS STATUS:\n'",
      "sudo sysctl crypto.fips_enabled",
      "echo -e '\nBEGIN INSTALL CHEF SERVER\n'",
      "curl -vo /tmp/${replace(var.upgrade_version_url, "/^.*\\//", "")} ${var.upgrade_version_url}",
      "sudo ${replace(var.upgrade_version_url, "rpm", "") != var.upgrade_version_url ? "rpm -U" : "dpkg -iEG"} /tmp/${replace(var.upgrade_version_url, "/^.*\\//", "")}",
      "sudo chown root:root /tmp/chef-server.rb",
      "sudo chown root:root /tmp/dhparam.pem",
      "sudo mv /tmp/chef-server.rb /etc/opscode",
      "sudo mv /tmp/dhparam.pem /etc/opscode",
      "sudo chef-server-ctl reconfigure --chef-license=accept",
      "sleep 120",
      "echo -e '\nEND INSTALL CHEF SERVER\n'",
    ]
  }

  # add user + organization
  provisioner "remote-exec" {
    script = "${path.module}/../../../common/files/add_user.sh"
  }
}

resource "null_resource" "chef_server_test" {
  depends_on = ["null_resource.chef_server_config"]

  connection {
    type = "ssh"
    user = "${module.chef_server.ssh_username}"
    host = "${module.chef_server.public_ipv4_dns}"
  }

  # run smoke test
  provisioner "remote-exec" {
    script = "${path.module}/../../../common/files/test_chef_server-smoke.sh"
  }

  # install push jobs addon
  provisioner "remote-exec" {
    script = "${path.module}/../../../common/files/install_addon_push_jobs.sh"
  }

  # test push jobs addon
  provisioner "remote-exec" {
    script = "${path.module}/../../../common/files/test_addon_push_jobs.sh"
  }

  # install chef manage addon
  provisioner "remote-exec" {
    script = "${path.module}/../../../common/files/install_addon_chef_manage.sh"
  }

  # run pedant test
  provisioner "remote-exec" {
    script = "${path.module}/../../../common/files/test_chef_server-pedant.sh"
  }

  # run psql test
  provisioner "remote-exec" {
    script = "${path.module}/../../../common/files/test_psql.sh"
  }

  # run gather-logs test
  provisioner "remote-exec" {
    script = "${path.module}/../../../common/files/test_gather_logs.sh"
  }
}
