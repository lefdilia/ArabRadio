//
//  AppConfig.swift
//  ArabRadio
//
//  Created by Lefdili Alaoui Ayoub on 8/7/2021.
//

import Foundation


class recordingConfiguration {
    let defaultName = "default.mp3"
    let folder = "Arab-Radio"
}

class appConfiguration {
    let gcmMessageIDKey = "arabRadioApp"
}

class userDefaultKeys {
    let _wifiOnlyKey = "wifiOnly"
}

struct AppConfig {
    
    static let recording = recordingConfiguration()
    static let initial = appConfiguration()
    
}

