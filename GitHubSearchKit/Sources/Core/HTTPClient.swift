import Dependencies
import DependenciesMacros
import Foundation

@DependencyClient
public struct HTTPClient: Sendable {
  /// 2xx 면 응답 본문을 돌려주고, 아니면 `HTTPError` 를 던진다.
  public var send: @Sendable (_ request: HTTPRequest) async throws -> Data
}

extension HTTPClient {
  /// `send` 후 JSON 으로 해석한다. 해석할 수 없으면 `HTTPError.unknown`.
  public func send<Response: Decodable>(
    _ request: HTTPRequest,
    as type: Response.Type = Response.self,
    decoder: JSONDecoder = JSONDecoder()
  ) async throws -> Response {
    let data = try await send(request)
    do {
      return try decoder.decode(Response.self, from: data)
    } catch {
      throw HTTPError.unknown
    }
  }
}

extension HTTPClient {
  public static func live(session: URLSession = .shared) -> Self {
    Self(send: { request in
      guard var components = URLComponents(url: request.url, resolvingAgainstBaseURL: false)
      else { throw HTTPError.invalidRequest }
      if !request.queryItems.isEmpty {
        components.queryItems = (components.queryItems ?? []) + request.queryItems
      }
      guard let url = components.url else { throw HTTPError.invalidRequest }

      var urlRequest = URLRequest(url: url)
      for (field, value) in request.headers {
        urlRequest.setValue(value, forHTTPHeaderField: field)
      }

      let data: Data
      let response: URLResponse
      do {
        (data, response) = try await session.data(for: urlRequest)
      } catch let error as URLError where error.code == .cancelled {
        // 취소는 오류가 아니라 취소로 전달해 effect 취소가 그대로 동작하게 한다.
        throw CancellationError()
      } catch is URLError {
        throw HTTPError.network
      } catch is CancellationError {
        throw CancellationError()
      } catch {
        throw HTTPError.unknown
      }

      guard let httpResponse = response as? HTTPURLResponse else { throw HTTPError.unknown }
      let headerFields = Dictionary(
        httpResponse.allHeaderFields.compactMap { key, value in
          (key as? String).map { ($0, "\(value)") }
        },
        uniquingKeysWith: { first, _ in first }
      )
      if let error = HTTPError(statusCode: httpResponse.statusCode, headerFields: headerFields) {
        throw error
      }
      return data
    })
  }
}

extension HTTPClient: DependencyKey {
  public static let liveValue = HTTPClient.live()
  public static let testValue = HTTPClient()
}

extension DependencyValues {
  public var httpClient: HTTPClient {
    get { self[HTTPClient.self] }
    set { self[HTTPClient.self] = newValue }
  }
}
