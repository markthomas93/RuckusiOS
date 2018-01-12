//
//  ARAnimationController.swift
//  ruckus
//
//  Created by Gareth on 26.12.17.
//  Copyright © 2017 Gareth. All rights reserved.
//

import Foundation
import SceneKit

class ARAnimationController {
    var model = SCNNode()
    var players: [SCNAnimationPlayer] = []
    let animations: [Move] = [.jab, .cross, .idle, .rightHook, .bigCross]
    
    var runningPlayer: SCNAnimationPlayer?
    var speed: Double = 0.5
    var callOutsEnabled: Bool = true
    
    var settingsAccessor: SettingsAccessor?
    
    var aniamtionSequences: [Timer] = []
    var attackTimer: Timer?
    
    static let sharedInstance = ARAnimationController()
    
    init() {
        settingsAccessor = SettingsAccessor()
        
        if let difficulty = settingsAccessor?.getDifficulty() {
            speed = Double(difficulty) + 0.5
        }
        
        if let enabled = settingsAccessor?.getCallOuts() {
            callOutsEnabled = enabled
        }
    }
    
    convenience init(withModel model: SCNNode) {
        self.init()
        self.model = model
        setUpMoves()
        
        // start with the idle stance on init
        playMove(named: .idle, after: 0)
    }
    
    @objc func runCombo() {
        // clear all the animation timers from the last combo
        aniamtionSequences = []
        let combo = HitGiver.sharedInstance.getCombo()
        var i: Double = 0.0
        var factor = 1.0
        for move in combo {
            playMove(named: move, after: i)
            if move == .bigCross {
                factor = 2.0
            }
            i = i + (factor / speed)
        }
    }
    
    // this gets called when we switch to a form of working mode
    func didStart() {
        runCombo()
        // just go into full attack mode
        attackTimer = Timer.scheduledTimer(timeInterval: 5.0 / speed, target: self, selector: #selector(runCombo), userInfo: nil, repeats: true)
    }
    
    // this gets called when we go into a paused / rest / ended mode
    func didStop() {
        // stop all that are qeued
        for timer in aniamtionSequences {
            timer.invalidate()
        }
        
        attackTimer?.invalidate()
        
        // stop the animations running
        for pl in players {
            pl.stop(withBlendOutDuration: 0.2)
        }
        // play the idle
        playMove(named: .idle, after: 0)
    }
    
    func playMove(named move: Move, after: Double) {
        if let player = model.animationPlayer(forKey: move.rawValue) {
            let move = Timer.scheduledTimer(timeInterval: after, target: self, selector: #selector(whosGotta(_:)), userInfo: player, repeats: false)
            aniamtionSequences.append(move)
            runningPlayer = player
        }
    }
    
    @objc func whosGotta(_ timer: Timer) {
        if let player = timer.userInfo as? SCNAnimationPlayer {
            // stop other animations
            for pl in players {
                pl.stop(withBlendOutDuration: 0.2)
            }
            player.play()
        }
       
    }
    
    func setUpMoves() {
        for animation in animations {
            let player = AnimationLoader.loadAnimation(fromSceneNamed: "art.scnassets/\(animation.rawValue).dae")
            
            switch (animation) {
            case .idle:
                player.speed = 1.2
            default:
                player.speed = CGFloat(speed)
            }

            players.append(player)

            model.addAnimationPlayer(player, forKey: animation.rawValue)
        }
    }
}
