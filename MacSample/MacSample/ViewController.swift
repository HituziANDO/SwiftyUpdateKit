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
    }

    override func viewDidAppear() {
        super.viewDidAppear()

        SUK.checkVersion(VersionCheckConditionAlways(),
                         newRelease: { [weak self] newVersion, releaseNotes, _ in
                             guard let self else { return }
                             SUK.showReleaseNotes(from: self, text: releaseNotes,
                                                  version: newVersion)
                             {
                                 print("Release Notes has been closed.")
                             }
                         }) {
            SUK.requestReview(RequestReviewConditionAlways())
        }
    }
}
