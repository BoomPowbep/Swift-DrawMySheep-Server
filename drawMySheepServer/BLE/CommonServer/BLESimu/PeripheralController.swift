import CoreBluetooth

public class PeripheralController: NSObject, CBPeripheralManagerDelegate {
    
    var notifyingChars = [CBCharacteristic]()
    var peripheralState = PeripheralState.defaultState()
    var stateCallBack:((PeripheralState)->())?
    
    enum Error: Swift.Error {
        case peripheralAlredyOn
        case peripheralAlreadyOff
    }
    
    private(set) var peripheral: CBPeripheralManager!
    var peripheralName: String {
        didSet{
            peripheralState.name = self.peripheralName
            self.stateCallBack?(peripheralState)
        }
    }
    var serviceControllers: [ServiceController] = []
    
    public init(peripheralName: String) {
        self.peripheralName = peripheralName
        super.init()
    }
    
    public init(config: PeripheralGatt) {
        self.peripheralName = config.name
        super.init()
        config.services.forEach{ registerServiceController($0) }
    }
    
    func listenForState(callBack:@escaping (PeripheralState)->()){
        self.stateCallBack = callBack
    }
    
    public func registerServiceController(_ serviceController: ServiceController) {
        serviceControllers.append(serviceController)
    }
    
    public func turnOn() throws {
        if peripheral != nil { throw Error.peripheralAlredyOn }
        peripheral = CBPeripheralManager(delegate: self, queue: .main)
    }
    
    public func turnOff() throws {
        if peripheral == nil || peripheral.state != .poweredOn { throw Error.peripheralAlreadyOff }
        serviceControllers = []
        peripheral.stopAdvertising()
        peripheralState.advertising = false
        peripheralState.connected = false
        self.stateCallBack?(peripheralState)
        peripheral = nil
    }
    
    private func startAdvertising() {
        print("Starting advertising")
        
        serviceControllers
            .map { $0.service }
            .forEach { peripheral.add($0) }
        
        let advertisementData: [String: Any] = [CBAdvertisementDataLocalNameKey: peripheralName,
                                                CBAdvertisementDataServiceUUIDsKey: serviceControllers.map({ $0.service.uuid })]
        peripheral.startAdvertising(advertisementData)
        peripheralState.advertising = true
        peripheralState.connected = true
        self.stateCallBack?(peripheralState)
    }
    
    // MARK: - CBPeripheralManagerDelegate
    
    public func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        switch peripheral.state {
        case .poweredOn:
            print("Peirpheral is on")
            peripheralState.bleIsOn = true
            peripheralState.connected = true
            startAdvertising()
        case .poweredOff:
            print("Peripheral \(peripheral.description) is off")
            peripheralState.bleIsOn = false
            peripheralState.connected = false
            serviceControllers = []
            self.peripheral.removeAllServices()
        case .resetting:
            print("Peripheral \(peripheral.description) is resetting")
            peripheralState.bleIsOn = false
            peripheralState.connected = false
        case .unauthorized:
            print("Peripheral \(peripheral.description) is unauthorized")
            peripheralState.bleIsOn = false
            peripheralState.connected = false
        case .unsupported:
            print("Peripheral \(peripheral.description) is unsupported")
            peripheralState.bleIsOn = false
            peripheralState.connected = false
        case .unknown:
            print("Peripheral \(peripheral.description) state unknown")
            peripheralState.bleIsOn = false
            peripheralState.connected = false
        @unknown default:
            fatalError()
        }
        self.stateCallBack?(peripheralState)
    }
    
    public func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        let serviceUUID = request.characteristic.service.uuid
        serviceControllers
            .first(where: { $0.service.uuid == serviceUUID })
            .map { $0.handleReadRequest(request, peripheral: peripheral) }
    }
    
    public func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        for request in requests {
            let serviceUUID = request.characteristic.service.uuid
            serviceControllers
                .first(where: { $0.service.uuid == serviceUUID })
                .map { $0.handleWriteRequest(request, peripheral: peripheral) }
        }
    }
    
    public func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        let serviceUUID = characteristic.service.uuid
        serviceControllers
            .first(where: { $0.service.uuid == serviceUUID })
            .map { $0.handleSubscribeToCharacteristic(characteristic: characteristic, on: peripheral) }
        
        // All char notifying...
        notifyingChars.append(characteristic)
        
    }
    
}

