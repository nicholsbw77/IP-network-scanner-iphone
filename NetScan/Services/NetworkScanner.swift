import Foundation
import Combine

/// Drives a full local-network sweep: works out the subnet, probes every host
/// for the well-known ports, resolves names for the ones that answer, and
/// publishes results to the UI as they arrive.
@MainActor
final class NetworkScanner: ObservableObject {
    @Published private(set) var devices: [Device] = []
    @Published private(set) var isScanning = false
    @Published private(set) var progress: Double = 0
    @Published private(set) var statusMessage = "Ready to scan."
    @Published private(set) var subnetDescription: String?

    /// Ports probed on each host. Exposed so the UI can describe the scan.
    let ports = ServicePort.wellKnown

    private let portScanner = PortScanner()
    private var scanTask: Task<Void, Never>?

    /// How many hosts are probed at once. Kept modest so iOS doesn't throttle
    /// the burst of sockets.
    private let maxConcurrentHosts = 40

    func start() {
        guard !isScanning else { return }
        scanTask = Task { await scan() }
    }

    func stop() {
        scanTask?.cancel()
        scanTask = nil
    }

    private func scan() async {
        isScanning = true
        progress = 0
        devices = []
        statusMessage = "Finding local network…"

        guard let interface = LocalNetwork.wifiInterface() else {
            statusMessage = "No Wi-Fi connection found. Join a Wi-Fi network and try again."
            isScanning = false
            return
        }

        subnetDescription = "\(interface.address)  ·  mask \(interface.netmask)"
        let hosts = LocalNetwork.hostAddresses(address: interface.address,
                                               netmask: interface.netmask)

        guard !hosts.isEmpty else {
            statusMessage = "Couldn't work out which subnet to scan."
            isScanning = false
            return
        }

        statusMessage = "Scanning \(hosts.count) addresses…"

        let total = hosts.count
        var completed = 0
        let ports = self.ports
        let scanner = self.portScanner
        let window = min(maxConcurrentHosts, total)

        await withTaskGroup(of: Device?.self) { group in
            var index = 0
            while index < window {
                let host = hosts[index]
                index += 1
                group.addTask { await NetworkScanner.scanHost(host, ports: ports, scanner: scanner) }
            }

            while let result = await group.next() {
                completed += 1
                progress = Double(completed) / Double(total)
                if let result { insert(result) }

                if index < total && !Task.isCancelled {
                    let host = hosts[index]
                    index += 1
                    group.addTask { await NetworkScanner.scanHost(host, ports: ports, scanner: scanner) }
                }
            }
        }

        progress = 1
        isScanning = false

        if Task.isCancelled {
            statusMessage = "Scan stopped."
        } else if devices.isEmpty {
            statusMessage = "No devices found. On the first run, allow Local Network access when iOS asks "
                + "(or enable it later in Settings ▸ Privacy & Security ▸ Local Network)."
        } else {
            statusMessage = "Found \(devices.count) device\(devices.count == 1 ? "" : "s")."
        }
    }

    private func insert(_ device: Device) {
        if let existing = devices.firstIndex(where: { $0.ipAddress == device.ipAddress }) {
            devices[existing] = device
        } else {
            devices.append(device)
            devices.sort { $0.sortKey < $1.sortKey }
        }
    }

    /// Probes one host across all ports concurrently, then resolves its name.
    private static func scanHost(_ host: String,
                                 ports: [ServicePort],
                                 scanner: PortScanner) async -> Device? {
        var openPorts: [ServicePort] = []
        var reachable = false

        await withTaskGroup(of: (ServicePort, PortProbe).self) { group in
            for service in ports {
                group.addTask { (service, await scanner.probe(host: host, port: service.port)) }
            }
            for await (service, probe) in group {
                switch probe {
                case .open:
                    openPorts.append(service)
                    reachable = true
                case .closed:
                    reachable = true
                case .unreachable:
                    break
                }
            }
        }

        guard reachable else { return nil }
        openPorts.sort { $0.port < $1.port }
        let hostname = await resolveName(host)
        return Device(ipAddress: host, hostname: hostname, openPorts: openPorts, isReachable: true)
    }

    /// Bridges the blocking reverse-DNS call onto a background GCD queue so it
    /// never stalls the structured-concurrency thread pool.
    private static func resolveName(_ host: String) async -> String? {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .utility).async {
                continuation.resume(returning: HostResolver.reverseLookup(host))
            }
        }
    }
}
