//
//  ContentView.swift
//  LAKE
//
//  Created by Chris Dzombak on 8/30/21.
//

import AVKit
import SwiftUI

// https://stackoverflow.com/questions/56610957/is-there-a-method-to-blur-a-background-in-swiftui
struct VisualEffectView: UIViewRepresentable {
    var effect: UIVisualEffect?
    func makeUIView(context: UIViewRepresentableContext<Self>) -> UIVisualEffectView { UIVisualEffectView() }
    func updateUIView(_ uiView: UIVisualEffectView, context: UIViewRepresentableContext<Self>) { uiView.effect = effect }
}

struct LakeView: View {
    @ObservedObject var wavePlayer: WavePlayer
    
    init() {
        wavePlayer = WavePlayer()
    }
    
    var body: some View {
        HStack {
            Spacer()
            VStack {
                Spacer()
                Button(action:{
                    wavePlayer.toggle()
                }, label: {
                    // TODO(cdzombak): how to dedupe this button style code?
                    if wavePlayer.isPlaying {
                        Image(systemName: "pause.circle")
                            .font(Font.system(.largeTitle))
                            .padding(45)
                            .foregroundColor(Color(UIColor.darkGray))
                    } else {
                        Image(systemName: "play.circle")
                            .font(Font.system(.largeTitle))
                            .padding(45)
                            .foregroundColor(Color(UIColor.darkGray))
                    }
                })
                .background(VisualEffectView(effect: UIBlurEffect(style: .light)))
                .cornerRadius(40)
                Spacer()
            }
            Spacer()
        }
        .background(
            Image("gradient").resizable()
        )
        .edgesIgnoringSafeArea(.all)
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification), perform: { _ in
            wavePlayer.resyncState()
        })
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        LakeView()
    }
}
