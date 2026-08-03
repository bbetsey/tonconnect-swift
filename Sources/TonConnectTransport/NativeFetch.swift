import Foundation

/// The fetch result — the minimum the SDK reads.
public struct FetchResponse: Sendable {
    public let ok: Bool // 200..<300
    public let status: Int
}

/// The cancellation handle — the polyfill wires it to a JS AbortSignal. Pure Swift.
public final class NativeFetchTask: @unchecked Sendable {
    private let task: URLSessionDataTask
    init(_ task: URLSessionDataTask) { self.task = task }
    public func cancel() { task.cancel() }
}

/// POST via URLSession. No headers/streaming/response-body parsing — the SDK
/// reads only response.ok/.status. A URLSession error is
/// carried into the completion as .failure → the polyfill maps it to TonConnectError.network.
public final class NativeFetch: @unchecked Sendable {
    private let session: URLSession
    public init(session: URLSession = URLSession(configuration: .ephemeral)) {
        self.session = session
    }

    /// Posts `body` and reports only what the caller needs: whether the request
    /// was accepted and its status code. The returned handle cancels it.
    @discardableResult
    public func post(
        url: String,
        body: Data,
        completion: @escaping (Result<FetchResponse, Error>) -> Void
    ) -> NativeFetchTask {
        guard let parsed = URL(string: url) else {
            completion(.failure(URLError(.badURL)))
            return NativeFetchTask(session.dataTask(with: URLRequest(url: URL(string: "about:blank")!)))
        }
        var request = URLRequest(url: parsed)
        request.httpMethod = "POST"
        // Browser-fetch parity: fetch with a string body defaults to
        // text/plain;charset=UTF-8, and the JS SDK relied on that. Without an
        // explicit header URLSession injects application/x-www-form-urlencoded,
        // which Tonhub's bridge rejects with HTTP 415 (observed on a live wallet).
        request.setValue("text/plain;charset=UTF-8", forHTTPHeaderField: "Content-Type")
        request.httpBody = body
        let task = session.dataTask(with: request) { _, response, error in
            if let error = error {
                completion(.failure(error)); return
            }
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            completion(.success(FetchResponse(ok: (200..<300).contains(status), status: status)))
        }
        task.resume()
        return NativeFetchTask(task)
    }
}
