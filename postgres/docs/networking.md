# Networking Concepts

## Docker Networking

- Docker network concepts
  - Each container runs its own `network namespace` which isolates its network stack from the host and other containers so as to avoid conflicts on IP addresses, routing tables etc
  - Docker uses `veth (Virtual Ethernet interface)` pairs to connect the container to a network bridge (or some network device on host)
  - A `network bridge` acts like a virtual switch that forwards traffic between the container and the host, and is created by default by docker unless specified otherwise
  - Docker also allows `port mapping` so that the container's exposed port can be accessed using the host IP and corresponding mapped port
  - Docker provides an internal `DNS service` that allows containers to resolve each other by name
  - Docker also assigns containers IP addresses from a configured subnet so that they can directly communicate over the network
  - Docker manages `routing rules` so that packets can move between containers and host via the network, and containers follow the routing tables defined by their network namespace
  - Docker configures `iptables` rules to manage traffic between containers and host which enforce isolation and port forwarding
- Docker supports six network types
  - `Bridge` is a default for standalone containers where a private internal network is created for all the containers to communicate
  - `Host` removes network isolation and allows the container to share the host's IP and ports (useful for performance and compatibility needs)
  - `None` disables networking completely (useful for security or manual config)
  - `Overlay` enables multi-host networking allowing containers on different hosts to communicate (using Docker Swarm)
  - `Macvlan` assigns a MAC address to each container making it appear as a physical device on the network
  - `Ipvlan` is similar to macvlan but uses a different method for traffic handling which is better for high-density environments but less flexible
- We created a new bridge network `docker network create demo-net -d bridge` and recreated both containers with `--network demo-net`
  - we can see now that they can ping each other by name which wasn't previously happening even though they were on the default bridge
  - we can put all containers that need to communicate on the same network and containers on other networks won't be able to reach them
  - they are still unreachable from host and WSL so need to check why this works on work setup [CHECK] (it is supposed to be unreachable via container IP)

---

## Network debugging for v18

- On personal setup, there seems to be an issue with networks as each container is not getting its own IP
- First, lets look at CIDR
  - Total number of bits in IP = 32 bits separated into network bits and host bits
  - Each section of the IP separated by dots has 8 network bits
  - So IP/8 implies first 8 bits (first section) specify network and rest specify the hosts within the network
  - Similarly IP/16 and IP/24 specify the first 2 and first 3 sections of the IP as network
  - We can calculate how many hosts can be assigned in the network of IP/12 by `2^(32 - 12) = 2^20`
- So looks like the container IPs are set but aren't accessible to each other
  - but since both containers are running on WSL2, we can use the WSL2 IP and use the port to map since they are running on localhost
  - we can get this by either `wsl -d <wsl-host>` (wsl-host here is `docker-desktop`) and then running `ip a` to get the IPv4 address of WSL2 host
  - we can also get this by running `ipconfig` directly on Windows and get the IPv4 address of the WSL Ethernet adapter
  - both of these can be different and that's as expected as per https://superuser.com/questions/1645340/wsl2-ip-mismatches-wsl2-adapter

---
