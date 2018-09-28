//
//  PostController.swift
//  Timeline-CloudKit
//
//  Created by Eric Andersen on 9/25/18.
//  Copyright © 2018 Eric Andersen. All rights reserved.
//

import UIKit
import CloudKit
import UserNotifications

class PostController {
    
    static let shared = PostController()
    static let PostsChangedNotification = Notification.Name("PostsChangedNotification")
    let publicDB = CKContainer.default().publicCloudDatabase
    
    var posts = [Post]() {
        didSet {
            DispatchQueue.main.async {
                let nc = NotificationCenter.default
                nc.post(name: PostController.PostsChangedNotification, object: self)
            }
        }
    }
    
    private init() {
        subscribeToNewPosts(completion: nil)
    }
    
    
    // MARK: - CRUD
    func createPostWith(image: UIImage, caption: String, completion: @escaping (Post?) -> ()) {
        let post = Post(caption: caption, photo: image)
        self.posts.append(post)
        
        publicDB.save(CKRecord(post)) { (_, error) in
            
            if let error = error {
                print("Error saving post record \(error) \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            completion(post)
        }
    }
    
    func addComment(text: String, post: Post, completion: @escaping (Comment?) -> ()) {
        let comment = Comment(text: text, post: post)
        post.comments.append(comment)
        
        publicDB.save(CKRecord(comment)) { (record, error) in
            
            if let error = error {
                print("Error saving comment: \(error) \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            completion(comment)
        }
    }
    
    
    // MARK: - Fetch
    func fetchAllPostsFromCloudKit(completion: @escaping([Post]?) -> Void) {
        
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: "Post", predicate: predicate)
        
        publicDB.perform(query, inZoneWith: nil) { (records, error) in
            
            if let error = error {
                print("Error fetching posts from cloudKit \(#function) \(error) \(error.localizedDescription)")
                completion(nil);return
            }
            
            guard let records = records else {completion(nil); return }
            
            let posts = records.compactMap{Post(record: $0)}
            
            self.posts = posts
            completion(posts)
        }
    }
//    func fetchAllPostsFromCloudKit(completion: @escaping([Post]?) -> Void) {
//
//        let predicate = NSPredicate(value: true)
//        let query = CKQuery(recordType: "Post", predicate: predicate)
//
//        publicDB.perform(query, inZoneWith: nil) { (records, error) in
//
//            if let error = error {
//                print("Error fetching posts from cloudKit: \(error) \(error.localizedDescription)")
//                completion(nil)
//                return
//            }
//
//            if let records = records {
//                let posts = records.compactMap{Post(record: $0)}
//                self.posts = posts
//                completion(posts)
//            }
//        }
//    }
    
    func fetchComments(from post: Post, completion: @escaping (Bool) -> Void) {
        
        let postReference = post.recordID
        let predicate = NSPredicate(format: "postReference == %@", postReference)
        let commentIDs = post.comments.compactMap({$0.recordID})
        let predicate2 = NSPredicate(format: "NOT(recordID IN %@)", commentIDs)
        let compoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate, predicate2])
        
        let query = CKQuery(recordType: "Comment", predicate: compoundPredicate)
        
        publicDB.perform(query, inZoneWith: nil) { (records, error) in
            
            if let error = error {
                print("Error fetching comments from cloudKit \(#function) \(error) \(error.localizedDescription)")
                completion(false)
                return
            }
            
            if let records = records {
                let comments = records.compactMap{Comment(record: $0)}
                post.comments.append(contentsOf: comments)
                completion(true)
            }
        }
    }
    
    
    // MARK: - CloudKit Availablility
    func presentErrorAlert(errorTitle: String, errorMessage: String) {
        DispatchQueue.main.async {
            if let appDelegate = UIApplication.shared.delegate, let appWindow = appDelegate.window!, let rootViewController = appWindow.rootViewController {
                rootViewController.showAlertMessage(title: errorTitle, message: errorMessage)
            }
        }
    }
    
    func checkAccountStatus(completion: @escaping (_ isLoggedIn: Bool) -> Void) {
        CKContainer.default().accountStatus { [weak self] (status, error) in
            
            if let error = error {
                
                print("There was an error checking account status \(error) \(error.localizedDescription)")
                completion(false); return
                
            } else {
                
                let errorText = "Sign into iCloud in Settings"
                
                switch status {
                case .available:
                    completion(true)
                case .noAccount:
                    let noAccount = "No account found"
                    self?.presentErrorAlert(errorTitle: errorText, errorMessage: noAccount)
                    completion(false)
                case .couldNotDetermine:
                    self?.presentErrorAlert(errorTitle: errorText, errorMessage: "Error with iCloud account status")
                    completion(false)
                case .restricted:
                    self?.presentErrorAlert(errorTitle: errorText, errorMessage: "Restricted iCloud account")
                    completion(false)
                }
            }
        }
    }
    
    
    // MARK: - CloudKit Subscriptions
    func subscribeToNewPosts(completion: ((Bool, Error?) -> Void)?) {
        
        let predicate = NSPredicate(value: true)
        let subscription = CKQuerySubscription(recordType: "Post", predicate: predicate, subscriptionID: "AllPosts", options: .firesOnRecordCreation)
        
        let notificationInfo = CKSubscription.NotificationInfo()
        notificationInfo.alertBody = "New post added to Timeline"
        notificationInfo.shouldBadge = true
        notificationInfo.shouldSendContentAvailable = true
        subscription.notificationInfo = notificationInfo
        
        publicDB.save(subscription) { (subscription, error) in
            
            if let error = error {
                print("There was an error subscribing to new post: \(error) \(error.localizedDescription)")
                completion?(false, error)
            } else {
                completion?(true, nil)
            }
        }
    }
    
    func addSubscriptionTo(commentsForPost post: Post, completion: ((Bool, Error?) -> ())?) {
        
        let postRecordID = post.recordID
        
        let predicate = NSPredicate(format: "postReference = %@", postRecordID)
        let subscription = CKQuerySubscription(recordType: "Comment", predicate: predicate, subscriptionID: post.recordID.recordName, options: .firesOnRecordCreation)
        
        let notificationInfo = CKSubscription.NotificationInfo()
        notificationInfo.alertBody = "A new comment was added to a post you follow!"
        notificationInfo.shouldSendContentAvailable = true
        notificationInfo.desiredKeys = nil
        subscription.notificationInfo = notificationInfo
        
        publicDB.save(subscription) { (_, error) in
            
            if let error = error {
                print("There was an error subscribing to post: \(error) \(error.localizedDescription)")
                completion?(false, error)
            }else{
                completion?(true, nil)
            }
        }
    }
    
    func removeSubscriptionTo(commentsForPost post: Post, completion: ((Bool) -> ())?) {
        
        let subscriptionID = post.recordID.recordName
        
        publicDB.delete(withSubscriptionID: subscriptionID) { (_, error) in
            
            if let error = error {
                print("There was an error removing subscription: \(error) \(error.localizedDescription)")
                completion?(false)
                return
            } else {
                print("Subscription deleted")
                completion?(true)
            }
        }
    }
    
    func checkForSubscription(to post: Post, completion: ((Bool) -> ())?) {
        
        let subscriptionID = post.recordID.recordName
        
        publicDB.fetch(withSubscriptionID: subscriptionID) { (subscription, error) in
            
            if let error = error {
                print("There was an error checking for subscripion status: \(error) \(error.localizedDescription)")
                completion?(false)
                return
            }
            
            if subscription != nil {
                completion?(true)
            } else {
                completion?(false)
            }
        }
    }
    
    func toggleSubscriptionTo(commentsForPost post: Post, completion: ((Bool, Error?) -> ())?) {
        checkForSubscription(to: post) { (isSubscribed) in
            
            if isSubscribed {
                self.removeSubscriptionTo(commentsForPost: post, completion: { (success) in
                    if success {
                        print("Successfully removed the subscription to the post with caption: \(post.caption)")
                        completion?(true, nil)
                    } else {
                        print("Something went wrong removing the subscription to the post with caption: \(post.caption)") ; completion?(true, nil)
                        completion?(false, nil)
                    }
                })
                
            } else {
                
                self.addSubscriptionTo(commentsForPost: post, completion: { (success, error) in
                    
                    if let error = error {
                        print("There was an error subscribing to post: \(error) \(error.localizedDescription)")
                        completion?(false, error)
                        return
                    }
                    
                    if success {
                        print("Successfully added the subscription to the post with caption: \(post.caption)")
                        completion?(true, nil)
                    } else {
                        print("Something went wrong adding the subscription to the post with caption: \(post.caption)")
                        completion?(false, nil)
                    }
                })
            }
        }
    }
}
