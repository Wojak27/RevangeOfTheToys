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
    
    var repeatsCar = 10
    var repeatsAirstrike = 10
    var waveNumber = 0
    var currentRepeatCar = 1
    var currentRepeatAirstrike = 1
    var root: SCNNode!
    var parentNode: SCNNode!
    var objectFactory: ObjectFactory!
    weak var delegate : WaveControlerProtocol? = nil
    
    
    init(rootNode: SCNNode){
        self.root = rootNode
        objectFactory = ObjectFactory()
    }
    
    func initNextWave(node: SCNNode){
        waveNumber += 1
        currentRepeatCar = 1
        currentRepeatAirstrike = 0
        repeatsAirstrike = 1 * waveNumber
        parentNode = node
        let ranadomTimeInterval = Double.random(in: 2.0 ..< 10)
        Timer.scheduledTimer(withTimeInterval: ranadomTimeInterval, repeats: true, block: spawnNewEnemyAirstrike)
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true, block: spawnNewEnemyCar)
    }
    
    // TODO: animated text with countdown from 3
    // TODO: alert window on last enemy aliminated
    // TODO: hit detection
    
    func spawnNewEnemyAirstrike(timer: Timer){
        if(currentRepeatAirstrike == repeatsAirstrike){
            return
        }
        //let box = SCNNode(geometry: SCNBox(width: 0.1, height: 0.1, length: 0.1, chamferRadius: 0))
        let box = objectFactory.createObject(ofType: "cylinder")
        box.name = "target_Airstrike_\(currentRepeatAirstrike)"
        print(box.name!)
        //box.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
        //box.physicsBody = SCNPhysicsBody(type: .kinematic, shape: SCNPhysicsShape(geometry: box.geometry!))
        box.physicsBody?.categoryBitMask = BitMaskCategory.target.rawValue
        box.physicsBody?.contactTestBitMask = (BitMaskCategory.bullet.rawValue | BitMaskCategory.gold.rawValue)
        
        // spawning at random position form the plane middle
        let fraction = Double.random(in: 0 ..< 2)
        let r = 1.0;
        let x = r * sin(fraction * Double.pi)
        let z = r * cos(fraction * Double.pi)
        let y = Double.random(in: 0.4 ..< 3) //enemies height
        
        box.position = SCNVector3(x,y,z)
        box.eulerAngles = SCNVector3(0,  Double.pi - fraction * Double.pi, Double.pi)
        //box.eulerAngles = SCNVector3(0,-(x + z),0)
        parentNode.addChildNode(box)
        
        SCNTransaction.begin()
        self.moveEnemy(node: box, position: box.position, duration: 5)
        SCNTransaction.commit()
        
        currentRepeatAirstrike += 1
    }
    
    func spawnNewEnemyCar(timer: Timer){
        print("SpawnEnemy car")
        
        print("repeatCar \(repeatsCar)")
        print("currentRepeatCar \(currentRepeatCar)")
        print("repeatsAirstrike \(repeatsAirstrike)")
        print("currentRepeatAirstrike \(currentRepeatAirstrike)")
        
        if(currentRepeatCar == repeatsCar){
            timer.invalidate()
            delegate!.isCompleted()
            return
        }
        //let box = SCNNode(geometry: SCNBox(width: 0.1, height: 0.1, length: 0.1, chamferRadius: 0))
        let box = objectFactory.createObject(ofType: "enemy")
        box.name = "target_\(currentRepeatCar)"
        print(box.name!)
        //box.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
        //box.physicsBody = SCNPhysicsBody(type: .kinematic, shape: SCNPhysicsShape(geometry: box.geometry!))
        box.physicsBody?.categoryBitMask = BitMaskCategory.target.rawValue
        box.physicsBody?.contactTestBitMask = (BitMaskCategory.bullet.rawValue | BitMaskCategory.gold.rawValue)
        addAnimation(node: box)
        
        // spawning at random position form the plane middle
        let fraction = Double.random(in: 0 ..< 2)
        let r = 1.0;
        let x = r * sin(fraction * Double.pi)
        let z = r * cos(fraction * Double.pi)
        let y = 0.1 //enemies height
        
        box.position = SCNVector3(x,y,z)
        box.eulerAngles = SCNVector3(0,  Double.pi - fraction * Double.pi, Double.pi)
        //box.eulerAngles = SCNVector3(0,-(x + z),0)
        parentNode.addChildNode(box)
        
        SCNTransaction.begin()
        self.moveEnemy(node: box, position: box.position, duration: 15)
        SCNTransaction.commit()

        currentRepeatCar += 1
    }
    
    func addAnimation(node: SCNNode){
        let rotationRight = SCNAction.rotateBy(x: 0, y: 0, z: 0.08, duration: 0.08)
        let rotationLeft = SCNAction.rotateBy(x: 0, y: 0, z: -0.08, duration: 0.08)
        let sequence = SCNAction.sequence([rotationLeft, rotationRight])
        let repeatForever = SCNAction.repeatForever(sequence)
        node.runAction(repeatForever)
    }
    
    func moveEnemy(node: SCNNode, position: SCNVector3, duration: Int){
        let spin = CABasicAnimation(keyPath: "position")
        spin.fromValue = position
        spin.toValue = SCNVector3(0,0.1,0)
        spin.duration = Double(duration)
        node.addAnimation(spin, forKey: "position")
    }
    
}
