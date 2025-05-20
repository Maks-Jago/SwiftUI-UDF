public func unwrapAsync<T>(
    _ expression: @autoclosure () async throws -> T?,
    _ message: @autoclosure () -> String = ""
) async throws -> T {
    let result = try await expression()
    if let value = result {
        return value
    }
    struct UnwrapError: Error, CustomStringConvertible {
        var description: String
    }
    throw UnwrapError(description: message())
}
