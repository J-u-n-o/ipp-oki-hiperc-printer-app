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




For debugging

/usr/local/bin/docker-entrypoint.sh strace -f -s 4096 -e trace=execve,execveat -o /tmp/printer-trace.log legacy-printer-app -o log-level=debug server



```
services:
  ipp-oki-hiperc-printer-app:
    image: ghcr.io/j-u-n-o/ipp-oki-hiperc-printer-app:latest
    container_name: ipp-oki-hiperc-printer-app
    command:
      - strace
      - -f
      - -s
      - "4096"
      - -e
      - trace=execve,execveat
      - -o
      - /tmp/printer-trace.log
      - legacy-printer-app
      - server
    hostname: oki-c5800
    # Or with domain
    domainname: my.dns.org
    dns:
      - 8.8.8.8
    environment:
      - UID=1234
      - GID=1234
      - TZ=Europe/Amsterdam
    # Linux Capabilities configuration
    cap_add:
      - NET_BIND_SERVICE
      - SYS_PTRACE
    volumes:
      - /host/container/ipp-oki-hiperc-printer-app/pappl:/var/lib/legacy-printer-app
      - /host/container/ipp-oki-hiperc-printer-app/spool:/var/spool/legacy-printer-app
      # Ensure you mount the host system's Let's Encrypt directory completely to handle nested symlinks
      - /host/container/letsencrypt/config/etc/letsencrypt:/etc/letsencrypt:ro
      # Target the explicit /ssl/ subfolder inside your config mount path
      - /host/container/letsencrypt/config/etc/letsencrypt/live/my.dns.org/privkey.pem:/var/lib/legacy-printer-app/ssl/oki.juno.ddnss.org.key:ro
      - /host/container/letsencrypt/config/etc/letsencrypt/live/my.dns.org/fullchain.pem:/var/lib/legacy-printer-app/ssl/oki.juno.ddnss.org.crt:ro
    restart: always
    networks:
      mymacvlan:
        ipv4_address: 192.168.172.208
        mac_address: 12:34:56:78:ab:cd
    working_dir: /var/lib/legacy-printer-app
networks:
  mymacvlan:
    external: true
```

```
# Sets the standard HTTP listening port
# server-port=80
# Force the specific FQDN across the entire web engine
server-hostname=my.dns.org
# server-name=my.dns.org
# Set back to the explicit FQDN to stop the framework from defaulting to .local discovery
listen-hostname=my.dns.org
# listen-hostname=*
# dns-sd-name=my.dns.org
server-port=443

# Explicitly disables TLS/HTTPS and leaves standard web access on
# server-options=no-tls

# Enables the web security panel and explicit TLS management pages
server-options=multi-queue,web-interface,raw-socket,web-security,web-tls
```
