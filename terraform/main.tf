terraform {
    required_providers {
        docker = {
        source  = "kreuzwerker/docker"
        version = "2.13.0"
        }
    }
}

# Proveedor de Docker
provider "docker" {
    host = "unix:///var/run/docker.sock"
}

# Recurso para crear una red de Docker
resource "docker_network" "wp_network" {
    name = "wp_network"   
}

# Recurso para la imagen de MySQL
resource "docker_image" "mysql" {
    name = "mysql:5.7"
}

# Recurso para el contenedor de MySQL
resource "docker_container" "mysql" {
    image = docker_image.mysql.latest
    name  = "mysql"
    env = [
        "MYSQL_ROOT_PASSWORD=rootpassword",
        "MYSQL_DATABASE=wordpress",
        "MYSQL_USER=wpuser",
        "MYSQL_PASSWORD=wppassword"
    ]
    networks_advanced {
        name = docker_network.wp_network.name
    }
    ports {
        internal = 3306
        external = 3306
    }
}

# Recurso para la imagen de WordPress
resource "docker_image" "wordpress" {
    name = "wordpress:latest"
}

# Recurso para el contenedor de WordPress
resource "docker_container" "wordpress" {
    image = docker_image.wordpress.latest
    name  = "wordpress"
    env = [
        "WORDPRESS_DB_HOST=mysql:3306",
        "WORDPRESS_DB_NAME=wordpress",
        "WORDPRESS_DB_USER=wpuser",
        "WORDPRESS_DB_PASSWORD=wppassword"
    ]
    networks_advanced {
        name = docker_network.wp_network.name
    }
    ports {
        internal = 80
        external = 8080
    }
}
