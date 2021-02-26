# Kubernetes

## ``kubeadm init``

````bash
sudo kubeadm init --apiserver-advertise-address 192.168.56.35 --pod-network-cidr=10.244.0.0/16
````

### post init

````bash
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
````

## flannel

```bash
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
````
