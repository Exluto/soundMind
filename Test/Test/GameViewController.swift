//
//  GameViewController.swift
//  Test
//
//  Created by King Brent the 3rd on 2018-07-04.
//  Copyright © 2018 King Brent the 3rd. All rights reserved.
//

import UIKit
import SpriteKit


class GameViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        let scene =
            GameScene(size:CGSize(width: 1536, height: 2048))
        let skView = self.view as! SKView
        skView.showsFPS = true
        skView.showsNodeCount = true
        skView.ignoresSiblingOrder = true
        scene.scaleMode = .aspectFill
        skView.presentScene(scene)
        }

    override var prefersStatusBarHidden: Bool {
    return true
    }
}

