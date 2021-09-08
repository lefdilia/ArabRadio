//
//  SavedListController.swift
//  ArabRadio
//
//  Created by Lefdili Alaoui Ayoub on 26/4/2021.
//

import UIKit

class SavedListController: UIViewController, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    
    var myCollectionView: UICollectionView?
    
    let _stations = Data.stationsList
    
    let _jumbetron: UIView = {
        let jumbetronView = UIView()
        jumbetronView.translatesAutoresizingMaskIntoConstraints = false
        jumbetronView.backgroundColor = UIColor.CLJumbetron
        return jumbetronView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
  
        title = "Saved List"
        navigationItem.backButtonTitle = ""
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "gear"), style: .plain, target: self, action: #selector(setupSettings))
 
        
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 60, left: 10, bottom: 10, right: 10)
        layout.itemSize = CGSize(width: 100, height: 100)

        
        myCollectionView = UICollectionView(frame: self.view.frame, collectionViewLayout: layout)
        myCollectionView?.register(SavedListControllerCell.self, forCellWithReuseIdentifier: "MyCell")
        myCollectionView?.backgroundColor = UIColor.white

        view.addSubview(myCollectionView ?? UICollectionView())
                
        myCollectionView?.delegate = self
        myCollectionView?.dataSource = self
        
        // MARK: - Add Top View

        view.addSubview(_jumbetron)
        NSLayoutConstraint.activate([
            _jumbetron.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            _jumbetron.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            _jumbetron.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            _jumbetron.heightAnchor.constraint(equalToConstant: 48)
        ])
        
        let headerLabel: UILabel = {
            let label = UILabel()
            let attributedText = NSMutableAttributedString(string: "Saved Stations",
                                                           attributes: [NSAttributedString.Key.font : UIFont(name: Theme.readFontName, size: 16) as Any, NSAttributedString.Key.foregroundColor : UIColor.darkBlue as Any ])
            label.attributedText = attributedText
            label.translatesAutoresizingMaskIntoConstraints = false
            return label
        }()
        
        let _stationIcon: UIImageView = {
            let imageView = UIImageView()
            imageView.image = UIImage(named: "saved-list")
            imageView.tintColor = UIColor.lightGreen
            imageView.translatesAutoresizingMaskIntoConstraints = false
            return imageView
        }()
        
        _jumbetron.addSubview(_stationIcon)
        _jumbetron.addSubview(headerLabel)
        
        NSLayoutConstraint.activate([
            _stationIcon.centerYAnchor.constraint(equalTo: _jumbetron.centerYAnchor),
            _stationIcon.leadingAnchor.constraint(equalTo: _jumbetron.leadingAnchor, constant: 8),
            headerLabel.centerYAnchor.constraint(equalTo: _stationIcon.centerYAnchor),
            headerLabel.leadingAnchor.constraint(equalTo: _stationIcon.trailingAnchor, constant: 7)
        ])
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return _stations.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let myCell = collectionView.dequeueReusableCell(withReuseIdentifier: "MyCell", for: indexPath) as! SavedListControllerCell
        
        myCell.station = _stations[indexPath.item]
        return myCell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print("User tapped on item \(indexPath.row)")
        
        let _station = _stations[indexPath.item]

        let playerController = PlayerController()
        playerController.station = _station

        navigationController?.pushViewController(playerController, animated: true)
        
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 10
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 8
    }
    
}
