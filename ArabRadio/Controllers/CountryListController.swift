//
//  CountryListController.swift
//  ArabRadio
//
//  Created by Lefdili Alaoui Ayoub on 27/4/2021.
//

import UIKit
import CoreData


class CountryListController: UICollectionViewController {
    
    var _reloadedCountries: [Country]?
    var _countries = CoreDataManager.shared.fetchCountries()
    
    let refreshControl = UIRefreshControl()
    let cellId = "cellId"
    let headerId = "headerId"
    
    override func viewDidAppear(_ animated: Bool) {
        _ = BannerManager.shared.setupBannerView(view: view, viewController: self)
        
        //Initial Setup (First Run)...
        if _countries.count == 0 {
            self.refreshData()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if self._reloadedCountries != nil {
            self._countries = self._reloadedCountries ?? []
            DispatchQueue.main.async {
                self.collectionView.reloadData()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "Arab Radio".localized()
        navigationItem.backButtonTitle = ""
        navigationItem.setHidesBackButton(true, animated: true)
        
        refreshControl.addTarget(self, action: #selector(self.refreshData), for: .valueChanged)
        refreshControl.tintColor = .white
        refreshControl.attributedTitle = NSMutableAttributedString(string: "Updating Stations".localized(), attributes: [.foregroundColor : UIColor.white, .font : UIFont.systemFont(ofSize: 16, weight: .regular)])
        
        if #available(iOS 10.0, *) {
            collectionView.refreshControl = refreshControl
        } else {
            collectionView.addSubview(refreshControl)
        }
        
        collectionView.register(CountryCell.self, forCellWithReuseIdentifier: cellId)
        collectionView.register(HeaderCollectionReusableView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: headerId)
        collectionView.backgroundColor = UIColor.white
        
    }
}

extension CountryListController : UICollectionViewDelegateFlowLayout, NSFetchedResultsControllerDelegate  {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 70, height: 73)
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return _countries.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! CountryCell
        cell._country = _countries[indexPath.item]
        
        return cell
        
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        let _country = _countries[indexPath.item]
        let radioListController = RadioListController()
        
        radioListController._country = _country
        
        if let countryTitle = _country.title {
            UserDefaults.standard.setValue(countryTitle, forKey: "country")
        }
        
        navigationController?.pushViewController(radioListController, animated: true)
    }
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader,
                                                                     withReuseIdentifier: headerId,
                                                                     for: indexPath) as! HeaderCollectionReusableView
        return header
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: view.frame.size.width, height: 48)
    }
    
    
    @objc private func refreshData() {
        CoreDataManager.shared.updateCountries { (_countries, _error) in
            DispatchQueue.main.async { [weak self] in
                UIView.transition(with: self!.collectionView,
                                  duration: 1,
                                  options: .curveEaseOut,
                                  animations: {
                                    guard let countries = _countries else {
                                        return
                                    }
                                    self?._countries = countries
                                    self?.collectionView.reloadData()
                                  }, completion : { _ in
                                    self?.refreshControl.endRefreshing()
                                  })
            }
        }
    }
    
    
}


