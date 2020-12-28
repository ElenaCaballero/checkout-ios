// Copyright (c) 2020 optile GmbH
// https://www.optile.net
//
// This file is open source and available under the MIT license.
// See the LICENSE file for more information.

import Foundation

class InstallmentItem: NSObject, Decodable {
    /// An amount of this installment in major units.
    let amount: Double?

    /// An installment (or payment) date.
    let date: String?
}
