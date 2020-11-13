// Copyright (c) 2020 optile GmbH
// https://www.optile.net
//
// This file is open source and available under the MIT license.
// See the LICENSE file for more information.

import XCTest

func XCTFail(_ error: Error, file: StaticString = #file, line: UInt = #line) {
    XCTFail(String(describing: error), file: file, line: line)
}
