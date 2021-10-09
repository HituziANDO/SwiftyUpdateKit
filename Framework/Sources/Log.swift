//
//  Log.swift
//  SwiftyUpdateKit
//
//  Created by Masaki Ando on 2021/10/08.
//  Copyright © 2021 Hituzi Ando. All rights reserved.
//

import Foundation

/// The log closure.
///
/// ```
/// let log: Log = { message in
///     // Use `print` function or any logger.
///     print(message)
/// }
/// ```
public typealias Log = (_ message: Any) -> ()

func logf(_ message: String, _ log: Log?) {
    log?("[SwiftyUpdateKit] \(message)")
}
