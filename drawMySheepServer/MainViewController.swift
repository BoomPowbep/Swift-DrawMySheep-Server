//
//  ViewController.swift
//  drawMySheepServer
//
//  Created by Mickaël Debalme on 10/03/2020.
//  Copyright © 2020 Mickael Debalme. All rights reserved.
//

import UIKit
import CoreBluetooth

class MainViewController: UIViewController {
    
    @IBOutlet weak var startServerButton: UIBarButtonItem!
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    enum Geometry:String {
        case circle = "CIRCLE", square = "SQUARE", triangle = "TRIANGLE"
    }
    
    struct Shape {
        let geometry: Geometry
        let image: UIImage
        var count: Int
    }
    
    var geometries: [Shape] = [
        Shape(geometry: .circle, image: UIImage(named: "circle")!, count: 0),
        Shape(geometry: .square, image: UIImage(named: "square")!, count: 0),
        Shape(geometry: .triangle, image: UIImage(named: "triangle")!, count: 0)
    ]
    
    var lastCellClickedIndex:Int = -1
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        collectionView.delegate = self
        collectionView.dataSource = self
    }
    
    @IBAction func onStartServerButtonClicked(_ sender: Any) {
        let serverName = "ouiouioui"
        BLEServer.instance.startServerWithName(name: serverName) { (state) in
            self.startServerButton.isEnabled = false
            self.startServerButton.title = "Server started ✅"
            print("✅ Server started as " + serverName)
            
            BLEServer.instance.sendMessage(data: "HELLO".data(using: .utf8)!)
        }
    }
    
    func sendInstruction() {
        
        if let chunks = DataChunker.instance.prepareForSending(obj: "test") {
            for c in chunks {
                let d = Data(c)
                BLEServer.instance.sendMessage(data: d)
                print("⬆️ Sending data chunk to client")
            }
        }
    }
    
    func startMessageListener() {
        BLEServer.instance.listenForMessages { (msgFromClient) in
            print("⬇️ Message from client")
            
            if let datable = DataChunker.instance.newDataIncoming(data: msgFromClient) {
               
               DataChunker.instance.clearCurrentTransfer()
               
               switch datable {
               case is String:
                   let str = datable as! String
                   self.checkReceivedData(str)
                   
               default: print("Unknown error")
                   
               }
           }
        }
    }
    
    func checkReceivedData(_ str:String) {
        print("❇️ RECEIVED: " + str)
        
        if geometries[lastCellClickedIndex].geometry.rawValue == str {
            geometries[lastCellClickedIndex].count += 1
            print("🥳 Correct")
        }
        else {
            geometries[lastCellClickedIndex].count -= 1
            print("😡 Incorrect")
        }
        
        collectionView.reloadData()
    }
}



extension MainViewController:UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return geometries.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "oneCell", for: indexPath)
        
        let image = geometries[indexPath.row].image
        let count = geometries[indexPath.row].count
        
        // TODO set image & count
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print("Click on " + String(indexPath.row))
        
        lastCellClickedIndex = indexPath.row
        
        sendInstruction()
    }
}


extension MainViewController:UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let side = UIScreen.main.bounds.width / 2
        return CGSize(width: side, height: side)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets.zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 10.0
    }
}
