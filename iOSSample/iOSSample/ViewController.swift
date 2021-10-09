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

        SUK.checkVersion(CheckVersionConditionAlways())
    }
}
