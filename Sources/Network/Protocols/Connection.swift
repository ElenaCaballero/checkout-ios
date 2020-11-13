// Copyright (c) 2020 optile GmbH
// https://www.optile.net
//
// This file is open source and available under the MIT license.
// See the LICENSE file for more information.

import Foundation

/// Protocol responsible for sending requests, maybe faked when unit testing
public protocol Connection {
    func send(request: URLRequest, completionHandler: @escaping ((Result<Data?, Error>) -> Void))
}
