//
//  Alert.swift
//  SwiftyUpdateKit
//
//  Created by Masaki Ando on 2021/10/08.
//  Copyright © 2021 Hituzi Ando. All rights reserved.
//

import Foundation

#if os(OSX)
import AppKit
#elseif os(iOS)
import UIKit
#endif

#if os(iOS)
extension UIApplication {

    static var keyWindow: UIWindow? {
        UIApplication.shared.windows.filter { $0.isKeyWindow }.first
    }
}

extension UIViewController {
    /// Returns current presented ViewController.
    var topViewController: UIViewController {
        if let viewController = presentedViewController {
            return viewController.topViewController
        }

        return self
    }
}
#endif

open class Alert {

    /// The button click event handler.
    public typealias ActionHandler = () -> ()

    /// Styles to apply to action buttons in an alert.
    public enum ActionStyle {
        /// Apply the default style to the action’s button.
        case `default`
        /// Apply a style that indicates the action cancels the operation and leaves things unchanged.
        case cancel
        /// Apply a style that indicates the action might change or delete data.
        case destructive

        #if os(iOS)
        fileprivate var uiAlertActionStyle: UIAlertAction.Style {
            switch self {
                case .cancel:
                    return .cancel
                case .destructive:
                    return .destructive
                default:
                    return .default
            }
        }
        #endif
    }

    public enum AlertStyle {
        case critical
        case informational
        case warning

        #if os(OSX)
        fileprivate var nsAlertStyle: NSAlert.Style {
            switch self {
                case .critical:
                    return .critical
                case .warning:
                    return .warning
                default:
                    return .informational
            }
        }
        #endif
    }

    /// Shortcut keys to apply to action buttons in an alert.
    public enum ShortcutKey: String {
        /// The return key.
        case returnKey = "\r"
        /// The esc key.
        case esc = "\u{1b}"
        /// The y key. Maybe it means "yes".
        case y = "y"
        /// The n key. Maybe it means "no".
        case n = "n"
        /// The o key. Maybe it means "ok".
        case o = "o"
        /// The c key. Maybe it means "cancel".
        case c = "c"
    }

    #if os(OSX)
    private let alert: NSAlert
    private var firstButtonHandler: ActionHandler?
    private var secondButtonHandler: ActionHandler?
    private var thirdButtonHandler: ActionHandler?
    private var buttonIndex = 0
    #elseif os(iOS)
    private let alert: UIAlertController
    #endif

    /// - Parameters:
    ///   - title: A title of the alert.
    ///   - message: A message of the alert.
    ///   - style: A style of the alert. Ignored if UIKit.
    public init(title: String?, message: String? = nil, style: AlertStyle? = .informational) {
        #if os(OSX)
        alert = NSAlert()
        alert.messageText = title ?? ""
        alert.informativeText = message ?? ""
        alert.alertStyle = style?.nsAlertStyle ?? .informational
        #elseif os(iOS)
        alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        #endif
    }

    /// Adds a button.
    ///
    /// - Parameters:
    ///   - title: A title of the button.
    ///   - style: A style of the button. Ignored if AppKit.
    ///   - shortcutKey: Assigns the shortcut key to the button if given. Ignored if UIKit.
    ///   - handler: A click event handler.
    /// - Returns: Self.
    @discardableResult
    open func addAction(_ title: String,
                        style: ActionStyle? = .default,
                        shortcutKey: ShortcutKey? = nil,
                        handler: ActionHandler? = nil) -> Self {
        #if os(OSX)
        if buttonIndex == 0 {
            alert.addButton(withTitle: title)
            firstButtonHandler = handler
            if let key = shortcutKey {
                alert.buttons[0].keyEquivalent = key.rawValue
            }
            buttonIndex += 1
        }
        else if buttonIndex == 1 {
            alert.addButton(withTitle: title)
            secondButtonHandler = handler
            if let key = shortcutKey {
                alert.buttons[1].keyEquivalent = key.rawValue
            }
            buttonIndex += 1
        }
        else if buttonIndex == 2 {
            alert.addButton(withTitle: title)
            thirdButtonHandler = handler
            if let key = shortcutKey {
                alert.buttons[2].keyEquivalent = key.rawValue
            }
            buttonIndex += 1
        }
        else {
            fatalError("The alert can have up to 3 buttons.")
        }
        #elseif os(iOS)
        alert.addAction(UIAlertAction(title: title, style: style?.uiAlertActionStyle ?? .default) { _ in
            handler?()
        })
        #endif
        return self
    }

    /// Shows the alert.
    open func showAsModal() {
        #if os(OSX)
        let response = alert.runModal()
        switch response {
            case .alertFirstButtonReturn:
                firstButtonHandler?()
            case .alertSecondButtonReturn:
                secondButtonHandler?()
            case .alertThirdButtonReturn:
                thirdButtonHandler?()
            default:
                break
        }
        #elseif os(iOS)
        UIApplication.keyWindow?
            .rootViewController?
            .topViewController
            .present(alert, animated: true)
        #endif
    }
}
