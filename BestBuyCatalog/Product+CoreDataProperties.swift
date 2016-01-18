//
//  Product+CoreDataProperties.swift
//  BestBuyCatalog
//
//  Created by Victor Bozelli Alvarez on 1/17/16.
//  Copyright © 2016 Bozelli. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Product {

    @NSManaged var brand: String?
    @NSManaged var image: String?
    @NSManaged var name: String?
    @NSManaged var price: Float
    @NSManaged var largeImage: String?

}
