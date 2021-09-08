//
//  StationJson.swift
//  ArabRadio
//
//  Created by Lefdili Alaoui Ayoub on 25/4/2021.
//

import Foundation

struct StationJson: Codable {

    var Country: String
    var Category: String
    var image: String
    var Status: Bool
    var Stations: [StationList]
    
    struct StationList: Codable {
        var status: Bool
        var ID: UUID
        var type: [String]
        var title: String
        var signal: String
        var country: String
        var image: String
        var sDescription: String
        var stream: [String]

    }
    
}
    
