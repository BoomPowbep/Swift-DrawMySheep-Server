//
//  DataChunker.swift
//  PeerToPeerBLE
//
//  Created by Mickaël Debalme on 09/03/2020.
//  Copyright © 2020 AL. All rights reserved.
//

import Foundation
import UIKit

class DataChunker {
    static let instance = DataChunker()
    
    var currentSetup: ChunkSetup? = nil
    var currentBytesArray:[UInt8]? = nil
    
    
    enum ReceiveStatus { case received, error }
    
    struct ChunkSetup {
        
        enum HeaderValue:UInt8, CaseIterable {
            case headerImage = 255
            case headerString = 222
            
            func getBytesArray() -> [UInt8] {
                switch self {
                case .headerImage: return [HeaderValue.headerImage.rawValue,
                                           HeaderValue.headerImage.rawValue,
                                           HeaderValue.headerImage.rawValue]
                case .headerString: return [HeaderValue.headerString.rawValue,
                                            HeaderValue.headerString.rawValue,
                                            HeaderValue.headerString.rawValue]
                }
            }
        }
        
        var headerValue:HeaderValue
        var chunkSize:Int
        var nbBytes:Int
        var startBytes:UInt8
        var endBytes:UInt8
        
        static func customSetup(value:HeaderValue) -> ChunkSetup {
            return ChunkSetup(headerValue: value,
                              chunkSize: 512,
                              nbBytes: 3,
                              startBytes: value.rawValue,
                              endBytes: value.rawValue)
        }
        
        static func imageSetup() -> ChunkSetup {
            return customSetup(value: .headerImage)
        }
        
        static func stringSetup() -> ChunkSetup {
            return customSetup(value: .headerString)
        }
        
        static func buildSetupForBytes(_ headerBytesArray:[UInt8]) -> ChunkSetup? {
            
            for value in HeaderValue.allCases {
                if headerBytesArray == value.getBytesArray() {
                    return ChunkSetup.customSetup(value: value)
                }
            }
            
//            let filteredArray = headerBytesArray.filter { $0 == HeaderValue.headerString.rawValue }
            
            return nil
        }
    }
    
    
    
    func removeBounds(bytesArray:inout [UInt8]) {
        
        if let setup = self.currentSetup {
            for _ in 0..<setup.nbBytes {
                bytesArray.removeFirst()
                bytesArray.removeLast()
            }
        }
    }
    
    
    func clearCurrentTransfer()  {
        self.currentSetup = nil
        self.currentBytesArray = nil
    }
    
    
    func checkEndBoundsOn(bytesArray:[UInt8]) -> Bool {
        if let setup = self.currentSetup {
            let sizeArray = bytesArray.count-1
            for i in 0..<setup.nbBytes {
                if bytesArray[sizeArray-i] != setup.endBytes {
                    return false
                }
            }
            return true
        }
        return false
    }
    
    
    
    func buildDatableObjectFrom(bytesArray:[UInt8]) -> Datable? {
        if let setup = currentSetup {
            switch setup.headerValue {
            case .headerImage:
                return UIImage(data: Data(bytesArray))
            default:
                return nil
            }
        }
        return nil
    }
    
    
    
    func newDataIncoming(data:Data) -> Datable? {
        
        if let _ = currentSetup {
          
            let byteArray = self.convertToByteArrax(data: data)
            self.currentBytesArray?.append(contentsOf: byteArray)
            
            if checkEndBoundsOn(bytesArray: byteArray) {
                // Fini
                if var finalBytes = self.currentBytesArray {
                    removeBounds(bytesArray: &finalBytes)
                    return buildDatableObjectFrom(bytesArray: finalBytes)
                }
            }
            
        } else {
            // Check first byte then set current setup
            let byteArray = self.convertToByteArrax(data: data)
            let header = Array(byteArray[0..<3])
            if let setup = ChunkSetup.buildSetupForBytes(header) {
                self.currentSetup = setup
                self.currentBytesArray = byteArray
                if checkEndBoundsOn(bytesArray: byteArray) {
                   // Fini
                   if var finalBytes = self.currentBytesArray {
                       removeBounds(bytesArray: &finalBytes)
                       return buildDatableObjectFrom(bytesArray: finalBytes)
                   }
               }
            }
        }
    
        return nil
    }
    
    
    
    func receiveData(data:Data, callback:@escaping (ReceiveStatus, Any)->()) {
        
        var isReceivingImage = false
        var tmpByteArray = [UInt8]()
        
        let bytes = [UInt8](data)
        
        // If first bytes correspond to image, start receiving image
        if checkFirstBytes(bytes) {
            print("🤓 RECEIVING IMAGE")
            isReceivingImage = true
            tmpByteArray.append(contentsOf: bytes)
        }
        
        // Executed while receiving and image
        else if isReceivingImage {
            tmpByteArray.append(contentsOf: bytes)
            
            // Testing if we are at the end of the image transmission
            if checkLastBytes(bytes) {
                print("😎 IMAGE RECEIVED")
                isReceivingImage = false
                for _ in 0..<3 {
                    tmpByteArray.removeFirst()
                    tmpByteArray.removeLast()
                }
                let imageData = Data(tmpByteArray)
                if let image = UIImage(data:imageData) {
                    print(image.size)
                    callback(.received, image)
                }
                else {
                    print("🤨 Unable to build image")
                    callback(.error, UIImage())
                }
            }
        }
        
            // If receiving text
        else {
            let str = (data.stringUTF8 ?? "error")
            print("😀 RECEIVED: " + str)
            callback(.received, str)
        }
    }
    
    
    
    func checkFirstBytes(_ bytes:[UInt8]) -> Bool {
        return bytes[0] == 255 && bytes[1] == 255 && bytes[2] == 255
    }
    
    
    
    func checkLastBytes(_ bytes:[UInt8]) -> Bool {
        return bytes[bytes.count-1] == 0 && bytes[bytes.count-2] == 0 && bytes[bytes.count-3] == 0
    }
    
    
    
    func prepareForSending<T:Datable>(obj:T, setup:ChunkSetup = ChunkSetup.imageSetup()) -> [[UInt8]]? {
        
        guard let data = convertToData(obj: obj) else {
            return nil
        }
        
//        do {
//            let compressedData = try (data as NSData).compressed(using: .lzfse)
//        }
//        catch {
//            print(error.localizedDescription)
//        }
        
        var setup:ChunkSetup
        switch obj {
            case is UIImage: setup = ChunkSetup.imageSetup()
            case is String: setup = ChunkSetup.stringSetup()
            default: return nil
        }
        
        var byteArray = convertToByteArrax(data: data)
        let boundedArray = addBounds(bytesArray: &byteArray, nBytes: setup.nbBytes, start: setup.startBytes, end: setup.endBytes)
        
        let chunkedBoundedArray = chunkByteArray(boundedArray, chunkSize: setup.chunkSize)
        
        return chunkedBoundedArray
    }
    
    
    func chunkByteArray(_ byteArray:[UInt8], chunkSize:Int) -> [[UInt8]] {
        return byteArray.chunked(into: chunkSize)
    }
    
    
    
    func convertToData<T:Datable>(obj:T) -> Data? {
        return obj.toData()
    }
    
    
    
    func convertToByteArrax(data:Data) -> [UInt8] {
        return [UInt8](data)
    }
    
    
    
    func addBounds(bytesArray:inout [UInt8], nBytes:Int, start:UInt8, end:UInt8) -> [UInt8] {
        
        for _ in 0..<nBytes {
            bytesArray.insert(start, at: 0)
            bytesArray.append(end)
        }
        
        return bytesArray
    }
}



protocol Datable {
    func toData() -> Data?
}

extension String:Datable {
    func toData() -> Data? {
        return self.data(using: .utf8)
    }
}

extension UIImage:Datable {
    func toData() -> Data? {
        return self.pngData()
    }
}
