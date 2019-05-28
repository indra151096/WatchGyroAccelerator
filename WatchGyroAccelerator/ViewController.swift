//
//  ViewController.swift
//  WatchGyroAccelerator
//
//  Created by Indra Sumawi on 16/05/19.
//  Copyright © 2019 Indra Sumawi. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController, SessionHandlerDelegate {
    
    var audioPlayer = AVAudioPlayer()
    var beatPlayer = AVAudioPlayer()
    var isPlaying = false
    let constraintHeight: CGFloat = 896.0
    @IBOutlet weak var volumeView: UIView!
    @IBOutlet weak var volumeHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var beatView: UIView!
    @IBOutlet weak var countDownLabel: UILabel!
    
    func receiveRequest(_ detection: String) {
        print("DETECT: \(detection)")
        countDown(range: 3)
        DispatchQueue.global().async {
            print("GLOBAL")
            sleep(3)
            self.countDown(range: 5)
        }
    }
    
    func countDown(range: Int) {
        DispatchQueue.global().async {
            for i in 1...range {
                DispatchQueue.main.async {
                    self.countDownLabel.transform = .init(scaleX: 1, y: 1)
                    self.countDownLabel.text = "\(range+1-i)"
                    self.countDownLabel.alpha = 1
                    UIView.animate(withDuration: 1, delay: 0, animations: {
                        self.countDownLabel.transform = .init(scaleX: 5, y: 5)
                        self.countDownLabel.alpha = 0
                        
                        print("CT: " + self.countDownLabel.text!)
                    }, completion: nil)
                }
                sleep(1)
            }
        }
    }
    
    func receiveRequestData(_ data: WatchLog) {
        //this all section run in another thread
        //will not block the UI
        
        self.playAudio()
        
        let yawMin = data.yaw.min()!
        let yawMax = data.yaw.max()!
        
        let pitchMin = data.pitch.min()!
        let pitchMax = data.pitch.max()!
        
//        let accMin = data.accX.min()!
//        let accMax = data.accX.max()!
        
        //tune
        let beatBound = 0.4//(accMax + accMin) / 2.0
        print("BOUND: \(beatBound)")
        
        let queueMusic = DispatchQueue(label: "queueMusic")
        let queueBeat = DispatchQueue(label: "queueBeat")
        self.beatPlayer.setVolume(1, fadeDuration: 0)

        print("MIN: \(yawMin)")
        var volume: Float = 0.0
        for i in 0...data.yaw.count-1 {
            queueMusic.sync {
                //music
                //let volume = Float ((data.yaw[i] + abs(yawMin)) / (yawMax + abs(yawMin)))
                /*if yawMin < 0 {
                    volume = Float ((data.yaw[i] + abs(yawMin)) / (yawMax + abs(yawMin)))
                }
                else {
                    volume = Float ((data.yaw[i] - yawMin) / (yawMax - yawMin))
                }*/
                
                if yawMin < 0 {
                    volume = Float ((data.pitch[i] + abs(pitchMin)) / (pitchMax + abs(pitchMin)))
                }
                else {
                    volume = Float ((data.pitch[i] - pitchMin) / (pitchMax - pitchMin))
                }
                
                DispatchQueue.main.async {
                    UIView.animate(withDuration: 0.1, delay: 0, options: .curveEaseInOut, animations: {
                        //update UI when volume change
                        let width = self.constraintHeight-(CGFloat(volume) * self.constraintHeight)
                        self.volumeHeightConstraint.constant = width
                        self.view.layoutIfNeeded()
                    }, completion: nil)
                }
                //delay a bit
                usleep(100000)
                self.audioPlayer.setVolume(volume, fadeDuration: 0)
            }
            
            
            queueBeat.async {
                //switch beat on and off
                if data.accX[i] < beatBound {
                    //print("Beat: 0 from data \(data.accX[i])")
                }
                else {
                    if self.isPlaying {
                    usleep(250000)
                    DispatchQueue.main.async {
                        self.beatView.alpha = 1
                        self.beatView.transform = CGAffineTransform(scaleX: 1, y: 1)
                        self.beatView.frame.origin = .init(x: Double.random(in: 1...300), y: Double.random(in: 1...896))
                        UIView.animate(withDuration: 0.7, delay: 0, options: .curveEaseInOut, animations: {
                            self.beatView.transform = CGAffineTransform(scaleX: 5, y: 5)
                            self.beatView.alpha = 0
                        }, completion: nil)
                    }
                    self.beatPlayer.play()
                    print("Beat: 1 from data \(data.accX[i])")
                    }
                }
            }
        }
        print("STOP")
        self.stopAudio()
    }
    
    func setupAudio(fileName: String, isMusic: Bool) {
        let path: String
        if (isMusic) {
            //music by https://www.bensound.com
            path = Bundle.main.path(forResource: fileName, ofType: "mp3")!
        }
        else {
            //music by https://sampleswap.org/
            path = Bundle.main.path(forResource: fileName, ofType: "wav")!
        }
        
        let url = URL(fileURLWithPath: path)
        
        do {
            if isMusic {
                audioPlayer = try AVAudioPlayer(contentsOf: url)
            }
            else {
                beatPlayer = try AVAudioPlayer(contentsOf: url)
            }
        }
        catch {
            print("CAN'T LOAD")
        }
    }
    
    func playAudio() {
        if isPlaying {
            audioPlayer.pause()
            isPlaying = false
        }
        else {
            audioPlayer.play()
            isPlaying = true
        }
    }
    
    func stopAudio() {
        audioPlayer.stop()
        beatPlayer.stop()
        beatPlayer.currentTime = 0
        audioPlayer.currentTime = 0
        isPlaying = false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        SessionHandler.shared.delegate = self
        
        setupAudio(fileName: "bensound-hey", isMusic: true)
        setupAudio(fileName: "kick", isMusic: false)
    }
}

