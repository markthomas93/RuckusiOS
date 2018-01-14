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
    
    var speed: Double = 0.5
    var callOutsEnabled: Bool = true
    
    var settingsAccessor: SettingsAccessor?
    
    var aniamtionSequences: [Timer] = []
    var attackTimer: Timer?
    
    static let sharedInstance = ARAnimationController()
    
    let soundManager = ARSoundManager()
    
    var hitting = false
    
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
        playMove(named: .idle, after: 0, lastMove: true)
    }
    
    @objc func runCombo() {
        hitting = true
        // clear all the animation timers from the last combo
        aniamtionSequences = []
        let combo = HitGiver.sharedInstance.getCombo()
        var i: Double = 0.0
        var factor = 1.0
        var index = 1
        for move in combo {
            let lastMove = (index == combo.count)
            playMove(named: move, after: i, lastMove: lastMove)
            switch move {
            case .bigCross:
                factor = 1.8
            case .cross:
                factor = 0.6
            default:
                factor = 1.0
            }
            i = i + (factor / speed)
            index += 1
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
        playMove(named: .idle, after: 0, lastMove: true)
    }
    
    func playMove(named move: Move, after: Double, lastMove: Bool) {
        if let player = model.animationPlayer(forKey: move.rawValue) {
            let moveTime = Timer.scheduledTimer(timeInterval: after, target: self, selector: #selector(whosGotta(_:)), userInfo: [player, lastMove, move], repeats: false)
            aniamtionSequences.append(moveTime)
        }
    }
    
    @objc func whosGotta(_ timer: Timer) {
        if let info = timer.userInfo as? [AnyObject] {
            if let player = info[0] as? SCNAnimationPlayer, let lastMove = info[1] as? Bool, let move = info[2] as? Move {
                // stop other animations
                for pl in players {
                    pl.stop(withBlendOutDuration: 0.2)
                }
                player.play()
                
                // play the swoosh sound for each punch
                if move != .idle {
                    // work out delay time for swoosh noise
                    var delay: Double = 0
                    switch move {
                    case .bigCross:
                        delay = 1.2 / speed
                    default:
                        delay = 0.4 / speed
                    }
                    Timer.scheduledTimer(withTimeInterval: delay, repeats: false, block: { _ in
                        self.soundManager.swoosh()
                    })
                }
                
                if lastMove {
                    hitting = false
                }
            }
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
