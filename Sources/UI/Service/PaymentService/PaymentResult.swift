import Foundation

/// Class contains payment result, `operationResult` or `errorInfo` is always present (one of them).
@objc public class PaymentResult: NSObject {
    public var operationResult: OperationResult? {
        guard case let .success(unwrappedOperationResult) = result else {
            return nil
        }
        
        return unwrappedOperationResult
    }
    
    public var errorInfo: ErrorInfo? {
        guard case let .failure(error) = result else {
            return nil
        }
        
        return error
    }
    
    /// Contains value if something went wrong inside framework. In the most cases it would contain `InternalError` type.
    public var cause: Error? {
        return (errorInfo as? CustomErrorInfo)?.underlyingError
    }
    
    /// A reference to `Interaction` object inside `operationResult` or `errorInfo`.
    public var interaction: Interaction { result.interaction }

    // MARK: Internal
    
    private let result: Result<OperationResult, ErrorInfo>

    internal init(operationResult: Result<OperationResult, ErrorInfo>) {
        self.result = operationResult
    }
}
