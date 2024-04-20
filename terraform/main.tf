terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.13"
}

# Провайдер

provider "yandex" {
  token        = var.yc_token
  cloud_id     = var.yc_cloud_id
  folder_id    = var.yc_folder_id
}

# Создание сети

resource "yandex_vpc_network" "network1" {
  name = "network1"
}

# Создание подсетей

resource "yandex_vpc_subnet" "subnet1" {
  name = "subnet1"
  zone = "ru-central1-a"
  network_id = yandex_vpc_network.network1.id
  v4_cidr_blocks = ["10.128.0.0/24"]
}
resource "yandex_vpc_subnet" "subnet2" {
  name = "subnet2"
  zone = "ru-central1-b"
  network_id = yandex_vpc_network.network1.id
  v4_cidr_blocks = ["10.129.0.0/24"]
}

# nginx servers

resource "yandex_compute_instance" "nginxserver1" {
  name = "nginxserver1"
  zone = "ru-central1-a"
  
  resources{
    cores = 2
    core_fraction = 20
    memory = 4
  }

  boot_disk{
    initialize_params {
      image_id = "fd8ne6e3etbrr2ve9nlc"
      size = 10
      description = "boot disk for nginx_server1"
    }
  }
  network_interface {
    subnet_id = yandex_vpc_subnet.subnet1.id
    nat = true
  }
  metadata = {
    user-data = "${file("./meta.txt")}"
  }
}

resource "yandex_compute_instance" "nginxserver2" {
  name = "nginxserver2"
  zone = "ru-central1-b"
  
  resources{
    cores = 2
    core_fraction = 20
    memory = 4
  }

  boot_disk{
    initialize_params {
      image_id = "fd8ne6e3etbrr2ve9nlc"
      size = 10
      description = "boot disk for nginx_server1"
    }
  }
  network_interface {
    subnet_id = yandex_vpc_subnet.subnet2.id
    nat = true
  }
  metadata = {
    user-data = "${file("./meta.txt")}"
  }
}


# zabbix

resource "yandex_compute_instance" "zabbix"{
  name = "zabbix"
  zone = "ru-central1-a"
  resources{
    cores = 4
    core_fraction = 20
    memory = 4
  }

  boot_disk{
    initialize_params {
      image_id = "fd8ne6e3etbrr2ve9nlc"
      size = 10
      description = "boot disk for zabbix"
    }
  }
  network_interface {
    subnet_id = yandex_vpc_subnet.subnet1.id
    nat = true
  }
  metadata = {
    user-data = "${file("./meta.txt")}"
  }
}

# elasticsearch

resource "yandex_compute_instance" "elastic"{
  name = "elastic"
  zone = "ru-central1-a"
  
  resources{
    cores = 4
    core_fraction = 20
    memory = 8
  }

  boot_disk{
    initialize_params {
      image_id = "fd8ne6e3etbrr2ve9nlc"
      size = 20
      description = "boot disk for elastic"
    }
  }
  network_interface {
    subnet_id = yandex_vpc_subnet.subnet1.id
    nat = true
  }
  metadata = {
    user-data = "${file("./meta.txt")}"
  }
}

# kibana

resource "yandex_compute_instance" "kibana"{
  name = "kibana"
  zone = "ru-central1-a"
  
  resources{
    cores = 4
    core_fraction = 20
    memory = 8
  }

  boot_disk{
    initialize_params {
      image_id = "fd8ne6e3etbrr2ve9nlc"
      size = 20
      description = "boot disk for kibana"
    }
  }
  network_interface {
    subnet_id = yandex_vpc_subnet.subnet1.id
    nat = true
  }
  metadata = {
    user-data = "${file("./meta.txt")}"
  }
}



#target group

resource "yandex_lb_target_group" "tgtest"{
  name = "tgtest"

  target {
    subnet_id = "${yandex_vpc_subnet.subnet1.id}"
    address = "${yandex_compute_instance.nginxserver1.network_interface.0.ip_address}"
}

  target {
    subnet_id = "${yandex_vpc_subnet.subnet2.id}"
    address = "${yandex_compute_instance.nginxserver2.network_interface.0.ip_address}"
}

}


resource "yandex_lb_network_load_balancer" "foo" {
  name = "my-network-load-balancer"

  listener {
    name = "my-listener"
    port = 80
    external_address_spec {
      ip_version = "ipv4"
    }
  }

  attached_target_group {
    target_group_id = "${yandex_lb_target_group.tgtest.id}"

    healthcheck {
      name = "http"
      http_options {
        port = 80
        path = "/"
      }
    }
  }
}




output "nginx_server1_ip_pub" {
  value = yandex_compute_instance.nginxserver1.network_interface.0.nat_ip_address
}

output "nginx_server2_ip_pub" {
  value = yandex_compute_instance.nginxserver2.network_interface.0.nat_ip_address
}

output "zabbix_ip_pub" {
  value = yandex_compute_instance.zabbix.network_interface.0.nat_ip_address
}

output "elastic_ip" {
  value = yandex_compute_instance.elastic.network_interface.0.nat_ip_address
}

output "kibana_ip" {
  value = yandex_compute_instance.kibana.network_interface.0.nat_ip_address
}


