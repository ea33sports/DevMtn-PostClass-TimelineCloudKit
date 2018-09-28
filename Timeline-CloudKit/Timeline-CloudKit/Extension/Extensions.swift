//
//  Extensions.swift
//  Timeline-CloudKit
//
//  Created by Eric Andersen on 9/27/18.
//  Copyright © 2018 Eric Andersen. All rights reserved.
//

import UIKit

extension UIViewController {
    func showAlertMessage(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
}
