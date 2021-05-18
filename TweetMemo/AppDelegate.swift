//
//  AppDelegate.swift
//  TweetMemo
//
//  Created by Newton on 2020/05/06.
//  Copyright © 2020 Newton. All rights reserved.
//

import UIKit
import RealmSwift

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    let defaults = UserDefaults()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        openRealm()
        realmVersion()
        
        // Splash Loading
        sleep(2)
        return true
    }
    
    func realmVersion(){
        let config = Realm.Configuration(schemaVersion: 20, migrationBlock: { migration, oldSchemaVersion in
            if oldSchemaVersion < 20 {
            }
        })
        Realm.Configuration.defaultConfiguration = config
    }
    
    func openRealm() {
        let defaultRealmPath = Realm.Configuration.defaultConfiguration.fileURL!
        print("FilePath: \(defaultRealmPath)")
    }
    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


}

