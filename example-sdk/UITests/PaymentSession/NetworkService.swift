// Copyright (c) 2020–2021 Payoneer Germany GmbH
// https://www.optile.net
//
// This file is open source and available under the MIT license.
// See the LICENSE file for more information.

import Foundation

/// Class responsible for sending network requests.
class NetworkService {
    typealias RequestCompletionHandler = (Result<Data?, Error>) -> Void

    func send(request: URLRequest, completionHandler: @escaping ((Result<Data?, Error>) -> Void)) {
        // Send a network request
        let task = URLSession.shared.dataTask(with: request) { [handleDataTaskResponse] (data, response, error) in
            handleDataTaskResponse(data, response, error, completionHandler)
        }

        task.resume()
    }

    // MARK: - Helper methods

    private func handleDataTaskResponse(data: Data?, response: URLResponse?, error: Error?, completionHandler: @escaping RequestCompletionHandler) {
        // HTTP Errors
        if let error = error {
            completionHandler(.failure(error))
            return
        }

        guard let response = response else {
            let error = NetworkError(description: "Incorrect completion from a URLSession, we have no error and no response")
            completionHandler(.failure(error))
            return
        }

        // We expect HTTP response
        guard let httpResponse = response as? HTTPURLResponse else {
            let error = NetworkError(description: "Unexpected server response (receive a non-HTTP response)")
            completionHandler(.failure(error))
            return
        }

        // - TODO: Read more about backend's status codes
        guard httpResponse.statusCode >= 200, httpResponse.statusCode < 400 else {
            let error = NetworkError(description: "Non-OK response from a server")
                completionHandler(.failure(error))
            return
        }

        completionHandler(.success(data))
    }
}

private struct NetworkError: LocalizedError {
    var errorDescription: String?

    init(description: String) {
        self.errorDescription = description
    }
}
