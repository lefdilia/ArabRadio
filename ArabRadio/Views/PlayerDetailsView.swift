//
//  PlayerDetailsView.swift
//  ArabRadio
//
//  Created by Lefdili Alaoui Ayoub on 16/6/2021.
//

import UIKit
import AVKit
import MediaPlayer
import Network


class PlayerDetailsView: UIView, AVAudioRecorderDelegate {
    
    var obsVolume: NSKeyValueObservation?
    
    var typeValue:Int?
    var pickerData = [5, 10, 20, 30, 60, 90, 120]
    
    let player = AVPlayerSingleton.shared.player
    let AVSingelton = AVPlayerSingleton.shared
    
    var _player: AVPlayer!
    var _playerItem: CachingPlayerItem!
    var _stream: String?
    var recordingName: String?
    var stationName: String?

    var panGesture: UIPanGestureRecognizer!
    let activityIndicator = UIActivityIndicatorView()
 
    
    var station: Station? {
        didSet {
            
            guard let station = station else {return}
            
            radioTitleLabel.text = station.title

            let _signal = station.signal ?? "Stream".localized()
            radioSignalLabel.text = _signal
            
            let _type = (station.type ?? []).map{ $0.capitalizingFirstLetter() }.joined(separator: " - ")
            radioGenresLabel.text = _type
            
            //Mini Player
            miniStationTitle.text = station.title
            
            let attributedText = NSMutableAttributedString(attributedString: NSAttributedString(string: "Signal".localized()+": ", attributes: [.font : UIFont(name: Theme.displayFontName, size: 12) as Any]))
            attributedText.append(NSAttributedString(string: station.signal ?? "Stream".localized(), attributes: [.font : UIFont(name: Theme.readFontName, size: 12) as Any]))
            
            miniStationSignal.attributedText = attributedText
                        
            //To Prevent taking AudioSession from Other apps just by starting this app
            setupAudioSession(type: .playback)
            
            //Start Playing
            playStation()
            
            //save station on Singleton Class
            AVPlayerSingleton.shared.station = station

            //setup Remote Url
//            guard let _image = URL(string: station.image ?? "") else {return}
            // exit from everything and cost the player deatail view to put wrong data
             let _image = URL(string: station.image ?? "") //Fix & hack

            radioImageView.sd_setImage(with: _image)  { (image, error, cache, urls) in
                if (error != nil) {
                    // Failed to load image
                    self.miniStationImageView.image = UIImage(named: "RadioImage")
                } else {
                    // Successful in loading image
                    self.miniStationImageView.image = image
                    //Lock screen Info
                    self.setupNowPlayingInfo(image: image)
                }
            }
            
            //Stop recording when switching stations
            if AVPlayerSingleton.shared.isRecording == true {
                finishRecording(success: true)
            }
            
            //Check playlist we can't record
            guard let _urlString = station.stream?.first else {return}
    
            //init and disable Recording until Check if allowed
            self.recordButton.isEnabled = false
            self.recordButton.setImage(UIImage(named: "Record_opac"), for: .normal)
            
            if let streamUrl = URL(string: _urlString){
                
                AVPlayerSingleton.shared.getHeaderInformations(myUrl: streamUrl) { allowedRecoding, _error in

                    DispatchQueue.main.async {
                        if allowedRecoding == true {
                            self.recordButton.isEnabled = true
                            self.recordButton.setImage(UIImage(named: "Record"), for: .normal)
                        }else{
                            self.recordButton.isEnabled = false
                            self.recordButton.setImage(UIImage(named: "Record_opac"), for: .normal)
                        }
                    }
                }
            }
        }
    }
    

    @IBOutlet weak var recordButton: UIButton! {
        didSet{
            recordButton.addTarget(self, action: #selector(handleRecord), for: .touchUpInside)
            recordButton.isHidden = false
        }
    }
    
    @objc func handleRecord(){
        
        if player.timeControlStatus == .playing {
        
           if AVPlayerSingleton.shared.isRecording == false {
                self.startRecording()
            } else {
                self.finishRecording(success: true)
            }
            
        }else{
            //Init
            recordButton.setImage(UIImage(named: "Record"), for: .normal)
            AVPlayerSingleton.shared.isRecording = false
        }
    }

    private func generateRecordName(station: String?) -> String {

        var station = station ?? "Default"
        let _timeInterval = Int(Date().timeIntervalSince1970)
        
        station = station.trimmingCharacters(in: .whitespacesAndNewlines)
                    .replacingOccurrences(of: " ", with: "-")
                    .replacingOccurrences(of: #"-+"#, with: "-", options: .regularExpression, range: nil)

        return "\(station.capitalizingFirstLetter())|\(_timeInterval).mp3"
    }
    
    func startRecording(){
        
        recordingName = "\(Int(Date().timeIntervalSince1970)).mp3"
        stationName = station?.title
                
        guard let streamList = self.station?.stream else {return}
        guard let url = URL(string: streamList.first ?? "") else { return }
        
        recordButton.setImage(UIImage(named: "stopRecording"), for: .normal)
        AVPlayerSingleton.shared.isRecording = true
        
        _playerItem = CachingPlayerItem(url: url, recordingName: recordingName ?? AppConfig.recording.defaultName)
        _player = AVPlayer(playerItem: _playerItem)
        _player.automaticallyWaitsToMinimizeStalling = false
    }
    
    func finishRecording(success: Bool) {
        AVPlayerSingleton.shared.isRecording = false
        
        if success == true {
            recordButton.setImage(UIImage(named: "Record"), for: .normal)
            self.saveRecordingWithUserProvidedName(name: recordingName)
        }else{
            recordButton.setImage(UIImage(named: "Record_opac"), for: .normal)
        }
    }
    
    func saveRecordingWithUserProvidedName(name: String?){
        _playerItem?.stopDownloading()
        
        guard let currentName = recordingName else {return}
        guard let stationName = stationName else {return}
        
        do {
            
            let recordingFolder = AppConfig.recording.folder
            let manager = FileManager.default
            
            guard let documentDirectory = manager.urls(for: .documentDirectory, in: .userDomainMask).first else {
                return
            }
                                    
            let savingFolder = documentDirectory.appendingPathComponent(recordingFolder)
            try manager.createDirectory(at: savingFolder, withIntermediateDirectories: true, attributes: [:])
            let originPath = documentDirectory.appendingPathComponent(currentName)
            
            let _name = generateRecordName(station: stationName)
            let destinationPath = savingFolder.appendingPathComponent(_name)
            
            try FileManager.default.moveItem(at: originPath, to: destinationPath)

        } catch {
            recordButton.setImage(UIImage(named: "Record"), for: .normal)
            AVPlayerSingleton.shared.isRecording = false
        }
    }
    
        
    fileprivate func setupAudioSession(type: AVAudioSession.Category){
            try? AVAudioSession.sharedInstance().setCategory(type, mode: .default, options: .defaultToSpeaker)
            try? AVAudioSession.sharedInstance().setActive(true)
    }
    
    fileprivate func setupRemoteControl(){
        
        MPRemoteCommandCenter.shared().playCommand.isEnabled = true
        MPRemoteCommandCenter.shared().playCommand.addTarget { _ in
            
            self.player.play()
            self.playPauseButton.setImage(UIImage(named: "AVPause"), for: .normal)
            self.miniPlayPauseButton.setImage(UIImage(named: "AVPause"), for: .normal)
            return .success
        }
        
        MPRemoteCommandCenter.shared().pauseCommand.isEnabled = true
        MPRemoteCommandCenter.shared().pauseCommand.addTarget { _ in
            
            self.player.pause()
            self.playPauseButton.setImage(UIImage(named: "AVPlay"), for: .normal)
            self.miniPlayPauseButton.setImage(UIImage(named: "AVPlay"), for: .normal)
            self.finishRecording(success: true)
            return .success
        }
        
        
        MPRemoteCommandCenter.shared().togglePlayPauseCommand.isEnabled = true
        MPRemoteCommandCenter.shared().togglePlayPauseCommand.addTarget { _ in
            
            self.handlePlayPause()
            return .success
        }
        
        MPRemoteCommandCenter.shared().nextTrackCommand.isEnabled = true
        MPRemoteCommandCenter.shared().nextTrackCommand.addTarget(self, action: #selector(handleNextTrack))
    
        MPRemoteCommandCenter.shared().previousTrackCommand.isEnabled = true
        MPRemoteCommandCenter.shared().previousTrackCommand.addTarget(self, action: #selector(handlePreviousTrack))
    }
    

    @objc func handlePreviousTrack() -> MPRemoteCommandHandlerStatus {
                
        if AVPlayerSingleton.shared.playlistStations.count == 0 {  return .noSuchContent }
                
        let index = AVPlayerSingleton.shared.playlistStations.firstIndex { stationObj in
            return
                stationObj.title == self.station?.title &&
                stationObj.country == self.station?.country
        }
        
        guard let currentIndex = index else { return .noSuchContent }
        
        var previousStation: Station?
        
        if currentIndex == 0 {
            let nextIndex = AVPlayerSingleton.shared.playlistStations.count - 1
            previousStation = AVPlayerSingleton.shared.playlistStations[nextIndex]
        }else{
            previousStation = AVPlayerSingleton.shared.playlistStations[currentIndex - 1]
        }
        
        self.station = previousStation
        return .success
    }
    
    
    @objc func handleNextTrack() -> MPRemoteCommandHandlerStatus {
                
        if AVPlayerSingleton.shared.playlistStations.count == 0 {  return .noSuchContent }
        
        let currentIndex = AVPlayerSingleton.shared.playlistStations.firstIndex { stationObj in
            return
                stationObj.title == self.station?.title &&
                stationObj.country == self.station?.country
        }
        
        guard let index = currentIndex else { return .noSuchContent }
        
        var nextStation: Station?
        if index == AVPlayerSingleton.shared.playlistStations.count - 1 {
            nextStation = AVPlayerSingleton.shared.playlistStations[0]
        }else{
            nextStation = AVPlayerSingleton.shared.playlistStations[index + 1]
        }
        
        self.station = nextStation
        return .success
    }
    
    
    fileprivate func setupInterruptionObserver(){
        NotificationCenter.default.addObserver(self, selector: #selector(handleInterruption),
                                               name: AVAudioSession.interruptionNotification,
                                               object: nil)
    }
    
    
    @objc fileprivate func handleInterruption(notification: Notification){
        
        guard let userInfo = notification.userInfo else { return }
        
        guard let type = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt else { return }
        
        if type == AVAudioSession.InterruptionType.began.rawValue {
            
            playPauseButton.setImage(UIImage(named: "AVPlay"), for: .normal)
            miniPlayPauseButton.setImage(UIImage(named: "AVPlay"), for: .normal)
            
        }else{
            
            guard let options = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt else { return }
            
            if options == AVAudioSession.InterruptionOptions.shouldResume.rawValue {
                self.player.play()
                playPauseButton.setImage(UIImage(named: "AVPause"), for: .normal)
                miniPlayPauseButton.setImage(UIImage(named: "AVPause"), for: .normal)
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        
        guard let tempImage = UIImage(systemName: "xmark") else { return }
        let lightTempImage = tempImage.withTintColor(UIColor.darkBlueLighted ?? .gray, renderingMode: .alwaysTemplate)
        let _image = NSTextAttachment(image: lightTempImage)
        _image.bounds = CGRect(x: 0, y: -3, width: 17, height: 17)
        let attributedText =  NSMutableAttributedString(attachment: _image)
        let extString = NSAttributedString(string: " \(dismissButtonTop.localizedText) ", attributes: [.font : UIFont(name: Theme.displayFontName, size: 18) as Any,
             .foregroundColor : UIColor.darkBlueLighted as Any
        ])
        
        attributedText.append(extString)
        
        dismissButtonTop.setAttributedTitle(attributedText, for: .normal)
        
        
        activityIndicator.style = .medium
        activityIndicator.center = center
        activityIndicator.color = UIColor.darkBlue
        activityIndicator.hidesWhenStopped = true
        
        setupRemoteControl()
        setupGestures()
        
        setupInterruptionObserver()
        
        let CTime = CMTimeMake(value: 1, timescale: 3)
        
        player.addBoundaryTimeObserver(forTimes: [NSValue(time: CTime)], queue: .main) {
            self.playPauseButton.setImage(UIImage(named: "AVPause"), for: .normal)
            self.miniPlayPauseButton.setImage(UIImage(named: "AVPause"), for: .normal)
            self.activityIndicator.stopAnimating()
        }
        
        //Observe Change On System Volume
        self.obsVolume = AVSingelton.audioSession.observe( \.outputVolume ) { (av, change) in
            self.SoundControl.setValue(av.outputVolume, animated: true)
        }
    }
    
    fileprivate func setupGestures() {
        
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTapMaximize)))
        
        maximizedStackView.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(handleDismissalPan)))
        
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
        miniPlayerView.addGestureRecognizer(panGesture) // add gesture to only the player
        
    }

    @objc func handleTapMaximize(){
        let navBarController = window?.rootViewController as? UINavigationController
        let radioListController = navBarController?.topViewController as? RadioListController
        radioListController?.maximizePlayerDetails(station: nil)
    }
    
    
    @objc func handleDismissalPan(gesture: UIPanGestureRecognizer){
        if gesture.state == .changed {
            let translation = gesture.translation(in: superview)
            maximizedStackView.transform = CGAffineTransform(translationX: 0, y: translation.y)
        }else if gesture.state == .ended {
            let translation = gesture.translation(in: superview)
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut) {
                self.maximizedStackView.transform = .identity
                
                if translation.y > 50 {
                    let navController = self.window?.rootViewController as? UINavigationController //As in SceneDelegate
                    let radioListController = navController?.topViewController as? RadioListController
                    radioListController?.minimizePlayerDetails()
                    
                    if self.player.timeControlStatus == .playing {
                        self.miniPlayPauseButton.setImage(UIImage(named: "AVPause"), for: .normal)
                    }
                }
            }
        }
    }
    
    fileprivate func handlePanEnded(gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: superview).y
        let velocity = gesture.velocity(in: superview).y
        
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut) {
            
            self.transform = .identity
            if translation < -200 || velocity < -500 {
                let navBarController = self.window?.rootViewController as? UINavigationController
                let radioListController = navBarController?.topViewController as? RadioListController
                radioListController?.maximizePlayerDetails(station: nil)
            }else{
                self.miniPlayerView.alpha = 1
                self.maximizedStackView.alpha = 0
            }
        }
    }
    
    fileprivate func handlePanChanged(gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: superview)
        self.transform = CGAffineTransform(translationX: 0, y: translation.y)
        self.miniPlayerView.alpha = 1 + translation.y / 200
        self.maximizedStackView.alpha = -translation.y / 200
    }
    
    @objc func handlePan(gesture: UIPanGestureRecognizer){
        if gesture.state == .changed {
            handlePanChanged(gesture: gesture)
        }else if gesture.state == .ended {
            handlePanEnded(gesture: gesture)
        }
    }
    
    static func initFromNib() -> PlayerDetailsView {
        return Bundle.main.loadNibNamed("PlayerDetailsView", owner: self, options: nil)?.first as! PlayerDetailsView
    }
    
    //MARK:- IBAction && IBOutlet
    
    //Mini Player Outlets
    @IBOutlet weak var miniPlayerView: UIView!
    @IBOutlet weak var maximizedStackView: UIStackView!
    
    @IBOutlet weak var miniStationImageView: UIImageView!
    @IBOutlet weak var miniStationTitle: UILabel!
    @IBOutlet weak var miniStationSignal: UILabel!
    @IBOutlet weak var miniPlayPauseButton: UIButton!{
        didSet{
            miniPlayPauseButton.addTarget(self, action: #selector(handlePlayPause), for: .touchUpInside)
        }
    }
    
    @IBOutlet weak var radioImageView: UIImageView!{
        didSet{
            let scale: CGFloat = 0.7
            radioImageView.transform = CGAffineTransform(scaleX: scale, y: scale)
        }
    }
    
    @IBOutlet weak var playPauseButton: UIButton!{
        didSet{
            playPauseButton.addTarget(self, action: #selector(handlePlayPause), for: .touchUpInside)
        }
    }
    
    @IBOutlet weak var stopButton: UIButton!{
        didSet{
            stopButton.addTarget(self, action: #selector(handleStop), for: .touchUpInside)
        }
    }
        
    
    @IBOutlet weak var radioTitleLabel: UILabel!
    @IBOutlet weak var radioSignalLabel: UILabel!
    @IBOutlet weak var radioGenresLabel: UILabel!
    
    @IBOutlet weak var addToFavoriteStation: UIButton!{
        didSet{
            addToFavoriteStation.heightAnchor.constraint(equalToConstant: 0).isActive = true
        }
    }
    
    @IBOutlet weak var sleepRemainingTimeLabel: UILabel!
    @IBOutlet weak var sleepButton: UIButton! {
        didSet{
            sleepButton.addTarget(self, action: #selector(handleSleep), for: .touchUpInside)
        }
    }
    
    @IBOutlet weak var SoundControl: UISlider!
    
    @IBAction func setVolumeOff(_ sender: Any) {
        if let view = AVSingelton.volumeView.subviews.first as? UISlider{
            view.value = 0.0
            self.SoundControl.setValue(0.0, animated: true)
        }
    }
    
    @IBAction func setVolumetFull(_ sender: Any) {
        if let view = AVSingelton.volumeView.subviews.first as? UISlider{
            view.value = 1.0
            self.SoundControl.setValue(1.0, animated: true)
        }
    }
    
    
    @IBAction func handleVolumeChange(_ sender: UISlider) {
        let _updatedValue = sender.value
        if let view = AVSingelton.volumeView.subviews.first as? UISlider {
            view.value = _updatedValue
        }
    }
    
    @IBAction func handleDismiss(_ sender: Any) {
        let navController = window?.rootViewController as? UINavigationController //As in SceneDelegate
        let radioListController = navController?.topViewController as? RadioListController
        radioListController?.minimizePlayerDetails()
        
        if player.timeControlStatus == .playing {
            miniPlayPauseButton.setImage(UIImage(named: "AVPause"), for: .normal)
        }
    }
    
    @IBOutlet weak var dismissButtonTop: UIButton!
    
    //MARK:- Functions

    @objc func handlePlayPause(){
        
        if player.currentItem == nil {
            playStation()
        }else{
            if player.timeControlStatus == .playing {
                player.pause()
                playPauseButton.setImage(UIImage(named: "AVPlay"), for: .normal)
                miniPlayPauseButton.setImage(UIImage(named: "AVPlay"), for: .normal)
                //Handle Recording (Stoped same time as station)
                self.finishRecording(success: true)
            }else{
                player.play()
                playPauseButton.setImage(UIImage(named: "AVPause"), for: .normal)
                miniPlayPauseButton.setImage(UIImage(named: "AVPause"), for: .normal)
            }
        }
    }
    
    @objc func handleStop(){
        AVSingelton.stopPlayer { _playingStatus in
            self.playPauseButton.setImage(UIImage(named: "AVPlay"), for: .normal)
            self.miniPlayPauseButton.setImage(UIImage(named: "AVPlay"), for: .normal)
            self.activityIndicator.stopAnimating()
            //Handle Recording (Stoped same time as station)
            
            //check if isRecording finished...
            if AVPlayerSingleton.shared.isRecording == true {
                self.finishRecording(success: true)
            }

        }
    }
    
    fileprivate func setupNowPlayingInfo(image: UIImage?){
        
        var nowPlayingInfo = [String:Any]()
        nowPlayingInfo[MPMediaItemPropertyTitle] = station?.title
        nowPlayingInfo[MPMediaItemPropertyArtist] = station?.signal
        
        guard let _image = image else {return}
        
        let artWork = MPMediaItemArtwork(boundsSize: _image.size) { _ in
            return _image
        }
        
        nowPlayingInfo[MPMediaItemPropertyArtwork] = artWork
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
    
    fileprivate func playStation(){
                
        self.playPauseButton.setImage(UIImage(named: "AVPause"), for: .normal)
        self.miniPlayPauseButton.setImage(UIImage(named: "AVPause"), for: .normal)
        
        // Start Loading....
        addSubview(activityIndicator)
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        activityIndicator.bottomAnchor.constraint(equalTo: stopButton.topAnchor, constant: -10).isActive = true
        
        activityIndicator.startAnimating()
                
        //Clear Sleep before start New station
        self.AVSingelton.sleepTimer?.invalidate()
        self.AVSingelton.sleepTimeInterval = 0.0
        self.AVSingelton.sleepTimeRemaining = 0.0
        
        //update sleepRemainingTimeLabel to empty string..
        self.sleepRemainingTimeLabel.text = ""
        
        //Slider Value must be equal to system Volume
        //Set initial value for SoundControl
        self.SoundControl.setValue(self.AVSingelton.audioSession.outputVolume , animated: true)
        
        if UserDefaults.standard.bool(forKey: "wifiOnly") == true && NetworkStatus.shared.ConnectionType == .cellular {

            let alertMessage = UIAlertController(title: "", message: "You can play station on Wi-fi Only".localized(), preferredStyle: .alert)
            
            let navBarController = UIApplication.shared.windows.first?.rootViewController as? UINavigationController
            let radioListController = navBarController?.topViewController as? RadioListController
            radioListController?.present(alertMessage, animated: true, completion: nil)

                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 4){
                    alertMessage.dismiss(animated: true, completion: nil)
                    
                    AVPlayerSingleton.shared.clearPlayer {
                        
                    self.playPauseButton.setImage(UIImage(named: "AVPlay"), for: .normal)
                    self.miniPlayPauseButton.setImage(UIImage(named: "AVPlay"), for: .normal)
                    self.activityIndicator.stopAnimating()
                        
                        //Handle Recording (Stoped same time as station)
                        self.finishRecording(success: true)
    
                    return
                }
            }
        }
        
        guard let streamList = station?.stream else { return }
        guard let stream = streamList.first  else { return }
        
            AVPlayerSingleton.shared.initStation(stream: stream, completion: { (_timeControlStatus, _remainTime, _timerIsValid) in
                self.sleepRemainingTimeLabel.fadeTransition(0.4)
                if _timerIsValid {
                    let attributedText = NSMutableAttributedString(attributedString: NSAttributedString(string: "\("Sleep in".localized()) \(_remainTime)", attributes: [.font : UIFont(name: Theme.displayFontName, size: 14) as Any, .foregroundColor : UIColor.MRed as Any ]))
                    self.sleepRemainingTimeLabel.attributedText = attributedText
                }else{
                    self.sleepRemainingTimeLabel.text = ""
                }
                
                if _timeControlStatus == true && self.activityIndicator.isAnimating {
                    self.activityIndicator.stopAnimating()
                }
            })
    }
}

