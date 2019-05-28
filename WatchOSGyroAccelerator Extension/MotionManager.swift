//
//  MotionManager.swift
//  WatchOSGyroAccelerator Extension
//
//  Created by Indra Sumawi on 16/05/19.
//  Copyright © 2019 Indra Sumawi. All rights reserved.
//

import Foundation
import CoreMotion
import WatchKit
import os.log

//protocol to inform motion changes
protocol MotionManagerDelegate: class {
    func didUpdateMotion(_ manager: MotionManager, gravityStr: String, rotationStr: String, accelerationStr: String, attitudeStr: String)
}

class MotionManager {
    let motionManager = CMMotionManager()
    let queue = OperationQueue()
    let wristLocationIsLeft = WKInterfaceDevice.current().wristLocation == .left

    //let app use 50hz data and buffer going to hold data
    let sampleInterval = 1.0 / 37
    
    weak var delegate: MotionManagerDelegate?
  
    var recentDetection = false
    
    var gravityStr: String!
    var accelerationStr: String!
    var rotationStr: String!
    var attitudeStr: String!
    
    init() {
        //serial queue for sample handling and calculation
        queue.maxConcurrentOperationCount = 1
        queue.name = "MotionManagerQueue"
    }
    
    func startUpdates() {
        if !motionManager.isDeviceMotionAvailable {
            print("Device motion is not available")
            return
        }
        
        //reset  when we start
        resetAllState()
        
        motionManager.deviceMotionUpdateInterval = sampleInterval
        motionManager.startDeviceMotionUpdates(to: queue) {
            (deviceMotion: CMDeviceMotion?, error: Error?) in
            if (error != nil) {
                print("Error: \(error)")
            }
            
            if (deviceMotion != nil) {
                self.processDeviceMotion(deviceMotion!)
            }
        }
    }
    
    func stopUpdates() {
        if motionManager.isDeviceMotionAvailable {
            motionManager.stopDeviceMotionUpdates()
        }
    }
    
    func processDeviceMotion(_ deviceMotion: CMDeviceMotion) {
        //print("YAW: \(deviceMotion.attitude.yaw) ROLL: \(deviceMotion.attitude.roll)")
        let rotation = atan2(deviceMotion.gravity.x, deviceMotion.gravity.y) - .pi
        print("roation: \(rotation) PITCH: \(deviceMotion.attitude.pitch)")
        
        let timestamp = Date().timeIntervalSince1970
            //take avg of acceleration
            //because sometimes good pattern only in x or y
        InterfaceController.watchData.accX.append((deviceMotion.userAcceleration.x + deviceMotion.userAcceleration.y + deviceMotion.userAcceleration.z) / 3.0)
        InterfaceController.watchData.yaw.append(deviceMotion.attitude.yaw)
        InterfaceController.watchData.pitch.append(deviceMotion.attitude.pitch)
        
        // 1. These strings are to show on the UI. Trying to fit
        // x,y,z values for the sensors is difficult so we’re
        // just going with one decimal point precision.
        gravityStr = String(format: "X: %.1f Y: %.1f Z: %.1f" ,
                            deviceMotion.gravity.x,
                            deviceMotion.gravity.y,
                            deviceMotion.gravity.z)
        accelerationStr = String(format: "X: %.1f Y: %.1f Z: %.1f" ,
                                 deviceMotion.userAcceleration.x,
                                 deviceMotion.userAcceleration.y,
                                 deviceMotion.userAcceleration.z)
        rotationStr = String(format: "X: %.1f Y: %.1f Z: %.1f" ,
                             deviceMotion.rotationRate.x,
                             deviceMotion.rotationRate.y,
                             deviceMotion.rotationRate.z)
        attitudeStr = String(format: "r: %.1f p: %.1f y: %.1f" ,
                             deviceMotion.attitude.roll,
                             deviceMotion.attitude.pitch,
                             deviceMotion.attitude.yaw)
        /*
        //append(WatchLog(accX: , yaw: ))
        // 3. Log this data so we can extract it later
        /*os_log("Motion: %@, %@, %@, %@, %@, %@, %@, %@, %@, %@, %@, %@",
               String(timestamp),
               String(deviceMotion.gravity.x),
               String(deviceMotion.gravity.y),
               String(deviceMotion.gravity.z),
               String(deviceMotion.userAcceleration.x),
               String(deviceMotion.userAcceleration.y),
               String(deviceMotion.userAcceleration.z),
               String(deviceMotion.rotationRate.x),
               String(deviceMotion.rotationRate.y),
               String(deviceMotion.rotationRate.z),
               String(deviceMotion.attitude.roll),
               String(deviceMotion.attitude.pitch),
               String(deviceMotion.attitude.yaw))*/
        */
        // 4. update values in the UI
        updateMetricsDelegate();
    }
    
    func resetAllState() {
        recentDetection = false
    }
    
    func updateMetricsDelegate() {
        delegate?.didUpdateMotion(self,gravityStr: gravityStr, rotationStr: rotationStr, accelerationStr: accelerationStr, attitudeStr: attitudeStr)
    }
}
