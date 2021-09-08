//
//  AVPlayerSingleton.swift
//  ArabRadio
//
//  Created by Lefdili Alaoui Ayoub on 22/6/2021.
//

import UIKit
import AVKit
import MediaPlayer

class AVPlayerSingleton {
    
    static let shared = AVPlayerSingleton()
    
    //Check wifiOnly setting options
    var assetOptions: [String: Bool]? = [:]
    var playerTimeObserver: Any?
    var startupStation: Bool = false
    var station: Station? {
        didSet {
            
            guard let station = station else { return }
            let objectId = station.objectID
            if objectId.isTemporaryID == false {
                let objectURL = objectId.uriRepresentation()
                UserDefaults.standard.set(objectURL, forKey: "stationObjectUrl")
            }
        }
    }
    
    // Create a variable for playlist
    var playlistStations = [Station]()
    
    //CurrentStream
    var streamUrl: URL?
    
    // Timer
    var timePlayed: Double = 0
    
    //Audio Setup
    let volumeView: MPVolumeView = MPVolumeView(frame: .zero)
    let audioSession = AVAudioSession.sharedInstance()
    
    // Player
    var player: AVPlayer = {
        let player = AVPlayer()
        player.actionAtItemEnd = .pause
        return player
    }()
    
    var isRecording: Bool = false
    
    var allowedMimes = [
        (ext: "m3u8", mime: "application/x-mpegURL", allowed: true),
        (ext: "m3u", mime: "audio/x-mpegurl", allowed: false),
        (ext: "aac", mime: "audio/aacp", allowed: true),
        (ext: "mp3", mime: "audio/mpeg", allowed: true),
        (ext: "mp4", mime: "audio/mp4", allowed: true),
        (ext: "ogg", mime: "audio/ogg", allowed: true),
    ]
    
    func getHeaderInformations (myUrl: URL, completionHandler: @escaping (_ allowedRecording: Bool, _ error: Error?) -> Void) -> Void {
        
        var allowedRecoding: Bool = false
        
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = TimeInterval(2)
        config.timeoutIntervalForResource = TimeInterval(2)
        
        let urlSession = URLSession(configuration: config)
        var request = URLRequest(url: myUrl)
        request.httpMethod = "GET"
        
        urlSession.dataTask(with: request) { _data, response, error in

            if let reponse = response as? HTTPURLResponse {
                let contentType = reponse.allHeaderFields["Content-Type"]
                let content = String(describing: contentType ?? "").lowercased()
                
                if self.allowedMimes.contains(where: { $0.mime == content && $0.allowed == true }) {
                    allowedRecoding = true
                }else{
                    allowedRecoding = false
                }
                
                completionHandler(allowedRecoding, error)
            }
        }.resume()
    }
    
    // Get the shared MPRemoteCommandCenter
    func initStation(stream: String, completion: @escaping (_ status: Bool, _ remainTime: String, _ timerIsValid: Bool )->() ){
        
        self.timePlayed = 0
        
        if let token = playerTimeObserver {
            self.player.removeTimeObserver(token)
            self.playerTimeObserver = nil
        }
        
        self.player.replaceCurrentItem(with: nil)
        
        guard let streamUrl = URL(string: stream) else { return }
        
        if UserDefaults.standard.bool(forKey: "wifiOnly") == true {
            assetOptions?[AVURLAssetAllowsCellularAccessKey] = false
        }else{
            assetOptions?[AVURLAssetAllowsCellularAccessKey] = true
        }
        
        let asset = AVURLAsset(url: streamUrl, options: assetOptions)
        let playerItem = AVPlayerItem(asset: asset)
        
        self.player.replaceCurrentItem(with: playerItem)
        self.player.volume = 1.0
        self.player.play()
        
        // Add started playing observer
        let interval = CMTime.init(value: 1, timescale: 2)
        playerTimeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            
            guard let self = self else { return }
            
            self.timePlayed = CMTimeGetSeconds(time)
            
            let playerStatus = AVPlayerSingleton.shared.player.timeControlStatus == .playing
            
            if self.sleepTimeRemaining > 0.0 {
                self.sleepTimeRemaining -= 1/2
            }
            
            let remainTime = self.sleepTimeRemaining.asString(style: .abbreviated)
            let timerIsValid = self.sleepTimer?.isValid ?? false
            
            if (playerStatus == true) {
                completion(playerStatus, remainTime, timerIsValid)
            }
        }
        return
    }
    
    
    func stopPlayer(completion: @escaping (_ status: Bool)->() ) {
        
        self.player.pause()
        self.player.replaceCurrentItem(with: nil)
        
        self.timePlayed = 0
        if let token = playerTimeObserver {
            self.player.removeTimeObserver(token)
            self.playerTimeObserver = nil
        }
        
        return completion(player.timeControlStatus == .playing)
    }
    
    //clearLock Screen
    func clearPlayer(completion: @escaping ()->()){
        self.stopPlayer { _ in
            
            //To prevent Double trigger on Previous/Next tracks Command /!\
            MPRemoteCommandCenter.shared().nextTrackCommand.removeTarget(nil)
            MPRemoteCommandCenter.shared().previousTrackCommand.removeTarget(nil)
            
            let _MPNowPlayingInfoCenter =  [String:Any]()
            MPNowPlayingInfoCenter.default().nowPlayingInfo = _MPNowPlayingInfoCenter
            return completion()
        }
    }
    
    
    func setupNowPlayingInfo(title: String, artist: String, image: UIImage? = UIImage(named: "Record")){
        var nowPlayingInfo = [String:Any]()
        nowPlayingInfo[MPMediaItemPropertyTitle] = title
        nowPlayingInfo[MPMediaItemPropertyArtist] = artist
        
        guard let _image = image else {return}
        
        let artWork = MPMediaItemArtwork(boundsSize: _image.size) { _ in
            return _image
        }
        
        nowPlayingInfo[MPMediaItemPropertyArtwork] = artWork
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
    
    func toggleStatusMPRemoteCenter(status: Bool = true){
        MPRemoteCommandCenter.shared().playCommand.isEnabled = status
        MPRemoteCommandCenter.shared().pauseCommand.isEnabled = status
        MPRemoteCommandCenter.shared().togglePlayPauseCommand.isEnabled = status
        MPRemoteCommandCenter.shared().nextTrackCommand.isEnabled = status
        MPRemoteCommandCenter.shared().previousTrackCommand.isEnabled = status
    }
    
    //Sleep Mode
    var sleepTimer: Timer? = nil
    var sleepTimeInterval: Double = 0.0
    var sleepTimeRemaining: Double = 0.0
    
    func setSleepMode(timerChoise: Int, completion: @escaping ()->()){
        
        self.sleepTimeInterval = Double( (timerChoise * 60) )
        self.sleepTimeRemaining = self.sleepTimeInterval
        
        sleepTimer?.invalidate()
        sleepTimer = Timer.scheduledTimer(withTimeInterval: self.sleepTimeInterval, repeats: false, block: { _ in
            
            self.sleepTimeInterval = 0.0
            self.sleepTimeRemaining = 0.0
            
            self.stopPlayer { _ in
                return completion()
            }
        })
    }
}
