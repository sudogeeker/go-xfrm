# tunnel-helper

A small interactive generator for multiple types of VPNs and tunnels. 
It supports creating configurations for **IPsec/IKEv2 (XFRM via strongSwan)**, **WireGuard**, **AmneziaWG**, **VXLAN**, and **GRE**.

## Table of Contents

- [Quick Start](#quick-start)
- [Requirements](#requirements)
- [Build and Run](#build-and-run)
- [Configuration Details](#configuration-details)
  - [IPsec/IKEv2 (XFRM)](#ipsecikev2-xfrm)
  - [WireGuard & AmneziaWG](#wireguard--amneziawg)
  - [VXLAN & GRE](#vxlan--gre)
- [License](#license)

---

## Quick Start

Run from GitHub (no clone, downloads latest release and runs):

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/sudogeeker/tunnel-helper/main/run.sh)
```

By default it installs to `./bin` under your current working directory when run this way.

Run via `go run` from GitHub:

```bash
sudo go run github.com/sudogeeker/tunnel-helper/cmd/tunnel-helper@latest
```

Run locally after cloning:

```bash
./run.sh
```

---

## Requirements

- Linux with root access
- `ip` command available
- **For XFRM, VXLAN, and GRE:** ifupdown networking (`/etc/network/interfaces`) is required. *(netplan or systemd-networkd are not supported by this tool)*
- **For XFRM:** strongSwan + swanctl installed. Recommended: `charon-systemd`, `strongswan-swanctl`, `libstrongswan-extra-plugins`.
- **For WireGuard:** `wireguard-tools` (the script can auto-install this via `apt` if missing).
- **For AmneziaWG:** The script can automatically download, compile, and install the kernel module and tools from source if they are missing.

---

## Build and Run

### Build

```bash
make build
```

Binary is written to `./bin/tunnel-helper`.

### Run

```bash
sudo ./bin/tunnel-helper
```

The wizard will first prompt you to select the tunnel type:

1. XFRM (IPsec/IKEv2 via strongSwan)
2. WireGuard
3. AmneziaWG
4. VXLAN
5. GRE

It will then guide you through an interactive process to collect IP addresses, keys, and other parameters, and generate the necessary configuration files.

---

## Configuration Details

### IPsec/IKEv2 (XFRM)

Generates three files:
- `swanctl` connection config: `/etc/swanctl/conf.d/<ifname>.conf`
- `swanctl` secrets config: `/etc/swanctl/conf.d/<ifname>.secrets` (PSK only)
- XFRM interface config: `/etc/network/interfaces.d/<ifname>.cfg`

Supports both **PSK (Pre-Shared Key)** and **RPK (Raw Public Key)** authentication. It automatically detects and offers strong DH groups for PFS.

### WireGuard & AmneziaWG

Generates a standard WireGuard config in `/etc/wireguard/wg-<name>.conf` or AmneziaWG config in `/etc/amnezia/amneziawg/awg-<name>.conf`. 
- Can automatically generate key pairs.
- Supports specifying listening ports, MTU, PersistentKeepalive, and routing table.
- **AmneziaWG** adds obfuscation parameters (Jc, Jmin, Jmax, S1, S2, H1, H2, H3, H4) and compiles kernel module/tools from source automatically if they're not installed.
- Use `wg-quick up wg-<name>` or `awg-quick up awg-<name>` to bring the interface up.

### VXLAN & GRE

Generates an ifupdown config in `/etc/network/interfaces.d/<name>.cfg`.
- For VXLAN: Uses `ip link add type vxlan` natively.
- For GRE: Uses `ip tunnel add mode gre/ip6gre`.
- Handles both IPv4 and IPv6 underlay/inner networks.
- Supports automatic replacement of inner IP addresses upon interface creation.

---

## License

MIT
