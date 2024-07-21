//
//  SettingView.swift
//  A2GPad2
//
//  Created by Shunichi Kitahara on 2023/05/28.
//

import SwiftUI

struct SettingView: View {
    @ObservedObject var viewModel: Esp32ViewModel
    var body: some View {
        VStack {
            
        }
        HStack {
            Spacer(minLength:50)
            Stepper(value: $viewModel.midValueX, in: 0...255) {
                Text("Center X")
                    .font(.largeTitle)
                
            }
            Text(" \(Int(viewModel.midValueX))")
                .font(.largeTitle)
            Spacer(minLength:100)
        }
        HStack {
            Spacer(minLength:50)
            Stepper(value: $viewModel.midValueY, in: 0...255) {
                Text("Center Y")
                    .font(.largeTitle)
                
            }
            Text(" \(Int(viewModel.midValueY))")
                .font(.largeTitle)
            Spacer(minLength:100)
        }
        HStack {
            Spacer(minLength:50)
            Stepper(value: $viewModel.maxValue, in: 0...255) {
                Text("Max")
                    .font(.largeTitle)
            }
            Text(" \(Int(viewModel.maxValue))")
                .font(.largeTitle)
            Spacer(minLength:100)
        }
        .onDisappear(perform: {viewModel.disconnectDigitalPot()})
    }
}

struct SettingView_Previews: PreviewProvider {
    static var viewModel = Esp32ViewModel()
    static var previews: some View {
        SettingView(viewModel: viewModel)
    }
}
