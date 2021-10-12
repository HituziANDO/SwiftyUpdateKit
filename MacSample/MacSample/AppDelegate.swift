//
//  AppDelegate.swift
//  MacSample
//
//  Created by Masaki Ando on 2021/10/08.
//

import Cocoa

import SwiftyUpdateKit

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        print("SwiftyUpdateKit.version: \(SUK.version)")

//        SUK.reset()

        let config = SwiftyUpdateKitConfig(
            // Current app version.
            version: Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String,
            // iTunes ID.
            // e.g.) The App Store URL: "https://apps.apple.com/app/sampleapp/id1234567890" -> iTunesID is 1234567890
            iTunesID: "1492010457",
            // The App Store URL of your app.
            storeURL: "https://apps.apple.com/app/blue-sketch/id1492010457",
            // The country code used by iTunes Search API.
            // See http://en.wikipedia.org/wiki/ISO_3166-1_alpha-2 for a list of ISO Country Codes.
            country: "us",
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
            remindMeLaterButtonTitle: "Remind me later"
        )
        SUK.applicationDidFinishLaunching(withConfig: config) { print($0) }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
}
