//
//  UIVIewControllerExtension.swift
//  PeerToPeerBLE
//
//  Created by Mickaël Debalme on 28/02/2020.
//  Copyright © 2020 AL. All rights reserved.
//

import UIKit

extension UIViewController {
    func displayAlertWithText(_ text:String) {
        let a = UIAlertController(title: "Message recu", message: text, preferredStyle: .alert)
        a.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
        self.present(a, animated: true, completion: nil)
    }
}
