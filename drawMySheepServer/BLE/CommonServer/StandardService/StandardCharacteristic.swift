//
//  StandardCharacteristic.swift
//  BLEPeripheralSimulatorCLI
//
//  Created by AL on 05/06/2019.
//  Copyright © 2019 AL. All rights reserved.
//

import Foundation
import CoreBluetooth

public class StandardCharacteristic: CharacteristicController {
    public var characteristic: CBMutableCharacteristic
    public var peripheral: CBPeripheralManager?
    
    var name:String
    var scenario:Scenario?
    var scenarioDidFinish:((Bool,Scenario)->())?
    
    required public init(characteristic:CBMutableCharacteristic, name:String) {
        self.name = name
        self.characteristic = characteristic
    }
    
    public func handleReadRequest(_ request: CBATTRequest, peripheral: CBPeripheralManager) {
        print("Did receive read request on \(self.characteristic.uuid)")
        
        ChararcteristicPipe.instance.emitEvent(ChararcteristicPipe.BLEEvent(type: .read, char: self, message: nil))
        
        if let s = scenario {
            if let currentAction = s.bleActions.top,
                currentAction is CentralReadAction {
                if let actionSuccess = currentAction.performActionFor(request: request,peripheral: peripheral),
                    actionSuccess == true {
                    popScenario()
                }
            }else if let currentAction = s.bleActions.top,
                currentAction is AckAction {
                _ = currentAction.performActionFor(request: request,peripheral: peripheral)
                popScenario()
            }else{
                scenarioDidFinish?(false,s)
            }
        }else{
            peripheral.respond(to: request, withResult: .readNotPermitted)
        }
        
    }
    
    public func handleWriteRequest(_ request: CBATTRequest, peripheral: CBPeripheralManager) {
        print("Did receive write request on \(self.characteristic.uuid)\n with value \(request.value ?? Data(repeating: 0, count: 0))")
        
        ChararcteristicPipe.instance.emitEvent(ChararcteristicPipe.BLEEvent(type: .write, char: self, message: request.value))
        
        if let s = scenario {
            if let currentAction = s.bleActions.top,
                currentAction is CentralWriteAction {
                if let actionSuccess = currentAction.performActionFor(request: request,peripheral: peripheral),
                    actionSuccess == true {
                    popScenario()
                }
            }else{
                scenarioDidFinish?(false,s)
            }
        }else{
            peripheral.respond(to: request, withResult: .writeNotPermitted)
        }
        
    }
    
    public func handleSubscribeToCharacteristic(on peripheral: CBPeripheralManager) {
        self.peripheral = peripheral
    }

    public func updateCharacteristicWithData(data:Data) {
        peripheral?.updateValue(data, for: characteristic, onSubscribedCentrals: nil)
    }
    
    func setupScenario(_ scenario:Scenario?) {
        self.scenario = scenario
        updateCharValueIfNeeded()
    }
    
    func popScenario() {
        _ = scenario?.bleActions.pop()
        updateCharValueIfNeeded()
    }
    
    func updateCharValueIfNeeded() {
        if let currentAction = self.scenario?.bleActions.top,
            currentAction is UpdateCharValueAction {
            _ = currentAction.performActionFor(request: nil,peripheral: self.peripheral)
            _ = scenario?.bleActions.pop()
        }
        if let s = self.scenario,
            s.bleActions.isEmpty {
            ScenarioManager.instance.setupCharsWithScenarioFilePaths(s.nextScenarios)
            scenarioDidFinish?(true,s)
        }
    }

}
