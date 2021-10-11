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

class ReleaseNotesController: NSViewController {

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
}
#endif

#if os(iOS)
class CloseButton: UIButton {

    init() {
        super.init(frame: CGRect(x: 0, y: 0, width: 32, height: 32))

        let base64 = "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"
        let data = Data(base64Encoded: base64)!
        let image = UIImage(data: data)?.withRenderingMode(.alwaysTemplate)
        setImage(image, for: .normal)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class ReleaseNotesController: UIViewController {

    private var isDarkMode: Bool {
        UITraitCollection.current.userInterfaceStyle == .dark
    }

    private lazy var textView: UITextView = {
        let view = UITextView()
        view.isEditable = false
        view.isSelectable = false
        view.backgroundColor = .clear
        view.textColor = .label
        view.textContainerInset = UIEdgeInsets(top: 8, left: 24, bottom: 100, right: 24)
        view.font = .systemFont(ofSize: 15, weight: .regular)
        return view
    }()

    private lazy var titleLabel: UILabel = {
        let view = UILabel()
        view.font = .systemFont(ofSize: 28, weight: .bold)
        view.textColor = .label
        return view
    }()

    private lazy var versionLabel: UILabel = {
        let view = UILabel()
        view.font = .systemFont(ofSize: 18, weight: .bold)
        view.textColor = .label
        return view
    }()

    private lazy var effectView: UIVisualEffectView = {
        UIVisualEffectView(effect: UIBlurEffect(style: isDarkMode ? .dark : .extraLight))
    }()

    private lazy var closeButton: CloseButton = {
        let button = CloseButton()
        button.tintColor = isDarkMode ? .white : .black
        button.addTarget(self, action: #selector(close), for: .touchUpInside)
        return button
    }()

    private let pageTitle: String
    /// The release notes.
    private let text: String
    /// Latest version of the app.
    private let version: String?

    init(title: String, text: String, version: String?) {
        self.pageTitle = title
        self.text = text
        self.version = version

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .clear

        titleLabel.text = pageTitle
        versionLabel.text = version?.isEmpty == false ? "ver.\(version!)" : ""

        let style = NSMutableParagraphStyle()
        style.lineSpacing = 10
        textView.attributedText = NSAttributedString(string: text,
                                                     attributes: [.paragraphStyle: style, .font: textView.font!])

        view.addSubview(effectView)
        view.addSubview(textView)
        view.addSubview(versionLabel)
        view.addSubview(titleLabel)
        view.addSubview(closeButton)
    }

    public override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        effectView.frame = view.bounds

        titleLabel.sizeToFit()
        versionLabel.sizeToFit()

        titleLabel.frame.origin = CGPoint(x: 24, y: 56)
        versionLabel.frame.origin = CGPoint(x: 24, y: titleLabel.frame.maxY + 16)
        closeButton.center = CGPoint(x: view.center.x,
                                     y: view.frame.maxY - closeButton.frame.height / 2 - 44)
        textView.frame = CGRect(x: 0,
                                y: versionLabel.frame.maxY + 8,
                                width: view.frame.width,
                                height: view.frame.maxY - (versionLabel.frame.maxY + 8))
    }
}

private extension ReleaseNotesController {

    @objc func close() {
        dismiss(animated: true)
    }
}
#endif
