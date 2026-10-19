import SwiftUI

struct ContentView: View {
    @StateObject private var scanner = NetworkScanner()

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ScanHeaderView(scanner: scanner)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                }

                if !scanner.devices.isEmpty {
                    Section("Devices (\(scanner.devices.count))") {
                        ForEach(scanner.devices) { device in
                            NavigationLink(value: device) {
                                DeviceRowView(device: device)
                            }
                        }
                    }
                } else if !scanner.isScanning {
                    Section {
                        ContentUnavailableView(
                            "No devices yet",
                            systemImage: "wifi",
                            description: Text("Tap Scan to discover devices on your local network.")
                        )
                    }
                }
            }
            .navigationTitle("NetScan")
            .navigationDestination(for: Device.self) { device in
                DeviceDetailView(device: device)
            }
        }
    }
}

#Preview {
    ContentView()
}
