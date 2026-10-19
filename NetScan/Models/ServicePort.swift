import Foundation

/// A well-known TCP service that the scanner probes for on each host.
struct ServicePort: Identifiable, Hashable {
    let port: UInt16
    let name: String
    let detail: String

    var id: UInt16 { port }

    /// The default set of ports NetScan probes, ordered roughly by how
    /// commonly they turn up on a home or office LAN.
    static let wellKnown: [ServicePort] = [
        ServicePort(port: 80,    name: "HTTP",        detail: "Web server"),
        ServicePort(port: 443,   name: "HTTPS",       detail: "Secure web server"),
        ServicePort(port: 22,    name: "SSH",         detail: "Secure shell"),
        ServicePort(port: 3389,  name: "RDP",         detail: "Remote Desktop"),
        ServicePort(port: 5900,  name: "VNC",         detail: "Screen sharing"),
        ServicePort(port: 445,   name: "SMB",         detail: "Windows / file sharing"),
        ServicePort(port: 139,   name: "NetBIOS",     detail: "Windows networking"),
        ServicePort(port: 548,   name: "AFP",         detail: "Apple file sharing"),
        ServicePort(port: 21,    name: "FTP",         detail: "File transfer"),
        ServicePort(port: 23,    name: "Telnet",      detail: "Unencrypted shell"),
        ServicePort(port: 25,    name: "SMTP",        detail: "Mail transfer"),
        ServicePort(port: 53,    name: "DNS",         detail: "Name resolution"),
        ServicePort(port: 631,   name: "IPP",         detail: "Printing"),
        ServicePort(port: 8080,  name: "HTTP-alt",    detail: "Alternate web server"),
        ServicePort(port: 8443,  name: "HTTPS-alt",   detail: "Alternate secure web"),
        ServicePort(port: 3306,  name: "MySQL",       detail: "Database"),
        ServicePort(port: 5432,  name: "PostgreSQL",  detail: "Database"),
        ServicePort(port: 62078, name: "iPhone sync", detail: "Apple lockdown service"),
    ]
}
