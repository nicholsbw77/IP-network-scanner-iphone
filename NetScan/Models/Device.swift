import Foundation

/// The result of probing a single host on the local network.
struct Device: Identifiable, Hashable {
    let ipAddress: String
    var hostname: String?
    var openPorts: [ServicePort]
    /// True when the host answered at least one probe (open or refused).
    var isReachable: Bool

    var id: String { ipAddress }

    /// Prefer the resolved hostname, falling back to the raw IP address.
    var displayName: String {
        if let hostname, !hostname.isEmpty { return hostname }
        return ipAddress
    }

    /// Numeric form of the IP so that 192.168.1.2 sorts before 192.168.1.10.
    var sortKey: UInt32 {
        ipAddress.split(separator: ".").reduce(0) { accumulated, octet in
            (accumulated << 8) | (UInt32(octet) ?? 0)
        }
    }
}
