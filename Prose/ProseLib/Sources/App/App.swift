//
// This file is part of prose-app-macos.
// Copyright (c) 2022 Prose Foundation
//

import AccountBookmarksClient
import AppDomain
import AuthenticationFeature
import Combine
import ComposableArchitecture
import ConnectivityClient
import CredentialsClient
import Foundation
import MainScreenFeature
import NotificationsClient
import ProseCoreTCA
import struct ProseCoreTCA.ProseClient
import Toolbox

private extension BareJid {
  static let placeholder = BareJid(node: "placeholder", domain: "prose.org")
}

struct App: ReducerProtocol {
  struct State: Equatable {
    var initialized = false
    var connectivity = Connectivity.online

    var currentUser = BareJid.placeholder
    var availableAccounts = IdentifiedArrayOf<Account>([
      .init(jid: .placeholder, status: .disconnected),
    ])

    var mainState = MainScreen.MainScreenState()
    var auth: Authentication.State?

    public init() {}
  }

  public enum Action: Equatable {
    case onAppear
    case dismissAuthenticationSheet

    case didReceiveMessage(Message, UserInfo)
    case availableAccountsChanged(Set<BareJid>)
    case connectivityChanged(Connectivity)

    case auth(Authentication.Action)
    case main(MainScreen.Action)
    case account(BareJid, AccountReducer.Action)
  }

  private enum EffectToken: Hashable, CaseIterable {
    case observeAvailableAccounts
    case observeConnectivity
  }

  @Dependency(\.accountBookmarksClient) var accountBookmarks
  @Dependency(\.accountsClient) var accounts
  @Dependency(\.connectivityClient) var connectivityClient
  @Dependency(\.credentialsClient) var credentials
  @Dependency(\.notificationsClient) var notifications

  public var body: some ReducerProtocol<State, Action> {
    self.core
      .ifLet(\.auth, action: /Action.auth) {
        Authentication()
      }
      .handleNotifications()
      .handleAccounts()

    ConditionallyEnable(when: \.isMainScreenEnabled) {
      Scope(state: \.main, action: /Action.main) {
        MainScreen()
      }
    }
  }

  @ReducerBuilder<State, Action>
  private var core: some ReducerProtocol<State, Action> {
    Reduce { state, action in
      func proceedToMainFlow(with jid: BareJid) -> EffectTask<Action> {
        state.currentUser = jid
        if state.availableAccounts[id: jid] == nil {
          state.availableAccounts[id: jid] = .init(jid: jid, status: .connecting)
        }
        state.auth = nil
        return .none
      }

      func proceedToLogin(jid _: JID? = nil) -> EffectTask<Action> {
        state.auth = .init()
        return .none
      }

      switch action {
      case .onAppear where !state.initialized:
        state.initialized = true

        var effects: [EffectTask<Action>] = [
          .fireAndForget {
            self.notifications.promptForPushNotifications()
          },
          .run { send in
            for try await accounts in self.accounts.availableAccounts() {
              await send(.availableAccountsChanged(accounts))
            }
          }.cancellable(id: EffectToken.observeAvailableAccounts),
          .run { send in
            for try await connectivity in self.connectivityClient.connectivity() {
              await send(.connectivityChanged(connectivity))
            }
          }.cancellable(id: EffectToken.observeConnectivity),
        ]

        do {
          let credentials = try self.loadSavedCredentials()

          #warning("Save & restore selected account")
          if let firstCredentials = credentials.first {
            effects.append(
              .fireAndForget {
                self.accounts.connectAccounts(credentials)
              }
            )

          } else {
            effects.append(proceedToLogin())
          }
        } catch {
          logger.error("Error when loading credentials: \(error.localizedDescription)")
          return proceedToLogin()
        }

        return .merge(effects)

      case let .didReceiveMessage(message, userInfo):
        return self.notifications.scheduleLocalNotification(message, userInfo)
          .fireAndForget()

      case let .connectivityChanged(connectivity):
        state.connectivity = connectivity
        return .none

      case .dismissAuthenticationSheet:
        if state.availableAccounts.isEmpty {
          // We don't have a valid account and the user wants to dismiss the authentication sheet.
          exit(0)
        }
        state.auth = nil
        return .none

      case .onAppear, .auth, .main, .availableAccountsChanged, .account:
        return .none
      }
    }
  }

  private func loadSavedCredentials() throws -> [Credentials] {
    try self.accountBookmarks.loadBookmarks()
      .lazy
      .map(\.jid)
      .compactMap(self.credentials.loadCredentials)
  }
}

struct ConditionallyEnable<State, Action, Child: ReducerProtocol>: ReducerProtocol
  where State == Child.State, Action == Child.Action
{
  let child: Child
  let enableWhen: KeyPath<Child.State, Bool>

  init(when: KeyPath<State, Bool>, @ReducerBuilder<State, Action> _ child: () -> Child) {
    self.enableWhen = when
    self.child = child()
  }

  func reduce(into state: inout Child.State, action: Child.Action) -> EffectTask<Child.Action> {
    if state[keyPath: self.enableWhen] {
      return self.child.reduce(into: &state, action: action)
    }
    return .none
  }
}

extension App.State {
  var isMainScreenEnabled: Bool { self.auth == nil }
  var isMainScreenRedacted: Bool { self.currentUser == .placeholder }

  var main: SessionState<MainScreen.MainScreenState> {
    get {
      .init(
        currentUser: self.currentUser,
        accounts: self.availableAccounts,
        childState: self.mainState
      )
    }
    set {
      self.mainState = newValue.childState
      self.currentUser = newValue.currentUser
    }
  }
}