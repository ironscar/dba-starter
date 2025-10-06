# Networking Concepts

## Docker Networking

---

## WSL Networking

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
