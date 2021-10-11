//
//  AppDelegate.swift
//  MacSample
//
//  Created by Masaki Ando on 2021/10/08.
//

import Cocoa

import SwiftyUpdateOSXKit

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        print("SwiftyUpdateKit.version: \(SUK.version)")

//        SUK.reset()

        let config = SwiftyUpdateKitConfig(
            version: Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String,
            iTunesID: "1492010457",
            storeURL: "https://apps.apple.com/app/blue-sketch/id1492010457",
            country: "jp",
            releaseNotesVersion: 1
        )
        SUK.applicationDidFinishLaunching(withConfig: config) { print($0) }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
}
