//
//  WorkoutManager.swift
//  WatchOSGyroAccelerator Extension
//
//  Created by Indra Sumawi on 16/05/19.
//  Copyright © 2019 Indra Sumawi. All rights reserved.
//

import Foundation
import HealthKit

/**
 `WorkoutManagerDelegate` exists to inform delegates of swing data changes.
 These updates can be used to populate the user interface.
 */
protocol WorkoutManagerDelegate: class {
    func didUpdateMotion(_ manager: WorkoutManager, gravityStr: String, rotationStr: String, accelerationStr: String, attitudeStr: String)
}

class WorkoutManager: MotionManagerDelegate {
    
    let motionManager = MotionManager()
    let healthStore = HKHealthStore()
    
    weak var delegate: WorkoutManagerDelegate?
    var session: HKWorkoutSession?
    
    init() {
        motionManager.delegate = self
    }
    
    func startDetection() {
        print("RECORD START")
        //if already start workout, then do nothing
        if (session != nil) {
            return
        }
        
        //configure workout session
        let workoutConfiguration = HKWorkoutConfiguration()
        workoutConfiguration.activityType = .other
        workoutConfiguration.locationType = .indoor
        
        do {
            session = try HKWorkoutSession(healthStore: healthStore, configuration: workoutConfiguration)
        } catch {
            fatalError("Unable to create the workout session!")
        }
        
        //reset
        InterfaceController.watchData.accX.removeAll()
        InterfaceController.watchData.yaw.removeAll()
        InterfaceController.watchData.pitch.removeAll()
        // Start the workout session and device motion updates.
        session?.startActivity(with: .init())
        motionManager.startUpdates()
    }
    
    func stopDetection() {
        // If we have already stopped the workout, then do nothing.
        if (session == nil) {
            return
        }
        
        // Stop the device motion updates and workout session.
        motionManager.stopUpdates()
        session?.stopActivity(with: .init())
        
        // Clear the workout session.
        session = nil
    }

    func didUpdateMotion(_ manager: MotionManager, gravityStr: String, rotationStr: String, accelerationStr: String, attitudeStr: String) {
        delegate?.didUpdateMotion(self,gravityStr:gravityStr, rotationStr: rotationStr, accelerationStr: accelerationStr, attitudeStr: attitudeStr)
    }
}
