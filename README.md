# Procedures From Task 0 to Task 7
Background:
My host machine OS is Windows 11.

Task0 Install a ubuntu 18.04 server 64-bit:
 1. Download virtualbox from https://www.virtualbox.org/ and download ubuntu iso image from http://releases.ubuntu.com/18.04/.  The one I was using is http://releases.ubuntu.com/18.04/ubuntu-18.04.6-desktop-amd64.iso .
 2. Create new virtual machine called demo with 4GB memory, 32 GB storage and 4vcpus.  Start VM with the downloaded iso image and install ubuntu system followed by the instruction. We will create a system user with password at the end.
 3. After installation, in the terminal, install ssh server on ubuntu by running a few commands: `sudo apt update`, `sudo apt install openssh-server`, `sudo systemctl status ssh`.
 4. Configure firewall to open ssh port on server with command `sudo ufw allow ssh`
 5. Configure network settings of the VM in virtual box.  Choose NAT network adapter and add port forwarding rules in advanced section.


| Name | Protocol | Host Port | Guest Port |
|--|--|--|--|
| ssh | TCP | 22222 | 22 |
| gitlab | TCP | 28080 | 80 |
| app1 | TCP | 28081 | 8081 |
| app2 | TCP | 28082 | 8082 |
| app1-k8s | TCP | 31080 | 31080 |
| app2-k8s | TCP | 31081 | 31081 |

Task1 Update system:

 1. ssh to VM from my host machine with command `ssh xqian@localhost -p 22222`, input the password of the user xqian.
 2. upgrade the system to the latest compatible kernel with commands: `sudo apt-get update` and `sudo apt-get dist-upgrade`

Task2 Install gitlab-ce version in the host:

 1. Install and configure the necessary dependencies with command `sudo apt-get install -y curl openssh-server ca-certificates tzdata perl`
 2. Install Postfix to send notification emails with command `sudo apt-get install -y postfix`
 3. Add gitlab package repository `curl -sS https://packages.gitlab.com/install/repositories/gitlab/gitlab-ce/script.deb.sh | sudo bash`
 4. Install gitlab package `sudo EXTERNAL_URL="http://127.0.0.1" apt-get install gitlab-ce`
 5. After installation is done, gitlab service is accessible from host machine with link `http://127.0.0.1:28080`

Task3 Create a demo project in gitlab:

 1. Log into gitlab with username `root` and password (password is stored in file /etc/gitlab/initial_root_password).
 2. Click plus button on right top of gitlab page and select `New group`. Give `demo` as name of the group and make private as visibility level. Then click create group.
 3. In the group page, click `New project` button and name the project as `go-web-hello-world`
 4. Install git cli on VM `sudo apt install git` and configure git with commands `git config --global user.name "Xueqian Wang"` and `git config --global user.email "xqianwang2015@gmail.com"`
 5. Clone the project `git clone git@127.0.0.1:demo/go-web-hello-world.git` and cd into project `cd go-web-hello-world.git`.
 6. Create new folder `go-web` and create a new file called main.go `vi main.go` under `go-web` and write the golang code for the web server
 ```
    package main

    import (
        "fmt"
        "net/http"
    )

    func main() {
        http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
            fmt.Fprintf(w, "Go Web Hello World!\n")
        })

        http.ListenAndServe(":8081", nil)
    }
 ```
 7. Check in code with commands `git add .`, `git commit -m "Added golang web hello world example code"` and `git push`.

Task4 build the app and expose ($ go run) the service to 28081 port:
 1. Install golang 1.18 with commands `curl -LO https://go.dev/dl/go1.18beta1.linux-amd64.tar.gz` and `sudo tar -C /usr/local -xzf go1.18beta1.linux-amd64.tar.gz`. Edit file `~/.bashrc` and add a few commands: `export GOROOT=/usr/local/go`, `export GOPATH=$HOME/go` and `export PATH=$GOPATH/bin:$GOROOT/bin:$PATH`. Then we execute commands by running `source ~/.bashrc`.
 2. Under folder `go-web`, run web server `go run main.go` and on the host machine, we can verify if it is working through browser `http://localhost:28081` or calling curl command `curl -XGET http://localhost:28081`. "Go Web Hello World!" should be shown on webpage or terminal.
 3. Initiate go module `go mod init demo/goweb && go mod tidy`
 4. Push go module file to repo `git add go.mod`, `git commit -m "Added module file"` and `git push`

Task5 Install docker:

 1. Setup repository with commands `sudo apt-get update` and `sudo apt-get install ca-certificates curl gnupg lsb-release`
 2. Add docker gpg key `curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg`
 3. Setup stable repository
 ```
 echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
 ```
 4. Install docker engine `sudo apt-get update` and `sudo apt-get install docker-ce docker-ce-cli containerd.io`

Task6 Run the app in container:
 1. Write a Dockerfile with code in project directory:
 ```
    FROM golang:1.18

    WORKDIR /usr/src/app

    COPY ./go-web/* ./
    RUN go build -v -o /usr/local/bin/app ./
    EXPOSE 8081

    CMD ["app"]
 ```
 2. Build docker image `sudo docker build -t xqian/go-web-hello-world:v0.1 .`
 3. Run the app with command `sudo docker run -d -p 28082:8081 xqian/go-web-hello-world:v0.1`
 4. Verify if it's working by running command `curl -XGET http://localhost:28082` on VM. Should be able to see string "Go Web Hello World!"
 5. Check in the Dockerfile into gitlab `git add Dockerfile`, `git commit -m "Add Dockerfile"` and `git push`

Task7 push image to dockerhub:
 1. Log into docker hub `sudo docker login` and input username and password.
 2. Push docker image to docker hub `sudo docker push xqian/go-web-hello-world:v0.1`

Task8 Publish procesures to repo
 1. Publish README.md file to repo `git add README.md`, `git commit -m "Add README.md"` and `git push`

# Procedures for installing kubernetes with kubeadm
 1. Add Kubernetes GPG key: `sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg \
  https://packages.cloud.google.com/apt/doc/apt-key.gpg`
  2. Add Kubernetes apt repository: `echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list`
  3. Update apt package index, install kubelet, kubeadm and kubectl: `sudo apt-get update`, `sudo apt-get install -y kubelet kubeadm kubectl` and prevent them from being updated automatically `sudo apt-mark hold kubelet kubeadm kubectl`
  4. Configure docker for kubeadm, otherwise installation will be failed:
  ```
  # Configure docker to use overlay2 storage and systemd

  sudo mkdir -p /etc/docker

  cat <<EOF | sudo tee /etc/docker/daemon.json
  {
    "exec-opts": ["native.cgroupdriver=systemd"],
    "log-driver": "json-file",
    "log-opts": {"max-size": "100m"},
    "storage-driver": "overlay2"
  }
  EOF

  # Restart docker to load new configuration
  sudo systemctl restart docker
  # Add docker to start up programs
  sudo systemctl enable docker
  # Allow current user access to docker command line
  sudo usermod -aG docker $USER
  ```
  5. Disable swap, otherwise preflight check will be failed:
  ```
  # See if swap is enabled
  swapon --show
  # Turn off swap
  sudo swapoff -a
  # Disable swap completely
  sudo sed -i -e '/swap/d' /etc/fstab
  ```
  6. Create cluster: `sudo kubeadm init --pod-network-cidr=10.128.0.0/16`

  7. After installation is done, we should be able to configure kubectl now:
  ```
  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config
  ```
  8. Due to single node cluster, our node needs to be untainted to allow pod to be scheduled to the node: `kubectl taint nodes --all node-role.kubernetes.io/master-`
  9. Install CNI plugin with flannel; `kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml`
  10. Under project root directory, create new folder called `kubernetes` and copy admin.conf file in the folder:
  ```
  mkdir kubernetes
  #Copy file to project directory
  sudo cp /etc/kubernetes/admin.conf ./kubernetes/admin.conf
  #Change permission of the file
  sudo chown $(id -u):$(id -g) ./admin.conf
  #Check in file to repo
  git add admin.conf
  git commit -m "Add admin.conf file"
  git push
  ```
# Deploy the hello world in k8s with nodePort 31080
 1. Under `kubernetes` folder, create deployment yaml file with k8s Deployment and Service resource:
 ```
 apiVersion: apps/v1
kind: Deployment
metadata:
  name: go-web-example
  labels:
    app: go-web-example
spec:
  replicas: 1
  selector:
    matchLabels:
      app: go-web-example
  template:
    metadata:
      labels:
        app: go-web-example
    spec:
      containers:
      - name: go-web-example
        image: xqian/go-web-hello-world:v0.1
        ports:
        - containerPort: 8081

---
apiVersion: v1
kind: Service
metadata:
  name: go-web
spec:
  type: NodePort
  selector:
    app: go-web-example
  ports:
    - protocol: TCP
      port: 8081
      targetPort: 8081
      nodePort: 31080

 ```
 2. Create deployment  and service `kubectl apply -f deployment.yaml`

 3. Verify work on host machine `curl -XGET http://localhost:31080` and should be able to see "Go Web Hello World!"

 4. Publish deployment file to repo: `git add deployment.yaml`, `git commit -m "Add deployment file"` and `git push`

# Deploy dashboard and generate token for login
 1. Deploy dashboard `kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.5.0/aio/deploy/recommended.yaml`

 2. Patch dashboard service to use nodeport with port 31081 `kubectl --namespace kubernetes-dashboard patch svc kubernetes-dashboard -p '{"spec": {"type": "NodePort", "ports": [{"port": 443, "targetPort": 443, "nodePort": 31081}]}}'`

 3. Under `kubernetes` folder, create a service account and cluste role binding for user with dashboard-user.yaml
 ```
 apiVersion: v1
 kind: ServiceAccount
 metadata:
   name: admin-user
   namespace: kubernetes-dashboard
 ---
 apiVersion: rbac.authorization.k8s.io/v1
 kind: ClusterRoleBinding
 metadata:
   name: admin-user
 roleRef:
   apiGroup: rbac.authorization.k8s.io
   kind: ClusterRole
   name: cluster-admin
 subjects:
 - kind: ServiceAccount
   name: admin-user
   namespace: kubernetes-dashboard
 ```
 4. Create Service Account and ClusterRoleBinding `kubectl apply -f dashboard-user.yaml`

 5. Get token from service account `kubectl -n kubernetes-dashboard get secret $(kubectl -n kubernetes-dashboard get sa/admin-user -o jsonpath="{.secrets[0].name}") -o go-template="{{.data.token | base64decode}}"`

 6. Access to dashboard from host machine with url "https://localhost:31081/". Choose Token field and copy the token and paste it and then click sign in.
 7. Check in dashboard-user.yaml and publish to repo. `git add .` and `git commit -m "Added dashboard-user.yaml for creating user"` and `git push`

# Publish work to my github (https://github.com/xqianwang/go-web-hello-world)
 1. Add ssh pub key to my github account
 2. Create new project called "go-web-hello-world" and clone it in VM.
 3. Copy all work from gitlab project to github project
 4. Publish work `git add .`, `git commit -m "Add all work"` and `git push`
