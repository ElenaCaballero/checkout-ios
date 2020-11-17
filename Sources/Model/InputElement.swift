// Copyright (c) 2020 optile GmbH
// https://www.optile.net
//
// This file is open source and available under the MIT license.
// See the LICENSE file for more information.

import Foundation

public class InputElement: NSObject, Decodable {
    /// The name of the parameter represented by this input element.
    public let name: String

    /// Input type / restrictions that can and should be enforced by the client for this input element.
    ///
    /// Possible values: `string`, `numeric`, `integer`, `select`, `checkbox`
    public let type: String

    /// Array of possible options for element of the `select` type.
    public let options: [SelectOption]?

    // MARK: - Enumerations

    public var inputElementType: InputElementType? { InputElementType(rawValue: type) }

    public enum InputElementType: String, Decodable {
        case string, numeric, integer, select, checkbox
    }

    internal init(name: String, type: String, options: [SelectOption]? = nil) {
        self.name = name
        self.type = type
        self.options = options
    }
}
