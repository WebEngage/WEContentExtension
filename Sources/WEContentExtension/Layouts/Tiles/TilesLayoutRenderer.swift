//
//  TilesLayoutRenderer.swift
//
//
//  Created by Shubham Naidu on 2025.
//

import Foundation
import UIKit

extension WEXTilesPushNotificationViewController {

    func setupTilesView() {
        guard let view = view else { return }

        view.backgroundColor = .clear
        view.isOpaque = false
        viewController?.view.backgroundColor = .clear
        viewController?.view.isOpaque = false

        setupBackground(on: view)

        let tileSize: CGFloat = 60
        let itemCount = min(tileItems.count, 5)
        let hasBgImage = hasBackgroundImage

        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.backgroundColor = .clear
        container.isOpaque = false
        view.addSubview(container)

        NSLayoutConstraint.activate([
            container.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            container.topAnchor.constraint(equalTo: view.topAnchor, constant: 12),
            container.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -12),
            container.heightAnchor.constraint(equalToConstant: tileSize)
        ])

        // Create spacer views and tile buttons for equal spacing pattern:
        // [spacer][tile][spacer][tile][spacer]...[spacer]
        var spacers: [UIView] = []
        var buttons: [UIButton] = []

        for index in 0..<itemCount {
            let item = tileItems[index]

            // Leading spacer
            let leadingSpacer = UIView()
            leadingSpacer.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview(leadingSpacer)
            spacers.append(leadingSpacer)

            let button = UIButton(type: .custom)
            button.tag = index
            button.translatesAutoresizingMaskIntoConstraints = false
            button.clipsToBounds = true
            button.backgroundColor = .clear
            button.isOpaque = false
            button.addTarget(self, action: #selector(tileTapped(_:)), for: .touchUpInside)
            container.addSubview(button)
            buttons.append(button)

            let imageView = UIImageView()
            imageView.contentMode = .scaleAspectFill
            imageView.clipsToBounds = true
            imageView.translatesAutoresizingMaskIntoConstraints = false
            imageView.isUserInteractionEnabled = false
            imageView.backgroundColor = .clear
            imageView.isOpaque = false
            button.addSubview(imageView)

            NSLayoutConstraint.activate([
                imageView.topAnchor.constraint(equalTo: button.topAnchor),
                imageView.bottomAnchor.constraint(equalTo: button.bottomAnchor),
                imageView.leadingAnchor.constraint(equalTo: button.leadingAnchor),
                imageView.trailingAnchor.constraint(equalTo: button.trailingAnchor),
                button.widthAnchor.constraint(equalToConstant: tileSize),
                button.heightAnchor.constraint(equalToConstant: tileSize),
                button.centerYAnchor.constraint(equalTo: container.centerYAnchor)
            ])

            loadTileImage(for: index, item: item, into: imageView, hasBgImage: hasBgImage)
        }

        // Trailing spacer
        let trailingSpacer = UIView()
        trailingSpacer.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(trailingSpacer)
        spacers.append(trailingSpacer)

        // Layout: [spacer0][button0][spacer1][button1]...[spacerN]
        // First spacer leading = container leading
        spacers[0].leadingAnchor.constraint(equalTo: container.leadingAnchor).isActive = true

        for i in 0..<itemCount {
            // button leading = spacer[i] trailing
            buttons[i].leadingAnchor.constraint(equalTo: spacers[i].trailingAnchor).isActive = true
            // spacer[i+1] leading = button[i] trailing
            spacers[i + 1].leadingAnchor.constraint(equalTo: buttons[i].trailingAnchor).isActive = true
        }

        // Last spacer trailing = container trailing
        if let lastSpacer = spacers.last {
            lastSpacer.trailingAnchor.constraint(equalTo: container.trailingAnchor).isActive = true
        }

        // All spacers equal width
        for i in 1..<spacers.count {
            spacers[i].widthAnchor.constraint(equalTo: spacers[0].widthAnchor).isActive = true
        }

        // Spacers need height constraint (can be 0, they're just for spacing)
        for spacer in spacers {
            spacer.heightAnchor.constraint(equalToConstant: 1).isActive = true
            spacer.centerYAnchor.constraint(equalTo: container.centerYAnchor).isActive = true
        }

        viewController?.view.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
    }

    // MARK: - Background

    private var hasBackgroundImage: Bool {
        guard let expandableDetails = notification?.request.content.userInfo[WEConstants.EXPANDABLEDETAILS] as? [String: Any],
              let bgImageURL = expandableDetails[WEConstants.IMAGE] as? String, !bgImageURL.isEmpty else {
            return false
        }
        return true
    }

    private func setupBackground(on view: UIView) {
        guard let expandableDetails = notification?.request.content.userInfo[WEConstants.EXPANDABLEDETAILS] as? [String: Any] else { return }

        if let bgImageURL = expandableDetails[WEConstants.IMAGE] as? String, !bgImageURL.isEmpty {
            let bgImageView = UIImageView()
            bgImageView.contentMode = .scaleAspectFill
            bgImageView.clipsToBounds = true
            bgImageView.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(bgImageView)

            NSLayoutConstraint.activate([
                bgImageView.topAnchor.constraint(equalTo: view.topAnchor),
                bgImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                bgImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                bgImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
            ])

            // Background is always stored at attachment index "0" when present
            if let attachments = notification?.request.content.attachments,
               let attachment = attachments.first(where: { $0.identifier == "0" }),
               attachment.url.startAccessingSecurityScopedResource() {
                if let data = try? Data(contentsOf: attachment.url),
                   let image = UIImage(data: data) {
                    bgImageView.image = image
                }
                attachment.url.stopAccessingSecurityScopedResource()
            }
        } else if let colorHex = expandableDetails[WEConstants.BACKCOLOR] as? String, !colorHex.isEmpty {
            if #available(iOS 13.0, *) {
                view.backgroundColor = UIColor.colorFromHexString(colorHex, defaultColor: .clear)
            }
        } else {
            view.backgroundColor = .clear
        }
    }

    // MARK: - Tile Image Loading

    private func loadTileImage(for index: Int, item: [String: Any], into imageView: UIImageView, hasBgImage: Bool) {
        let attachmentIndex = hasBgImage ? index + 1 : index

        if let attachments = notification?.request.content.attachments,
           let attachment = attachments.first(where: { $0.identifier == "\(attachmentIndex)" }),
           attachment.url.startAccessingSecurityScopedResource() {
            defer { attachment.url.stopAccessingSecurityScopedResource() }
            if let data = try? Data(contentsOf: attachment.url),
               let image = UIImage.animatedImageWithAnimatedGIF(data: data) ?? UIImage(data: data) {
                imageView.image = image
            }
        }
    }
}
