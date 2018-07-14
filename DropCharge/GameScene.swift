import SpriteKit
import CoreMotion
import UIKit

// MARK: - Game States
enum GameStatus: Int {
  case waitingForTap = 0
  case waitingForStar = 1
  case playing = 2
  case gameOver = 3
}

enum PlayerStatus: Int {
  case idle = 0
  case jump = 1
  case fall = 2
  case dead = 4
}

struct PhysicsCategory {
  static let None: UInt32              = 0
  static let Player: UInt32            = 0b1      // 1
  static let PlatformNormal: UInt32    = 0b10     // 2
  static let PlatformBreakable: UInt32 = 0b100    // 4
  static let CoinNormal: UInt32        = 0b1000   // 8
  static let CoinSpecial: UInt32       = 0b10000  // 16
  static let Edges: UInt32             = 0b100000 // 32
}

class GameScene: SKScene, SKPhysicsContactDelegate {
  // MARK: - Properties
  var bgNode: SKNode!
  var fgNode: SKNode!
  var backgroundOverlayTemplate: SKNode!
  var backgroundOverlayHeight: CGFloat!
  var player: SKSpriteNode!
  var deathwall: SKSpriteNode!
  
  var platform5Across: SKSpriteNode!
  var coinArrow: SKSpriteNode!

  var platformArrow: SKSpriteNode!
  var platformDiagonal: SKSpriteNode!
  var breakArrow: SKSpriteNode!
  var break5Across: SKSpriteNode!
  var breakDiagonal: SKSpriteNode!
  var break5Meteor: SKSpriteNode!
  var break5MeteorLeft: SKSpriteNode!
  var break5MeteorRight: SKSpriteNode!
  var coin5Across: SKSpriteNode!
  var coinDiagonal: SKSpriteNode!
  var coinCross: SKSpriteNode!
  var coinS5Across: SKSpriteNode!
  var coinSDiagonal: SKSpriteNode!
  var coinSCross: SKSpriteNode!
  var coinSArrow: SKSpriteNode!
  
  var lastOverlayPosition = CGPoint.zero
  var lastOverlayHeight: CGFloat = 0.0
  var levelPositionY: CGFloat = 0.0
  
  var gameState = GameStatus.waitingForTap
  var playerState = PlayerStatus.idle
  
  let motionManager = CMMotionManager()
  var xAcceleration = CGFloat(0)
  let cameraNode = SKCameraNode()
  
  var lastUpdateTimeInterval: TimeInterval = 0
  var deltaTime: TimeInterval = 0
  var lives = 1
  
  var maxY: CGFloat = 0.0
  var posWall: CGFloat = 1200.0
  var playerTrail: SKEmitterNode!
  
  
  
  // Sound Effects
  let soundStarDrop = SKAction.playSoundFileNamed("bombDrop.wav", waitForCompletion: true)
  let soundSuperBoost = SKAction.playSoundFileNamed("nitro.wav", waitForCompletion: false)
  let soundTickTock = SKAction.playSoundFileNamed("tickTock.wav", waitForCompletion: true)
  let soundBoost = SKAction.playSoundFileNamed("boost.wav", waitForCompletion: false)
  let soundJump = SKAction.playSoundFileNamed("jump.wav", waitForCompletion: false)
  let soundCoin = SKAction.playSoundFileNamed("coin1.wav", waitForCompletion: false)
  let soundBrick = SKAction.playSoundFileNamed("brick.caf", waitForCompletion: false)
  let soundGameOver = SKAction.playSoundFileNamed("player_die.wav", waitForCompletion: false)
  
  var coinAnimation: SKAction!
  var coinSpecialAnimation: SKAction!
 
  var playerAnimationJump: SKAction!
  var playerAnimationFall: SKAction!
  var playerAnimationSteerLeft: SKAction!
  var playerAnimationSteerRight: SKAction!
  var currentPlayerAnimation: SKAction?
  
  let gameGain: CGFloat = 2.5
  var redAlertTime: TimeInterval = 0
  
  var scoreLabel:SKLabelNode!
  var score:Int = 0 {
    didSet {
      scoreLabel.text = "Score: \(score)"
    }
  }
  
  // MARK: - Setup
  override func didMove(to view: SKView) {
    setupNodes()
    setupLevel()
    setupPlayer()
    setupCoreMotion()
    //playBackgroundMusic(name: "fleeTheme.caf")
    physicsWorld.contactDelegate = self
    
    let scale = SKAction.scale(to: 1.0, duration: 0.5)
    fgNode.childNode(withName: "Ready")!.run(scale)
    scoreLabel = SKLabelNode(text: "Score: 0")
    
    scoreLabel.fontName = "AmericanTypewriter-Bold"
    scoreLabel.position = CGPoint(x: 100, y: self.frame.size.height - 60)
    scoreLabel.zPosition = 11
    scoreLabel.fontSize = 36
    scoreLabel.fontColor = UIColor.white
    score = 0
    
    self.addChild(scoreLabel)
    
    
    
    playerAnimationJump = setupAnimationWithPrefix("player_fly_", start: 23, end: 23, timePerFrame: 0.1, duration: 10000)
    playerAnimationFall = setupAnimationWithPrefix("player_fly_", start: 23, end: 23, timePerFrame: 0.1, duration: 10000)
    playerAnimationSteerLeft = setupAnimationWithPrefix("player_fly_", start: 21, end: 22, timePerFrame: 0.1, duration: 10000)
    playerAnimationSteerRight = setupAnimationWithPrefix("player_fly_", start: 24, end: 25, timePerFrame: 0.1, duration: 10000)
  }
  
  func setupNodes() {
    let worldNode = childNode(withName: "World")!
    bgNode = worldNode.childNode(withName: "Background")!
    backgroundOverlayTemplate = bgNode.childNode(withName: "Overlay")!.copy() as! SKNode
    backgroundOverlayHeight = backgroundOverlayTemplate.calculateAccumulatedFrame().height
    fgNode = worldNode.childNode(withName: "Foreground")!
    player = fgNode.childNode(withName: "Player") as! SKSpriteNode
    setupDeathwall()
    fgNode.childNode(withName: "Star")?.run(SKAction.hide())

    
    platformArrow = loadForegroundOverlayTemplate("PlatformArrow")
    platform5Across = loadForegroundOverlayTemplate("Platform5Across")
    platformDiagonal = loadForegroundOverlayTemplate("PlatformDiagonal")
    breakArrow = loadForegroundOverlayTemplate("BreakArrow")
    break5Across = loadForegroundOverlayTemplate("Break5Across")
    breakDiagonal = loadForegroundOverlayTemplate("BreakDiagonal")
    break5Meteor = loadForegroundOverlayTemplate("Break5Meteor")
    break5MeteorLeft = loadForegroundOverlayTemplate("Break5Meteor Left")
    break5MeteorRight = loadForegroundOverlayTemplate("Break5Meteor Right")
    
    
    coinAnimation = setupAnimationWithPrefix("powerup05_", start: 1, end: 6, timePerFrame: 0.15, duration: 10000)
    coinSpecialAnimation = setupAnimationWithPrefix("powerup01_", start: 1, end: 1, timePerFrame: 0.083, duration: 10000)
    
    coin5Across = loadForegroundOverlayTemplate("Coin5Across")
    coinDiagonal = loadForegroundOverlayTemplate("CoinDiagonal")
    coinCross = loadForegroundOverlayTemplate("CoinCross")
    coinArrow = loadForegroundOverlayTemplate("CoinArrow")
    coinS5Across = loadForegroundOverlayTemplate("CoinS5Across")
    coinSDiagonal = loadForegroundOverlayTemplate("CoinSDiagonal")
    coinSCross = loadForegroundOverlayTemplate("CoinSCross")
    coinSArrow = loadForegroundOverlayTemplate("CoinSArrow")
    
    addChild(cameraNode)
    camera = cameraNode
  }
  
  func setupLevel() {
    // Place initial platform
    let initialPlatform = platform5Across.copy() as! SKSpriteNode
    var overlayPosition = player.position
    overlayPosition.y = player.position.y - (player.size.height * 0.5 + initialPlatform.size.height * 0.20)
    initialPlatform.position = overlayPosition
    fgNode.addChild(initialPlatform)
    lastOverlayPosition = overlayPosition
    lastOverlayHeight = initialPlatform.size.height / 2.0
    
    // Create random level
    levelPositionY = bgNode.childNode(withName: "Overlay")!.position.y + backgroundOverlayHeight
    while lastOverlayPosition.y < levelPositionY {
      addRandomForegroundOverlay()
    }
  }
  
//  func playBackgroundMusic(name: String) {
//    if let backgroundMusic = childNode(withName: "backgroundMusic"){
//      backgroundMusic.removeFromParent()
//    }
//    let music = SKAudioNode(fileNamed: name)
//    music.name = "backgroundMusic"
//    music.autoplayLooped = true
//    addChild(music)
//  }
  
  func setupPlayer() {
    player.physicsBody = SKPhysicsBody(circleOfRadius: player.size.width * 0.3)
    player.physicsBody!.isDynamic = false
    player.physicsBody!.allowsRotation = false
    player.physicsBody!.categoryBitMask = PhysicsCategory.Player
    player.physicsBody!.collisionBitMask = 0
    
   
  }
  
  func setupDeathwall() {
   // deathwall.physicsBody = SKPhysicsBody(circleOfRadius: deathwall.size.width)
   // deathwall.physicsBody!.isDynamic = false
    deathwall = fgNode.childNode(withName: "deathwall") as! SKSpriteNode
    let emitter = SKEmitterNode(fileNamed: "deathwall.sks")!
    emitter.particlePositionRange = CGVector (dx: size.width * 1.125, dy: 0.0)
    emitter.advanceSimulationTime(3.0)
    deathwall.addChild(emitter)

  }
  
  func addTrail(name: String) -> SKEmitterNode {
    let trail = SKEmitterNode(fileNamed: name)!; trail.zPosition = -1
    player.addChild(trail)
    return trail }
  
  
  func removeTrail(trail: SKEmitterNode) {
    trail.numParticlesToEmit = 1
    trail.run(SKAction.removeFromParentAfterDelay(1.0))
  }
  
  func setupCoreMotion() {
    motionManager.accelerometerUpdateInterval = 0.2
    let queue = OperationQueue()
    motionManager.startAccelerometerUpdates(to: queue, withHandler:
      { accelerometerData, error in
        guard let accelerometerData = accelerometerData else {
          return
        }
        let acceleration = accelerometerData.acceleration
        self.xAcceleration = CGFloat(acceleration.x) * 0.75 + self.xAcceleration * 0.50
    })
  }
  
  // MARK: - Overlay nodes
  func loadForegroundOverlayTemplate(_ fileName: String) -> SKSpriteNode {
    let overlayScene = SKScene(fileNamed: fileName)!
    let overlayTemplate = overlayScene.childNode(withName: "Overlay")
    return overlayTemplate as! SKSpriteNode
  }
  
  func createForegroundOverlay(_ overlayTemplate: SKSpriteNode, flipX: Bool) {
    let foregroundOverlay = overlayTemplate.copy() as! SKSpriteNode
    lastOverlayPosition.y = lastOverlayPosition.y + (lastOverlayHeight + (foregroundOverlay.size.height / 2.0))
    lastOverlayHeight = foregroundOverlay.size.height / 2.0
    foregroundOverlay.position = lastOverlayPosition
    if flipX == true {
      foregroundOverlay.xScale = -1.0
    }
    fgNode.addChild(foregroundOverlay)
    foregroundOverlay.isPaused = false
  }
  
  func addRandomForegroundOverlay() {
    let overlaySprite: SKSpriteNode!
    var flipH = false
    let platformPercentage = 60
    
    if Int.random(min: 1, max: 100) <= platformPercentage {
      if Int.random(min: 1, max: 100) <= 20 {
        // Create standard platforms 50%
        switch Int.random(min: 0, max: 3) {
        case 0:
          overlaySprite = platformArrow
        case 1:
          overlaySprite = platform5Across
        case 2:
          overlaySprite = platformDiagonal
        case 3:
          overlaySprite = platformDiagonal
          flipH = true
        default:
          overlaySprite = platformArrow
        }
      } else {
        // Create breakable platforms 50%
        switch Int.random(min: 0, max: 6) {
        case 0:
          overlaySprite = breakArrow
        case 1:
          overlaySprite = break5Across
        case 2:
          overlaySprite = breakDiagonal
        case 3:
          overlaySprite = breakDiagonal
        case 4:
          overlaySprite = break5Meteor
        case 5:
          overlaySprite = break5MeteorLeft
        case 6:
          overlaySprite = break5MeteorRight
          flipH = true
        default:
          overlaySprite = breakArrow
        }
      }
    } else {
      if Int.random(min: 1, max: 100) <= 60 {
        // Create standard coins 75%
        switch Int.random(min: 0, max: 4) {
        case 0:
          overlaySprite = coinArrow
        case 1:
          overlaySprite = coin5Across
        case 2:
          overlaySprite = coinDiagonal
        case 3:
          overlaySprite = coinDiagonal
          flipH = true
        case 4:
          overlaySprite = coinCross
        default:
          overlaySprite = coinArrow
        }
      } else {
        // Create special coins 25%
        switch Int.random(min: 0, max: 4) {
        case 0:
          overlaySprite = coinSArrow
        case 1:
          overlaySprite = coinS5Across
        case 2:
          overlaySprite = coinSDiagonal
        case 3:
          overlaySprite = coinSDiagonal
          flipH = true
        case 4:
          overlaySprite = coinSCross
        default:
          overlaySprite = coinSArrow
        }
      }
      animateCoinsInOverlay(overlaySprite)
    }
    
    createForegroundOverlay(overlaySprite, flipX: flipH)
  }
  
  func createBackgroundOverlay() {
    let backgroundOverlay = backgroundOverlayTemplate.copy() as! SKNode
    backgroundOverlay.position = CGPoint(x: 0.0, y: levelPositionY)
    bgNode.addChild(backgroundOverlay)
    levelPositionY += backgroundOverlayHeight
  }
  
  // MARK: - Events
  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    if gameState == .waitingForTap {
      starDrop()
    } else if gameState == .gameOver {
      let newScene = GameScene(fileNamed:"GameScene")
      newScene!.scaleMode = .aspectFill
      let reveal = SKTransition.flipHorizontal(withDuration: 0.5)
      view?.presentScene(newScene!, transition: reveal)
    }
  }
  
  func starDrop() {
    gameState = .waitingForStar
    // Scale out title & ready label.
    let scale = SKAction.scale(to: 0, duration: 0.4)
    fgNode.childNode(withName: "Title")!.run(scale)
    fgNode.childNode(withName: "Ready")!.run(SKAction.sequence([SKAction.wait(forDuration: 0.2), scale]))
    // Bounce star
    let scaleUp = SKAction.scale(to: 3.0, duration: 0.25)
    let scaleDown = SKAction.scale(to: 2.0, duration: 0.25)
    let sequence = SKAction.sequence([scaleUp, scaleDown])
    let repeatSeq = SKAction.repeatForever(sequence)
    fgNode.childNode(withName: "Star")!.run(SKAction.unhide())
    fgNode.childNode(withName: "Star")!.run(repeatSeq)
    run(SKAction.sequence([
      soundStarDrop,
      soundTickTock,
      SKAction.run(startGame)
      ]))
  }
  
  func startGame() {
    let star = fgNode.childNode(withName: "Star")!



    star.removeFromParent()
   
    gameState = .playing
    player.physicsBody!.isDynamic = true
    superBoostPlayer()

    let music = SKAudioNode(fileNamed: "fleeTheme.au")
    music.name = "music"
    music.autoplayLooped = true
    addChild(music)
    }
  
  func gameOver() {
    // 1
    gameState = .gameOver
    playerState = .dead
    // 2
    physicsWorld.contactDelegate = nil
    player.physicsBody?.isDynamic = false
    // 3
    let moveUp = SKAction.moveBy(x: 0.0, y: size.height/2.0, duration: 0.5)
    moveUp.timingMode = .easeOut
    let moveDown = SKAction.moveBy(x: 0.0, y: -(size.height * 1.5), duration: 1.0)
    moveDown.timingMode = .easeIn
    player.run(SKAction.sequence([moveUp, moveDown]))
    run(soundGameOver)
    // 4
    let gameOverSprite = SKSpriteNode(imageNamed: "GameOver")
    gameOverSprite.position = camera!.position
    gameOverSprite.zPosition = 10
    addChild(gameOverSprite)
    if let music = childNode(withName: "music") {
      music.removeFromParent()
      
    }
    
   
   
  }
  
  func setPlayerVelocity(_ amount: CGFloat) {
    player.physicsBody!.velocity.dy = max(player.physicsBody!.velocity.dy, amount * gameGain)
  }
  
  func jumpPlayer() {
    setPlayerVelocity(650)
    posWall += 60
  }
  func slowPlayer() {
    setPlayerVelocity(100)
    posWall -= 100
  }
  
  func boostPlayer() {
    setPlayerVelocity(1200)
    posWall += 120
    
  }
  
  func superBoostPlayer() {
    setPlayerVelocity(1700)
    posWall += 1400
  }
  
  func didBegin(_ contact: SKPhysicsContact) {
    let other = contact.bodyA.categoryBitMask == PhysicsCategory.Player ? contact.bodyB : contact.bodyA
    switch other.categoryBitMask {
    case PhysicsCategory.CoinNormal:
      if (other.node as? SKSpriteNode) != nil {
        (other.node as! SKSpriteNode).removeFromParent()
        jumpPlayer()
        run(soundCoin)
        score += 10
        print(score)
      }
    case PhysicsCategory.CoinSpecial:
      if (other.node as? SKSpriteNode) != nil {
        print(lives)
        

        boostPlayer()
        run(soundBoost)
      }
    case PhysicsCategory.PlatformNormal:
      if let platform = other.node as? SKSpriteNode {
          platformAction(platform, breakable: false)
          jumpPlayer()
          platform.removeFromParent()
          run(soundJump)
      }
    case PhysicsCategory.PlatformBreakable:
      if let platform = other.node as? SKSpriteNode {
          platformAction(platform, breakable: true)
          slowPlayer()
          platform.removeFromParent()


      }
    default:
      break
    }
  }
  
  // MARK: - Updates
  
  override func update(_ currentTime: TimeInterval) {
    // 1
    if lastUpdateTimeInterval > 0 {
      deltaTime = currentTime - lastUpdateTimeInterval
    } else {
      deltaTime = 0
    }
    lastUpdateTimeInterval = currentTime
    // 2
    if isPaused {
      return
    }
    // 3
    if gameState == .playing {
      updateCamera()
      updateLevel()
      updatePlayer()



     
    }
  }
  
  func updateCamera() {
    
  
   
    // 5
    camera!.position.y = player.position.y + 400
  }
  
  func sceneCropAmount() -> CGFloat {
    guard let view = view else {
      return 0
    }
    let scale = view.bounds.size.height / size.height
    let scaledWidth = size.width * scale
    let scaledOverlap = scaledWidth - view.bounds.size.width
    return scaledOverlap / scale
  }
  
  func updatePlayer() {
    
    player.run(SKAction.repeatForever(self.playerAnimationJump))
    
    setPlayerVelocity(350)
    let deathY = maxY - posWall
    
    posWall -= 0.6
    
    deathwall.position.y = deathY
    
    if(posWall < (0 + player.size.height)){
      gameOver()
    }
    
    if(posWall > 1200){
      posWall = 1200
    }
    
    if(lives < 0){
      gameOver()
    }
    if(player.position.y > maxY){
      maxY = player.position.y
    }
    
    if(player.position.y < deathY){
      lives -= 1
      superBoostPlayer()
    }
    // Set velocity based on core motion
    player.physicsBody?.velocity.dx = xAcceleration * 2500.0
    
    // Wrap player around edges of screen
    var playerPosition = convert(player.position, from: fgNode)
    let rightLimit = size.width/2 - sceneCropAmount()/2 + player.size.width/2
    let leftLimit = -rightLimit
    
    if playerPosition.x < leftLimit {
      playerPosition = convert(CGPoint(x: rightLimit, y: 0.0), to: fgNode)
      player.position.x = playerPosition.x
    }
    else if playerPosition.x > rightLimit {
      playerPosition = convert(CGPoint(x: leftLimit, y: 0.0), to: fgNode)
      player.position.x = playerPosition.x
    }
    // Check player state
    if player.physicsBody!.velocity.dy < CGFloat(0.0) && playerState != .fall {
      playerState = .fall
    } else if player.physicsBody!.velocity.dy > CGFloat(0.0) && playerState != .jump {
      playerState = .jump
    }
    // Animate player
    if playerState == .jump {
      if abs(player.physicsBody!.velocity.dx) > 100.0 {
        if player.physicsBody!.velocity.dx > 0 {
          runPlayerAnimation(playerAnimationSteerRight)
        } else {
          runPlayerAnimation(playerAnimationSteerLeft)
        }
      } else {
        runPlayerAnimation(playerAnimationJump)
      }
    } else if playerState == .fall {
      runPlayerAnimation(playerAnimationFall)
    }
  }
  

  
  func updateLevel() {
    scoreLabel.position = CGPoint(x: player.position.x + player.size.height, y: player.position.y + player.size.height)
    let cameraPos = camera!.position
    if cameraPos.y > levelPositionY - size.height {
      createBackgroundOverlay()
      while lastOverlayPosition.y < levelPositionY {
        addRandomForegroundOverlay()
      }
    }
    
    // remove old foreground nodes...
    for fgChild in fgNode.children {
      let nodePos = fgNode.convert(fgChild.position, to: self)
      if !isNodeVisible(fgChild, positionY: nodePos.y) {
        fgChild.removeFromParent()
      }
    }
  }
  
  // MARK: - Particles
  
  
  
  
  // MARK: - Audio
  
  
  // MARK: - Animation
  func setupAnimationWithPrefix(_ prefix: String, start: Int, end: Int, timePerFrame: TimeInterval, duration: Float) -> SKAction {
    var textures: [SKTexture] = []
    for i in start...end {
      textures.append(SKTexture(imageNamed: "\(prefix)\(i)"))
    }
    return SKAction.animate(with: textures, timePerFrame: timePerFrame)
  }
  
  func animateCoinsInOverlay(_ overlay: SKSpriteNode) {
    overlay.enumerateChildNodes(withName: "*", using: { (node, stop) in
      if node.name == "special" {
        node.run(SKAction.repeatForever(self.coinSpecialAnimation))
      } else {
        node.run(SKAction.repeatForever(self.coinAnimation))
      }
    })
  }
  
  func runPlayerAnimation(_ animation: SKAction) {
    if animation != currentPlayerAnimation {
      player.removeAction(forKey: "playerAnimation")
      player.run(animation, withKey: "playerAnimation")
      currentPlayerAnimation = animation
    }
  }
  
  // MARK: - Screen Effects
 
  // MARK: - Sprite Effects
  func isNodeVisible(_ node: SKNode, positionY: CGFloat) -> Bool {
    if !camera!.contains(node) {
      if positionY < camera!.position.y - size.height * 2.0 {
        return false
      }
    }
    return true
  }
  

  
  func platformAction(_ sprite: SKSpriteNode, breakable: Bool) {
    let amount = CGPoint(x: 0, y: -75.0)
    let action = SKAction.screenShakeWithNode(sprite, amount: amount, oscillations: 10, duration: 2.0)
    sprite.run(action)

  }
  
}
