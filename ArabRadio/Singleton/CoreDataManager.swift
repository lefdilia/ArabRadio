//
//  CoreDataManager.swift
//  ArabRadio
//
//  Created by Lefdili Alaoui Ayoub on 30/4/2021.
//

import CoreData



struct CoreDataManager {
    
    static let shared = CoreDataManager()
    
    let persistentContainer: NSPersistentContainer = {
        let persistentContainer = NSPersistentContainer(name: "StationsModels")
        
        persistentContainer.loadPersistentStores { storeDescription, error in
            persistentContainer.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
            
            if let error = error {
                fatalError("Loading of store failed : \(error)")
            }
        }
        return persistentContainer
        
    }()
    
    
    //MARK: - Country
    
    func fetchCountries(country: String? = nil) -> [Country]{
        
        var countries = [Country]()
        
        let context = self.persistentContainer.viewContext
        let request = NSFetchRequest<Country>(entityName: "Country")
        
        var predicateArray = [NSPredicate]()
        let whereStatus: NSPredicate = NSPredicate(format: "status == true")
        
        if let country = country {
            let whereCountry: NSPredicate = NSPredicate(format: "title == %@", country)
            predicateArray.append(whereCountry)
        }
        
        predicateArray.append(whereStatus)
        
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicateArray)
        
        do {
            countries = try context.fetch(request)
            return countries
            
        }catch {
            return []
        }
    }
    
    func searchStations(country: String, searchText: String) -> [Station] {
        var stations = [Station]()
        
        let context = self.persistentContainer.viewContext
        let request = NSFetchRequest<Station>(entityName: "Station")
        request.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]
        
        var predicateArray = [NSPredicate]()
        
        let whereCountry: NSPredicate = NSPredicate(format: "country == %@", country)
        let whereSearchText: NSPredicate = NSPredicate(format: "title contains[c] %@", searchText)
        
        if !searchText.isEmpty {
            predicateArray.append(whereSearchText)
        }
        
        predicateArray.append(whereCountry)
        
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicateArray)
        
        do {
            stations = try context.fetch(request)
            return stations
        }catch{
            return []
        }
        
    }
    
    func fetchStations(country: String, _ findFavoriteStations: Bool? = false) -> [Station] {
        
        var stations = [Station]()
        
        let context = self.persistentContainer.viewContext
        let request = NSFetchRequest<Station>(entityName: "Station")
        request.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]
        
        var predicateArray = [NSPredicate]()
        
        let whereStatus: NSPredicate = NSPredicate(format: "status == true")
        let whereCountry: NSPredicate = NSPredicate(format: "country == %@", country)
        let whereFavorite: NSPredicate = NSPredicate(format: "isFavorite == true")
        
        if findFavoriteStations == true {
            predicateArray.append(whereFavorite)
        }else{
            predicateArray.append(whereCountry)
        }
        
        predicateArray.append(whereStatus)
        
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicateArray)
        
        do {
            stations = try context.fetch(request)
            return stations
        }catch {
            return []
        }
        
    }
    
    func fetchStartStation(objectURL: URL, completion: @escaping (Station)->() ) {
        
        let privateContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        privateContext.parent = self.persistentContainer.viewContext
        
        guard let _objectID = privateContext.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: objectURL) else {return}
        guard let station = privateContext.object(with: _objectID) as? Station else {return}
        
        completion(station)
    }
    
    func updateFavorite(station: Station, completion: @escaping (Bool?, Error?) -> Void) {
        
        let privateContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        privateContext.parent = self.persistentContainer.viewContext
        
        guard let stationSafe = privateContext.object(with: station.objectID) as? Station else {return}
        stationSafe.isFavorite = !stationSafe.isFavorite
        
        let isFavorite = stationSafe.isFavorite 
        
        do {
            
            try privateContext.save()
            try privateContext.parent?.save()
            
            completion(isFavorite, nil)
        }catch let updateFavoritesError {
            completion(nil, updateFavoritesError)
        }
    }
    
    private func fetchIsfavorite(station: StationJson.StationList) -> Bool {
        
        let context = self.persistentContainer.viewContext
        let request = NSFetchRequest<Station>(entityName: "Station")
        request.predicate = NSPredicate(format: "%K == %@ AND %K == %@", argumentArray:["country", station.country, "title", station.title])
        request.fetchLimit = 1
        
        var isFavorite: Bool = false
        
        do {
            let _station = try context.fetch(request)
            if _station.count > 0 {
                isFavorite = _station[0].isFavorite
            }
            
            return isFavorite
            
        }catch {
            return isFavorite
        }
    }
    
    func updateCountries(completion: @escaping ([Country]?, Error?) -> Void ){
        
        let privateContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        privateContext.parent = self.persistentContainer.viewContext
        
        NetworkRequest.shared.fetchRemoteSource { List, error in
            
            guard let List = List else {
                return completion(nil, error)
            }
            
            List.forEach { _list in
                let country = NSEntityDescription.insertNewObject(forEntityName: "Country", into: privateContext) as! Country
                country.setValue(_list.Country, forKey: "title")
                country.setValue(_list.image, forKey: "image")
                country.setValue(_list.Status, forKey: "status")
                
                _list.Stations.forEach { _station in
                    
                    let isFavorite =  self.fetchIsfavorite(station: _station)
                    let station = NSEntityDescription.insertNewObject(forEntityName: "Station", into: privateContext) as! Station

                    station.setValue(_list.Country, forKey: "country")
                    station.setValue(_station.image, forKey: "image")
                    station.setValue(isFavorite, forKey: "isFavorite")
                    station.setValue(_station.sDescription, forKey: "sDescription")
                    station.setValue(_station.signal, forKey: "signal")
                    station.setValue(_station.status, forKey: "status")
                    station.setValue(_station.stream, forKey: "stream")
                    station.setValue(_station.title, forKey: "title")
                    station.setValue(_station.type, forKey: "type")
                }
                
                try? privateContext.save()
                try? privateContext.parent?.save()
                
            }
            
            do {
                let buildCountries = try privateContext.parent?.fetch(NSFetchRequest<Country>(entityName: "Country"))
                completion(buildCountries, nil)
            }catch let errorBuildCountries {
                completion([], errorBuildCountries)
            }
        }
    }
    
    
    func resetApp(completion : @escaping ([Country]?, Error?)->Void){ // closure
        
        let context = self.persistentContainer.viewContext
        let bashDeleteRequest = NSBatchDeleteRequest(fetchRequest: Country.fetchRequest())
        let bashDeleteRequest2 = NSBatchDeleteRequest(fetchRequest: Station.fetchRequest())
        
        do {
            try context.execute(bashDeleteRequest)
            try context.execute(bashDeleteRequest2)
            
            self.resetDefaults()
            self.updateCountries { (_countries, _error) in
                completion(_countries, _error)
            }
            
        }catch let errorBashDeleteRequest{
            completion(nil, errorBashDeleteRequest)
        }
    }
    
    private func resetDefaults() {
        let defaults = UserDefaults.standard
        let dictionary = defaults.dictionaryRepresentation()
        dictionary.keys.forEach { key in
            defaults.removeObject(forKey: key)
        }
    }
}


