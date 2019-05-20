//
//  SessionHandler.swift
//  WatchGyroAccelerator
//
//  Created by Indra Sumawi on 19/05/19.
//  Copyright © 2019 Indra Sumawi. All rights reserved.
//

import Foundation
import WatchConnectivity

protocol SessionHandlerDelegate: AnyObject {
    func receiveRequest(_ detection: String)
    func receiveRequestData(_ data: WatchLog)
}

class SessionHandler: NSObject, WCSessionDelegate {
    
    weak var delegate: SessionHandlerDelegate?
    
    // 1: Singleton
    static let shared = SessionHandler()
    
    // 2: Property to manage session
    private var session = WCSession.default
    
    override init() {
        super.init()
        
        // 3: Start and avtivate session if it's supported
        if isSupported() {
            session.delegate = self
            session.activate()
        }
        
        print("isPaired?: \(session.isPaired), isWatchAppInstalled?: \(session.isWatchAppInstalled)")
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("activationDidCompleteWith activationState:\(activationState) error:\(String(describing: error))")
    }
    
    /// Observer to receive messages from watch and we be able to response it
    ///
    /// - Parameters:
    ///   - session: session
    ///   - message: message received
    ///   - replyHandler: response handler
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        if message["detection"] as? String == "start" {
            delegate?.receiveRequest((message["detection"] as? String)!)
            replyHandler(["version" : "\(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") ?? "No version")"])
        }
    }
    
    func session(_ session: WCSession, didReceiveMessageData messageData: Data, replyHandler: @escaping (Data) -> Void) {
        let decoder = JSONDecoder()
        do {
            let data = try decoder.decode(WatchLog.self, from: messageData)
            delegate?.receiveRequestData(data)
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func isSupported() -> Bool {
        return WCSession.isSupported()
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        print("sessionDidBecomeInactive: \(session)")
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        print("sessionDidDeactivate: \(session)")
        // Reactivate session
        /**
         * This is to re-activate the session on the phone when the user has switched from one
         * paired watch to second paired one. Calling it like this assumes that you have no other
         * threads/part of your code that needs to be given time before the switch occurs.
         */
        self.session.activate()
    }
}
