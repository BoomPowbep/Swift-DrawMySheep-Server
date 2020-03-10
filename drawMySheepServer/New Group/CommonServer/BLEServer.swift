//
//  BLEServer.swift
//  BLEClient
//
//  Created by AL on 27/02/2020.
//  Copyright © 2020 AL. All rights reserved.
//

import Foundation
import CoreBluetooth

class BLEServer {
    static let instance = BLEServer()
    
    private var periphGatt:PeripheralGatt!
    var periph:PeripheralController?
    private var serverName:String = ""
    
    var stateCallback:((PeripheralState)->())? = nil
    
    func startServerWithName(name:String, callback:@escaping(PeripheralState)->()) {
        stateCallback = callback
        let customGATT = GATTStruct.replacingOccurrences(of: "###", with: name)
        setupServerWithJSONGatt(customGATT)
    }
    
    func listenForMessages(callback:@escaping(Data)->()) {
        ChararcteristicPipe.instance.listenForEvents { (event) in
            if let data = event.message {
                callback(data)
            }
        }
    }
    
    func sendMessage(data:Data) {
        if let p = self.periph,
            let char = BLEServer.instance.periph!.notifyingChars.first {
            p.peripheral.updateValue(data, for: char as! CBMutableCharacteristic, onSubscribedCentrals: nil)
        }
    }
    
    func stop() {
        if periph?.peripheralState.advertising ?? false {
            try? periph?.turnOff()
        }
    }
    
    func managePeripheralState(_ state:PeripheralState)  {
        stateCallback?(state)
    }
    
    
    private func setupServerWithJSONGatt(_ structStr:String) {
        if let jsonData = structStr.data(using: String.Encoding.utf8),
            let gattModel = try? JSONDecoder().decode(Gatt.self, from: jsonData) {
            
            periphGatt = PeripheralGatt(model: gattModel)
            periph = PeripheralController(config: periphGatt)
            
            periph?.listenForState { (state) in
                self.managePeripheralState(state)
            }
            
            do {
                try periph?.turnOn()
            } catch {
                
            }
        }
    }
}



