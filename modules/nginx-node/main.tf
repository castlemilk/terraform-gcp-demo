resource "google_compute_instance" "nginx-node" {
  name         = "nginx-node"
  machine_type = "n1-standard-2"
  tags = [ "nginx-node"]
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
    }
  }

  metadata_startup_script = <<SCRIPT
sudo apt-get -y update
sudo apt-get -y install \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg2 \
    software-properties-common
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo apt-key add -
sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/debian \
   $(lsb_release -cs) \
   stable"
sudo apt-get -y update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io
sudo systemctl enable docker
sudo systemctl start docker
while (! sudo docker stats --no-stream ); do
  echo "Waiting for Docker to launch..."
  sleep 1
done
sleep 30
sudo docker run -d --name nginx -p 80:80 nginx  
while [ $(curl -sL -o /dev/null -w "%%{http_code}" http://localhost) != "200" ]; do printf "."; sleep 5; done
mkdir -p html
echo $(curl localhost | sed -e 's/[^[:alpha:]]/ /g' | tr '\n' " " |  tr -s " " | tr " " '\n'| tr 'A-Z' 'a-z' | sort | uniq -c | sort -nr | nl | head -1 | awk '{print $3,$2}') > html/index.html
sudo docker rm -f nginx
sudo docker run -d --name nginx -v $pwd/html:/usr/share/nginx/html -p 80:80 nginx 
SCRIPT

  network_interface {
    # A default network is created for all GCP projects
    network       = "${google_compute_network.nginx-nodes.name}"
    access_config {
    }
  }
}

resource "google_compute_firewall" "allow-http-nginx-node" {
  name    = "allow-http-nginx-node"
  network = "${google_compute_network.nginx-nodes.name}"

  allow {
    protocol = "tcp"
    ports    = ["80", "22"]
  }
  target_tags = [ "nginx-node"]
}

resource "google_compute_network" "nginx-nodes" {
  name = "nginx-nodes"
}