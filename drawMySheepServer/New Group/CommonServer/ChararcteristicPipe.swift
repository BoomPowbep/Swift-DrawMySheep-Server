//
//  ChararcteristicPipe.swift
//  AppleBLEServer
//
//  Created by AL on 04/12/2019.
//  Copyright © 2019 AL. All rights reserved.
//

import Foundation

class ChararcteristicPipe {
    
    static let instance = ChararcteristicPipe()
    
    enum EventType:String {
        case read,write,readNotify,writeNotify
    }
    
    struct BLEEvent:CustomDebugStringConvertible {
        var debugDescription: String {
            switch type {
            case .read,.readNotify:
                return "\(type.rawValue.uppercased()) on \(char.name)"
            case .write,.writeNotify:
                let str = String(data: (message ?? Data(capacity: 0)), encoding: .utf8)
                return "\(type.rawValue.uppercased()) \(str ?? "") on \(char.name)"
            }
        }
        
        var type:EventType
        var char:StandardCharacteristic
        var message:Data?
    }
    
    typealias EventCallBack = (BLEEvent)->()
    private var localCallBack:EventCallBack?
    
    func listenForEvents(callBack:@escaping EventCallBack) {
        localCallBack = callBack
    }
    
    func emitEvent(_ event:BLEEvent) {
        if let callBack = localCallBack {
            callBack(event)
        }else{
            print("Use 'listenForEvents' on ChararcteristicPipe")
        }
    }
}
