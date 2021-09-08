//
//  UILabel.swift
//  ArabRadio
//
//  Created by Lefdili Alaoui Ayoub on 5/7/2021.
//

import UIKit

extension UIButton {
    @IBInspectable var localizedText: String {
        get { return titleLabel!.text! }
        set (key) { setTitle(key.localized(), for: .normal) }
    }
}

extension String {
    func localized () -> String {
        return NSLocalizedString(
            self,
            tableName: "Localizable",
            bundle: .main,
            value: self,
            comment: self)
    }
}

