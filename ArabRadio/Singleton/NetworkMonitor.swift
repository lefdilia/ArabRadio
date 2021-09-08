//
//  NetworkManager.swift
//  ArabRadio
//
//  Created by Lefdili Alaoui Ayoub on 26/6/2021.
//

import Foundation
import Network


public enum ConnectionType {
    case wifi
    case ethernet
    case cellular
    case unknown
}

class NetworkStatus {
    
    static public let shared = NetworkStatus()
    
    private var monitor: NWPathMonitor
    private var queue = DispatchQueue.global(qos: .background)
    
    public private(set) var isConnected: Bool = false
    public private(set) var ConnectionType: ConnectionType = .unknown
    
    private init() {
        self.monitor = NWPathMonitor()
    }
    
    func start( ) {
        self.monitor.start(queue: queue)
        self.monitor.pathUpdateHandler = { path in
            self.isConnected = (path.status == .satisfied)
            self.ConnectionType = self.checkConnectionTypeForPath(path)
        }
    }
    
    func stop() {
        self.monitor.cancel()
    }
    
    func checkConnectionTypeForPath(_ path: NWPath) -> ConnectionType {
        if path.usesInterfaceType(.wifi) {
            return .wifi
        } else if path.usesInterfaceType(.wiredEthernet) {
            return .ethernet
        } else if path.usesInterfaceType(.cellular) {
            return .cellular
        }
        return .unknown
    }
    
}

