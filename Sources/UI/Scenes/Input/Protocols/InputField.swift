// Copyright (c) 2020 optile GmbH
// https://www.optile.net
//
// This file is open source and available under the MIT license.
// See the LICENSE file for more information.

import Foundation

/// Generic UI model for input element
protocol InputField: class {
    var name: String { get }
    var value: String { get set }
}

extension InputField where Self: InputElementModel {
    var name: String { inputElement.name }
}
