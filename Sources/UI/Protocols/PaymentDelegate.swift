// Copyright (c) 2020 optile GmbH
// https://www.optile.net
//
// This file is open source and available under the MIT license.
// See the LICENSE file for more information.

import Foundation

/// A protocol used to implement event handling for payment service events.
public protocol PaymentDelegate: class {
    /// Method is called when payment result was received, you should handle a payment result and dismiss a view manually
    /// - Parameters:
    ///   - controller: payment view controller, it should be dismissed
    func paymentService(didReceivePaymentResult paymentResult: PaymentResult, viewController: List.ViewController)
}
