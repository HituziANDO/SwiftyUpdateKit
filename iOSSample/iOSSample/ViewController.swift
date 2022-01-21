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
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        SUK.checkVersion(VersionCheckConditionAlways(), newRelease: { [weak self] newVersion, releaseNotes, firstUpdated in
            guard let self = self else { return }
            SUK.showReleaseNotes(from: self, text: releaseNotes, version: newVersion) {
                print("Release Notes has been closed.")
            }
        }) {
            SUK.requestReview(RequestReviewConditionAlways())
        }
    }
}
