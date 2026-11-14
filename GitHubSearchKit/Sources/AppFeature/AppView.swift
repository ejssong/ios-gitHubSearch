import ComposableArchitecture
import SwiftUI

public struct AppView: View {
  let store: StoreOf<AppFeature>

  public init(store: StoreOf<AppFeature>) {
    self.store = store
  }

  public var body: some View {
    NavigationStack {
      Text("GitHub Search")
        .navigationTitle("GitHub Search")
    }
  }
}
