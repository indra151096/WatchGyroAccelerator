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
    var isPlaying = false
    
    func receiveRequest(_ detection: String) {
        print("DETECT: \(detection)")
        updateLabel(labelStr: "3.2.1")
    }
    
    func receiveRequestData(_ data: WatchLog) {
        print("ACC min: \(data.accX.min()) max: \(data.accX.max())")
        print("YAW min: \(data.yaw.min()) max: \(data.yaw.max())")
        
        self.playAudio()
        var accXmin = data.accX.min()!
        var accXmax = data.accX.max()!
        for item in data.accX {
            usleep(50000)
            let volume = Float ((item + abs(accXmin)) / (accXmax + abs(accXmin)))
            self.audioPlayer.setVolume(volume, fadeDuration: 0)
            print("Volume: \(volume)")
        }
        
        self.stopAudio()
    }
    
    func updateLabel(labelStr: String) {
        DispatchQueue.main.async { // Correct
            self.label.text = labelStr
        }
    }
    
    func setupAudio() {
        //music by https://www.bensound.com
        let path = Bundle.main.path(forResource: "music", ofType: "mp3")!
        let url = URL(fileURLWithPath: path)
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
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
        audioPlayer.currentTime = 0
        isPlaying = false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        SessionHandler.shared.delegate = self
        
        // Do any additional setup after loading the view.
        label.text = "count"
        setupAudio()
    }


}

