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
        }else if(type == "cylinder"){
            object = createCylinder()
        }else if(type == "tower"){
            object = createTower()
        }else if(type == "pointer"){
            object = createPointer()
        }else if(type == "gold"){
            object = createGold()
        }
        
        return object
    }
    
    public func createObjectWithFriction(object: SCNNode)-> SCNNode{
        let bodyShape = SCNPhysicsShape(geometry: object.geometry!)
        let body = SCNPhysicsBody(type: .kinematic, shape: bodyShape)
        body.restitution = 0
        body.mass = 1000
        body.rollingFriction = 1
        body.angularDamping = 1
        body.isAffectedByGravity = false
        object.physicsBody?.categoryBitMask = BitMaskCategory.object.rawValue
        
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
        object.physicsBody?.categoryBitMask = BitMaskCategory.pointer.rawValue
        object.physicsBody?.contactTestBitMask = BitMaskCategory.object.rawValue
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
    
    private func createCylinder()-> SCNNode{
        let object = SCNNode()
        object.geometry = SCNCylinder(radius: 0.05, height: 0.1)
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

    
    private func createPointer()->SCNNode{
        let object = SCNNode()
        object.geometry = SCNCylinder(radius: 0.05, height: 0.01)
        object.geometry?.firstMaterial?.diffuse.contents = UIColor.white
        object.geometry?.firstMaterial?.transparency = 0.9
        object.position = SCNVector3(-1, 0, 0)
        return object
    }
}
