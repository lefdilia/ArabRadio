//
//  String+Ext.swift
//  ArabRadio
//
//  Created by Lefdili Alaoui Ayoub on 10/5/2021.
//

import Foundation

extension String {
    
    func capitalizingFirstLetter() -> String {
        return prefix(1).capitalized + dropFirst()
    }

    mutating func capitalizeFirstLetter() {
        self = self.capitalizingFirstLetter()
    }
    
    func secureLink() -> String{
        return self.replacingOccurrences(of: "http://", with: "https://")
    }
    

}


