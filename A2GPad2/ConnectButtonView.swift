//
//  ConnectButtonView.swift
//  Mcp4151VolTest
//
//  Created by Shunichi Kitahara on 2023/05/05.
//

import Foundation
import SwiftUI

struct ConnectButtonView: View {
    @ObservedObject var viewModel: DigitalPotViewModel
    
    var body: some View {

            if viewModel.connected {
                Button(action: {
                    viewModel.disconnectDigitalPot()
                }, label: {
                    Text("Disconnect").font(.largeTitle)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .padding()
                })
            } else {
                Button(action: {
                    viewModel.connectDigitalPot()
                }, label: {
                    Text("Connect").font(.largeTitle)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .padding()
                })
            }
    }
}

struct ConnectButtonView_Previews: PreviewProvider {
    static var viewModel = DigitalPotViewModel()
    static var previews: some View {
        ConnectButtonView(viewModel: viewModel)
    }
}
