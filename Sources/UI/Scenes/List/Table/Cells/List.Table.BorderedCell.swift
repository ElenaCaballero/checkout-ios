// Copyright (c) 2020 optile GmbH
// https://www.optile.net
//
// This file is open source and available under the MIT license.
// See the LICENSE file for more information.

#if canImport(UIKit)
import Foundation
import UIKit

extension List.Table {
    class BorderedCell: UITableViewCell {
        weak var leftBorder: UIView?
        weak var rightBorder: UIView?
        weak var topBorder: UIView?
        weak var bottomBorder: UIView?

        var cellIndex: CellIndex = .middle {
            didSet { cellIndexDidChange() }
        }

        enum CellIndex {
            case first
            case middle
            case last
        }

        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)

            addBordersViews()
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}

// MARK: - Views

extension List.Table.BorderedCell {
    fileprivate func cellIndexDidChange() {
        switch cellIndex {
        case .first, .middle: bottomBorder?.isHidden = true
        case .last: bottomBorder?.isHidden = false
        }
    }
    
    /// Add border views.
    /// - Description: we create 2 rectangles, outer rectangle will have a border background color, inner background will have a normal background color and it will have 1px spacing between outer one. Result will be a border that we could round.
    // I think it's the best way to create a rounded border around section's content and use dynamic constraints instead of frame calculations. It's iOS10+ way, if requirements will be iOS11+ that could be done easier with `maskedCorners`.
    fileprivate func addBordersViews() {
        let leftBorder = UIView(frame: .zero)
        self.leftBorder = leftBorder

        let rightBorder = UIView(frame: .zero)
        self.rightBorder = rightBorder
        
        let topBorder = UIView(frame: .zero)
        self.topBorder = topBorder
        
        let bottomBorder = UIView(frame: .zero)
        self.bottomBorder = bottomBorder
        bottomBorder.isHidden = true

        for border in [leftBorder, rightBorder, topBorder, bottomBorder] {
            border.translatesAutoresizingMaskIntoConstraints = false
            border.backgroundColor = .red
            addSubview(border)
        }

        NSLayoutConstraint.activate([
            leftBorder.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            leftBorder.topAnchor.constraint(equalTo: topAnchor),
            leftBorder.bottomAnchor.constraint(equalTo: bottomAnchor),
            leftBorder.widthAnchor.constraint(equalToConstant: .separatorWidth),

            rightBorder.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            rightBorder.topAnchor.constraint(equalTo: topAnchor),
            rightBorder.bottomAnchor.constraint(equalTo: bottomAnchor),
            rightBorder.widthAnchor.constraint(equalToConstant: .separatorWidth),
            
            topBorder.topAnchor.constraint(equalTo: topAnchor),
            topBorder.leadingAnchor.constraint(equalTo: leftBorder.leadingAnchor),
            topBorder.trailingAnchor.constraint(equalTo: rightBorder.trailingAnchor),
            topBorder.heightAnchor.constraint(equalToConstant: .separatorWidth),
            
            bottomBorder.bottomAnchor.constraint(equalTo: bottomAnchor),
            bottomBorder.leadingAnchor.constraint(equalTo: leftBorder.leadingAnchor),
            bottomBorder.trailingAnchor.constraint(equalTo: rightBorder.trailingAnchor),
            bottomBorder.heightAnchor.constraint(equalToConstant: .separatorWidth)
        ])

        addSelectedBackgroundView()
    }

    private func addSelectedBackgroundView() {
        let selectedBackgroundView = UIView(frame: .zero)
        selectedBackgroundView.backgroundColor = .clear
        self.selectedBackgroundView = selectedBackgroundView

        let viewWithPaddings = UIView(frame: .zero)
        viewWithPaddings.backgroundColor = .themedTableCellSeparator
        selectedBackgroundView.addSubview(viewWithPaddings)

        viewWithPaddings.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            viewWithPaddings.leadingAnchor.constraint(equalTo: selectedBackgroundView.leadingAnchor),
            viewWithPaddings.topAnchor.constraint(equalTo: selectedBackgroundView.topAnchor),
            // Have to be the same as outer's view bottom anchor constant
            viewWithPaddings.bottomAnchor.constraint(equalTo: selectedBackgroundView.bottomAnchor, constant: 1),
            viewWithPaddings.trailingAnchor.constraint(equalTo: selectedBackgroundView.trailingAnchor)
        ])
    }
}

// MARK: - Constants

private extension CGFloat {
    static var separatorWidth: CGFloat { return 1 }
    static var cornerRadius: CGFloat { return 2 }
}
#endif
