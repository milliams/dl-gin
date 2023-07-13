terraform {
 required_version = ">= 0.14.0"
 required_providers {
   openstack = {
     source  = "terraform-provider-openstack/openstack"
     version = "~> 1.52"
   }
 }
}

provider "openstack" {
 user_name   = ""
 #password = "..."  # password OR the two application_credential_* settings
 application_credential_name = ""
 application_credential_secret = ""
 tenant_name = "demo"
 auth_url    = "http://api.dl.acrc.bris.ac.uk:5000"
}

data "openstack_images_image_v2" "rocky_9" {
  name        = "Rocky-9.2"
  most_recent = true
}

data "openstack_compute_flavor_v2" "m1_medium" {
  name = "m1.medium"
}

data "template_file" "user_data" {
  template = file("cloud-init.yaml")
}

resource "openstack_compute_instance_v2" "basic" {
  name            = "matt-tf-test"
  flavor_id       = data.openstack_compute_flavor_v2.m1_medium.id
  key_pair        = "harold"
  security_groups = ["default"]
  user_data       = data.template_file.user_data.rendered
  
  block_device {
    uuid                  = data.openstack_images_image_v2.rocky_9.id
    source_type           = "image"
    volume_size           = 40
    boot_index            = 0
    destination_type      = "volume"
    delete_on_termination = true
  }

  network {
    name = "demo-vxlan"
  }
}

resource "openstack_compute_floatingip_v2" "floatip_1" {
  pool = "external"
}

resource "openstack_compute_floatingip_associate_v2" "fip_1" {
  floating_ip = openstack_compute_floatingip_v2.floatip_1.address
  instance_id = openstack_compute_instance_v2.basic.id
}

output "ip" {
 value = openstack_compute_floatingip_v2.floatip_1.address
}
