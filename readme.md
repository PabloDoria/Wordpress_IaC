# Despliegue de WordPress con Docker, Terraform y Ansible

Nombre: Pablo Torres Doria 3003910

Video: https://youtu.be/Htj_x404UJc

## Descripción

Este proyecto proporciona un entorno automatizado para el despliegue de un sitio web WordPress utilizando contenedores Docker. La infraestructura se define utilizando Terraform y la configuración de los contenedores se gestiona con Ansible. El entorno incluye un contenedor para MySQL como base de datos y otro contenedor para WordPress.

## Requisitos

Para ejecutar este proyecto, necesitas tener instaladas las siguientes herramientas:

- [Docker](https://www.docker.com/get-started)
- [Terraform](https://www.terraform.io/downloads)
- [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html)
- [JQ](https://stedolan.github.io/jq/download/) (para manipular JSON en shell)

## Instrucciones de Uso

### 1. Clonar el repositorio

```bash
git clone https://github.com/tu-usuario/wordpress_deploy.git
cd wordpress_deploy
```

### 2. Ejecutar Ansible

Ansible se utiliza para gestionar la configuración de los contenedores una vez que están desplegados.

`ansible-playbook -i inventory.ini playbook.yml`

### 3. Acceder a WordPress

Una vez que el despliegue esté completo, puedes acceder a tu sitio web de WordPress navegando a `http://localhost:8080`.

## Archivos del Proyecto

### Terraform

main.tf: Define la infraestructura de Docker incluyendo la red, las imágenes y los contenedores.
    - Ejemplo de main.tf:

```bash
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

resource "docker_image" "wordpress" {
  name = "wordpress:latest"
}

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
```

### Ansible

playbook.yml: Define las tareas necesarias para configurar los contenedores de MySQL y WordPress.
Ejemplo de playbook.yml:

```bash
---
- hosts: localhost
  tasks:
    - name: Ensure Docker is installed
      apt:
        name: docker.io
        state: present
        update_cache: yes

    - name: Ensure Docker is running
      service:
        name: docker
        state: started
        enabled: yes

    - name: Create Docker network
      community.docker.docker_network:
        name: wp_network

    - name: Deploy MySQL container
      community.docker.docker_container:
        name: mysql
        image: mysql:5.7
        state: started
        ports:
          - "3306:3306"
        env:
          MYSQL_ROOT_PASSWORD: rootpassword
          MYSQL_DATABASE: wordpress
          MYSQL_USER: wpuser
          MYSQL_PASSWORD: wppassword
        networks:
          - name: wp_network

    - name: Get MySQL container IP address
      shell: "docker inspect mysql | jq -r '.[0].NetworkSettings.Networks.wp_network.IPAddress'"
      register: mysql_ip_address
      changed_when: false

    - name: Debug MySQL IP
      debug:
        var: mysql_ip_address.stdout

    - name: Deploy WordPress container
      community.docker.docker_container:
        name: wordpress
        image: wordpress:latest
        state: started
        ports:
          - "8080:80"
        env:
          WORDPRESS_DB_HOST: "{{ mysql_ip_address.stdout }}:3306"
          WORDPRESS_DB_NAME: wordpress
          WORDPRESS_DB_USER: wpuser
          WORDPRESS_DB_PASSWORD: wppassword
        networks:
          - name: wp_network

    - name: Install dnsutils in WordPress container
      community.docker.docker_container_exec:
        container: wordpress
        command: /bin/bash -c "apt-get update && apt-get install -y dnsutils"

    - name: Install mariadb-client in WordPress container
      community.docker.docker_container_exec:
        container: wordpress
        command: /bin/bash -c "apt-get update && apt-get install -y mariadb-client"
```

### Justificación de la Implementación

Este enfoque se eligió para automatizar completamente el despliegue de WordPress con una base de datos MySQL. Al utilizar Terraform y Ansible juntos, se asegura que la infraestructura se despliegue de manera coherente y reproducible, minimizando errores humanos y facilitando el proceso de configuración.
