//
//  ConnectivityMonitor.swift
//  DeFilms
//

import Foundation
import Network

@MainActor
final class ConnectivityMonitor: ObservableObject {
    @Published private(set) var isConnected = false
    @Published private(set) var isChecking = true
    @Published private(set) var connectionDescription = ""

    private let queue = DispatchQueue(label: "defilms.connectivity.monitor")
    private var monitor: NWPathMonitor?

    init() {
        startMonitoring()
    }

    deinit {
        monitor?.cancel()
    }

    func retryConnectionCheck() {
        startMonitoring()
    }

    private func startMonitoring() {
        monitor?.cancel()
        isChecking = true

        let monitor = NWPathMonitor()
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.apply(path: path)
            }
        }
        monitor.start(queue: queue)
        self.monitor = monitor
    }

    private func apply(path: NWPath) {
        isChecking = false
        isConnected = path.status == .satisfied

        if path.usesInterfaceType(.wifi) {
            connectionDescription = "Wi-Fi"
        } else if path.usesInterfaceType(.cellular) {
            connectionDescription = "Cellular"
        } else if path.usesInterfaceType(.wiredEthernet) {
            connectionDescription = "Ethernet"
        } else {
            connectionDescription = ""
        }

        if isConnected {
            AppLogger.log("Network reachable via \(connectionDescription.isEmpty ? "unknown" : connectionDescription)", category: .network, level: .success)
        } else {
            AppLogger.log("Network unavailable", category: .network, level: .warning)
        }
    }
}
