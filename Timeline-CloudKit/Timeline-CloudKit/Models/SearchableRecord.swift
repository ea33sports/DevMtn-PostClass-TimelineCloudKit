//
//  SearchableRecord.swift
//  Timeline-CloudKit
//
//  Created by Eric Andersen on 9/25/18.
//  Copyright © 2018 Eric Andersen. All rights reserved.
//

import Foundation

protocol SearchableRecord {
    
    func matches(searchTerm: String) -> Bool
}
