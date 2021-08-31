//
//  WavePlayer.swift
//  LAKE
//
//  Created by Chris Dzombak on 8/30/21.
//

import AVKit
import Foundation
import MediaPlayer

class WavePlayer: NSObject, ObservableObject, AVAudioPlayerDelegate {
    
    private let player: AVAudioPlayer
    
    @Published var isPlaying: Bool = false
    
    override init() {
        let sound = Bundle.main.path(forResource: "LakeMichiganWaves", ofType: "m4a")
        self.player = try! AVAudioPlayer(contentsOf: URL(fileURLWithPath: sound!))
        self.player.numberOfLoops = -1
        
        super.init()
        
        self.player.delegate = self

        // https://developer.apple.com/documentation/avfaudio/avaudiosession/responding_to_audio_session_interruptions
        let nc = NotificationCenter.default
        nc.addObserver(self,
                       selector: #selector(handleInterruption),
                       name: AVAudioSession.interruptionNotification,
                       object: AVAudioSession.sharedInstance)
        // https://developer.apple.com/documentation/avfaudio/avaudiosession/responding_to_audio_session_route_changes
        nc.addObserver(self,
                       selector: #selector(handleRouteChange),
                       name: AVAudioSession.routeChangeNotification,
                       object: nil)
        
        // https://stackoverflow.com/questions/34688128/how-do-i-get-audio-controls-on-lock-screen-control-center-from-avaudioplayer-in
        UIApplication.shared.beginReceivingRemoteControlEvents()
        let commandCenter = MPRemoteCommandCenter.shared()
        commandCenter.playCommand.addTarget { [unowned self] event in
            if !self.isPlaying {
                self.play()
                return .success
            }
            return .commandFailed
        }
        commandCenter.pauseCommand.addTarget { [unowned self] event in
            if self.isPlaying {
                self.pause()
                return .success
            }
            return .commandFailed
        }
    }
    
    @objc func handleInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo,
                let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
                let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
                    return
            }

        switch type {
        case .began:
            pause()
        case .ended:
            guard let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt else { return }
            let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
            if options.contains(.shouldResume) {
                play()
            }
        default: ()
        }
    }
    
    @objc func handleRouteChange(notification: Notification) {
        guard let userInfo = notification.userInfo,
            let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
            let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else {
                return
        }
        
        switch reason {
//        case .newDeviceAvailable:
//            let session = AVAudioSession.sharedInstance()
//            headphonesConnected = hasHeadphones(in: session.currentRoute)
        case .oldDeviceUnavailable:
            // for my use case, I just care that audio pauses when a speaker disconnects:
            pause()
//            if let previousRoute =
//                userInfo[AVAudioSessionRouteChangePreviousRouteKey] as? AVAudioSessionRouteDescription {
//                headphonesConnected = hasHeadphones(in: previousRoute)
//            }
        default: ()
        }
    }

//    func hasHeadphones(in routeDescription: AVAudioSessionRouteDescription) -> Bool {
//        // Filter the outputs to only those with a port type of headphones.
//        return !routeDescription.outputs.filter({$0.portType == .headphones}).isEmpty
//    }
    
    @objc func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isPlaying = false
    }
    
    func play() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playback, mode: .default, options: [])
            try audioSession.setActive(true, options: [])
            try audioSession.setPrefersNoInterruptionsFromSystemAlerts(true)
        } catch {
            print("Failed to set audio session category/active.")
        }
        
        player.play()
        isPlaying = true
    
        var nowPlayingInfo = [String : Any]()
        nowPlayingInfo[MPMediaItemPropertyTitle] = "LAKE"
        if let image = UIImage(named: "sunset") {
            nowPlayingInfo[MPMediaItemPropertyArtwork] =
                MPMediaItemArtwork(boundsSize: image.size) { size in
                    return image
            }
        }
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = player.currentTime
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = player.rate
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
    
    func pause() {
        player.pause()
        isPlaying = false
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: [])
        } catch {
            print("Failed to set audio session inactive.")
        }
    }
   
    func toggle() {
        if isPlaying {
            pause()
        } else {
            play()
        }
    }
    
    func resyncState() {
        isPlaying = player.isPlaying
    }
}
