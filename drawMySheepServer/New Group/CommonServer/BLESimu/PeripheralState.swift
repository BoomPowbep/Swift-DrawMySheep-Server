//
//  PeripheralState.swift
//  AppleBLEServer
//
//  Created by AL on 04/12/2019.
//  Copyright © 2019 AL. All rights reserved.
//

import Foundation

struct PeripheralState:CustomStringConvertible {
    var description: String {
        if !self.bleIsOn {
            return "Please turn on BLE"
        }else{
            return "Peripheral is on: \(self.connected), advertising: \(self.advertising)"
        }
    }
    
    var advertising:Bool
    var connected:Bool
    var bleIsOn:Bool
    var name:String
    
    static func defaultState() -> PeripheralState {
        return PeripheralState(advertising: false, connected: false, bleIsOn: false, name: "")
    }
}
