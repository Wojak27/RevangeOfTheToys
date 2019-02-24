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
    public static func createObject(ofType type: String)-> SCNNode{
        var object = SCNNode()
        if(type == "box"){
            object = createBox()
        }else if(type == "cylinder"){
            object = createCylinder()
        }else if(type == "tower"){
            object = createTower()
        }else if(type == "pointer"){
            object = createPointer()
        }
        
        return object
    }
    
    public static func createObjectWithFriction(object: SCNNode)-> SCNNode{
        let bodyShape = SCNPhysicsShape(geometry: object.geometry!)
        let body = SCNPhysicsBody(type: .kinematic, shape: bodyShape)
        body.restitution = 0
        body.mass = 1000
        body.rollingFriction = 1
        body.angularDamping = 1
        body.isAffectedByGravity = false
        
        body.damping = 10
        body.friction = 10
        body.angularVelocity = SCNVector4(0, 0, 0, 0)
        object.physicsBody = body
        return object
    }
    
    private static func createBox()-> SCNNode{
        let object = SCNNode()
        object.geometry = SCNBox(width: 0.1, height: 0.1, length: 0.1, chamferRadius: 0)
        object.geometry?.firstMaterial?.diffuse.contents = UIColor.red
        object.position = SCNVector3(-1, 0, 0)
        return object
    }
    
    private static func createCylinder()-> SCNNode{
        let object = SCNNode()
        object.geometry = SCNCylinder(radius: 0.05, height: 0.1)
        object.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
        object.position = SCNVector3(-1, 0, 0)
        return object
    }
    
    private static func createTower()->SCNNode{
        let scene = SCNScene(named: "Tower.scn")
        let frame = (scene?.rootNode.childNode(withName: "body", recursively: false))!
        frame.position = SCNVector3(-1, 0, 0)
        frame.name = "shootable"
        return frame
    }
    
    private static func createPointer()->SCNNode{
        let object = SCNNode()
        object.geometry = SCNSphere(radius: 0.05)
        object.geometry?.firstMaterial?.diffuse.contents = UIColor.white
        object.geometry?.firstMaterial?.transparency = 0.9
        object.position = SCNVector3(-1, 0, 0)
        return object
    }
}
