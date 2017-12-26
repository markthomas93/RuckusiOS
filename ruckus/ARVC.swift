//
//  ARVC.swift
//  ruckus
//
//  Created by Gareth on 22.12.17.
//  Copyright © 2017 Gareth. All rights reserved.
//

import UIKit
import QuartzCore
import SceneKit
import ARKit

class ARVC: UIViewController, ARSCNViewDelegate {
    @IBOutlet weak var scnView: SCNView!
    @IBOutlet weak var arSceneView: ARSCNView!
    
    let scene = ARScene.init(create: true)
   
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // AR version
//        arSceneView.scene = scene
//        arSceneView.allowsCameraControl = true
//        arSceneView.showsStatistics = true
        
        // normal verison
        arSceneView.isHidden = true
        scnView.scene = scene
        
        // allows the user to manipulate the camera
        scnView.allowsCameraControl = true
        
        // show statistics such as fps and timing information
        scnView.showsStatistics = true
        
        // configure the view
        scnView.backgroundColor = UIColor.black
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let orientation = UIInterfaceOrientation.landscapeRight.rawValue
        UIDevice.current.setValue(orientation, forKey: "orientation")
        UIViewController.attemptRotationToDeviceOrientation()
        
        // ARKit shizzle
//        let configuration = ARWorldTrackingConfiguration()
        
        // Run the view's session
//        arSceneView.session.run(configuration)
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .landscapeRight
        } else {
            return .portrait
        }
    }
    
    override var shouldAutorotate: Bool {
        return true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

}