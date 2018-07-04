//
//  GameScene.swift
//  iOS_TowerDefense
//
//  Created by Dad on 2018-06-25.
//  Copyright © 2018 Dad. All rights reserved.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene {
    
    var player = SKSpriteNode(imageNamed:"Player")
    var invisibleControlerSprite = SKSpriteNode()
    
    
    override func didMove(to view: SKView) {
        backgroundColor = SKColor.red
    }
    
    
}
