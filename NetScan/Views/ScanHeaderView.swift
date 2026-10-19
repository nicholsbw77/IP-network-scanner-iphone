import SwiftUI

/// The top card: status text, subnet summary, progress, and the Scan/Stop button.
struct ScanHeaderView: View {
    @ObservedObject var scanner: NetworkScanner

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(scanner.statusMessage)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    if let subnet = scanner.subnetDescription {
                        Text(subnet)
                            .font(.caption.monospaced())
                            .foregroundStyle(.tertiary)
                    }
                }
                Spacer(minLength: 12)
                Button {
                    scanner.isScanning ? scanner.stop() : scanner.start()
                } label: {
                    Label(scanner.isScanning ? "Stop" : "Scan",
                          systemImage: scanner.isScanning
                            ? "stop.fill"
                            : "antenna.radiowaves.left.and.right")
                        .frame(minWidth: 64)
                }
                .buttonStyle(.borderedProminent)
                .tint(scanner.isScanning ? .red : .accentColor)
            }

            if scanner.isScanning {
                ProgressView(value: scanner.progress)
                    .tint(.accentColor)
            }
        }
        .padding()
    }
}
