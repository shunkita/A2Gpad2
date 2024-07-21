//
//  ContentView.swift
//  A2GPad2
//
//  Created by Shunichi Kitahara on 2023/05/27.
//

import SwiftUI

struct ContentView: View {
    @StateObject var viewModel = Esp32ViewModel()
    @State  var connectState = " Play "
    var body: some View {
        NavigationView {
            VStack(spacing:70) {
                Text("apple II joystick controller")
                    .font(.custom("Motter Tektura", size: 34))
                    .foregroundColor(.blue)
                NavigationLink(destination:JoyStickView(viewModel: viewModel)) {
                    Text(connectState)
                        .font(.title)
                        .border(.blue)
                }
                .simultaneousGesture(TapGesture().onEnded{viewModel.connectESP32()})
                
                NavigationLink(destination: SettingView(viewModel: viewModel)) {
                    Text(" Settings" )}
                .font(.title)
                .border(.blue)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
