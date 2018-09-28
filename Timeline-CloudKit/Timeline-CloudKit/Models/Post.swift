//
//  Post.swift
//  Timeline-CloudKit
//
//  Created by Eric Andersen on 9/25/18.
//  Copyright © 2018 Eric Andersen. All rights reserved.
//

import UIKit
import CloudKit

class Post: SearchableRecord {
    
    let recordTypeKey = "Post"
    fileprivate let captionKey = "caption"
    fileprivate let timestampKey = "timestamp"
    fileprivate let photoDataKey = "photoData"
    
    var photoData: Data?
    var timestamp: Date
    var caption: String
    var comments: [Comment] = []
    var tempURL: URL?
    var recordID = CKRecord.ID(recordName: UUID().uuidString)
    
    var photo: UIImage? {
        get {
            guard let photoData = photoData else { return nil }
            return UIImage(data: photoData)
        } set {
            photoData = newValue?.jpegData(compressionQuality: 0.6)
        }
    }
    
    var imageAsset: CKAsset? {
        get {
            
            let tempDictionary = NSTemporaryDirectory()
            let tempDictionaryURL = URL(fileURLWithPath: tempDictionary)
            let fileURL = tempDictionaryURL.appendingPathComponent(UUID().uuidString).appendingPathExtension("jpg")
            self.tempURL = fileURL
            
            do {
                try photoData?.write(to: fileURL)
            } catch let error {
                print("Error writing to temp url \(error) \(error.localizedDescription)")
            }
            return CKAsset(fileURL: fileURL)
        }
    }
    
    init(caption: String, timestamp: Date = Date(), comments: [Comment] = [], photo: UIImage) {
        self.caption = caption
        self.timestamp = timestamp
        self.comments = comments
        self.photo = photo
    }
    
    init?(record: CKRecord) {
        guard let caption = record[captionKey] as? String,
              let timestamp = record.creationDate,
              let imageAsset = record[photoDataKey] as? CKAsset,
              let photoData = try? Data(contentsOf: imageAsset.fileURL)
              else { return nil }
        
        self.caption = caption
        self.timestamp = timestamp
        self.photoData = photoData
        self.comments = []
        self.recordID = record.recordID
    }
    
    deinit {
        if let url = tempURL {
            do {
                try FileManager.default.removeItem(at: url)
            } catch let error {
                print("Error deleting temp file, or may cause memory leak: \(error)")
            }
        }
    }
    
    
    func matches(searchTerm: String) -> Bool {
        
        if caption.lowercased().contains(searchTerm.lowercased()) {
            return true
        }
        
        for comment in self.comments {
            if comment.matches(searchTerm: searchTerm) {
                return true
            }
        }
        
        return false
    }
}

extension CKRecord {
    convenience init(_ post: Post) {
        let recordID = post.recordID
        self.init(recordType: post.recordTypeKey, recordID: recordID)
        self.setValue(post.caption, forKey: post.captionKey)
        self.setValue(post.timestamp, forKey: post.timestampKey)
        self.setValue(post.imageAsset, forKey: post.photoDataKey)
    }
}
