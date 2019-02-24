//  Created by Karol Wojtulewicz on 2019-01-14.
//  Copyright © 2019 Karol Wojtulewicz. All rights reserved.
//

import UIKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate, WaveControlerProtocol, SCNPhysicsContactDelegate {
    
    let itemsArray: [String] = ["box", "cylinder", "tower"]
    
    var groundPlane: SCNNode?
    var planeOriginPosition: SCNVector3?
    var informationLabelText = "Looking for surface"
    var pointer: SCNNode?
    var hasPointer = false;
    var selectedItem: String?
    var waveController: WaveMechanics!
    var target: SCNNode?
    
    @IBOutlet weak var sceneView: ARSCNView!
    @IBOutlet weak var addButton: UIButton!
    @IBOutlet weak var informationLabel: UILabel!
    @IBOutlet weak var itemsCollectionView: UICollectionView!
    
    let configuration = ARWorldTrackingConfiguration()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.sceneView.debugOptions = [ARSCNDebugOptions.showWorldOrigin, ARSCNDebugOptions.showFeaturePoints, .showPhysicsShapes]
        
        //for detecting horizontal surfaces
        self.configuration.planeDetection = .horizontal
        //order in which you put the functions matters
        self.sceneView.session.run(configuration)
        self.sceneView.autoenablesDefaultLighting = true
        self.sceneView.delegate = self
        self.itemsCollectionView.dataSource = self
        self.itemsCollectionView.delegate = self
        self.sceneView.scene.physicsWorld.contactDelegate = self
        self.selectedItem = itemsArray[0]
        
        // Do any additional setup after loading the view, typically from a nib.
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return itemsArray.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "collectionCell", for: indexPath) as! itemCell
        cell.alpha = 0.9
        cell.setImage(image: UIImage(named: "\(itemsArray[indexPath.row])_image")!)
        cell.backgroundColor = UIColor.red
        return cell
    }
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath)
        cell?.backgroundColor = UIColor.green
        selectedItem = itemsArray[indexPath.row]
    }
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        
        selectedItem = itemsArray[indexPath.row]
    }

    func deleteSCNNode(named name: String){
        self.sceneView.scene.rootNode.enumerateChildNodes({(node,_)in
            if let childNodeName = node.name{
                if childNodeName.contains(name){
                    node.removeFromParentNode()
                }
            }
        })
    }
    
    // TODO: Complete the UI
    // TODO: Sounds?
    // TODO: Disable/hide buttons if not needed
    // TODO: Menu with scoreboard
    // TODO: Quit button
    // TODO: 3d Models
    
    func updatePointer(currentPositionOfCamera: SCNVector3, orientation: SCNVector3){
        self.deleteSCNNode(named: "shadow")
        pointer = self.createPointer(type: selectedItem!)
        
        let rotationAngle = Float( atan((orientation.x/abs(orientation.x + orientation.z))/(orientation.z/(abs(orientation.x + orientation.z)))))
//        if there is a plane, display it on its surface
        if let plane = self.groundPlane{
            pointer!.position = SCNVector3(currentPositionOfCamera.x, plane.parent!.position.y + plane.geometry!.boundingBox.max.y + pointer!.geometry!.boundingBox.max.y, currentPositionOfCamera.z)
            pointer!.eulerAngles = SCNVector3(0,rotationAngle , 0)
        }else{
            pointer!.position = currentPositionOfCamera
            pointer!.eulerAngles = SCNVector3(0,rotationAngle , 0)
        }
        self.sceneView.scene.rootNode.addChildNode(pointer!)
    }
    
    func createPointer(type: String)-> SCNNode{
        
        var node:SCNNode?
        
        // shadow node: a very long opaque box or cylinder for knowing where the box
        //or cylinder to place would land. Uncomment in case you fix physics
        
//        var shadowNode:SCNNode?
        
        if(type == "tower"){
            node = ObjectFactory.createObject(ofType: "cylinder")
//            shadowNode = SCNNode(geometry: ObjectFactory.createObject(ofType: "cylinder").geometry)
        }else{
            node = ObjectFactory.createObject(ofType: type)
//            shadowNode = SCNNode(geometry: ObjectFactory.createObject(ofType: type).geometry)
        }
        
//        shadowNode!.scale = SCNVector3(0.97, 100, 0.97)
//        shadowNode!.geometry?.firstMaterial?.diffuse.contents = UIColor.white
//        shadowNode!.geometry?.firstMaterial?.transparency = 0.1
//        node!.addChildNode(shadowNode!)
        node!.name = type+"_shadow"
        node!.geometry?.firstMaterial?.diffuse.contents = UIColor.white
        node!.geometry?.firstMaterial?.transparency = 0.3
        
        return node!
    }

    //rule of thumb: every horisontal/ vertical surface should have a single anchor
    func renderer(_ renderer: SCNSceneRenderer, willRenderScene scene: SCNScene, atTime time: TimeInterval) {
        guard let pointOfView = sceneView.pointOfView else {return}
        let transform = pointOfView.transform
        let orientation = SCNVector3(-transform.m31,-transform.m32,-transform.m33)
        let location = SCNVector3(transform.m41,transform.m42,transform.m43)
        let currentPositionOfCamera = addVectors(left: orientation, right: location)
        DispatchQueue.main.async {
            if(self.hasPointer){
                self.updatePointer(currentPositionOfCamera: currentPositionOfCamera, orientation: orientation)
            }
            
        }
    }
    
    
    //////////////////////first triggered -----------------------
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        //this function checks if an AR anchore was added to the sceneview
        //check if the anchor added is the plane anchore
        guard let planeAnchor = anchor as? ARPlaneAnchor else {return}
        //check if the plane already exists
        guard groundPlane == nil else {return}
        
        //if it does not create one
        let groundNode = createGroundPlane(planeAnchor: planeAnchor)
        groundPlane = groundNode
        
        node.addChildNode(groundNode)
        // init waveController
        self.waveController = WaveMechanics(rootNode: self.sceneView.scene.rootNode)
        self.waveController.delegate = self
        
        DispatchQueue.main.async {
            self.informationLabel.text = ""
            self.hasPointer = true;
        }
        
    }
    

    //did update gets triggered when we update the anchor of something in the real world
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
//        print("update")
        guard let planeAnchor = anchor as? ARPlaneAnchor else {return}

        
        node.rotation = groundPlane!.rotation
        node.scale = groundPlane!.scale
        
        node.enumerateChildNodes { (childNode, _) in
            if(childNode.name == "planeNode"){
                let groundBodyShape = SCNPhysicsShape(geometry: childNode.geometry!)
                childNode.physicsBody = SCNPhysicsBody(type: .kinematic, shape: groundBodyShape)
            }else if(childNode.name == "goldNode"){
                childNode.physicsBody = SCNPhysicsBody.kinematic()
            }
            
        }

    }
    
    //is called if the device makes an error and adds additional anchore for the same surface
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        //informationLabel.text = "Looking for a surface"
        guard let _ = anchor as? ARPlaneAnchor else {return}
        node.enumerateChildNodes { (childNode, _) in
            if childNode.name == "planeNode" {
                childNode.removeFromParentNode()
                informationLabel.text = informationLabelText
            }
        }
    }
    
    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        print("contact")
        let nodeA = contact.nodeA
        let nodeB = contact.nodeB
        if nodeA.physicsBody?.categoryBitMask == BitMaskCategory.target.rawValue && nodeB.physicsBody?.categoryBitMask == BitMaskCategory.bullet.rawValue{
            self.target = nodeA
        }else if nodeB.physicsBody?.categoryBitMask == BitMaskCategory.target.rawValue && nodeA.physicsBody?.categoryBitMask == BitMaskCategory.bullet.rawValue{
            self.target = nodeB
        }
        if let name = nodeA.name {
            print("nodeA name")
            print(name)
        }
        if let name = nodeB.name {
            print("nodeB name")
            print(name)
        }
        
        if nodeB.physicsBody?.categoryBitMask == BitMaskCategory.target.rawValue && nodeA.physicsBody?.categoryBitMask == BitMaskCategory.bullet.rawValue || nodeA.physicsBody?.categoryBitMask == BitMaskCategory.target.rawValue && nodeB.physicsBody?.categoryBitMask == BitMaskCategory.bullet.rawValue{
            let confetti = SCNParticleSystem(named: "Models.scnassets/Confetti.scnp", inDirectory: nil)
            confetti?.loops = false
            confetti?.particleLifeSpan = 4
            confetti?.emitterShape = target?.geometry
            let confettiNode = SCNNode()
            confettiNode.addParticleSystem(confetti!)
            confettiNode.position = contact.contactPoint
            self.sceneView.scene.rootNode.addChildNode(confettiNode)
            target?.removeFromParentNode()
        }

    }

    @IBAction func addObject(_ sender: Any) {
        let object = ObjectFactory.createObjectWithFriction(object: ObjectFactory.createObject(ofType: selectedItem!))
//        let object = ObjectFactory.createObject(ofType: selectedItem!)
        // z is for height and is negative up
        print("plane bounding box max: ", groundPlane!.geometry!.boundingBox.max.y * 2)
        print("plane bounding box min: ", groundPlane!.geometry!.boundingBox.min)
        print("object bounding box max: ", object.geometry!.boundingBox.max.y * 4)
        print("object bounding box min: ", object.geometry!.boundingBox.min)
        object.position = SCNVector3(pointer!.position.x - groundPlane!.parent!.position.x, groundPlane!.geometry!.boundingBox.max.y + object.geometry!.boundingBox.max.y,pointer!.position.z - groundPlane!.parent!.position.z)
        object.eulerAngles = pointer!.eulerAngles

//        self.sceneView.scene.rootNode.addChildNode(object)
        groundPlane!.addChildNode(object)
        
    }
    @IBAction func addEnemy(_ sender: Any) {
        waveController.initNextWave(node: groundPlane!)
    }
    
    func handleShoot(){
        self.sceneView.scene.rootNode.enumerateChildNodes({(node,_)in
            if let nodeName = node.name{
                if nodeName.contains("shootable"){
                    
                }
            }})
    }
    @IBAction func shootAction(_ sender: Any) {
        
        selectedItem = "pointer"
        
        print("shooting action")
        guard let pointOfView = sceneView.pointOfView else {return}
        let transform = pointOfView.transform
        let orientation = SCNVector3(-transform.m31,-transform.m32,-transform.m33)
        let location = SCNVector3(transform.m41,transform.m42,transform.m43)
        let currentPositionOfCamera = addVectors(left: orientation, right: location)
        
        let shootingForce = Float(2)
        let bullet = SCNNode(geometry: SCNSphere(radius: 0.005))
        bullet.name = "bullet"
        bullet.geometry?.firstMaterial?.diffuse.contents = UIColor.red
        
        let body = SCNPhysicsBody(type: .dynamic, shape: SCNPhysicsShape(geometry: bullet.geometry!, options: nil))
        body.isAffectedByGravity = true
        bullet.physicsBody = body
        
        var nodes: [SCNNode] = []
        groundPlane!.childNodes.filter({ $0.name == "shootable" }).forEach({
            let node = $0
            nodes.append(node)
        })
        
        for var node in nodes {
            print("node")
            let bulletToShoot = bullet.clone()
            shootBullet(node: node, bullet: bulletToShoot, shootingForce: shootingForce, currentPositionOfCamera: currentPositionOfCamera)
        }
    }
    
    
    private func shootBullet(node: SCNNode, bullet: SCNNode, shootingForce: Float, currentPositionOfCamera: SCNVector3){
        
        //can use convertPosition(_:to:) to convert position from one node to another
        bullet.position = SCNVector3(x: node.position.x, y: groundPlane!.geometry!.boundingBox.max.y + node.position.y + node.geometry!.boundingBox.max.y + bullet.geometry!.boundingSphere.radius + 0.3, z: node.position.z)
        //            bullet.position = SCNVector3(x: groundPlane!.parent!.position.x, y: groundPlane!.parent!.position.y + 0.5, z: groundPlane!.parent!.position.z)
        
        print("pointer parent position")
        print(toPlaneCoordinates(node: pointer!, toNode: groundPlane!))
        print("pointer position")
        print(pointer!.position)
        let pointerPosInPlaneCoord = SCNVector3(pointer!.position.x - groundPlane!.parent!.position.x, 0.5,pointer!.position.z - groundPlane!.parent!.position.z)
        
        let forceVec = SCNVector3((pointerPosInPlaneCoord.x - node.position.x) * shootingForce, (groundPlane!.parent!.position.y) * shootingForce, (pointerPosInPlaneCoord.z - node.position.z) * shootingForce)
        bullet.physicsBody?.applyForce(forceVec, asImpulse: true)
        bullet.physicsBody?.categoryBitMask = BitMaskCategory.bullet.rawValue
        bullet.physicsBody?.contactTestBitMask = BitMaskCategory.target.rawValue
        groundPlane!.addChildNode(bullet)
        print("shoot!")
    }
    
    @IBAction func resetPlaneAction(_ sender: Any) {
        groundPlane?.removeFromParentNode()
        groundPlane = nil
    }
    
    func addVectors(left: SCNVector3, right: SCNVector3) -> SCNVector3{
        return SCNVector3Make(left.x+right.x, left.y+right.y, left.z+right.z)
    }
}

extension ViewController{
    func createGroundPlane(planeAnchor: ARPlaneAnchor)->SCNNode{
        
        let groundNode = SCNNode(geometry: SCNCylinder(radius: 2, height: 0.05))
        groundNode.geometry?.firstMaterial?.diffuse.contents = UIImage(named: "grass_circle")
        groundNode.geometry?.firstMaterial?.isDoubleSided = true
        groundNode.geometry?.firstMaterial?.transparency = 0.5
        groundNode.name = "planeNode"
        let groundBodyShape = SCNPhysicsShape(geometry: groundNode.geometry!)
        let body = SCNPhysicsBody(type: .kinematic, shape: groundBodyShape)
        groundNode.physicsBody = body
        groundNode.position = SCNVector3(planeAnchor.center.x,planeAnchor.center.y,planeAnchor.center.z)

        let goldNode = SCNNode(geometry: SCNBox(width: 0.2, height: 0.2, length: 0.2, chamferRadius: 0))
        goldNode.geometry?.firstMaterial?.diffuse.contents = UIColor.yellow
        goldNode.position = SCNVector3(0,0.1 + groundNode.geometry!.boundingBox.max.y,0)
        goldNode.name = "goldNode"
        goldNode.physicsBody = SCNPhysicsBody(type: .static, shape: SCNPhysicsShape(geometry: goldNode.geometry!))
        groundNode.addChildNode(goldNode)
        return groundNode
    }
    
    func isCompleted() {
        let alert = UIAlertController(title: "Wave", message: "Completed!", preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    func toPlaneCoordinates(node: SCNNode, toNode: SCNNode) -> SCNVector3{
        return node.convertPosition(node.position, to: toNode)
    }
}

extension Int{
    var degreesToRadians: Double {return Double(self) * .pi/180}
}

