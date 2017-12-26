//
//  ARScene.swift
//  ruckus
//
//  Created by Gareth on 25.12.17.
//  Copyright © 2017 Gareth. All rights reserved.
//

//
//  GameScene.swift
//  deer
//
//  Created by Gareth on 19.09.17.
//  Copyright © 2017 Gareth. All rights reserved.
//

import UIKit
import QuartzCore
import SceneKit

typealias AnimatedMove = [String:SCNAnimationPlayer]

class ARScene: SCNScene {
    var model = SCNNode()
    
    convenience init(create: Bool) {
        self.init()
        
        
        // load the first model state
        let stance = SCNScene(named: "art.scnassets/stance.dae")
        if let stanceUnWraped = stance {
            model = stanceUnWraped.rootNode.childNode(withName: "model", recursively: true)!
            
            
            // wrapper for scaling
            let nodeWrapper = SCNNode()
            nodeWrapper.scale = SCNVector3(1,1,1)
            nodeWrapper.position = SCNVector3Zero
            nodeWrapper.addChildNode(model)
            rootNode.addChildNode(nodeWrapper)
            
        }
        
        // start callin those babies
        let _ = ARAnimationController.init(withModel: model)
        
    }
    
    func lightsCameraAction() {
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        if let cam = cameraNode.camera {
            cam.usesOrthographicProjection = true
        }
        cameraNode.position = SCNVector3(0, 1, 5)
        
        // root node always accessible as we are subclassing scnscene
        rootNode.addChildNode(cameraNode)
        
        
        // lights
        let spotLightNode = SCNNode()
        spotLightNode.light = SCNLight()
        if let light = spotLightNode.light {
            light.type = .spot
            light.attenuationEndDistance = 100
            light.attenuationStartDistance = 0
            light.attenuationFalloffExponent = 1
            light.color = UIColor.white
        }
        spotLightNode.position = SCNVector3(0,10,10)
        rootNode.addChildNode(spotLightNode)
        //
        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        if let amLight = ambientLightNode.light {
            amLight.type = .ambient
            amLight.color = UIColor.white
        }
        rootNode.addChildNode(ambientLightNode)
        
        // DEBUG CUBE
        //        let cube = SCNBox(width: 1, height: 1, length: 1, chamferRadius: 0)
        //        cube.firstMaterial?.diffuse.contents = UIColor.red
        //        let box = SCNNode(geometry: cube)
        
        //        box.position = SCNVector3Zero
        //
        //        rootNode.addChildNode(box)
        
        // node to look at
        let spotLookAtNode = SCNNode()
        spotLookAtNode.position = SCNVector3Zero
        
        // look at look at node
        spotLightNode.constraints = [SCNLookAtConstraint(target: spotLookAtNode)]
        cameraNode.constraints = [SCNLookAtConstraint(target: spotLookAtNode)]
    }
}

