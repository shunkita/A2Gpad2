//
//  Esp32ViewModel.swift
//  Mcp4151VolTest
//
//  Created by Shunichi Kitahara on 2023/05/05.
//


import Foundation
import CoreBluetooth

enum Esp32Command:UInt8 {
    case button0
    case button1
    case button2
    case paddle0        //3
    case paddle1
    case paddle2
    case paddle3
}


//  Mid //c 96  //e  103     Max //c 198   //e x 205  y
class Esp32ViewModel : NSObject, ObservableObject, Identifiable {
    var id = UUID()

    // MARK: - Interface
    @Published var output = "Disconnected"  // current text to display in the output field
    @Published var connected = false  // true when BLE connection is active
    @Published var midValueX:Double = 96
    @Published var midValueY:Double = 96
    @Published var maxValue:Double = 198

    

    
    // MARK: - Set Command
    private var paddleOperands:[UInt8] = [0x00, 0x00]  // command, value
  
    // MARK: - JoyStick Command
    func paddleChange0(_ value: UInt8) {
        sendJoyStick(command: Esp32Command.paddle0, value: value)
    }
    func paddleChange1(_ value: UInt8) {
        sendJoyStick(command: Esp32Command.paddle1, value: value)
    }
    func centerPaddle() {
        sendJoyStick(command: Esp32Command.paddle0, value: UInt8(midValueX))
        sendJoyStick(command: Esp32Command.paddle1, value: UInt8(midValueY))
    }
    func buttonChange(command: Esp32Command,  value: UInt8) {
        sendJoyStick(command: command, value:value )
    }
    
    func sendJoyStick(command: Esp32Command, value: UInt8) {
        guard let peripheral = connectedPeripheral,
              let inputChar = inputChar else {
            output = "Connection error"
            return
        }
        paddleOperands[0] = command.rawValue
        paddleOperands[1] = value
        peripheral.writeValue(Data(paddleOperands), for: inputChar, type: .withoutResponse)
    }
    // MARK: - Mouse Command
    
   
    // MARK: - BLE
    private var centralQueue: DispatchQueue?

    private let serviceUUID = CBUUID(string: "AF4E5769-F201-46AF-8897-5787719E48EE")
    
    private let inputCharUUID = CBUUID(string: "DAEF00F5-CB68-4A1F-AB35-16C936FFD272")
    private var inputChar: CBCharacteristic?
//    private let outputCharUUID = CBUUID(string: "643954A4-A6CC-455C-825C-499190CE7DB0")
//    private var outputChar: CBCharacteristic?
    
    // service and peripheral objects
    private var centralManager: CBCentralManager?
    private var connectedPeripheral: CBPeripheral?

    func connectESP32() {
        output = "Connecting..."
        centralQueue = DispatchQueue(label: "test.discovery")
        centralManager = CBCentralManager(delegate: self, queue: centralQueue)
    }
    
    func disconnectDigitalPot() {
        guard let manager = centralManager,
              let peripheral = connectedPeripheral else { return }
        
        manager.cancelPeripheralConnection(peripheral)
    }
}

extension Esp32ViewModel: CBCentralManagerDelegate {
    
    // This method monitors the Bluetooth radios state
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print("Central Manager state changed: \(central.state)")
        if central.state == .poweredOn {
            central.scanForPeripherals(withServices: [serviceUUID], options: nil)
        }
    }

    // Called for each peripheral found that advertises the serviceUUID
    // This test program assumes only one peripheral will be powered up
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print("Discovered \(peripheral.name ?? "UNKNOWN")")
        central.stopScan()
        
        connectedPeripheral = peripheral
        central.connect(peripheral, options: nil)
    }

    // After BLE connection to peripheral, enumerate its services
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Connected to \(peripheral.name ?? "UNKNOWN")")
        peripheral.delegate = self
        peripheral.discoverServices(nil)
    }
    
    // After BLE connection, cleanup
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("Disconnected from \(peripheral.name ?? "UNKNOWN")")
        
        centralManager = nil
        
        DispatchQueue.main.async {
            self.connected = false
            self.output = "Disconnected"
        }
    }
}

extension Esp32ViewModel : CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        print("Discovered services for \(peripheral.name ?? "UNKNOWN")")
        
        guard let services = peripheral.services else {
            return
        }
        
        for service in services {
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        print("Discovered characteristics for \(peripheral.name ?? "UNKNOWN")")
        
        guard let characteristics = service.characteristics else {
            return
        }
        
        for ch in characteristics {
            switch ch.uuid {
                case inputCharUUID:
                    inputChar = ch
//                case outputCharUUID:
//                    outputChar = ch
                    // subscribe to notification events for the output characteristic
                    peripheral.setNotifyValue(true, for: ch)
                default:
                    break
            }
        }
        
        DispatchQueue.main.async {
            self.connected = true
            self.output = "Connected."
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        print("Notification state changed to \(characteristic.isNotifying)")
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        print("Characteristic updated: \(characteristic.uuid)")
        /*
        if characteristic.uuid == outputCharUUID, let data = characteristic.value {
            let bytes:[UInt8] = data.map {$0}
            
            if let answer = bytes.first {
                DispatchQueue.main.async {
                    self.output = "\(self.operands[0]) \(self.operatorSymbol) \(self.operands[1]) = \(answer)"
                    
                    // Clear inputs
                    self.operands[0] = 0x00
                    self.operands[1] = 0x00
                }
            }
        }
         */
    }
}
