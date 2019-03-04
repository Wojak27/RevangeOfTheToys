//
//  ObjectFactory.swift
//  RevangeOfTheToys
//
//  Created by Karol Wojtulewicz on 2019-01-18.
//  Copyright © 2019 Karol Wojtulewicz. All rights reserved.
//

import UIKit
import ARKit

class ObjectFactory{
    weak var delegate : EnableShootProtocol? = nil
    
    init() {
        
    }
    
    public func createObject(ofType type: String)-> SCNNode{
        
        var object = SCNNode()
        if(type == "box"){
            object = createBox()
        }else if(type == "letter_box"){
            object = createLetterBox()
        }else if(type == "textured_cylinder"){
            object = createTexturedCylinder()
        }else if(type == "cylinder_tower"){
            object = createCylinder(radious: 0.07)
        }else if(type == "cylinder"){
            object = createCylinder(radious: 0.05)
        }else if(type == "tower"){
            object = createToyTower()
        }else if(type == "pointer"){
            object = createPointer()
        }else if(type == "gold"){
            object = createGold()
        }else if(type == "enemy"){
            //object = createCar()
            object = createTrain()
        }else if(type == "missile"){
            object = createMissile()
        }
        
        return object
    }
    
    public func createObjectWithFriction(object: SCNNode)-> SCNNode{
        let body = object.physicsBody!
        body.restitution = 0
        body.mass = 1000
        body.rollingFriction = 1
        body.angularDamping = 1
        body.isAffectedByGravity = false
        
        body.damping = 10
        body.friction = 10
        body.angularVelocity = SCNVector4(0, 0, 0, 0)
        object.physicsBody = body
        object.physicsBody?.categoryBitMask = BitMaskCategory.object.rawValue
        object.physicsBody?.contactTestBitMask = BitMaskCategory.pointer.rawValue
        return object
    }
    
    public func createStaticPointer(object: SCNNode)-> SCNNode{
        
        object.physicsBody = SCNPhysicsBody.static()
        object.physicsBody?.categoryBitMask = BitMaskCategory.pointer.rawValue
        object.physicsBody?.contactTestBitMask = BitMaskCategory.object.rawValue
        return object
    }
    
    public func createStatic(object: SCNNode)-> SCNNode{
        
        object.physicsBody = SCNPhysicsBody.static()
        return object
    }
    
    private func createBox()-> SCNNode{
        let object = SCNNode()
        object.geometry = SCNBox(width: 0.1, height: 0.1, length: 0.1, chamferRadius: 0)
        object.geometry?.firstMaterial?.diffuse.contents = UIColor.red
        object.position = SCNVector3(-1, 0, 0)
        object.name = "box"
        return object
    }
    
    private func createCylinder(radious: CGFloat)-> SCNNode{
        let object = SCNNode()
        object.geometry = SCNCylinder(radius: radious, height: 0.1)
        object.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
        object.position = SCNVector3(-1, 0, 0)
        object.name = "cylinder"
        return object
    }
    
    private func createTower()->SCNNode{
        let scene = SCNScene(named: "Models.scnassets/Tower.scn")
        let frame = (scene?.rootNode.childNode(withName: "body", recursively: false))!
        frame.position = SCNVector3(-1, 0, 0)
        frame.name = "shootable"
        delegate!.enableShootButton()
        
        return frame
    }
    
    private func createGold()->SCNNode{
        let scene = SCNScene(named: "Models.scnassets/Gold.scn")
        let frame = (scene?.rootNode.childNode(withName: "body", recursively: false))!
        
        return frame
    }
    
    private func createToyTower()->SCNNode{
        let scene = SCNScene(named: "Models.scnassets/ToyTower.scn")
        let frame = (scene?.rootNode.childNode(withName: "Tower", recursively: false))!
        frame.scale = SCNVector3(x: 0.0003, y: 0.0003, z: 0.0003)
        frame.position = SCNVector3(-1, 0, 0)
        frame.name = "shootable"
        frame.physicsBody = SCNPhysicsBody(type: .kinematic, shape: SCNPhysicsShape(geometry: SCNCylinder(radius: 0.07, height: 0.2), options: nil))
        delegate!.enableShootButton()
        return frame
    }
    
    private func createMissile()->SCNNode{
        let scene = SCNScene(named: "Models.scnassets/Missile.scn")
        let frame = (scene?.rootNode.childNode(withName: "missile", recursively: false))!
        frame.scale = SCNVector3(x: 0.00001, y: 0.00001, z: 0.00001)
        frame.physicsBody = SCNPhysicsBody(type: .kinematic, shape: SCNPhysicsShape(geometry: SCNCylinder(radius: 0.1, height: 0.2), options: nil))
        return frame
    }
    
    private func createCar()-> SCNNode{
        let scene = SCNScene(named: "Models.scnassets/Car.scn")
        let chassis = (scene?.rootNode.childNode(withName: "chassis", recursively: false))!
        
        let body = SCNPhysicsBody(type: .kinematic, shape: SCNPhysicsShape(node: chassis, options: [SCNPhysicsShape.Option.keepAsCompound: true]))
        chassis.physicsBody = body
        
        return chassis
        
    }
    
    private func createTrain()-> SCNNode{
        let scene = SCNScene(named: "Models.scnassets/Train.scn")
        let chassis = (scene?.rootNode.childNode(withName: "Train", recursively: false))!
        chassis.scale = SCNVector3(x: 0.0001, y: 0.0001, z: 0.0001)
        let body = SCNPhysicsBody(type: .kinematic, shape: SCNPhysicsShape(node: chassis, options: [SCNPhysicsShape.Option.keepAsCompound: true]))
        chassis.physicsBody = body
        
        
        return chassis
        
    }
    
    private func createLetterBox()-> SCNNode{
        let scene = SCNScene(named: "Models.scnassets/LetterBox.scn")
        let frame = (scene?.rootNode.childNode(withName: "LetterBox", recursively: false))!
        let scale = Float(0.00017)
        frame.scale = SCNVector3(x: scale, y: scale, z: scale)
        frame.position = SCNVector3(-1, 0, 0)
        frame.physicsBody = SCNPhysicsBody(type: .kinematic, shape: SCNPhysicsShape(geometry: SCNBox(width: 0.1, height: 0.1, length: 0.1, chamferRadius: 0), options: nil))
        frame.name = "letter_box"
        
        return frame
        
        
    }
    
    private func createTexturedCylinder()-> SCNNode{
        let scene = SCNScene(named: "Models.scnassets/Cylinder.scn")
        let frame = (scene?.rootNode.childNode(withName: "Node", recursively: false))!
        let scale = Float(0.00021)
        frame.scale = SCNVector3(x: scale, y: scale, z: scale)
        frame.position = SCNVector3(-1, 0, 0)
        frame.name = "cylinder"
        frame.physicsBody = SCNPhysicsBody(type: .kinematic, shape: SCNPhysicsShape(geometry: SCNCylinder(radius: 0.05, height: 0.1), options: nil))
        
        return frame
        
    }

    
    private func createPointer()->SCNNode{
        let object = SCNNode()
        object.geometry = SCNCylinder(radius: 0.05, height: 0.01)
        object.geometry?.firstMaterial?.diffuse.contents = UIColor.white
        object.geometry?.firstMaterial?.transparency = 0.9
        object.position = SCNVector3(-1, 0, 0)
        return object
    }
}
