//
//  ViewController.swift
//  MacSample
//
//  Created by Masaki Ando on 2021/10/08.
//

import Cocoa

import SwiftyUpdateKit

class ViewController: NSViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        NotificationCenter.default.addObserver(forName: NSApplication.didBecomeActiveNotification,
                                               object: nil, queue: .main)
        { _ in
            SUK.checkVersion(VersionCheckConditionLaunchingAndDaily(),
                             newRelease: { [weak self] newVersion, releaseNotes, _ in
                                 guard let self else { return }
                                 SUK.showReleaseNotes(from: self, text: releaseNotes,
                                                      version: newVersion)
                                 {
                                     print("Release Notes has been closed.")
                                 }
                             }) { [weak self] in
                guard let self else { return }
                if #available(macOS 13.0, *) {
                    SUK.requestReview(RequestReviewConditionLaunchingAndDaily(),
                                      in: self)
                } else {
                    SUK.requestReview(RequestReviewConditionLaunchingAndDaily())
                }
            }
        }
    }
}
