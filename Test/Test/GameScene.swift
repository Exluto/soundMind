//
//  GameScene.swift
//  Test
//
//  Created by King Brent the 3rd on 2018-07-04.
//  Copyright © 2018 King Brent the 3rd. All rights reserved.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene {
    
    private var label : SKLabelNode?
    private var spinnyNode : SKShapeNode?
    
 
    override func didMove(to view: SKView) {
        backgroundColor = SKColor.black
    let background = SKSpriteNode(imageNamed: "background1")
        background.position = CGPoint(x: size.width/2, y: size.height/2)
        addChild(background);
        
        let mySize = background.size
        print("Size: \(mySize)")
        }
}

