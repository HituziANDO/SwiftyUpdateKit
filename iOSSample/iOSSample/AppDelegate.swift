//
//  AppDelegate.swift
//  iOSSample
//
//  Created by Masaki Ando on 2021/10/08.
//

import UIKit

import SwiftyUpdateKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication
                         .LaunchOptionsKey: Any]?) -> Bool
    {
        print("SwiftyUpdateKit.version: \(SUK.version)")

//        SUK.reset()

        let config = SwiftyUpdateKitConfig(// Current app version.
            version: Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String,
            // iTunes ID.
            // e.g.) The App Store URL: "https://apps.apple.com/app/sampleapp/id1234567890" ->
            // iTunesID is 1234567890
            iTunesID: "1491913803",
            // The App Store URL of your app.
            storeURL: "https://apps.apple.com/app/blue-sketch/id1491913803",
            // The country code used by iTunes Search API.
            // See http://en.wikipedia.org/wiki/ISO_3166-1_alpha-2 for a list of ISO Country Codes.
            country: "jp",
            // The method to compare the app version.
            versionCompare: VersionCompare(),
            // The update alert's title.
            updateAlertTitle: "Released new version!",
            // The update alert's message.
            updateAlertMessage: "Please update the app. Please refer to the App Store for details of the update contents.",
            // The update button's label.
            updateButtonTitle: "Update",
            // The remind-me-later button's label. If nil is specified, the button is hidden.
            // That is, you can force a user to update because it cannot be canceled.
            remindMeLaterButtonTitle: "Remind me later")
        SUK.initialize(withConfig: config) { print($0) }

        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication,
                     configurationForConnecting connectingSceneSession: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration
    {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        UISceneConfiguration(name: "Default Configuration",
                             sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication,
                     didDiscardSceneSessions sceneSessions: Set<UISceneSession>)
    {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called
        // shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as
        // they will not return.
    }
}
