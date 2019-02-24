//
//  WaveMachanics.swift
//  RevangeOfTheToys
//
//  Created by Karol Wojtulewicz on 2019-02-24.
//  Copyright © 2019 Karol Wojtulewicz. All rights reserved.
//

import Foundation
import ARKit


class WaveMechanics{
    
    var repeats = 10
    var waveNumber = 0
    var currentRepeat = 0
    var root: SCNNode!
    var parentNode: SCNNode!
    weak var delegate : WaveControlerProtocol? = nil
    
    init(rootNode: SCNNode){
        self.root = rootNode
    }
    
    func initNextWave(node: SCNNode){
        waveNumber += 1
        repeats = 10 * waveNumber
        currentRepeat = 0
        parentNode = node
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true, block: spawnNewEnemy)
    }
    
    // TODO: animated text with countdown from 3
    // TODO: alert window on last enemy aliminated
    // TODO: hit detection
    
    func spawnNewEnemy(timer: Timer){
        if(currentRepeat == repeats){
            timer.invalidate()
            delegate!.isCompleted()
        }
        let box = SCNNode(geometry: SCNBox(width: 0.1, height: 0.1, length: 0.1, chamferRadius: 0))
        box.name = "target"
        box.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
        box.physicsBody = SCNPhysicsBody(type: .kinematic, shape: SCNPhysicsShape(geometry: box.geometry!))
        box.physicsBody?.categoryBitMask = BitMaskCategory.target.rawValue
        box.physicsBody?.contactTestBitMask = BitMaskCategory.bullet.rawValue
        
        // spawning at random position form the plane middle
        let fraction = Double.random(in: 0 ..< 2)
        let r = 1.0;
        let x = r * sin(fraction * Double.pi)
        let z = r * cos(fraction * Double.pi)
        let y = 0.05 //enemies height
        
        box.position = SCNVector3(x,y,z)
        box.eulerAngles = SCNVector3(0,-(x + z),0)
        parentNode.addChildNode(box)
        
        SCNTransaction.begin()
        self.moveObject(node: box, position: box.position)
        SCNTransaction.commit()
        
//        self.root.enumerateChildNodes({(node,_)in
//            if node.name == "planeNode"{
//                box.position = SCNVector3(x,y,z)
//                box.eulerAngles = SCNVector3(0,-(x + z),0)
//                node.addChildNode(box)
//
//                SCNTransaction.begin()
//                self.moveObject(node: box, position: box.position)
//                SCNTransaction.commit()
//            }})
        currentRepeat += 1
    }
    
    func moveObject(node: SCNNode, position: SCNVector3){
        let spin = CABasicAnimation(keyPath: "position")
        spin.fromValue = position
        spin.toValue = SCNVector3(0,0.05,0)
        spin.duration = 15
        node.addAnimation(spin, forKey: "position")
    }
    
}
