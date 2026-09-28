# IPP Deamon

![Docker Image Size](https://img.shields.io/docker/image-size/J-u-n-o/ipp-oki-hiperc-printer-app)

Docker image for IPP Deamon server published on [Docker Hub](https://hub.docker.com/r/J-u-n-o/ipp-oki-hiperc-printer-app), source on [GitHub](https://github.com/J-u-n-o/ipp-oki-hiperc-printer-app).
Using work from ChatGPT and Gemini.

Thank you.


## Usage

See for configuration:


```sh
docker run -d \
  --name oki-c5800-printer-app \
  --net=host \
  --network docker_macvlan \
  --ip 192.168.2.124 \
  --mac-address 12:34:56:78:90:ab \
  --env PUID=1234 \
  --env PGID=1234  \
  -v /mnt/oki:/var/spool/pappl \
  -v /var/run/dbus:/var/run/dbus \
  --restart unless-stopped \
  ghcr.io/j-u-n-o/oki-c5800-pappl-retrofit:1.0\
```

Because the docker host cannot access its dockers using the macvlan, also use the bridge to allow a second network connection using the docker bridge to have a 'second' port accessible (only) by the docker host/Truenas server.

```
$ sudo docker network inspect bridge
[
    {
        "Name": "bridge",
        "IPAM": {
            "Config": [
                {
                    "Subnet": "172.16.0.0/24",
                    "Gateway": "172.16.0.1"
                }
            ]
        },
```
However setting an fixed/desired ip address for the container is not allowed on the internal bridge, so create a custom bridge:
```
sudo docker network create \
  --driver bridge \
  --subnet 172.16.1.0/24 \
  nut-bridge
```
and so 
```
sudo docker network connect --ip 172.16.1.10 nut-bridge nut-upsd
```

```
]$ sudo docker network inspect nut-bridge
[
    {
        "Name": "nut-bridge",
        },
        "ConfigOnly": false,
        "Containers": {
            "xyz": {
                "IPv4Address": "172.16.1.10/24",
                "IPv6Address": "fdd0:0:0:1::2/64"
            }
        },
    }
]
```
