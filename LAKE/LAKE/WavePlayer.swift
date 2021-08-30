//
//  WavePlayer.swift
//  LAKE
//
//  Created by Chris Dzombak on 8/30/21.
//

import AVKit
import Foundation

class WavePlayer: ObservableObject {
    
    private let player: AVAudioPlayer
    
    @Published var isPlaying: Bool
    
    init() {
        self.isPlaying = false
        let sound = Bundle.main.path(forResource: "LakeMichiganWaves", ofType: "m4a")
        self.player = try! AVAudioPlayer(contentsOf: URL(fileURLWithPath: sound!))
        self.player.numberOfLoops = -1
    }
   
    func toggle() {
        if isPlaying {
            player.pause()
            isPlaying = false
            let audioSession = AVAudioSession.sharedInstance()
            do {
                try audioSession.setActive(false, options: [])
            } catch {
                print("Failed to set audio session inactive.")
            }
        } else {
            let audioSession = AVAudioSession.sharedInstance()
            do {
                try audioSession.setCategory(.playback, mode: .default, options: [])
                try audioSession.setActive(true, options: [])
            } catch {
                print("Failed to set audio session category/active.")
            }
            player.play()
            isPlaying = true
        }
    }
}
