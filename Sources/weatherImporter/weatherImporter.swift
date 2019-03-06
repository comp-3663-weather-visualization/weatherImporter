
import Foundation

extension String: Error { }


private let session: URLSession = {
    let ses = URLSession(configuration: .ephemeral)
    ses.configuration.httpMaximumConnectionsPerHost = 4
    return ses
}()

final class WebService {


    func load(_ request: URLRequest) -> Future<Data> {

        return Future { completion in

            session.dataTask(with: request, completionHandler: { data, resp , _ in

                guard let data = data else {
                    completion(.error("No data"))
                    return
                }

                if let resp = resp as? HTTPURLResponse, resp.statusCode != 200 {
                    completion(Result(data, or: "Status Code: \(resp.statusCode)"))
                    return
                }

                completion(Result(data, or: "Couldn't parse data"))
            }).resume()
        }
    }
}

final class Future<A>: FutureType {
    typealias Expectation = A
    private var awaiters: [(Result<A>) -> ()] = []
    private var cached: Result<A>?

    init(compute: (@escaping (Result<A>) -> ()) -> ()) {
        compute(send)
    }

    private func send(_ value: Result<A>) {
        assert(cached == nil, "Futures emit only one value")
        DispatchQueue.main.async {
            self.cached = value
            for callback in self.awaiters {
                callback(value)
            }

            self.awaiters = []
        }
    }

    func await(_ callback: @escaping (Result<A>) -> ()) {
        if let value = cached {
            callback(value)
        } else {
            awaiters.append(callback)
        }
    }

    static func pure<B>(_ a: B) -> Future<B> {
        return Future<B> { f in
            f(Result<B>.success(a))
        }
    }
}

/// Run
extension Future {

    func run(onSuccess: @escaping (A) -> (),
             onFailure: @escaping (Error) -> ()) {
        await { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let result): onSuccess(result)
                case .error(let error): onFailure(error)
                }
            }
        }
    }

    func run(onSuccess: @escaping (A) -> (),
             onFailure: @escaping (Error) -> (),
             always: @escaping () -> ()) {
        await { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let result): onSuccess(result)
                case .error(let error):
                    onFailure(error)
                }
                always()
            }
        }
    }
}

protocol FutureType {
    associatedtype Expectation
    func await(_ callback: @escaping (Result<Expectation>) -> ())
}

/// Flatten
extension Array where Element: FutureType {

    func flatten() -> Future<[Element.Expectation]> {
        var expectations: [Element.Expectation] = []
        return Future<[Element.Expectation]> { f in
            self.forEach { future in
                future.await { result in
                    switch result {
                    case .success(let expection): expectations.append(expection)
                    if self.count == expectations.count {
                        f(Result<[Element.Expectation]>.success(expectations))
                        }
                    case .error(let error):
                        f(Result<[Element.Expectation]>.error(error))
                    }
                }
            }

        }
    }

}


/// Monad
extension Future {

    func map<B>(_ transform: @escaping (A) -> B) -> Future<B> {
        return Future<B> { completion in
            self.await { result in
                switch result {
                case .success(let value):
                    completion(Result.success(transform(value)))
                case .error(let error):
                    completion(.error(error))
                }
            }
        }
    }


    func flatMap<B>(_ transform: @escaping (A) -> Future<B>) -> Future<B> {
        return Future<B> { completion in
            self.await { result in
                switch result {
                case .success(let value):
                    transform(value).await(completion)
                case .error(let error):
                    completion(.error(error))
                }
            }
        }
    }

}

enum Result<A> {
    case success(A)
    case error(Error)

    init(_ value: A?, or error: Error) {
        if let value = value {
            self = .success(value)
        } else {
            self = .error(error)
        }
    }

    init(_ f: () throws -> A) {
        do {
            self = .success(try f())
        } catch {
            self = .error(error)
        }
    }

    static func wrap<B>(_ f: @escaping (B) throws -> A) -> (B) -> Result {
        return { b in
            do {
                return .success(try f(b))
            } catch {
                return .error(error)
            }
        }
    }
}

extension Result {

    func onError(_ errorHandler: (Error) -> ()) {
        switch self {
        case .success: return
        case .error(let error): return errorHandler(error)
        }
    }

}

extension Result {

    @discardableResult
    func map<B>(_ transform: (A) -> B) -> Result<B> {
        switch self {
        case .success(let value): return .success(transform(value))
        case .error(let error): return .error(error)
        }
    }

    @discardableResult
    func flatMap<B>(_ transform: (A) -> Result<B>) -> Result<B> {
        switch self {
        case .success(let value): return transform(value)
        case .error(let error): return .error(error)
        }
    }

}
