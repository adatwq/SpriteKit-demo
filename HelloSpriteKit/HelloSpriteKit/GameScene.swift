//
//  GameScene.swift
//  HelloSpriteKit
//
//  Created by WjdanMohammed on 04/08/2024.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene, SKPhysicsContactDelegate{
    var floor = SKSpriteNode()
    var player = SKSpriteNode(imageNamed: "run1")
    let runTextures = [
        SKTexture(imageNamed: "run1"),
        SKTexture(imageNamed: "run2"),
        SKTexture(imageNamed: "run3"),
        SKTexture(imageNamed: "run4")
    ]
    var runAnimation = SKAction()
    let jumpTextures =  SKTexture(imageNamed: "jump")
    var canJump = true
    var healthNodes = [SKSpriteNode(imageNamed: "heart-fill"),
                       SKSpriteNode(imageNamed: "heart-fill"),
                       SKSpriteNode(imageNamed: "heart-fill"),
                       SKSpriteNode(imageNamed: "heart-fill"),
                       SKSpriteNode(imageNamed: "heart-fill")]
    
    var fullHeartTexture = SKTexture(imageNamed: "heart-fill")
    var emptyHeartTexture = SKTexture(imageNamed: "heart")
    var health = 5
    
    // didMove method is called when the scene is presented by the SKView and is about to be displayed.
    override func didMove(to view: SKView) {
        self.backgroundColor = #colorLiteral(red: 0.7882352941, green: 0.8941176471, blue: 0.8117647059, alpha: 1)
        setupScene()
    }
    
    func setupScene() {
        // set up floor node
        floor.size = CGSize(width: self.frame.width - 10  , height: self.frame.height)
        floor.color = #colorLiteral(red: 0.4431372549, green: 0.7294117647, blue: 0.6666666667, alpha: 1)
        floor.position = CGPoint(x: frame.midX, y: frame.minY)
        floor.physicsBody = SKPhysicsBody(rectangleOf: floor.size)
        floor.physicsBody?.isDynamic = false
        floor.name = "floor"
        floor.physicsBody?.categoryBitMask = Category.floor.rawValue
        addChild(floor)
        
        // set up and position health nodes (hearts) in a row
        healthNodes[0].position = CGPoint(x: frame.minX + 120, y: frame.maxY - 140)
        healthNodes[0].size = CGSize(width: 40, height: 35)
        addChild(healthNodes[0])
        
        for i in 1..<healthNodes.count{
            healthNodes[i].position = CGPoint(x:  healthNodes[i-i].position.x + CGFloat((50 * i)) , y: frame.maxY - 140)
            healthNodes[i].size = CGSize(width: 40, height: 35)
            addChild(healthNodes[i])
        }
        
        // set up player node
        player.size = CGSize(width: 70, height: 88)
        player.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: player.size.width, height: player.size.height - 6))
        player.physicsBody?.isDynamic = true
        player.physicsBody?.affectedByGravity = true
        player.physicsBody?.restitution = 0.2
        player.zPosition = 1
        player.physicsBody?.categoryBitMask = Category.player.rawValue
        player.physicsBody?.contactTestBitMask = Category.floor.rawValue | Category.snake.rawValue
        player.name = "player"
        runAnimation = SKAction.animate(with: runTextures, timePerFrame: 0.2) // run animation
        player.run(SKAction.repeatForever(runAnimation))
        addChild(player)
        
        // configure and start enemy spawning
        let waitAction = SKAction.wait(forDuration: 2.0)
        let sequence = SKAction.sequence([ waitAction, SKAction.run(spawnSnakes)])
        run(SKAction.repeatForever(sequence))
        
        /// contactDelegate - This tells SpriteKit that the current SKScene instance (self) is responsible for handling physics contact events between physics bodies in the scene. If not set, any interactions or collisions between physics bodies will not trigger the didBegin(_:) or didEnd(_:) methods, and only the default physical responses will happen.
        physicsWorld.contactDelegate = self
    }
    
    // update method is called before each frame is rendered.
    override func update(_ currentTime: TimeInterval) {
    
        player.zRotation = 0 // force the player to stay upright
        player.position.x =  frame.midX // force the player to stay in the middle of the X-axis
        
        updateHealthNodes() // update the health nodes based on current health
        if health < 1 {
            gameOver() // trigger game-over logic when health is below 1
        }
    }
    
    func gameOver() {
        self.removeAllActions() // stop all actions
        self.isPaused = true // pause the scene
        
        // optionally, display a game over message or transition to a game over scene
        let gameOverLabel = SKLabelNode(fontNamed: "HelveticaNeue-bold")
        gameOverLabel.text = "Game Over"
        gameOverLabel.fontSize = 45
        gameOverLabel.fontColor = #colorLiteral(red: 0.7882352941, green: 0.8941176471, blue: 0.8117647059, alpha: 1)
        gameOverLabel.position = CGPoint(x: frame.midX, y: frame.midY - 200)
        gameOverLabel.zPosition = 10
        addChild(gameOverLabel)
        
        let restartButton = SKLabelNode(fontNamed: "Helvetica-Semibold")
        restartButton.text = "Restart"
        restartButton.fontSize = 30
        restartButton.fontColor = #colorLiteral(red: 0.7882352941, green: 0.8941176471, blue: 0.8117647059, alpha: 1)
        restartButton.position = CGPoint(x: frame.midX, y: frame.midY - 260)
        restartButton.zPosition = 10
        restartButton.name = "restartButton"
        addChild(restartButton)
    }
    
    func restartGame() {
        health = 5
        for i in 0..<healthNodes.count {
            healthNodes[i].texture = fullHeartTexture
        }
        
        self.removeAllChildren()
        self.removeAllActions()
        
        setupScene()
        self.isPaused = false
        canJump = true
    }
    
    // touchesBegan method is called when a touch begins on the screen.
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let location = touch.location(in: self)
            if let node = self.atPoint(location) as? SKLabelNode {
                if node.name == "restartButton" {
                    restartGame()
                }
            }
            else if canJump{ // allow single jump
                player.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 180)) // jump action
                player.removeAllActions() // stop run animation while jumping
                player.texture = jumpTextures // add jump texture
                canJump = false // allow player to jump only once
            }
        }
    }
    
    // didBegin method is called when two physics bodies make contact.
    func didBegin(_ contact: SKPhysicsContact) {
        guard let nodeA = contact.bodyA.node else { return }
        guard let nodeB = contact.bodyB.node else { return }
        
        if  nodeA == floor || nodeB == floor {
            player.run(SKAction.repeatForever(runAnimation))
            canJump = true
            print("hiiiiii")
        }
        else if (nodeA == player && nodeB.name == "snake") || (nodeB == player && nodeA.name == "snake") {
            health -= 1
            updateHealthNodes()
        }
    }
    
    func spawnSnakes(){
        // used randomX to spawn snakes at various positions along the X-axis
        let randomX = GKRandomDistribution(lowestValue: 300, highestValue: 400)
        let move = SKAction.moveBy(x: -1000 , y: 0, duration: 3)
        let dissapeare = SKAction.removeFromParent()
        
        let snake = SKSpriteNode(imageNamed: "snake")
        snake.size = CGSize(width: 45, height: 58)
        snake.name = "snake"
        snake.position = CGPoint(x: randomX.nextInt(), y: Int(frame.midY))
        
        snake.physicsBody = SKPhysicsBody(rectangleOf: snake.size)
        snake.physicsBody?.affectedByGravity = true
        snake.physicsBody?.categoryBitMask = Category.snake.rawValue
        
        snake.run(SKAction.sequence([move, dissapeare]))
        
        addChild(snake)
    }
    
    func updateHealthNodes() {
        for (index, heart) in healthNodes.enumerated() {
            heart.texture = index < health ? fullHeartTexture : emptyHeartTexture
        }
    }
}

enum Category : UInt32 {
    case player = 1
    case floor = 2
    case snake = 4
}
