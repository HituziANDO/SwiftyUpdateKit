//
//  ReleaseNotesController.swift
//  SwiftyUpdateKit
//
//  Created by Masaki Ando on 2021/10/10.
//  Copyright © 2021 Hituzi Ando. All rights reserved.
//

#if os(OSX)
import AppKit
#elseif os(iOS)
import UIKit
#endif

#if os(OSX)
class VisualEffectView: NSVisualEffectView {

    override var isFlipped: Bool {
        true
    }
}

public class ReleaseNotesController: NSViewController {

    private let scrollView = NSTextView.scrollableTextView()

    private lazy var textView: NSTextView = {
        let view = scrollView.documentView as! NSTextView
        view.isEditable = false
        view.isSelectable = false
        view.backgroundColor = .clear
        view.textColor = .textColor
        view.textContainerInset = CGSize(width: 48, height: 8)
        return view
    }()

    private lazy var titleLabel: NSTextField = {
        let view = NSTextField(labelWithString: "")
        view.font = .systemFont(ofSize: 24, weight: .bold)
        view.textColor = .textColor
        return view
    }()

    private lazy var versionLabel: NSTextField = {
        let view = NSTextField(labelWithString: "")
        view.font = .systemFont(ofSize: 16, weight: .bold)
        view.textColor = .textColor
        return view
    }()

    private let windowSize: CGSize
    private let pageTitle: String
    /// The release notes.
    private let text: String
    /// Latest version of the app.
    private let version: String?

    init(windowSize: CGSize, title: String, text: String, version: String?) {
        self.windowSize = windowSize
        self.pageTitle = title
        self.text = text
        self.version = version

        super.init(nibName: nil, bundle: nil)

        // Creates the view of this view controller as root view.
        view = VisualEffectView(frame: CGRect(origin: .zero, size: windowSize))
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.textBackgroundColor.cgColor
        (view as? VisualEffectView)?.blendingMode = .behindWindow
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
    }

    public override func viewWillAppear() {
        super.viewWillAppear()

        // Fixed window and the title bar is hidden.
        view.window?.minSize = windowSize
        view.window?.maxSize = windowSize
        view.window?.titlebarAppearsTransparent = true
        view.window?.titleVisibility = .hidden
        view.window?.styleMask = [.fullSizeContentView, .titled, .closable]

        titleLabel.stringValue = pageTitle
        versionLabel.stringValue = version?.isEmpty == false ? "ver.\(version!)" : ""
        textView.string = text

        // Must set the frame and addSubview in viewWillAppear to show the subview.
        titleLabel.sizeToFit()
        versionLabel.sizeToFit()
        titleLabel.frame.origin = CGPoint(x: 24, y: 40)
        versionLabel.frame.origin = CGPoint(x: 24, y: titleLabel.frame.maxY + 16)
        scrollView.frame = CGRect(x: 0,
                                  y: versionLabel.frame.maxY + 8,
                                  width: windowSize.width,
                                  height: windowSize.height - (versionLabel.frame.maxY + 8))
        view.addSubview(scrollView)
        view.addSubview(versionLabel)
        view.addSubview(titleLabel)
    }

    /// Shows the release notes to a user when new app version is installed.
    ///
    /// - Parameters:
    ///   - rootViewController: A parent view controller presents this view controller.
    ///   - text: Release notes.
    ///   - title: A title. Default value of this argument is "Release Notes".
    ///   - version: new app version.
    ///   - windowSize: A window size. Default value of this argument is (480, 320).
    public static func show(from rootViewController: NSViewController,
                            text: String?,
                            title: String = "Release Notes",
                            version: String? = nil,
                            windowSize: CGSize = CGSize(width: 480, height: 320)) {
        let viewController = ReleaseNotesController(windowSize: windowSize,
                                                    title: title,
                                                    text: text ?? "",
                                                    version: version)
        rootViewController.presentAsModalWindow(viewController)
    }
}
#elseif os(iOS)
public class ReleaseNotesController: UIViewController {

    public override func loadView() {
        view = UIVisualEffectView()
    }
}
#endif
