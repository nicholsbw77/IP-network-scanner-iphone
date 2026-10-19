import Foundation

/// Helpers for discovering the device's own IPv4 address / subnet and for
/// enumerating the host addresses that live inside it.
enum LocalNetwork {

    struct Interface {
        let name: String
        let address: String
        let netmask: String
    }

    /// Returns the active Wi-Fi IPv4 interface (`en0`), if any.
    static func wifiInterface() -> Interface? {
        var result: Interface?
        var ifaddrPtr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddrPtr) == 0, let first = ifaddrPtr else { return nil }
        defer { freeifaddrs(ifaddrPtr) }

        var pointer: UnsafeMutablePointer<ifaddrs>? = first
        while let current = pointer {
            defer { pointer = current.pointee.ifa_next }

            let flags = Int32(current.pointee.ifa_flags)
            guard let addr = current.pointee.ifa_addr,
                  addr.pointee.sa_family == UInt8(AF_INET),
                  (flags & IFF_UP) == IFF_UP,
                  (flags & IFF_LOOPBACK) == 0 else { continue }

            let name = String(cString: current.pointee.ifa_name)
            guard name == "en0" else { continue }

            if let address = Self.string(from: addr) {
                let netmask = current.pointee.ifa_netmask
                    .flatMap { Self.string(from: $0) } ?? "255.255.255.0"
                result = Interface(name: name, address: address, netmask: netmask)
            }
        }
        return result
    }

    private static func string(from sockaddr: UnsafeMutablePointer<sockaddr>) -> String? {
        var host = [CChar](repeating: 0, count: Int(NI_MAXHOST))
        let status = getnameinfo(sockaddr, socklen_t(sockaddr.pointee.sa_len),
                                 &host, socklen_t(host.count),
                                 nil, 0, NI_NUMERICHOST)
        guard status == 0 else { return nil }
        return String(cString: host)
    }

    /// Every usable host address in the subnet defined by `address` and
    /// `netmask`, excluding the network and broadcast addresses.
    static func hostAddresses(address: String, netmask: String) -> [String] {
        guard let addr = ipv4ToUInt32(address),
              let mask = ipv4ToUInt32(netmask) else { return [] }

        let network = addr & mask
        let broadcast = network | ~mask
        guard broadcast > network else { return [] }

        // Guard against scanning an enormous range behind a very wide mask.
        guard broadcast - network <= 4096 else { return [] }

        var hosts: [String] = []
        var current = network + 1
        while current < broadcast {
            hosts.append(uint32ToIPv4(current))
            current += 1
        }
        return hosts
    }

    static func ipv4ToUInt32(_ ip: String) -> UInt32? {
        let parts = ip.split(separator: ".")
        guard parts.count == 4 else { return nil }
        var value: UInt32 = 0
        for part in parts {
            guard let octet = UInt32(part), octet <= 255 else { return nil }
            value = (value << 8) | octet
        }
        return value
    }

    static func uint32ToIPv4(_ value: UInt32) -> String {
        "\((value >> 24) & 0xFF).\((value >> 16) & 0xFF).\((value >> 8) & 0xFF).\(value & 0xFF)"
    }
}
