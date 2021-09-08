//
//  URL+Ext.swift
//  ArabRadio
//
//  Created by Lefdili Alaoui Ayoub on 8/7/2021.
//

import Foundation


extension URL {
    var attributes: [FileAttributeKey : Any]? {
        return try? FileManager.default.attributesOfItem(atPath: path)
    }
    
    var fileSize: UInt64 {
        return attributes?[.size] as? UInt64 ?? UInt64(0)
    }
    
    var fileSizeString: String {
        return ByteCountFormatter.string(fromByteCount: Int64(fileSize), countStyle: .file)
    }
    
    var creationDate: Date? {
        return attributes?[.creationDate] as? Date //as! Date
    }
    
}
