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

//        SUK.checkVersion(CheckVersionConditionAlways())
        SUK.checkVersion(CheckVersionConditionAlways(), newRelease: { newVersion, releaseNotes in
            ReleaseNotesController.show(from: self, text: releaseNotes, version: newVersion)
        }) {
            SUK.requestReview(RequestReviewConditionAlways())
        }
    }
}
