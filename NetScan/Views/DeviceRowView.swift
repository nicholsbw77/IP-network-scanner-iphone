import SwiftUI

/// One row in the device list: name, IP, and a strip of open-port badges.
struct DeviceRowView: View {
    let device: Device

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(.tint)
                Text(device.displayName)
                    .font(.headline)
                    .lineLimit(1)
                Spacer()
                Text(device.ipAddress)
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
            }

            if device.openPorts.isEmpty {
                Text("No open ports detected")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(device.openPorts) { port in
                            Text(port.name)
                                .font(.caption2.weight(.medium))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(.tint.opacity(0.15), in: Capsule())
                                .foregroundStyle(.tint)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var icon: String {
        device.hostname == nil ? "network" : "desktopcomputer"
    }
}
