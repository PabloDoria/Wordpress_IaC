terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "2.13.0"
    }
  }
}

provider "docker" {
  host = "unix:///var/run/docker.sock"
}

resource "docker_network" "wp_network" {
  name = "wp_network"
}

resource "docker_image" "mysql" {
  name = "mysql:5.7"
}

resource "docker_container" "mysql" {
  image = docker_image.mysql.latest
  name  = "mysql"
  ports {
    internal = 3306
    external = 3306
  }
  env = [
    "MYSQL_ROOT_PASSWORD=rootpassword",
    "MYSQL_DATABASE=wordpress",
    "MYSQL_USER=wpuser",
    "MYSQL_PASSWORD=wppassword"
  ]
  networks_advanced {
    name = docker_network.wp_network.name
  }
}

resource "docker_image" "wordpress" {
  name = "wordpress:latest"
}

resource "docker_container" "wordpress" {
  image = docker_image.wordpress.latest
  name  = "wordpress"
  ports {
    internal = 80
    external = 8080
  }
  env = [
    "WORDPRESS_DB_HOST=mysql:3306",
    "WORDPRESS_DB_NAME=wordpress",
    "WORDPRESS_DB_USER=wpuser",
    "WORDPRESS_DB_PASSWORD=wppassword"
  ]
  networks_advanced {
    name = docker_network.wp_network.name
  }
}
