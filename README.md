[![Travis](https://img.shields.io/travis/alexpirine/docker-sshtun.svg)](https://travis-ci.org/alexpirine/docker-sshtun)
[![Docker Automated build](https://img.shields.io/docker/automated/alexpirine/sshtun.svg)](https://hub.docker.com/r/alexpirine/sshtun/)
[![MicroBadger Size](https://img.shields.io/microbadger/image-size/alexpirine/sshtun.svg)](https://hub.docker.com/r/alexpirine/sshtun/)
[![GitHub license](https://img.shields.io/github/license/alexpirine/docker-sshtun.svg)](https://github.com/alexpirine/docker-sshtun/blob/master/LICENSE)

# Long-lived, reliable SSH tunnels

The purpose of this docker image is to provide a secure communication channel between your dockerized app and an external server by establishing a secure SSH tunnel.

It is designed to run in a [pod](https://kubernetes.io/docs/concepts/workloads/pods/pod-overview/) as a _sidecar_ container, providing the desired network resource through the shared loopback interface.

Under the hood, it uses an SSH client pre-configured to detect network issues in less than a minute, controlled by autossh.

## Quickstart

### Configuration

First, you need to generate a key pair for authentication purposes, and add your remote key to the list of known hosts.

You can just copy-paste the following in your working directory:

```shell
mkdir keys
cd keys
ssh-keygen -t rsa -b 2048 -N '' -C sshtun -f id_rsa
touch known_hosts
cat id_rsa.pub
cd ..
```

Append your remote server identity to the `known_hosts` file you just created (copy a line from `~/.ssh/known_hosts` for instance).

Append the public key `id_rsa.pub` you just created to the `authorized_hosts` file of your remote server.

That'is it!

### Test run

You should now be able to use the docker container with the same argument as the standard `ssh` client:

```shell
docker run -ti -v `pwd`/keys:/etc/ssh/keys alexpirine/sshtun remote-user@remote-server
```

* `-ti` lets you create an interactive shell
* ``-v `pwd`/keys:/etc/ssh/keys`` mounts your `keys` folder into the Docker container, so it can read `known_hosts` and `id_rsa` files.

You can of course create tunnels like this one:

```
docker run -v `pwd`/keys:/etc/ssh/keys alexpirine/sshtun -NTR 80000:127.0.0.1:8080 remote-user@remote-server
```

This will forward all connections on the _remote-server_ host to `localhost:8000` to `localhost:8080` inside the _container_ host.

If you want to better understand _local_ (`-L`) and _remote_ (`-R`) port forwarding, take a look at the [ssh man page](https://linux.die.net/man/1/ssh). You might especially want to set `GatewayPorts clientspecified` in the ssh server config of the remote server, if you use remote port forwarding which doesn't bind to the loopback interface.

## Example: remote port forwarding inside a Kubernetes pod

The following example will forward all TCP connections to `localhost:8000` on _remote-host_ to the TCP port 8888 of the _your-app_ container.

```yaml
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: your-app
  labels:
    app: your-app
spec:
  selector:
    matchLabels:
      app: your-app
  replicas: 1 # keep in mind you cannot bind more than once to the same port/interface
  template:
    metadata:
      labels:
        app: your-app
    spec:
      containers:
      - name: your-app
        image: your-org/your-app
        command: ["./your-service.py"]
        ports:
        - containerPort: 8888
      - name: sshtun
        image: alexpirine/sshtun
        args: ["-NTR", "8000:127.0.0.1:8888", "remote-user@remote-host"]
        volumeMounts:
          - name: sshtun-keys
            mountPath: /etc/ssh/keys
      volumes:
        - name: sshtun-keys
          secret:
            secretName: sshtun-keys
            defaultMode: 0400
```
