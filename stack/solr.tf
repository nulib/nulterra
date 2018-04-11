# SOLR CONTAINERS NEED UNIQUE HOSTNAMES

module "backup_volume" {
  source  = "cloudposse/efs/aws"
  version = "0.3.3"

  namespace          = "${var.stack_name}"
  stage              = "solr"
  name               = "backup"
  aws_region         = "${var.aws_region}"
  vpc_id             = "${module.vpc.vpc_id}"
  subnets            = "${module.vpc.private_subnets}"
  availability_zones = ["${var.azs}"]
  security_groups    = ["${module.solr_container.security_group}"]

  zone_id = "${module.dns.private_zone_id}"

  tags = "${local.common_tags}"
}

data "template_file" "solr_task" {
  template = "${file("task_definitions/solr_server.json")}"
  vars {
    zookeeper_hostname = "zk.${local.private_zone_name}"
  }
}

resource "aws_ecs_task_definition" "solr_task_definition" {
  family = "${var.stack_name}-solr-service"
  container_definitions = "${data.template_file.solr_task.rendered}"
  requires_compatibilities = ["EC2"]

  volume {
    name = "solr-data",
    host_path = "/var/app/solr-data"
  }

  volume {
    name = "solr-backup",
    host_path = "/var/app/solr-backup"
  }

  volume {
    name = "solr-scripts",
    host_path = "/var/app/solr-scripts"
  }
}

module "solr_container" {
  source = "../ecs"
  namespace = "${var.stack_name}"
  name = "solr"
  vpc_id = "${module.vpc.vpc_id}"
  subnets = ["${module.vpc.private_subnets}"]
  instance_type = "t2.medium"
  key_name = "${var.ec2_keyname}"
  instance_port = "8983"
  lb_port = "80"
  health_check_target = "HTTP:8983/solr"
  container_definitions = "${data.template_file.solr_task.rendered}"
  create_task_definition = false
  existing_task_definition_arn = "${aws_ecs_task_definition.solr_task_definition.arn}"
  min_size = 1
  max_size = 3
  desired_capacity = 3
  custom_userdata = <<EOF
yum install -y nfs-utils
mkdir -p /var/app/solr-data /var/app/solr-backup /var/app/solr-scripts
mount -t nfs4 ${module.backup_volume.dns_name}:/ /var/app/solr-backup/
chown 8983:8983 /var/app/solr-data /var/app/solr-backup
echo '#!/bin/bash\n\necho "SOLR_HOST=$(wget -qO- http://169.254.169.254/latest/meta-data/local-hostname)" >> /opt/solr/bin/solr.in.sh' > /var/app/solr-scripts/set_hostname.sh
chmod 0755 /var/app/solr-scripts/set_hostname.sh
EOF
  client_access = [
    {
      from_port = 80
      to_port   = 80
      protocol  = "tcp"
    }
  ]
  tags = "${local.common_tags}"
}

resource "aws_route53_record" "solr" {
  zone_id = "${module.dns.private_zone_id}"
  name    = "solr.${local.private_zone_name}"
  type    = "A"

  alias {
    name                   = "${module.solr_container.lb_endpoint}"
    zone_id                = "${module.solr_container.lb_zone_id}"
    evaluate_target_health = true
  }
}
