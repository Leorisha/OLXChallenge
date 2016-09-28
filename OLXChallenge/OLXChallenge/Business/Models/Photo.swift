//
//  Photo.swift
//  OLXChallenge
//
//  Created by Ana Neto on 28/09/16.
//  Copyright © 2016 Ana Neto. All rights reserved.
//

import Foundation
import RealmSwift
import SwiftyJSON

class Photo: Object {
    
    dynamic var key:Int  = 0
    dynamic var slot:Int = 0
    dynamic var width: Int = 0
    dynamic var height: Int = 0

    override static func primaryKey() -> String? {
        return "key"
    }
    
    static func parseFromJSON(key:Int, data:JSON)->Photo {
        
        let photo = Photo()
        
        photo.key = key
        
        if let slot = data["slot_id"].int {
            photo.slot = slot
        }
        
        if let w = data["w"].int {
            photo.width = w
        }
        
        if let h = data["h"].int {
            photo.height = h
        }
        
        return photo
    }
    
    // Specify properties to ignore (Realm won't persist these)
    
    //  override static func ignoredProperties() -> [String] {
    //    return []
    //  }
}
