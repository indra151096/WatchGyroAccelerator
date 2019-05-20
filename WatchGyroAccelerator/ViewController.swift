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
    
    @IBOutlet weak var label: UILabel!
    var audioPlayer = AVAudioPlayer()
    var beatPlayer = AVAudioPlayer()
    var isPlaying = false
    let constraintHeight: CGFloat = 896.0
    @IBOutlet weak var volumeView: UIView!
    @IBOutlet weak var volumeHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var beatView: UIView!
    
    func receiveRequest(_ detection: String) {
        print("DETECT: \(detection)")
        updateLabel(labelStr: "3.2.1")
    }
    
    func receiveRequestData(_ data: WatchLog) {
        //this all section run in another thread
        //will not block the UI
        print("ACC min: \(data.accX.min()) max: \(data.accX.max())")
        print("YAW min: \(data.yaw.min()) max: \(data.yaw.max())")
        
        self.playAudio()
        /*var accXmin = data.accX.min()!
        var accXmax = data.accX.max()!

        for item in data.accX {
            usleep(50000)
            let volume = Float ((item + abs(accXmin)) / (accXmax + abs(accXmin)))
            self.audioPlayer.setVolume(volume, fadeDuration: 0)
            print("Volume: \(volume)")
        }*/
        
        let yawMin = data.yaw.min()!
        let yawMax = data.yaw.max()!
        
        let accMin = data.accX.min()!
        let accMax = data.accX.max()!
        
        let beatBound = (accMax + accMin) / 2.0
        print("BOUND: \(beatBound)")
        
        let queueMusic = DispatchQueue(label: "queueMusic")
        let queueBeat = DispatchQueue(label: "queueBeat")
        self.beatPlayer.setVolume(1, fadeDuration: 0)

        for i in 0...data.yaw.count-1 {
            queueMusic.sync {
                //music
                    let volume = Float ((data.yaw[i] + abs(yawMin)) / (yawMax + abs(yawMin)))
                
                
                DispatchQueue.main.async {
                    //max constaint 896
                    UIView.animate(withDuration: 0.1, delay: 0, options: .curveEaseInOut, animations: {
                        
                        let width = self.constraintHeight-(CGFloat(volume) * self.constraintHeight)
                        print("WIDTH: \(width)")
                        self.volumeHeightConstraint.constant = width
                        self.view.layoutIfNeeded()
                        self.label.text = String(format: "%.0f", 100.0 - (width/self.constraintHeight*100.0))
                    }, completion: nil)
                }
                    usleep(100000)
                    self.audioPlayer.setVolume(volume, fadeDuration: 0)
                    print("Volume: \(volume)")
            
            }
            
            
            queueBeat.async {
                //switch beat on and off
                if data.accX[i] < beatBound {
                    //self.beatPlayer.setVolume(0, fadeDuration: 0)
                    print("Beat: 0 from data \(data.accX[i])")
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
    
    func updateLabel(labelStr: String) {
        DispatchQueue.main.async { // Correct
            self.label.text = labelStr
        }
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
        print("try play")
        if isPlaying {
            audioPlayer.pause()
            isPlaying = false
            print("not")
        }
        else {
            audioPlayer.play()
            isPlaying = true
            print("play")
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
        
        // Do any additional setup after loading the view.
        label.text = "count"
        
        setupAudio(fileName: "bensound-hey", isMusic: true)
        setupAudio(fileName: "kick", isMusic: false)
    }


}

