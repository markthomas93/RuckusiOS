//
//  ARScene.swift
//  ruckus
//
//  Created by Gareth on 25.12.17.
//  Copyright © 2017 Gareth. All rights reserved.
//
import UIKit
import QuartzCore
import SceneKit
import GameKit

// collision categories for interactions between fighter and player
enum CollisionCategory : Int {
    case player = 1
    case fighter
}

enum AnimationModelName: String {
    case regularBoxer
    case beastBoxer
    case soldier
    case swat
    case joe
}

class ARScene: SCNScene, SCNPhysicsContactDelegate {
    var model = SCNNode()
    var modelWrapper = SCNNode()
    
    
    var headNode = SCNNode()
    
    var punchDelegate: PunchInTheHeadDelegate?
    var theFloor: Float = 0
    
    var modelName: AnimationModelName = .regularBoxer
    var settingsAccessor: SettingsAccessor?
    
    var animationController: ARAnimationController?
    
    var spotLightNode = SCNNode()
    var ambientLightNode = SCNNode()
    
    var floorNode = SCNNode()
    
    convenience init(create: Bool) {
        self.init()
        
        settingsAccessor = SettingsAccessor()
        
        if let animationName = settingsAccessor?.getModelName() {
            if let enumValue = AnimationModelName.init(rawValue: animationName) {
                self.modelName = enumValue
            }
        }
        
        // this class will check for collisions
        physicsWorld.contactDelegate = self
        
//        createFloor()
        
        createPlayerNode()
        
        setUpChar()
        
        ligntMeUp()
        
        // start callin the hits
        animationController = ARAnimationController.init(withModel: model)
        
    }
    
    func updateHeadPos(withPosition position: matrix_float4x4) {
        // only look at if not throwing a combo, else it is too hard to move
        // out the way
        if let animationController = self.animationController {
            if !animationController.hitting {
                // where should we look
                let posForLookAt = SCNVector3(
                    position.columns.3.x,
                    theFloor,
                    position.columns.3.z
                )
                modelWrapper.look(at: posForLookAt)
            }
        }
    
        // then we set the head node transform using the normal transform matrix
        headNode.transform = SCNMatrix4FromMat4(position)
    }
    
    func ligntMeUp() {
        // lights
        spotLightNode.light = SCNLight()
        if let light = spotLightNode.light {
            light.type = .spot
            light.color = UIColor.white
            light.intensity = 1800
            // maybe we come back to shadows later
//            light.castsShadow = true
////            light.shadowColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.4)
//            light.shadowRadius = 200
//            light.shadowMode = .deferred
        }
        
        spotLightNode.position = SCNVector3(0,10,4)
        rootNode.addChildNode(spotLightNode)
        
        ambientLightNode.light = SCNLight()
        if let amLight = ambientLightNode.light {
            amLight.type = .ambient
            amLight.color = UIColor.white
            amLight.intensity = 200
        }
        rootNode.addChildNode(ambientLightNode)
        
        spotLightNode.constraints = [SCNLookAtConstraint(target: modelWrapper)]
        
    }
    
    func setUpChar() {
        // load the char dae
        let charModel = SCNScene(named: "art.scnassets/\(modelName.rawValue).dae")
        if let charUnwrapped = charModel {
            
            // we need to do this as mixamo puts all on root level
            for child in charUnwrapped.rootNode.childNodes {
                model.addChildNode(child)
            }
            
            // 'face' the correct direction, for the look at
            model.rotation = SCNVector4(0, 1, 0, Float(180).degreesToRadians)
            
//            0.0105 is my height
            model.scale = SCNVector3(0.0105, 0.0105, 0.0105)
            model.position = SCNVector3(0,0,0)
            
            // add some levels of detail for the main char to bring the size down
            var levelsOfDetail: [SCNLevelOfDetail] = []
            
            let charNode = rootNode.childNode(withName: "Alpha_Surface", recursively: true)
            
            for index in 0 ... 5 {
                if let geo = charNode?.geometry {
                    let detailLevel = SCNLevelOfDetail(geometry: geo, worldSpaceDistance: CGFloat(index - 1))
                    levelsOfDetail.append(detailLevel)
                }
            }
            
            if let geo = charNode?.geometry {
                geo.levelsOfDetail = levelsOfDetail
            }
            
            // add collision detection to the hand nodes, these are ones we will add!
            
            let handBoxSize = CGFloat(0.1)
            let leftGeo = SCNBox(width: handBoxSize, height: handBoxSize, length: handBoxSize, chamferRadius: 0)
            let rightGeo = SCNBox(width: handBoxSize, height: handBoxSize, length: handBoxSize, chamferRadius: 0)
            
            let leftHandNode = SCNNode(geometry: leftGeo)
            let rightHandNode = SCNNode(geometry: rightGeo)
            
            if let lh = model.childNode(withName: "mixamorig_LeftHandMiddle1", recursively: true), let rh = model.childNode(withName: "mixamorig_RightHandMiddle1", recursively: true) {
                lh.addChildNode(leftHandNode)
                rh.addChildNode(rightHandNode)
            }
            
            // add collision detection to the boxes on the hands
            leftHandNode.physicsBody = SCNPhysicsBody.kinematic()
            rightHandNode.physicsBody = SCNPhysicsBody.kinematic()
            
            if let leftPhysBod = leftHandNode.physicsBody, let rightPhysBod = rightHandNode.physicsBody {
                leftPhysBod.categoryBitMask = CollisionCategory.fighter.rawValue
                leftPhysBod.contactTestBitMask = CollisionCategory.player.rawValue
                rightPhysBod.categoryBitMask = CollisionCategory.fighter.rawValue
                rightPhysBod.contactTestBitMask = CollisionCategory.player.rawValue
            }
            
            // wrapper for scaling, and used later for following
            modelWrapper.addChildNode(model)
            
        }
    }
    
    func setCharAt(position: SCNVector3) {
        modelWrapper.position = position
        // the floor os used to work out the y for the look at!
        theFloor = position.y
        rootNode.addChildNode(modelWrapper)
    }
    
    func moveFloorTo(position: SCNVector3) {
        createFloor()
        floorNode.position = SCNVector3(0, position.y - 0.1, 0)
    }
    
    func createFloor() {
        let floorGeo = SCNFloor()
        floorGeo.reflectivity = 0
        
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.white
        
        material.blendMode = .multiply
        material.lightingModel = .lambert
        
//        material.colorBufferWriteMask = SCNColorMask(rawValue: 0)
        floorGeo.materials = [material]

        floorNode = SCNNode(geometry: floorGeo)
        
        rootNode.addChildNode(floorNode)
    }
    
    func createPlayerNode() {
        
        // add a box inside this piller, this is the one that represents the users head
        let headGeo = SCNBox(width: 0.1, height: 0.1, length: 0.1, chamferRadius: 0)
        // do not want to see the head
        headGeo.firstMaterial?.diffuse.contents = UIColor.clear
        headNode = SCNNode(geometry: headGeo)
        
        headNode.physicsBody = SCNPhysicsBody.kinematic()
        if let physBod = headNode.physicsBody {
            physBod.categoryBitMask = CollisionCategory.player.rawValue
            physBod.contactTestBitMask = CollisionCategory.fighter.rawValue
        }
        
        rootNode.addChildNode(headNode)
    }
    
    // MARK: - Collision detection set up and delegate
    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        let isAFighter = contact.nodeA.physicsBody!.categoryBitMask == CollisionCategory.fighter.rawValue
        let isAPlayer = contact.nodeA.physicsBody!.categoryBitMask == CollisionCategory.player.rawValue
        
        let isBFighter = contact.nodeB.physicsBody!.categoryBitMask == CollisionCategory.fighter.rawValue
        let isBPlayer = contact.nodeB.physicsBody!.categoryBitMask == CollisionCategory.player.rawValue
        
        if (isAPlayer && isBFighter) || (isAFighter && isBPlayer) {
            // send a message for the amount of times hit to the overlay
            if let delegate = punchDelegate {
                if delegate.canBeHit {
                    delegate.didGetPunched()
                }
            }
        }
    }
}

