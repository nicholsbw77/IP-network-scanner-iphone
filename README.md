# NetScan

A small SwiftUI iPhone app that scans your local Wi-Fi network, lists the
devices it finds, resolves their hostnames, and reports which well-known
TCP ports are open (HTTP, HTTPS, SSH, Remote Desktop, VNC, SMB, and more).

Think of it as a lightweight, open-source take on tools like Fing or LanScan —
useful for seeing what's on your own network and spotting services you didn't
realize were exposed.

> ⚠️ **Use responsibly.** Only scan networks you own or are explicitly
> authorized to test. Port scanning networks you don't control may be against
> the acceptable-use policy of the network, your ISP, or the law in your
> jurisdiction.

## Features

- **Host discovery** — works out your Wi-Fi subnet from the device's own IP and
  netmask, then probes every address in it.
- **Open-port detection** — checks each host for a curated list of well-known
  services and shows them as badges.
- **Name resolution** — reverse-DNS lookup turns `192.168.1.42` into
  `my-macbook.local` where a name is available.
- **Live results** — devices stream into the list as they're found, with a
  progress bar and a Stop button.
- **Device detail** — tap a device to see its IP, hostname, and the full list
  of open ports with friendly descriptions.

## Ports probed

| Port  | Service     | Port  | Service        |
|-------|-------------|-------|----------------|
| 21    | FTP         | 548   | AFP            |
| 22    | SSH         | 631   | IPP (printing) |
| 23    | Telnet      | 3306  | MySQL          |
| 25    | SMTP        | 3389  | RDP (Remote Desktop) |
| 53    | DNS         | 5432  | PostgreSQL     |
| 80    | HTTP        | 5900  | VNC            |
| 139   | NetBIOS     | 8080  | HTTP-alt       |
| 443   | HTTPS       | 8443  | HTTPS-alt      |
| 445   | SMB         | 62078 | iPhone sync    |

The list lives in [`NetScan/Models/ServicePort.swift`](NetScan/Models/ServicePort.swift) —
edit `ServicePort.wellKnown` to add or remove ports.

## How it works

1. **`LocalNetwork`** uses `getifaddrs` to read the `en0` (Wi-Fi) IPv4 address
   and netmask, then expands the subnet into a list of host addresses
   (skipping the network and broadcast addresses, and capping very wide masks).
2. **`PortScanner`** opens a TCP connection to each port with the `Network`
   framework. A connection that becomes `.ready` means the port is **open**; a
   `connection refused` means the host is **up but the port is closed**;
   anything else (including a timeout) is treated as **unreachable**.
3. **`NetworkScanner`** fans the work out across hosts and ports with
   `TaskGroup`s (bounded concurrency so iOS doesn't throttle the socket burst),
   marks a host reachable if it answered any probe, and then resolves its name.
4. **`HostResolver`** does a reverse-DNS (`getnameinfo` with `NI_NAMEREQD`)
   lookup on a background queue.
5. SwiftUI views render the results and update live via `@Published` state.

Because it relies only on unicast TCP connections, no special entitlement is
needed beyond iOS's standard Local Network privacy permission.

## Requirements

- Xcode 15 or newer
- iOS 17.0+ target
- A physical iPhone/iPad **or** the simulator. On the simulator the app scans
  the Mac's network; on device it scans the Wi-Fi network the phone is joined
  to. (Local Network access isn't available over cellular.)

## Build & run

1. Clone the repo and open `NetScan.xcodeproj` in Xcode.
2. Select the **NetScan** scheme and a simulator or your connected device.
3. For a device build, set your own **Team** and a unique **Bundle Identifier**
   under *Signing & Capabilities* (the project ships with the placeholder
   `com.example.NetScan`).
4. Press **Run** (⌘R).
5. The first time you tap **Scan**, iOS will ask for **Local Network** access —
   allow it, or the probes can't reach your LAN. You can change this later in
   *Settings ▸ Privacy & Security ▸ Local Network*.

### Regenerating the project (optional)

The committed `NetScan.xcodeproj` works out of the box. If you'd rather
generate it from a spec, a [`project.yml`](project.yml) for
[XcodeGen](https://github.com/yonaskolb/XcodeGen) is included:

```sh
brew install xcodegen
xcodegen generate
```

## Continuous builds (download the app)

Every push to `main` triggers the [**Build iOS app**](.github/workflows/build.yml)
GitHub Actions workflow, which compiles the app on a macOS runner and uploads
an **unsigned `.ipa`** you can download.

- **Where:** open the repo's **Actions** tab → the latest **Build iOS app** run
  → the **Artifacts** section → download `NetScan-unsigned-ipa`.
- **Releases:** creating a GitHub Release also attaches the `.ipa` to it.

### Installing the .ipa

The CI build is **unsigned**, because code signing requires *your* Apple ID or
developer account — GitHub can't sign on your behalf. To put it on an iPhone,
sign it on install with one of:

- **[AltStore](https://altstore.io)** or **[Sideloadly](https://sideloadly.io)** —
  free; you sign in with a normal Apple ID. Apps installed this way expire after
  7 days on a free account and must be re-installed.
- A **paid Apple Developer account** — re-sign the `.ipa` for ad-hoc / TestFlight
  distribution (see below).

> You can't just double-tap the `.ipa` — iOS only runs signed apps.

### Producing a signed build (optional)

If you have an Apple Developer account and want CI to emit a signed, directly
installable `.ipa`, extend the workflow to import your certificate and
provisioning profile from repository **Secrets**, then archive with
`xcodebuild -exportArchive`. GitHub's guide
["Installing an Apple certificate on macOS runners"](https://docs.github.com/actions/deployment/deploying-xcode-applications/installing-an-apple-certificate-on-macos-runners-for-xcode-development)
covers the exact steps.

## Project layout

```
NetScan/
  NetScanApp.swift          App entry point
  ContentView.swift         Root list + navigation
  Models/
    Device.swift            A discovered host + its open ports
    ServicePort.swift       The catalog of well-known ports
  Services/
    LocalNetwork.swift      Subnet discovery / IP math
    PortScanner.swift       TCP port probing (Network framework)
    HostResolver.swift      Reverse-DNS name resolution
    NetworkScanner.swift    Orchestrates the whole scan
  Views/
    ScanHeaderView.swift    Status + Scan/Stop control
    DeviceRowView.swift     List row
    DeviceDetailView.swift  Per-device detail
  Assets.xcassets           App icon slot + accent color
```

## Roadmap / ideas

- Bonjour/mDNS service discovery for richer device names and types
- ICMP ping sweep (via `SimplePing`) to find hosts with no open TCP ports
- MAC address + vendor lookup (where the OS exposes the ARP table)
- Configurable port list and timeout in-app
- Export results (CSV / share sheet)
- Pull-to-refresh and per-device re-scan

## License

GPL-3.0 — see [LICENSE](LICENSE).
