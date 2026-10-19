import Foundation

/// Reverse-DNS hostname resolution for IPv4 addresses.
enum HostResolver {
    /// Looks up the PTR record for an IPv4 address, returning `nil` when the
    /// host has no name. This call can block, so run it off the main thread.
    static func reverseLookup(_ ip: String) -> String? {
        var addr = sockaddr_in()
        addr.sin_family = sa_family_t(AF_INET)
        addr.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        guard inet_pton(AF_INET, ip, &addr.sin_addr) == 1 else { return nil }

        var host = [CChar](repeating: 0, count: Int(NI_MAXHOST))
        let status = withUnsafePointer(to: &addr) { pointer in
            pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) { sockaddrPointer in
                getnameinfo(sockaddrPointer, socklen_t(MemoryLayout<sockaddr_in>.size),
                            &host, socklen_t(host.count),
                            nil, 0, NI_NAMEREQD)
            }
        }
        guard status == 0 else { return nil }
        let name = String(cString: host)
        return name.isEmpty ? nil : name
    }
}
