//
//  InterfaceController.swift
//  WatchOSGyroAccelerator Extension
//
//  Created by Indra Sumawi on 16/05/19.
//  Copyright © 2019 Indra Sumawi. All rights reserved.
//

import WatchKit
import Foundation
import Dispatch
import WatchConnectivity

class InterfaceController: WKInterfaceController, WorkoutManagerDelegate {
    
    let workoutManager = WorkoutManager()
    //static var watchLog: String = "";
    static var watchData = WatchLog()
    var active = false
    var detectionStatus = false
    
    var gravityStr: String!
    var accelerationStr: String!
    var rotationStr: String!
    var attitudeStr: String!
    
    var isDataSend = true

    @IBOutlet weak var titleLabel: WKInterfaceLabel!
    @IBOutlet weak var sendButton: WKInterfaceButton!
    
    //connection
    var session = WCSession.default
    
    override init() {
        super.init()
        workoutManager.delegate = self
        self.sendButton.setHidden(true)
    }
    
    @IBAction func startDetection() {
        print("DETECT START")
        playHaptic(type: .start)
        
        self.sendButton.setHidden(true)
        detectionStatus = true
        if self.session.isReachable {
            self.session.sendMessage(["detection": "start"], replyHandler: { (response) in
                //self.titleLabel.setText("\(response)")
                print("\(response)")
            }) { (error) in
                //self.titleLabel.setText("Error: \(error)")
                print("\(error)")
            }
        }
        //delay 3 second
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.playHaptic(type: .start)
            self.titleLabel.setText("Start")
            self.workoutManager.startDetection()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 8) {
            self.playHaptic(type: .stop)
            self.stopDetection()
            self.titleLabel.setText("Stop")
            self.sendButton.setHidden(false)
            self.isDataSend = false
        }
    }
    
    func stopDetection() {
        print("DETECT STOP")
        detectionStatus = false
        self.workoutManager.stopDetection()
    }
    
    @IBAction func sendButtonClicked() {
        print("DATA SEND \(isDataSend)")
        playHaptic(type: .success)
        
        if !isDataSend {
            sendGyroAccData()
            isDataSend = true
        }
    }
    
    func sendGyroAccData() {
        titleLabel.setText("STOP")
        
        if self.session.isReachable {
            let jsonData = try! JSONEncoder().encode(InterfaceController.watchData)
            self.session.sendMessageData(jsonData, replyHandler: { (data) in
                
            }) { (error) in
                self.titleLabel.setText("Error: \(error)")
            }
        }
        sendButton.setHidden(true)
    }
    
    func didUpdateMotion(_ manager: WorkoutManager, gravityStr: String, rotationStr: String, accelerationStr: String, attitudeStr: String) {
        self.gravityStr = gravityStr
        self.rotationStr = rotationStr
        self.accelerationStr = accelerationStr
        self.attitudeStr = attitudeStr
        self.updateLabels()
    }
    
    func updateLabels() {
        if active {
            if detectionStatus == true {
                titleLabel.setText("Start")
            }
            else {
                titleLabel.setText("Stop")
            }
//            gravityLabel.setText(gravityStr)
//            AccelerationLabel.setText(accelerationStr)
//            rotationLabel.setText(rotationStr)
//            attitudeLabel.setText(attitudeStr)
        }
    }
    
    func playHaptic(type: WKHapticType) {
        WKInterfaceDevice.current().play(type)
    }


    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        // Configure interface objects here.
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        
        if WCSession.isSupported() {
            session.delegate = self
            session.activate()
        }
        
        active = true
        //on re-activation, update with the cached values
        updateLabels()
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
        active = false
    }
}

extension InterfaceController: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("activationDidCompleteWith activationState:\(activationState) error:\(String(describing: error))")
    }
}
