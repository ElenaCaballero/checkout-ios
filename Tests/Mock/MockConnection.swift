// Copyright (c) 2020 optile GmbH
// https://www.optile.net
//
// This file is open source and available under the MIT license.
// See the LICENSE file for more information.

import Foundation
import Optile

class MockConnection: Connection {
    private let serialQueue = DispatchQueue(label: "Mock connection serial queue")
    private(set) var requestedURL: URL?
    let dataSource: MockDataSource

    init(dataSource: MockDataSource) {
        self.dataSource = dataSource
    }

    func send(request: URLRequest, completionHandler: @escaping ((Result<Data?, Error>) -> Void)) {
        serialQueue.sync(flags: .barrier) {
            self.requestedURL = request.url!
        }

        completionHandler(dataSource.fakeData(for: request))
    }

    func cancel() {}
}
