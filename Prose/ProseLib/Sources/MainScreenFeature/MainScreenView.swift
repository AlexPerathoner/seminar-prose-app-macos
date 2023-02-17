import AddressBookFeature
import AppDomain
import Assets
import ComposableArchitecture
import ConversationFeature
import PasteboardClient
import ProseCoreTCA
import SidebarFeature
import SwiftUI
import TcaHelpers
import Toolbox
import UnreadFeature

public struct MainScreenView: View {
  private let store: StoreOf<MainScreen>
  @ObservedObject private var viewStore: ViewStore<SessionState<None>, Never>

  // swiftlint:disable:next type_contents_order
  public init(store: StoreOf<MainScreen>) {
    self.store = store
    self.viewStore = ViewStore(
      store.scope(state: { $0.get { _ in .none } }).actionless
    )
  }

  public var body: some View {
    NavigationView {
      SidebarView(store: self.store
        .scope(state: \.scoped.sidebar, action: MainScreen.Action.sidebar))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("Sidebar")

      ZStack(alignment: .top) {
        SwitchStore(self.store.scope(state: \.route)) {
          CaseLet(
            state: /MainScreen.Route.unreadStack,
            action: MainScreen.Action.unreadStack,
            then: UnreadScreen.init(store:)
          )
          CaseLet(
            state: { route in
              CasePath(MainScreen.Route.chat).extract(from: route)
                .map { state in
                  self.viewStore.state.get { _ in state }
                }
            },
            action: MainScreen.Action.chat,
            then: ConversationScreen.init(store:)
          )
          Default {
            Text("Not implemented.")
          }
        }

        if let account = viewStore.selectedAccount, account.status != .connected {
          OfflineBanner(account: account)
        }
      }
      .accessibilityElement(children: .contain)
      .accessibilityIdentifier("MainContent")
    }
  }
}

#warning("Localize me")
struct OfflineBanner: View {
  var account: Account

  var body: some View {
    HStack {
      Image(systemName: "hazardsign.fill")
      Text("You are offline")
      Text("New messages will not appear, drafts will be saved for later.")
        .opacity(0.55)
        .font(.callout)
      Spacer()
      Button(action: {}) {
        Text("Reconnect")
        if account.status == .connecting {
          ProgressView().controlSize(.mini)
        }
      }.disabled(account.status == .connecting)
    }
    .frame(maxWidth: .infinity)
    .padding()
    .background(Colors.State.coolGrey.color)
  }
}

#if DEBUG
  struct OfflineBanner_Previews: PreviewProvider {
    static var previews: some View {
      OfflineBanner(account: .init(jid: "hello@prose.org", status: .connected))
    }
  }
#endif
