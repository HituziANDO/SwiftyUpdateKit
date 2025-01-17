//
//  ViewController.swift
//  iOSSample
//
//  Created by Masaki Ando on 2021/10/08.
//

import UIKit

import SwiftyUpdateKit

class ViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification,
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
                             }) {
                if #available(iOS 16.0, *) {
                    SUK.requestReview(RequestReviewConditionLaunchingAndDaily(),
                                      in: self.view)
                } else {
                    SUK.requestReview(RequestReviewConditionLaunchingAndDaily())
                }
            }
        }
    }
}
