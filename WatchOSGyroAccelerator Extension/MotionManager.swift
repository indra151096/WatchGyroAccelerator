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
    func didUpdateForehandSwingCount(_ manager: MotionManager, forehandCount: Int)
    func didUpdateBackhandSwingCount(_ manager: MotionManager, backhandCount: Int)
    
    func didUpdateMotion(_ manager: MotionManager, gravityStr: String, rotationStr: String, accelerationStr: String, attitudeStr: String)
}
class MotionManager {
    let motionManager = CMMotionManager()
    let queue = OperationQueue()
    let wristLocationIsLeft = WKInterfaceDevice.current().wristLocation == .left
    
    //constant based on data, tuned for your needs
    let yawThreshold = 1.95 //radians
    let rateThreshold = 5.5  //radians/sec
    let resetThreshold = 5.5 * 0.05 // to avoid double counting on the return swing
    
    //let app use 50hz data and buffer going to hold data
    let sampleInterval = 1.0 / 30
    let rateAlongGravityBuffer = RunningBuffer(size: 30)
    
    weak var delegate: MotionManagerDelegate?
    
    //swing counts
    var forehandCount = 0
    var backhandCount = 0
    
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
        // 2. Since this is timeseries data, we want to include the
        //    time we log the measurements (in ms since it's
        //    recording every .02s)
        let timestamp = Date().timeIntervalSince1970
            //take avg of acceleration
            //because sometimes good pattern only in x or y
        InterfaceController.watchData.accX.append((deviceMotion.userAcceleration.x + deviceMotion.userAcceleration.y + deviceMotion.userAcceleration.z) / 3.0)
        InterfaceController.watchData.yaw.append(deviceMotion.attitude.yaw)
        
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
        // 4. update values in the UI
        updateMetricsDelegate();
        
        
//        let gravity = deviceMotion.gravity
//        let rotationRate = deviceMotion.rotationRate
//
//        let rateAlongGravity = rotationRate.x * gravity.x // r.g
//                            + rotationRate.y * gravity.y
//                            + rotationRate.z * gravity.z
//        rateAlongGravityBuffer.addSample(rateAlongGravity)
//
//        if !rateAlongGravityBuffer.isFull() {
//            return
//        }
//
//        let accumulatedYawRot = rateAlongGravityBuffer.sum() * sampleInterval
//        let peakRate = accumulatedYawRot > 0 ?
//            rateAlongGravityBuffer.max() : rateAlongGravityBuffer.min()
//
//        if (accumulatedYawRot < -yawThreshold && peakRate < -rateThreshold) {
//            // Counter clockwise swing.
//            if (wristLocationIsLeft) {
//                incrementBackhandCountAndUpdateDelegate()
//            } else {
//                incrementForehandCountAndUpdateDelegate()
//            }
//        } else if (accumulatedYawRot > yawThreshold && peakRate > rateThreshold) {
//            // Clockwise swing.
//            if (wristLocationIsLeft) {
//                incrementForehandCountAndUpdateDelegate()
//            } else {
//                incrementBackhandCountAndUpdateDelegate()
//            }
//        }
//
//        // Reset after letting the rate settle to catch the return swing.
//        if (recentDetection && abs(rateAlongGravityBuffer.recentMean()) < resetThreshold) {
//            recentDetection = false
//            rateAlongGravityBuffer.reset()
//        }
    }
    
    func resetAllState() {
        rateAlongGravityBuffer.reset()
        
        forehandCount = 0
        backhandCount = 0
        recentDetection = false
        
        updateForehandSwingDelegate()
        updateBackhandSwingDelegate()
    }
    
    func updateMetricsDelegate() {
        delegate?.didUpdateMotion(self,gravityStr:gravityStr, rotationStr: rotationStr, accelerationStr: accelerationStr, attitudeStr: attitudeStr)
    }
    
    func incrementForehandCountAndUpdateDelegate() {
        if (!recentDetection) {
            forehandCount += 1
            recentDetection = true
            
            print("Forehand swing. Count: \(forehandCount)")
            updateForehandSwingDelegate()
        }
    }
    
    func incrementBackhandCountAndUpdateDelegate() {
        if (!recentDetection) {
            backhandCount += 1
            recentDetection = true
            
            print("Backhand swing. Count: \(backhandCount)")
            updateBackhandSwingDelegate()
        }
    }
    
    func updateForehandSwingDelegate() {
        delegate?.didUpdateForehandSwingCount(self, forehandCount: forehandCount)
    }
    
    func updateBackhandSwingDelegate() {
        delegate?.didUpdateBackhandSwingCount(self, backhandCount: backhandCount)
    }
}
