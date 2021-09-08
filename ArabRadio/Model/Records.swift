//
//  Records.swift
//  ArabRadio
//
//  Created by Lefdili Alaoui Ayoub on 8/7/2021.
//

import Foundation

struct Records {
    var name: String
    var size: String
    var creationDate: Date
    var path: URL
    
    init(name: String, size: String, creationDate: Date, path: URL) {
        self.name = name
        self.size = size
        self.creationDate = creationDate
        self.path = path
    }
}
