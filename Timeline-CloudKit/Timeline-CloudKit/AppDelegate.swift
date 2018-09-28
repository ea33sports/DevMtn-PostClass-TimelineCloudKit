//
//  AppDelegate.swift
//  Timeline-CloudKit
//
//  Created by Eric Andersen on 9/25/18.
//  Copyright © 2018 Eric Andersen. All rights reserved.
//

import UIKit
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        PostController.shared.checkAccountStatus { (success) in
        }
        
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { (success, error) in
            
            if let error = error {
                print("There was an error requsting authorization: \(error) \(error.localizedDescription)")
                return
            }
            
            if success {
                print("Successfully authorized to send push notification")
            } else {
                print("Denied, Can't send this person notification")
            }
        }
        
        application.registerForRemoteNotifications()
        
        return true
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        print("Recieved a notification")
        PostController.shared.fetchAllPostsFromCloudKit { (_) in
        }
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert, .sound])
    }
}

