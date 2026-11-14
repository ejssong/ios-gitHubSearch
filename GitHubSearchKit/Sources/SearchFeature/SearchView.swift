import ComposableArchitecture
import SwiftUI

public struct SearchView: View {
  let store: StoreOf<SearchFeature>

  public init(store: StoreOf<SearchFeature>) {
    self.store = store
  }

  public var body: some View {
    Color.clear
  }
}
