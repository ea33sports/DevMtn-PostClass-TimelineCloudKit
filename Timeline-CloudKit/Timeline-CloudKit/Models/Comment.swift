//
//  Comment.swift
//  Timeline-CloudKit
//
//  Created by Eric Andersen on 9/25/18.
//  Copyright © 2018 Eric Andersen. All rights reserved.
//

import Foundation
import CloudKit

class Comment: SearchableRecord {
    
    let typeKey = "Comment"
    fileprivate let textKey = "text"
    fileprivate let timestampKey = "timestamp"
    fileprivate let postReferenceKey = "postReference"
    
    var text: String
    var timestamp: Date
    weak var post: Post?
    var recordID = CKRecord.ID(recordName: UUID().uuidString)
    
    init(text: String, timestamp: Date = Date(), post: Post?) {
        self.text = text
        self.timestamp = timestamp
        self.post = post
    }
    
    convenience required init?(record: CKRecord) {
        guard let text = record["text"] as? String,
              let timestamp = record.creationDate
              else { return nil }
        
        self.init(text: text, timestamp: timestamp, post: nil)
        self.recordID = record.recordID
    }
    
    
    func matches(searchTerm: String) -> Bool {
        return self.text.lowercased().contains(searchTerm.lowercased())
    }
}

extension CKRecord {
    convenience init(_ comment: Comment) {
        guard let post = comment.post else {
            fatalError("Comment does not have a post relationship.")
        }
        
        self.init(recordType: comment.typeKey, recordID: comment.recordID)
        self.setValue(comment.text, forKey: comment.textKey)
        self.setValue(comment.timestamp, forKey: comment.timestampKey)
        self.setValue(CKRecord.Reference(recordID: post.recordID, action: .deleteSelf), forKey: comment.postReferenceKey)
    }
}
