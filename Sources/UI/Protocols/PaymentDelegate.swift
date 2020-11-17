// Copyright (c) 2020 optile GmbH
// https://www.optile.net
//
// This file is open source and available under the MIT license.
// See the LICENSE file for more information.

import Foundation

public protocol PaymentDelegate: class {
    func paymentService(didReceivePaymentResult paymentResult: PaymentResult)
    func paymentViewControllerWillDismiss()
    func paymentViewControllerDidDismiss()
}

public extension PaymentDelegate {
    func paymentViewControllerWillDismiss() {}
    func paymentViewControllerDidDismiss() {}
}
