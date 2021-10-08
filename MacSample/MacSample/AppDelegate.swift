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
        print("SwiftyUpdateKit.version: \(SwiftyUpdateKit.version)")
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
}
