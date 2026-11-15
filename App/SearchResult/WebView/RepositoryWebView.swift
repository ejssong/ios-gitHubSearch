import ComposableArchitecture
import SwiftUI
import WebKit

/// 저장소 페이지를 `WKWebView` 로 보여준다. `NavigationStack` 에 push 해서 쓴다.
struct RepositoryWebView: View {
  let store: StoreOf<RepositoryWebFeature>

  init(store: StoreOf<RepositoryWebFeature>) {
    self.store = store
  }

  var body: some View {
    WebView(
      url: store.url,
      onLoadStarted: { store.send(.pageLoadStarted) },
      onLoadFinished: { store.send(.pageLoadFinished) }
    )
    .ignoresSafeArea(edges: .bottom)
    .overlay {
      if store.isLoading {
        ProgressView()
      }
    }
    .navigationTitle(store.title)
    .navigationBarTitleDisplayMode(.inline)
  }
}

/// `WKWebView` 를 SwiftUI 에서 쓰기 위한 래퍼. 불러오기의 시작과 끝만 밖으로 알린다.
private struct WebView: UIViewRepresentable {
  let url: URL
  let onLoadStarted: () -> Void
  let onLoadFinished: () -> Void

  func makeCoordinator() -> Coordinator {
    Coordinator(onLoadStarted: onLoadStarted, onLoadFinished: onLoadFinished)
  }

  func makeUIView(context: Context) -> WKWebView {
    let webView = WKWebView()
    webView.navigationDelegate = context.coordinator
    webView.load(URLRequest(url: url))
    return webView
  }

  // 주소는 화면이 만들어질 때 한 번 정해지므로 다시 불러올 것이 없다.
  func updateUIView(_ webView: WKWebView, context: Context) {}

  /// 화면이 닫힌 뒤에는 알릴 상태가 없다. 늦게 오는 콜백이 닫힌 화면으로 액션을 보내지 않게 끊는다.
  static func dismantleUIView(_ webView: WKWebView, coordinator: Coordinator) {
    webView.navigationDelegate = nil
    webView.stopLoading()
  }

  final class Coordinator: NSObject, WKNavigationDelegate {
    private let onLoadStarted: () -> Void
    private let onLoadFinished: () -> Void

    init(onLoadStarted: @escaping () -> Void, onLoadFinished: @escaping () -> Void) {
      self.onLoadStarted = onLoadStarted
      self.onLoadFinished = onLoadFinished
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
      report(webView)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
      report(webView)
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
      report(webView)
    }

    func webView(
      _ webView: WKWebView,
      didFailProvisionalNavigation navigation: WKNavigation!,
      withError error: Error
    ) {
      report(webView)
    }

    /// 웹 콘텐츠 프로세스가 죽으면 완료나 실패가 오지 않으므로 여기서 로딩을 끝낸다.
    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
      onLoadFinished()
    }

    /// 어떤 콜백이 왔는지가 아니라 웹뷰의 지금 상태를 알린다.
    /// 링크를 연달아 누르면 취소된 앞 이동의 실패가 새 이동의 시작보다 늦게 올 수 있기 때문이다.
    private func report(_ webView: WKWebView) {
      if webView.isLoading {
        onLoadStarted()
      } else {
        onLoadFinished()
      }
    }
  }
}
