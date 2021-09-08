//
//  BannerManager.swift
//  ArabRadio
//
//  Created by Lefdili Alaoui Ayoub on 4/7/2021.
//

import UIKit
import GoogleMobileAds
import AppTrackingTransparency

class BannerManager: NSObject {
    
    static let shared = BannerManager()
    
    static var bannerHeight: CGFloat = 65
    static var adUnitID: String {
        #if DEBUG
        return "ca-app-pub-3940256099942544/2934735716"
        #else
        return "ca-app-pub-0000000000000000/0000000000" // Production Ad-Unit
        #endif
    }
    
    private var _bannerView: GADBannerView = {
        let banner = GADBannerView()
        banner.translatesAutoresizingMaskIntoConstraints = false
        banner.adUnitID = adUnitID
        banner.load(GADRequest())
        return banner
    }()
  
    func setupBannerView(view: UIView, viewController: UIViewController) -> GADBannerView {
        
        if #available(iOS 14, *) {
            ATTrackingManager.requestTrackingAuthorization { status in
                switch status {
                case .notDetermined:
                    break
                case .restricted:
                    break
                case .denied:
                    break
                case .authorized:
                    self._bannerView.load(GADRequest())
                @unknown default:
                    break
                }
            }
        }else{
            self._bannerView.load(GADRequest())
        }

        view.addSubview(_bannerView)
        _bannerView.rootViewController = viewController

        NSLayoutConstraint.activate([
            _bannerView.heightAnchor.constraint(equalToConstant: BannerManager.bannerHeight),
            _bannerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            _bannerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            _bannerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            _bannerView.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
        
        return _bannerView
    }
    

}


