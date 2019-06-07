resource "google_compute_firewall" "allow-http-nginx-node" {
  name    = "allow-http-nginx-node"
  network = "${google_compute_network.nginx-nodes.name}"

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }
  target_tags = ["nginx-node"]
}

resource "google_compute_network" "nginx-nodes" {
  name = "nginx-nodes"
}

resource "google_compute_instance" "nginx-node" {
  name         = "nginx-node"
  machine_type = "n1-standard-2"
  tags         = ["nginx-node"]
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
    }
  }
  # run bootstrap and installer script when machine is started will carry out the following actions
  # 1. upgrade operating system with latest packages
  # 2. install dependencies for docker-de install
  # 3. install docker-de
  # 4. start a default nginx container and expose on port 80
  # 5. count the frequency of words in the default index.html
  # 6. inject a custom index.html which contains the highest occuring word and count
  # 7. uses systemd to run a basic metric collection command which logs to /var/log/nginx-metrics.log every 10seconds in csv 
  #    format. could then be ingested by more "production-grade" monitoring/logging solutions
  metadata_startup_script = <<SCRIPT
sudo apt-get -y update
sudo apt-get -y upgrade
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

cat << EOF > /etc/systemd/system/docker-metrics.service
[Unit]
Description=Log Metrics
[Service]
Restart=always
RestartSec=10s
ExecStart=/bin/bash -c '/usr/bin/docker stats nginx --no-stream --format {{.MemPerc}},{{.CPUPerc}},{{.MemUsage}},{{.Name}} >> /var/log/nginx-metrics.log 2>&1'
[Install]
WantedBy=multi-user.target
EOF
systemctl enable docker-metrics
systemctl start docker-metrics
SCRIPT

  network_interface {
    # A default network is created for all GCP projects
    network = "${google_compute_network.nginx-nodes.name}"
    access_config {
    }
  }
}