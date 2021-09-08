//
//  NetworkRequest.swift
//  ArabRadio
//
//  Created by Lefdili Alaoui Ayoub on 29/6/2021.
//

import Foundation
import Alamofire
import Firebase



class NetworkRequest {
    
    static let shared = NetworkRequest()
    
    private let storage = Storage.storage()
    
    private func fetchStationsJson(completion: @escaping ([StationJson]?, Error?)->() ){

        let storageReference = storage.reference()

        storageReference.listAll { (result, error) in
            
            if error != nil {
                completion(nil, error?.localizedDescription as? Error)
            }
            
            guard let jsonFile = result.items.first else { return }
            
            jsonFile.getData(maxSize: 10 * 1024 * 1024, completion: { data, error in
                
                if error != nil {
                    completion(nil, error?.localizedDescription as? Error)
                }
                
                guard let data = data else {return}
                
                do {
                    
                    let decoder = JSONDecoder()
                    let stations = try decoder.decode([StationJson].self, from: data)
                    
                    completion(stations, nil)
                    
                }catch let error {
                    completion(nil, error.localizedDescription as? Error)
                }
            })
        }
    }
    
    private func fetchStationsData(completion: @escaping ([String:URL]?, Error?)->() ){
        var _stations = [String:URL]()
        
        let storageReference = storage.reference().child("images/stations")
        storageReference.listAll { (result, error) in
            
            if error != nil {
                completion(nil, error?.localizedDescription as? Error)
            }
            
            for item in result.items {
                item.downloadURL(completion: { _url, _error in
                    
                    if _error != nil {
                        completion(nil, _error?.localizedDescription as? Error)
                    }
                    
                    guard let _url = _url else { return }
                    
                    let name = item.name.replacingOccurrences(of: #"(\.png|\.jp(e)?g)"#, with: "", options: .regularExpression, range: nil)
                    _stations[name] = _url.absoluteURL
                    if _stations.count == result.items.count {
                        completion(_stations, nil)
                    }
                })
            }
        }
    }
    
    private func fetchCountriesData(completion: @escaping ([String:URL]?, Error?)->() ){
        var _countries = [String:URL]()
        
        let storageReference = storage.reference().child("images/countries")
        storageReference.listAll { (result, error) in
            
            if error != nil {
                completion(nil, error?.localizedDescription as? Error)
            }
            
            for item in result.items {
                item.downloadURL(completion: { _url, _error in
                    
                    if _error != nil {
                        completion(nil, _error?.localizedDescription as? Error)
                    }
                    
                    guard let _url = _url else { return }
                    let name = item.name.replacingOccurrences(of: #"(\.png|\.jp(e)?g)"#, with: "", options: .regularExpression, range: nil)
                    _countries[name] = _url.absoluteURL
                    if _countries.count == result.items.count {
                        completion(_countries, nil)
                    }
                })
            }
        }
    }
    
    func fetchRemoteSource(completion: @escaping ([StationJson]?, Error?) -> Void) {
        
        var _stationsJson: [StationJson]?
        var _countriesImages: [String:URL]?
        var _stationsImages: [String:URL]?
        
        let group = DispatchGroup()
        
        //1. fetch Json Data
        group.enter()
        DispatchQueue.global(qos: .default).async {
            self.fetchStationsJson { stationsJson, _ in
                _stationsJson = stationsJson
                group.leave()
            }
        }
        
        //2. fetch Countries
        group.enter()
        DispatchQueue.global(qos: .default).async {
            self.fetchCountriesData { countriesImages, _ in
                _countriesImages = countriesImages
                group.leave()
            }
        }
        
        //3. fetch Stations
        group.enter()
        DispatchQueue.global(qos: .default).async {
            self.fetchStationsData { stationsImages, _ in
                _stationsImages = stationsImages
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            //4./5. Fix Json File && Return New json file with Firebase Images
            if _stationsJson == nil || _countriesImages == nil || _stationsImages ==  nil {
                 return completion(nil, "Error In fetching request" as? Error)
            }
                
            guard let _stationsJsonMe = _stationsJson else { return }
            
            for (idx, _stsJson) in _stationsJsonMe.enumerated() {
        
                let msCountry: String = _stsJson.Country
                guard let _image = _countriesImages?[msCountry] else {return}
                _stationsJson?[idx].image = _image.absoluteString
            
                //Edit station Image
                for (idy, _stations) in _stsJson.Stations.enumerated() {
                                     
                    let msStation: String = _stations.image
                    let _image_ = _stationsImages?[msStation]?.absoluteString ?? ""

                    _stationsJson?[idx].Stations[idy].image = _image_
                }
                
                if idx == _stationsJsonMe.count - 1 {
                    guard let _stationsJson = _stationsJson else {
                        return completion([], "Error Providing valid json data..." as? Error)
                    }
                    completion(_stationsJson, nil)
               }
            }
        }
    }
}
