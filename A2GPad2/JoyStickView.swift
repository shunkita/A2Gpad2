//
//  PlayView.swift
//  TransTest
//
//  Created by Shunichi Kitahara on 2023/05/22.
//

import SwiftUI
let potViewSize = 300.0

struct JoyStickView: View {
    @ObservedObject var viewModel: Esp32ViewModel
    @GestureState var translation: CGSize = .zero
    @State var position: CGSize = .zero
    @State var viewSize: CGSize = .zero
    @State var potSize: CGSize = .zero
    @State var potX: UInt = 0
    @State var potY: UInt = 0
 
    func adjust(size:inout CGSize)  {
        if (size.width < 0) {
            size.width = 0
        }
        if (size.width > viewSize.width) {
            size.width = viewSize.width
        }
        if (size.height < 0) {
            size.height = 0
        }
        if (size.height > viewSize.height) {
            size.height = viewSize.height
        }
    }
//send pot value
    func sendToPot(value:inout CGSize) {
        self.adjust(size: &value)

        let tmpX = Double(value.width / viewSize.width) * $viewModel.maxValue.wrappedValue
        let x = UInt8(tmpX)
        viewModel.paddleChange0(x)

        let tmpY = Double(value.height / viewSize.height) * $viewModel.maxValue.wrappedValue
        let y = UInt8(tmpY)
        viewModel.paddleChange1(y)
        print("x = \(x) y = \(y) ")
    }
    
// pot gesture
    var pDrag : some Gesture {
        DragGesture()
           .onChanged{ value in
               self.position = CGSize(
                   width: value.startLocation.x + value.translation.width,
                   height: value.startLocation.y + value.translation.height)

               self.sendToPot(value: &self.position)
           }
           .onEnded{ value in
               self.position = CGSize(
                   width: value.startLocation.x + value.translation.width,
                   height: value.startLocation.y + value.translation.height)

               self.sendToPot(value: &self.position)
           }
       }
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 50) {
// button gesture
                let gestureButton0 = DragGesture(minimumDistance: 0, coordinateSpace: .local).onChanged({_ in
                    viewModel.buttonChange(command: Esp32Command.button0, value:255)
                    print("btn push")
                }).onEnded({_ in
                    viewModel.buttonChange(command: Esp32Command.button0, value: 0)
                    print("btn end")
                })
                let gestureButton1 = DragGesture(minimumDistance: 0, coordinateSpace: .local).onChanged({_ in
                    viewModel.buttonChange(command: Esp32Command.button1,
                                           value:255)
                }).onEnded({_ in
                    viewModel.buttonChange(command: Esp32Command.button1, value: 0)
                })
 
// rectangles
// filler
                Rectangle()
                    .frame(width: 50)
                    .foregroundColor(.clear)
// button
                VStack (spacing:40){
                    Rectangle()
                        .frame(width: 200)
                        .foregroundColor(Color(red: 0, green: 0.8, blue: 0.6).opacity(0.4))
                        .gesture(gestureButton1)
                    Rectangle()
                        .frame(width: 200 )
                        .foregroundColor(Color(red: 0.9, green: 0, blue: 0.4).opacity(0.4))
                        .gesture(gestureButton0)
                }
// joystick
                Rectangle()
                    .fill(Color(.lightGray).opacity(0.3))
//                    .frame(width: geometry.size.height)
                    .frame(width: potViewSize, height: potViewSize)
//                    .onAppear(perform: {viewSize = geometry.size; print("VSIZE x=\(viewSize.width) x=\(viewSize.height)")})
                    .onAppear(perform: { viewSize = CGSize(width: potViewSize, height:potViewSize)})
// double tap
                    .onTapGesture(count:2, perform: {_ in
                        viewModel.centerPaddle()})
                    .gesture(pDrag)
//  single tap
                    .gesture(DragGesture(minimumDistance: 0).onEnded{ event in
                        potSize.width = event.location.x
                        potSize.height = event.location.y
                        self.sendToPot(value: &self.potSize)
                    })
            }
        }
        .onDisappear(perform: {viewModel.disconnectDigitalPot()})
    }
}

struct JoyStickView_Previews: PreviewProvider {
    static var viewModel = Esp32ViewModel()
    static var previews: some View {
        JoyStickView(viewModel: viewModel)
    }
}
