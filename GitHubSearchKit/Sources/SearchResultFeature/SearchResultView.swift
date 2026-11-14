import ComposableArchitecture
import SwiftUI

public struct SearchResultView: View {
  let store: StoreOf<SearchResultFeature>

  public init(store: StoreOf<SearchResultFeature>) {
    self.store = store
  }

  public var body: some View {
    Color.clear
  }
}
