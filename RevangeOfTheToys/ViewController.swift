//  Created by Karol Wojtulewicz on 2019-01-14.
//  Copyright © 2019 Karol Wojtulewicz. All rights reserved.
//

import UIKit
import ARKit
import AVFoundation
import SCLAlertView

class ViewController: UIViewController, ARSCNViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate, WaveControlerProtocol, SCNPhysicsContactDelegate, EnableShootProtocol, MissileLounched {

    let itemsArray: [String] = ["letter_box", "textured_cylinder", "tower"]
    
    
    var objectsToPlace = 3
    var groundPlane: SCNNode?
    var planeOriginPosition: SCNVector3?
    var informationLabelText = "Looking for surface"
    var pointer: SCNNode?
    var hasPointer = false;
    var selectedItem: String?
    var waveController: WaveMechanics!
    var objectFactory: ObjectFactory!
    var target: SCNNode?
    var goldHealth:Int = 100
    var player: AVAudioPlayer?
    var shootSoundEffectPlayer: AVAudioPlayer?
    var explosionSoundEffectPlayer: AVAudioPlayer?
    var goldHitSoundEffectPlayer: AVAudioPlayer?
    var objectDestroyedSoundEffectPlayer: AVAudioPlayer?
    var missileLaunchSoundEffectPlayer: AVAudioPlayer?
    var placeObjectSoundEffectPlayer: AVAudioPlayer?
    var enemiesHitArray: [String] = []
    var waveCompleted = false
    var pointerYPosition: Float!
    var planeAnchor: ARPlaneAnchor?
    var planeNode: SCNNode?
    
    @IBOutlet weak var sceneView: ARSCNView!
    
    @IBOutlet weak var startLogo: UIImageView!
    @IBOutlet weak var startView: UIView!
    @IBOutlet weak var objectsToPlaceLabel: UILabel!
    @IBOutlet weak var waveNumberLabel: UILabel!
    @IBOutlet weak var informationLabel: UILabel! //label in the middle
    @IBOutlet weak var itemsCollectionView: UICollectionView! //collectionview
    
    @IBOutlet weak var lookingForPlaneLabel: UILabel!
    //buttons
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var shootButton: UIButton!
    @IBOutlet weak var addButton: UIButton!
    @IBOutlet weak var nextWaveButton: UIButton!
    @IBOutlet weak var minigunButton: UIButton!
    
    let configuration = ARWorldTrackingConfiguration()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //self.sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints, .showBoundingBoxes, .showPhysicsShapes]
        self.sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints, .showBoundingBoxes]
        
        //for detecting horizontal surfaces
        self.configuration.planeDetection = .horizontal
        //order in which you put the functions matters
        self.sceneView.session.run(configuration)
        self.sceneView.autoenablesDefaultLighting = true
        self.sceneView.delegate = self
        self.itemsCollectionView.dataSource = self
        self.itemsCollectionView.delegate = self
        self.sceneView.scene.physicsWorld.contactDelegate = self
        self.objectFactory = ObjectFactory()
        self.objectFactory.delegate = self
        prepareUI()
        
        // Do any additional setup after loading the view, typically from a nib.
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return itemsArray.count
    }
    func editButtons(){
        nextWaveButton.layer.cornerRadius = 20
        nextWaveButton.clipsToBounds = true
        
        shootButton.layer.cornerRadius = 100
        shootButton.clipsToBounds = true
        
        addButton.layer.cornerRadius = 100
        addButton.clipsToBounds = true
        
        minigunButton.layer.cornerRadius = 100
        minigunButton.clipsToBounds = true
    }
    
    func prepareUI(){
        editButtons()
        addButton.isHidden = true
        self.selectedItem = itemsArray[0]
        objectsToPlaceLabel.isHidden = true
        waveNumberLabel.isHidden = true
        shootButton.isHidden = true
        itemsCollectionView.isHidden = true
        minigunButton.isHidden = true
        nextWaveButton.isHidden = true
        objectsToPlaceLabel.isHidden = true
        playButton.isHidden = true
        startLogo.isHidden = false
    }
    
    func enableUI(){
        itemsCollectionView.isHidden = false
        addButton.isHidden = false
        addButton.isEnabled = true
        nextWaveButton.isHidden = false
        waveNumberLabel.isHidden = false
        shootButton.isHidden = true
        objectsToPlaceLabel.isHidden = false
        updateObjectsToPlaceLabel()
        selectedItem = itemsArray[0]
        objectsToPlaceLabel.isHidden = false
        playButton.isHidden = true
        startLogo.isHidden = true
        startView.isHidden = true
        playMusicLoop()
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
    
    func findSCNNode(withName name: String)-> SCNNode{
        var nodeRet = SCNNode()
        self.sceneView.scene.rootNode.enumerateChildNodes({(node,_)in
            if let childNodeName = node.name{
                if childNodeName.contains(name){
                    nodeRet = node
                }
            }
        })
        return nodeRet
    }
    
    // TODO: Complete the UI
    // TODO: Menu with scoreboard
    // TODO: Quit button
    // TODO: 3d Models
    
    func updatePointer(currentPositionOfCamera: SCNVector3, orientation: SCNVector3){
        self.deleteSCNNode(named: "shadow")
        pointer = self.createPointer(type: selectedItem!)
        
        let rotationAngle = Float( atan((orientation.x/abs(orientation.x + orientation.z))/(orientation.z/(abs(orientation.x + orientation.z)))))
//        if there is a plane, display it on its surface
        if let plane = self.groundPlane{
            pointerYPosition = plane.parent!.position.y + plane.geometry!.boundingBox.max.y + pointer!.geometry!.boundingBox.max.y
            pointer!.position = SCNVector3(currentPositionOfCamera.x,pointerYPosition , currentPositionOfCamera.z)
            pointer!.eulerAngles = SCNVector3(0,rotationAngle , 0)
            
        }else{
            pointer!.position = currentPositionOfCamera
            pointer!.eulerAngles = SCNVector3(0,rotationAngle , 0)
        }
        self.sceneView.scene.rootNode.addChildNode(pointer!)
    }
    
    func doesNodeExist(name: String)-> Bool{
        var exists = false
        self.sceneView.scene.rootNode.enumerateChildNodes { (childNode, _) in
            if let nodeName = childNode.name{
                if(nodeName.contains(name)){
                    exists = true
                }
            }
            
            
        }
        return exists
    }
    
    func createPointer(type: String)-> SCNNode{
        
        var node:SCNNode?

        if(type == "tower"){
            node = objectFactory.createObject(ofType: "cylinder_tower")
        }else if type == "letter_box"{
            node = objectFactory.createObject(ofType: "box")
        }else if type == "textured_cylinder"{
            node = objectFactory.createObject(ofType: "cylinder")
        }else{
            node = objectFactory.createObject(ofType: type)
        }

        node = objectFactory.createStaticPointer(object: node!)
        node!.name = type+"_shadow"
        node!.geometry?.firstMaterial?.diffuse.contents = UIColor.white
        node!.geometry?.firstMaterial?.transparency = 0.3
        
        return node!
    }

    //rule of thumb: every horisontal/ vertical surface should have a single anchor
    func renderer(_ renderer: SCNSceneRenderer, willRenderScene scene: SCNScene, atTime time: TimeInterval) {
        guard let pointOfView = sceneView.pointOfView else {return}
        print("point of view \(pointOfView)")
        let posOr = getCurrentPositionOfCamera()
        let currentPositionOfCamera = posOr[0]
        let orientation = posOr[1]
        DispatchQueue.main.async {
            if(self.hasPointer){
                self.updatePointer(currentPositionOfCamera: currentPositionOfCamera, orientation: orientation)
            }
            if(self.doesNodeExist(name: "Airstrike")){
                self.minigunButton.isHidden = false
                self.informationLabel.text = "Missile Lounched!"
                
            }else if(!self.doesNodeExist(name: "target") && self.waveCompleted){
                self.onCompletedWave()
            }else if(self.doesNodeExist(name: "target")){
                //self.showPointerToEnemy()
            }else{
                self.noMissile()
            }
            
        }
        
    }
    //////////////////////first triggered -----------------------
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        //this function checks if an AR anchore was added to the sceneview
        
        //check if the plane already exists
        guard self.planeAnchor == nil else {return}
        //check if the anchor added is the plane anchore
        guard let planeAnchor = anchor as? ARPlaneAnchor else {return}
        
        self.planeAnchor = planeAnchor
        self.planeNode = node
        DispatchQueue.main.async {
            self.playButton.isHidden = false
            self.lookingForPlaneLabel.isHidden = true
        }
        
    }
    

    //did update gets triggered when we update the anchor of something in the real world
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {

        //checks if the plane has been placed
        guard self.groundPlane != nil else {return}
        
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
    
    //TODO: Need fix
    func showPointerToEnemy(){
        let currentPositionAndOrientation = getCurrentPositionOfCamera()
        let currentPositionOfCamera = currentPositionAndOrientation[0]
        
        self.sceneView.scene.rootNode.enumerateChildNodes { (childNode, _) in
            if let nodeName = childNode.name{
                if(nodeName.contains("target")){
                    deleteSCNNode(named: "arrow")
                    let coordOfTargetInSceneView = self.groundPlane!.convertPosition(childNode.position, to: self.sceneView.scene.rootNode)
                    let coordOfTargetWithPointOfViewAsCenter = SCNVector3(coordOfTargetInSceneView.x - currentPositionOfCamera.x, coordOfTargetInSceneView.y - currentPositionOfCamera.y, coordOfTargetInSceneView.z - currentPositionOfCamera.z)
                    print("coordinates to target: \(coordOfTargetWithPointOfViewAsCenter)")
                    let arrowNode = SCNNode(geometry: SCNCylinder(radius: 0.1, height: 0.2))
                    arrowNode.geometry?.firstMaterial?.diffuse.contents = UIColor.red
                    arrowNode.position = currentPositionOfCamera
                    arrowNode.name = "arrow"
                    sceneView.scene.rootNode.addChildNode(arrowNode)
                }
            }
            
            
        }
    }
    
    func noMissile(){
        self.minigunButton.isHidden = true
        self.informationLabel.text = ""
    }
    
    func initGroundPlane(){
        
        guard self.planeNode != nil else {return}
        self.sceneView.debugOptions = []
        groundPlane = createGroundPlane(planeAnchor: self.planeAnchor!)
        
        planeNode!.addChildNode(groundPlane!)
        // init waveController
        self.waveController = WaveMechanics(rootNode: self.sceneView.scene.rootNode)
        self.waveController.delegate = self
        self.waveController.delegateMissile = self
        
    }
    func onCompletedWave(){
        showWaveCompletedAlert()
        waveCompleted = false
        objectsToPlace += 3
        enableUI()
    }
    
    func getCurrentPositionOfCamera()-> [SCNVector3]{
        guard let pointOfView = sceneView.pointOfView else {return []}
        let transform = pointOfView.transform
        let orientation = SCNVector3(-transform.m31,-transform.m32,-transform.m33)
        let location = SCNVector3(transform.m41,transform.m42,transform.m43)
        let currentPositionOfCamera = addVectors(left: orientation, right: location)
        return [currentPositionOfCamera, orientation]
    }
    
    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        let nodeA = contact.nodeA
        let nodeB = contact.nodeB
        
        checkminigunBulletHitMissile(nodeA: nodeA, nodeB: nodeB)
        checkBulletHitEnemy(nodeA: nodeA, nodeB: nodeB, contact: contact)
        checkEnemyHitObject(nodeA: nodeA, nodeB: nodeB)
        checkEnemyReachedGold(nodeA: nodeA, nodeB: nodeB)
        checkPointerOverObject(nodeA: nodeA, nodeB: nodeB)
        

    }
    
    func checkminigunBulletHitMissile(nodeA: SCNNode, nodeB: SCNNode){
        
        //i the bullet hits the missile
        if nodeB.physicsBody?.categoryBitMask == BitMaskCategory.missile.rawValue && nodeA.physicsBody?.categoryBitMask == BitMaskCategory.minigunBullet.rawValue || nodeA.physicsBody?.categoryBitMask == BitMaskCategory.missile.rawValue && nodeB.physicsBody?.categoryBitMask == BitMaskCategory.minigunBullet.rawValue{
            nodeA.removeFromParentNode()
            nodeB.removeFromParentNode()
            playEnemyHit()
        }
    }
    
    
    func checkBulletHitEnemy(nodeA: SCNNode, nodeB: SCNNode, contact: SCNPhysicsContact){
        if nodeA.physicsBody?.categoryBitMask == BitMaskCategory.target.rawValue && nodeB.physicsBody?.categoryBitMask == BitMaskCategory.bullet.rawValue{
            self.target = nodeA
        }else if nodeB.physicsBody?.categoryBitMask == BitMaskCategory.target.rawValue && nodeA.physicsBody?.categoryBitMask == BitMaskCategory.bullet.rawValue{
            self.target = nodeB
        }
        
        if nodeA.physicsBody?.categoryBitMask == BitMaskCategory.object.rawValue && nodeB.physicsBody?.categoryBitMask == BitMaskCategory.pointer.rawValue{
            self.target = nodeA
        }else if nodeB.physicsBody?.categoryBitMask == BitMaskCategory.object.rawValue && nodeA.physicsBody?.categoryBitMask == BitMaskCategory.pointer.rawValue{
            self.target = nodeB
        }
        
        //i the bullet hits the target
        if nodeB.physicsBody?.categoryBitMask == BitMaskCategory.target.rawValue && nodeA.physicsBody?.categoryBitMask == BitMaskCategory.bullet.rawValue || nodeA.physicsBody?.categoryBitMask == BitMaskCategory.target.rawValue && nodeB.physicsBody?.categoryBitMask == BitMaskCategory.bullet.rawValue || nodeB.physicsBody?.categoryBitMask == BitMaskCategory.target.rawValue && nodeA.physicsBody?.categoryBitMask == BitMaskCategory.minigunBullet.rawValue || nodeA.physicsBody?.categoryBitMask == BitMaskCategory.target.rawValue && nodeB.physicsBody?.categoryBitMask == BitMaskCategory.minigunBullet.rawValue{
            let confetti = SCNParticleSystem(named: "Models.scnassets/Confetti.scnp", inDirectory: nil)
            confetti?.loops = false
            confetti?.particleLifeSpan = 4
            confetti?.emitterShape = target?.geometry
            let confettiNode = SCNNode()
            confettiNode.addParticleSystem(confetti!)
            confettiNode.position = contact.contactPoint
            self.sceneView.scene.rootNode.addChildNode(confettiNode)
            nodeA.removeFromParentNode()
            nodeB.removeFromParentNode()
            playEnemyHit()
        }
    }
    
    func checkPointerOverObject(nodeA: SCNNode, nodeB: SCNNode){
        //if the pointer is over an object
        if nodeB.physicsBody?.categoryBitMask == BitMaskCategory.object.rawValue && nodeA.physicsBody?.categoryBitMask == BitMaskCategory.pointer.rawValue || nodeA.physicsBody?.categoryBitMask == BitMaskCategory.object.rawValue && nodeB.physicsBody?.categoryBitMask == BitMaskCategory.pointer.rawValue{
            
            if(nodeA.physicsBody?.categoryBitMask == BitMaskCategory.pointer.rawValue){
                nodeA.geometry?.firstMaterial?.diffuse.contents = UIColor.red
                pointerYPosition = pointerYPosition + Float(nodeB.frame.height)
            }else if(nodeB.physicsBody?.categoryBitMask == BitMaskCategory.pointer.rawValue){
                nodeB.geometry?.firstMaterial?.diffuse.contents = UIColor.red
            }
            DispatchQueue.main.async {
                //Do UI Code here.
                self.addButton.isEnabled = false
            }
        }else{
            DispatchQueue.main.async {
                //Do UI Code here.
                self.addButton.isEnabled = true
            }
        }
    }
    
    func checkEnemyReachedGold(nodeA: SCNNode, nodeB: SCNNode){
        //if target reached the gold
        if  nodeA.physicsBody?.categoryBitMask == BitMaskCategory.gold.rawValue && nodeB.physicsBody?.categoryBitMask == BitMaskCategory.target.rawValue ||
            nodeA.physicsBody?.categoryBitMask == BitMaskCategory.target.rawValue && nodeB.physicsBody?.categoryBitMask == BitMaskCategory.gold.rawValue{
            
            var isAirstrike = false
            if let name = nodeA.name {
                print("##############nameA")
                print(name)
                if(name.contains("target")){
                    if(enemiesHitArray.contains(name)){
                        return
                    }else{
                        if  name.contains("Airstrike"){
                            isAirstrike = true
                        }
                        enemiesHitArray.append(name)
                    }
                }
                
            }
            //enemy
            print(enemiesHitArray)
            if let name = nodeB.name {
                if(name.contains("target")){
                    if(enemiesHitArray.contains(name)){
                        return
                    }else{
                        if  name.contains("Airstrike"){
                            isAirstrike = true
                        }
                        enemiesHitArray.append(name)
                    }
                }
            }
            
            DispatchQueue.main.async {
                //Do UI Code here.
                if(isAirstrike){
                    self.goldHealth = 0
                }else{
                    self.goldHealth = self.goldHealth - 10
                    if(self.goldHealth <= 0){
                        self.showAlertGameOver()
                    }
                }
                
            }
            print("health -10")
            print("health")
            print(goldHealth)
            
            if(nodeA.physicsBody?.categoryBitMask == BitMaskCategory.target.rawValue){
                nodeA.removeFromParentNode()
            }else if(nodeB.physicsBody?.categoryBitMask == BitMaskCategory.target.rawValue){
                nodeB.removeFromParentNode()
            }
            DispatchQueue.main.async {
                //Do UI Code here.
                self.addButton.isEnabled = false
            }
            let goldNode = findSCNNode(withName: "goldNode")
            deleteSCNNode(named: "healthNode")
            goldNode.addChildNode(createTextNode())
            playGoldHit()
        }
    }
    
    func checkEnemyHitObject(nodeA : SCNNode, nodeB: SCNNode){
        //if target reached the gold
        if nodeB.physicsBody?.categoryBitMask == BitMaskCategory.object.rawValue && nodeA.physicsBody?.categoryBitMask == BitMaskCategory.target.rawValue || nodeA.physicsBody?.categoryBitMask == BitMaskCategory.object.rawValue && nodeB.physicsBody?.categoryBitMask == BitMaskCategory.target.rawValue{
            nodeA.removeFromParentNode()
            nodeB.removeFromParentNode()
            playObjectDestroyed()
        }
        
    }
    
    @IBAction func startGame(_ sender: Any) {
        initGroundPlane()
        enableUI()
        self.hasPointer = true
    }
    @IBAction func addObject(_ sender: Any) {
        if(objectsToPlace == 0){
            showNoMoreObjectsAlert()
            return
        }
        objectsToPlace -= 1
        updateObjectsToPlaceLabel()
        let object = objectFactory.createObjectWithFriction(object: objectFactory.createObject(ofType: selectedItem!))
        // z is for height and is negative up
        
        let convertedPointerPos = toPlaneCoordinates(node: pointer!)
        print(convertedPointerPos)
        //object.position = SCNVector3(convertedPointerPos.x, groundPlane!.geometry!.boundingBox.max.y + object.geometry!.boundingBox.max.y, convertedPointerPos.z)
        if(object.name!.contains("shootable") || object.name!.contains("letter_box") || object.name!.contains("cylinder")){
            object.position = SCNVector3(convertedPointerPos.x, groundPlane!.geometry!.boundingBox.max.y , convertedPointerPos.z)
        }else{
            object.position = SCNVector3(convertedPointerPos.x, groundPlane!.geometry!.boundingBox.max.y + object.geometry!.boundingBox.max.y, convertedPointerPos.z)
        }
        
        
        object.eulerAngles = pointer!.eulerAngles
        playPlaceObject()

        groundPlane!.addChildNode(object)
        
    }
    func updateObjectsToPlaceLabel(){
        objectsToPlaceLabel.text = "Objects to place: \(objectsToPlace)"
    }
    @IBAction func addEnemy(_ sender: Any) {
        if(!doesNodeExist(name: "shootable")){
            showNoTowersAlert()
            return
        }
        enemiesHitArray = []
        shootButton.isEnabled = true
        addButton.isEnabled = false
        waveNumberLabel.text = "Current wave: \(waveController.waveNumber)"
        waveController.initNextWave(node: groundPlane!)
        startWaveSequenceUI()
    }
    
    @IBAction func shootMinigun(_ sender: Any) {
        let posOr = getCurrentPositionOfCamera()
        let position = posOr[0]
        let orientation = posOr[1]
        var power = Float(50)
        let bullet = SCNNode(geometry: SCNSphere(radius: 0.01))
        bullet.geometry?.firstMaterial?.diffuse.contents = UIColor.black
        bullet.position = position
        let body = SCNPhysicsBody(type: .dynamic, shape: SCNPhysicsShape(node: bullet, options: nil))
        body.isAffectedByGravity = false
        bullet.physicsBody = body
        bullet.physicsBody?.applyForce(SCNVector3(orientation.x * power,orientation.y * power,orientation.z * power), asImpulse: true)
        bullet.physicsBody?.categoryBitMask = BitMaskCategory.minigunBullet.rawValue
        bullet.physicsBody?.contactTestBitMask = ( BitMaskCategory.missile.rawValue|BitMaskCategory.target.rawValue)
        self.sceneView.scene.rootNode.addChildNode(bullet)
    }
    @IBAction func shootAction(_ sender: Any) {
        
        selectedItem = "pointer"
        
        guard let pointOfView = sceneView.pointOfView else {return}
        let transform = pointOfView.transform
        let orientation = SCNVector3(-transform.m31,-transform.m32,-transform.m33)
        let location = SCNVector3(transform.m41,transform.m42,transform.m43)
        let currentPositionOfCamera = addVectors(left: orientation, right: location)
        
        let bullet = SCNNode(geometry: SCNSphere(radius: 0.01))
        bullet.name = "bullet"
        bullet.geometry?.firstMaterial?.diffuse.contents = UIColor.black
        
        let body = SCNPhysicsBody(type: .dynamic, shape: SCNPhysicsShape(geometry: bullet.geometry!, options: nil))
        body.isAffectedByGravity = true
        bullet.physicsBody = body
        
        var nodes: [SCNNode] = []
        groundPlane!.childNodes.filter({ $0.name == "shootable" }).forEach({
            let node = $0
            nodes.append(node)
        })
        
        for var node in nodes {
            let bulletToShoot = bullet.clone()
            shootBullet(node: node, bullet: bulletToShoot, currentPositionOfCamera: currentPositionOfCamera)
        }
    }
    
    
    private func shootBullet(node: SCNNode, bullet: SCNNode, currentPositionOfCamera: SCNVector3){
        
        //can use convertPosition(_:to:) to convert position from one node to
        
        playShot()
        
        let convertedPointerPos = toPlaneCoordinates(node: pointer!)
        //pointer position in realation to the plane
        let pointerPosInPlaneCoord = SCNVector3(convertedPointerPos.x, 0.3,convertedPointerPos.z)
        
        let distanceToPointerFromTower = SCNVector3((pointerPosInPlaneCoord.x - node.position.x) * 10, 0, (pointerPosInPlaneCoord.z - node.position.z) * 10)
        let time = Float(2.0)
        
        //node is the tower we shoot from
        let forceVec = SCNVector3((distanceToPointerFromTower.x)/time, 0, (distanceToPointerFromTower.z)/time)
        let forceAngle = atan2(forceVec.z, forceVec.x)
        bullet.physicsBody?.applyForce(forceVec, asImpulse: true)
        let towerTop = node.childNode(withName: "Tower_Top", recursively: false)
        
        if let top = towerTop{
            let v1 = top.eulerAngles
            let v2 = forceVec
            let angle = Float.pi - forceAngle - node.eulerAngles.y - Float.pi/2
            print("top vec: \(v1)")
            print("force vec: \(v2)")
            print("force angle: \(forceAngle)")
            print("angle: \(angle)")
            top.eulerAngles = SCNVector3(top.eulerAngles.x, angle, top.eulerAngles.z)
        }
        let y = Float(0.25)
        let r = Float(0.05)
        let dx = r * cos(forceAngle)
        let dz = r * sin(forceAngle)
        //start position of the bullet
        bullet.position = SCNVector3(x: node.position.x + dx, y: y, z: node.position.z + dz)
        bullet.physicsBody?.categoryBitMask = BitMaskCategory.bullet.rawValue
        bullet.physicsBody?.contactTestBitMask = BitMaskCategory.target.rawValue
        groundPlane!.addChildNode(bullet)
    }
    
    func addVectors(left: SCNVector3, right: SCNVector3) -> SCNVector3{
        return SCNVector3Make(left.x+right.x, left.y+right.y, left.z+right.z)
    }
}

extension ViewController{
    
    
    func startWaveSequenceUI(){
        addButton.isHidden = true
        selectedItem = "pointer"
        itemsCollectionView.isHidden = true
        nextWaveButton.isHidden = true
        objectsToPlaceLabel.isHidden = true
        if(doesNodeExist(name: "shootable")){
            shootButton.isHidden = false
        }
    }
    func createGroundPlane(planeAnchor: ARPlaneAnchor)->SCNNode{
        
        let groundNode = SCNNode(geometry: SCNCylinder(radius: 2, height: 0.05))
        groundNode.geometry?.firstMaterial?.diffuse.contents = UIImage(named: "StreetCarpetTexture")
        groundNode.geometry?.firstMaterial?.isDoubleSided = true
        groundNode.geometry?.firstMaterial?.transparency = 1
        groundNode.name = "planeNode"
        let groundBodyShape = SCNPhysicsShape(geometry: groundNode.geometry!)
        let body = SCNPhysicsBody(type: .static, shape: groundBodyShape)
        //groundNode.physicsBody = body
        groundNode.position = SCNVector3(planeAnchor.center.x,planeAnchor.center.y,planeAnchor.center.z)

        let goldNode = createGoldNode()
        groundNode.addChildNode(goldNode)
        return groundNode
    }
    
    func createGoldNode()-> SCNNode{
        let goldNode = objectFactory.createObject(ofType: "gold")
        goldNode.position = SCNVector3(0,0.05,0)
        goldNode.name = "goldNode"
        goldNode.addChildNode(createTextNode())
        goldNode.physicsBody = SCNPhysicsBody.static()
        goldNode.physicsBody?.categoryBitMask = BitMaskCategory.gold.rawValue
        goldNode.physicsBody?.contactTestBitMask = BitMaskCategory.target.rawValue
        return goldNode
    }
    
    func createTextNode() -> SCNNode {
        let text = SCNText(string: "You have \(goldHealth) gold", extrusionDepth: 0.1)
        text.font = UIFont.systemFont(ofSize: 1.0)
        text.flatness = 0.01
        text.firstMaterial?.diffuse.contents = UIColor.white
        
        let textNode = SCNNode(geometry: text)
        textNode.name = "healthNode"
        
        let fontSize = Float(0.04)
        textNode.scale = SCNVector3(fontSize, fontSize, fontSize)
        textNode.position = SCNVector3(-0.1,0.2,0)
        
        return textNode
    }
    
    func isCompleted() {
        waveCompleted = true
    }
    
    func missileLounched() {
        informationLabel.text = "Missile Lounched!"
        minigunButton.isHidden = false
        playMissileLounch()
    }
    func showWaveCompletedAlert(){

        SCLAlertView().showSuccess("Wave \(waveController.waveNumber)", subTitle: "Completed!")
    }
    
    func showNoMoreObjectsAlert(){

        SCLAlertView().showError("Ooops!", subTitle: "Can't place more objects!")
    }
    func showNoTowersAlert(){

        SCLAlertView().showInfo("Nothing to shoot with", subTitle: "Add some towers!")
    }
    
    func showAlertGameOver(){

        SCLAlertView().showNotice("You've lost!", subTitle: "Play Again?")
    }
    
    func enableShootButton() {
        //shootButton.isHidden = false
        //shootButton.isEnabled = false
    }
    
    func toPlaneCoordinates(node: SCNNode) -> SCNVector3{
        return self.sceneView.scene.rootNode.convertPosition(node.position, to: groundPlane!)
    }
    
    func playEnemyHit(){
        guard let url = Bundle.main.url(forResource: "explosion_music", withExtension: "mp3") else { return }
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            
            /* The following line is required for the player to work on iOS 11. Change the file type accordingly*/
            explosionSoundEffectPlayer = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileType.mp3.rawValue)
            
            /* iOS 10 and earlier require the following line:
             player = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileTypeMPEGLayer3) */
            
            guard let explosionSoundEffectPlayer = explosionSoundEffectPlayer else { return }
            explosionSoundEffectPlayer.play()
            
        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    func playMissileLounch(){
        guard let url = Bundle.main.url(forResource: "missile_sound", withExtension: "mp3") else { return }
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            
            /* The following line is required for the player to work on iOS 11. Change the file type accordingly*/
            missileLaunchSoundEffectPlayer = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileType.mp3.rawValue)
            
            /* iOS 10 and earlier require the following line:
             player = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileTypeMPEGLayer3) */
            
            guard let missileLaunchSoundEffectPlayer = missileLaunchSoundEffectPlayer else { return }
            missileLaunchSoundEffectPlayer.play()
            
        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    func playShot(){
        guard let url = Bundle.main.url(forResource: "shot_music", withExtension: "mp3") else { return }
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            
            /* The following line is required for the player to work on iOS 11. Change the file type accordingly*/
            shootSoundEffectPlayer = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileType.mp3.rawValue)
            
            guard let shootSoundEffectPlayer = shootSoundEffectPlayer else { return }
            shootSoundEffectPlayer.play()
            
        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    func playGoldHit(){
        guard let url = Bundle.main.url(forResource: "gold_hit_sound", withExtension: "mp3") else { return }
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            
            /* The following line is required for the player to work on iOS 11. Change the file type accordingly*/
            goldHitSoundEffectPlayer = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileType.mp3.rawValue)
            
            guard let goldHitSoundEffectPlayer = goldHitSoundEffectPlayer else { return }
            goldHitSoundEffectPlayer.play()
            
        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    func playObjectDestroyed(){
        guard let url = Bundle.main.url(forResource: "object_destroyed_sound", withExtension: "mp3") else { return }
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            
            /* The following line is required for the player to work on iOS 11. Change the file type accordingly*/
            objectDestroyedSoundEffectPlayer = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileType.mp3.rawValue)
            
            guard let objectDestroyedSoundEffectPlayer = objectDestroyedSoundEffectPlayer else { return }
            objectDestroyedSoundEffectPlayer.play()
            
        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    func playPlaceObject(){
        guard let url = Bundle.main.url(forResource: "place_object_sound", withExtension: "mp3") else { return }
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            
            /* The following line is required for the player to work on iOS 11. Change the file type accordingly*/
            placeObjectSoundEffectPlayer = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileType.mp3.rawValue)
            
            guard let placeObjectSoundEffectPlayer = placeObjectSoundEffectPlayer else { return }
            placeObjectSoundEffectPlayer.play()
            
        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    func playMusicLoop() {
        guard let url = Bundle.main.url(forResource: "game_music", withExtension: "mp3") else { return }
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            
            /* The following line is required for the player to work on iOS 11. Change the file type accordingly*/
            player = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileType.mp3.rawValue)
            
            guard let player = player else { return }
            player.numberOfLoops = -1
            player.play()
            
        } catch let error {
            print(error.localizedDescription)
        }
    }
}

extension Int{
    var degreesToRadians: Double {return Double(self) * .pi/180}
}

