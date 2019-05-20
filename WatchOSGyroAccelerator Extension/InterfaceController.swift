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
    var forehandCount = 0
    var backhandCount = 0
    
    var gravityStr: String!
    var accelerationStr: String!
    var rotationStr: String!
    var attitudeStr: String!

    @IBOutlet weak var titleLabel: WKInterfaceLabel!
    
    @IBOutlet weak var gravityLabel: WKInterfaceLabel!
    @IBOutlet weak var AccelerationLabel: WKInterfaceLabel!
    @IBOutlet weak var rotationLabel: WKInterfaceLabel!
    @IBOutlet weak var attitudeLabel: WKInterfaceLabel!
    
    //connection
    var session = WCSession.default
    
    override init() {
        super.init()
        workoutManager.delegate = self
    }
    
    @IBAction func startWorkout() {
        if self.session.isReachable {
            self.session.sendMessage(["detection": "start"], replyHandler: { (response) in
                self.titleLabel.setText("\(response)")
            }) { (error) in
                self.titleLabel.setText("Error: \(error)")
            }
        }
        //delay 3 second
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.titleLabel.setText("Workout started")
            self.workoutManager.startWorkout()
        }
    }
    
    
    @IBAction func stopWorkout() {
        titleLabel.setText("Workout stopped")
        workoutManager.stopWorkout()
        
        if self.session.isReachable {
           let jsonData = try! JSONEncoder().encode(InterfaceController.watchData)
            self.session.sendMessageData(jsonData, replyHandler: { (data) in
                
            }) { (error) in
                self.titleLabel.setText("Error: \(error)")
            }
            /*
            self.session.sendMessage(["detection": "stop"], replyHandler: { (response) in
                self.titleLabel.setText("\(response)")
            }) { (error) in
                self.titleLabel.setText("Error: \(error)")
            }*/
        }
    }
    
    func didUpdateMotion(_ manager: WorkoutManager, gravityStr: String, rotationStr: String, accelerationStr: String, attitudeStr: String) {
        self.gravityStr = gravityStr
        self.rotationStr = rotationStr
        self.accelerationStr = accelerationStr
        self.attitudeStr = attitudeStr
        self.updateLabels()
    }
    
    func didUpdateForehandSwingCount(_ manager: WorkoutManager, forehandCount: Int) {
        /// Serialize the property access and UI updates on the main queue.
        DispatchQueue.main.async {
            self.forehandCount = forehandCount
            self.updateLabels()
        }
    }
    
    func didUpdateBackhandSwingCount(_ manager: WorkoutManager, backhandCount: Int) {
        /// Serialize the property access and UI updates on the main queue.
        DispatchQueue.main.async {
            self.backhandCount = backhandCount
            self.updateLabels()
        }
    }
    
    func updateLabels() {
        if active {
            gravityLabel.setText(gravityStr)
            AccelerationLabel.setText(accelerationStr)
            rotationLabel.setText(rotationStr)
            attitudeLabel.setText(attitudeStr)
            
            
            //forehandCountLabel.setText("\(forehandCount)")
            //backhandCountLabel.setText("\(backhandCount)")
        }
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
