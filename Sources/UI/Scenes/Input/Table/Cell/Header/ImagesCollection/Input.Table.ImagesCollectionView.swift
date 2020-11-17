// Copyright (c) 2020 optile GmbH
// https://www.optile.net
//
// This file is open source and available under the MIT license.
// See the LICENSE file for more information.

import UIKit

extension Input.Table {
    class ImagesCollectionView: UICollectionView {
        override func reloadData() {
            super.reloadData()

            self.invalidateIntrinsicContentSize()
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            invalidateIntrinsicContentSize()
        }

        override var intrinsicContentSize: CGSize {
            return collectionViewLayout.collectionViewContentSize
        }
    }
}
