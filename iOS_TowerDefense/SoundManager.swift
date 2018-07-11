//
//  ViewController.swift
//  Sound Manager
//
//  Created by Alex Rochon on 2018-06-26.
//  Copyright © 2018 Alex Rochon. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {
    
    var soundEffect: AVAudioPlayer = AVAudioPlayer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        let soundFile = Bundle.main.path(forResource: "sound1", ofType: ".wav")
        
        do {
            try soundEffect = AVAudioPlayer(contentsOf: URL (fileURLWithPath: soundFile!))
        }
            
        catch {
            print(error)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func PlaySound(_ sender: Any) {
        soundEffect.play()
    }
    
    @IBAction func PauseSound(_ sender: Any) {
        soundEffect.stop()
    }
    
    @IBAction func StopSound(_ sender: Any) {
        soundEffect.stop()
        soundEffect.currentTime = 0.0
    }
}

