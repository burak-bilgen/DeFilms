//
//  ConnectivityMonitor.swift
//  DeFilms
//

import Foundation
import Network
import Combine

@MainActor
final class ConnectivityMonitor: ObservableObject {
    @Published private(set) var isConnected = false
    @Published private(set) var isChecking = true
    @Published private(set) var hasResolvedInitialStatus = false
    @Published private(set) var connectionDescription = ""

    private let queue = DispatchQueue(label: "defilms.connectivity.monitor")
    private let verificationSession: URLSession
    private var monitor: NWPathMonitor?
    private var verificationTask: Task<Void, Never>?

    init(session: URLSession = ConnectivityMonitor.makeVerificationSession()) {
        self.verificationSession = session

        startMonitoring()
    }

    deinit {
        verificationTask?.cancel()
        monitor?.cancel()
    }

    func retryConnectionCheck() {
        startMonitoring()
    }

    private func startMonitoring() {
        monitor?.cancel()
        verificationTask?.cancel()
        isChecking = true
        hasResolvedInitialStatus = false

        let monitor = NWPathMonitor()
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self else { return }

            Task { @MainActor [self] in
                self.apply(path: path)
            }
        }
        monitor.start(queue: queue)
        self.monitor = monitor
    }

    private func apply(path: NWPath) {
        let interfaceDescription = Self.interfaceDescription(for: path)
        let previousConnectivity = isConnected

        guard path.status == .satisfied else {
            verificationTask?.cancel()
            verificationTask = nil
            isChecking = false
            hasResolvedInitialStatus = true
            isConnected = false
            connectionDescription = interfaceDescription
            Task {
                await ConnectivityStateStore.shared.setConnected(false)
            }

            AppLogger.log("Network unavailable", category: .network, level: .warning)
            return
        }

        verificationTask?.cancel()
        isChecking = true
        connectionDescription = interfaceDescription

        verificationTask = Task { @MainActor [weak self] in
            guard let self else { return }
            let isInternetReachable = await self.verifyInternetReachability()
            guard !Task.isCancelled else { return }

            self.isChecking = false
            self.hasResolvedInitialStatus = true
            self.isConnected = isInternetReachable
            self.connectionDescription = interfaceDescription
            self.verificationTask = nil
            Task {
                await ConnectivityStateStore.shared.setConnected(isInternetReachable)
            }

            if isInternetReachable {
                if previousConnectivity == false {
                    NotificationCenter.default.post(name: .connectivityDidRestore, object: nil)
                }
                AppLogger.log(
                    "Network reachable via \(self.connectionDescription.isEmpty ? "unknown" : self.connectionDescription)",
                    category: .network,
                    level: .success
                )
            } else {
                AppLogger.log("Network unavailable", category: .network, level: .warning)
            }
        }
    }

    private static func interfaceDescription(for path: NWPath) -> String {
        if path.usesInterfaceType(.wifi) {
            return "Wi-Fi"
        }

        if path.usesInterfaceType(.cellular) {
            return "Cellular"
        }

        if path.usesInterfaceType(.wiredEthernet) {
            return "Ethernet"
        }

        return ""
    }

    private func verifyInternetReachability() async -> Bool {
        guard let url = URL(string: "https://www.apple.com/library/test/success.html") else {
            return false
        }

        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.timeoutInterval = 4

        do {
            let (_, response) = try await verificationSession.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else { return false }
            return (200...299).contains(httpResponse.statusCode)
        } catch {
            return false
        }
    }

    nonisolated private static func makeVerificationSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 4
        configuration.timeoutIntervalForResource = 4
        configuration.waitsForConnectivity = false
        return URLSession(configuration: configuration)
    }
}
actor ConnectivityStateStore {
    static let shared = ConnectivityStateStore()

    private var isConnected = true

    func setConnected(_ isConnected: Bool) {
        self.isConnected = isConnected
    }

    func connected() -> Bool {
        isConnected
    }
}

extension Notification.Name {
    static let connectivityDidRestore = Notification.Name("defilms.connectivity.didRestore")
}

