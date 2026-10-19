import SwiftUI

/// Full detail for a single device: host info plus the list of open ports.
struct DeviceDetailView: View {
    let device: Device

    var body: some View {
        List {
            Section("Host") {
                LabeledContent("IP address", value: device.ipAddress)
                LabeledContent("Hostname", value: device.hostname ?? "—")
                LabeledContent("Status", value: "Reachable")
            }

            Section("Open ports (\(device.openPorts.count))") {
                if device.openPorts.isEmpty {
                    Text("No open ports were detected from the scanned list.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(device.openPorts) { port in
                        VStack(alignment: .leading, spacing: 3) {
                            HStack {
                                Text(port.name)
                                    .font(.headline)
                                Spacer()
                                Text(verbatim: "\(port.port)")
                                    .font(.subheadline.monospaced())
                                    .foregroundStyle(.secondary)
                            }
                            Text(port.detail)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
        }
        .navigationTitle(device.displayName)
        .navigationBarTitleDisplayMode(.inline)
    }
}
