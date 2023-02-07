//
// This file is part of prose-app-macos.
// Copyright (c) 2022 Prose Foundation
//

import ComposableArchitecture
import Foundation
import ProseCoreTCA
import ProseCore

struct RosterState: Equatable {
  var roster: Roster = .init(groups: [])
  var unreadCounts = [BareJid: Int]()
  var presences = [BareJid: Presence]()
  var userInfos = [BareJid: UserInfo]()
}

extension RosterState {
  var sidebar: SidebarRoster {
    SidebarRoster(groups: self.roster.groups.map { group in
      SidebarRoster.Group(
        name: group.name,
        items: group.items.map { item in
          SidebarRoster.Group.Item(
            jid: item.jid,
            avatarURL: userInfos[item.jid]?.avatar,
            numberOfUnreadMessages: self.unreadCounts[item.jid] ?? 0,
            status: self.presences[item.jid]?.onlineStatus ?? .offline
          )
        }
      )
    })
  }
}

private extension Presence {
  var onlineStatus: OnlineStatus {
    self.kind == .unavailable ? .offline : .online
  }
}

struct SidebarRoster: Equatable {
  var groups = [Group]()
}

extension SidebarRoster {
  struct Group: Equatable {
    var name: String
    var items = [Item]()
  }
}

extension SidebarRoster.Group {
  struct Item: Equatable {
    var jid: BareJid
    var avatarURL: URL?
    var numberOfUnreadMessages: Int
    var status: OnlineStatus
  }
}

extension AnyReducer where
  State == SessionState<SidebarState>,
  Action == SidebarAction,
  Environment == SidebarEnvironment
{
  func roster() -> Self {
    .combine(
      self,
      AnyReducer { state, action, environment in
        switch action {
        case .onAppear:
          return .merge(
            environment.proseClient.roster()
              .receive(on: environment.mainQueue)
              .catchToEffect(SidebarAction.rosterResult)
              .cancellable(
                id: SidebarEffectToken.rosterSubscription,
                cancelInFlight: true
              ),
            environment.proseClient.presence()
              .receive(on: environment.mainQueue)
              .catchToEffect(SidebarAction.presencesResult)
              .cancellable(
                id: SidebarEffectToken.presenceSubscription,
                cancelInFlight: true
              ),
            environment.proseClient.activeChats()
              .receive(on: environment.mainQueue)
              .catchToEffect(SidebarAction.activeChatsResult)
              .cancellable(
                id: SidebarEffectToken.activeChatsSubscription,
                cancelInFlight: true
              )
          )

        case let .rosterResult(.success(roster)):
          state.roster.roster = roster

          return environment.proseClient
            .userInfos(Set(roster.groups.flatMap { $0.items.map(\.jid) }))
            .receive(on: environment.mainQueue)
            .catchToEffect(SidebarAction.userInfosResult)
            .cancellable(id: SidebarEffectToken.userInfosSubscription, cancelInFlight: true)

        case let .rosterResult(.failure(error)):
          logger.error(
            "Could not load roster. \(error.localizedDescription, privacy: .public)"
          )
          return .none

        case let .activeChatsResult(.success(chats)):
          state.roster.unreadCounts =
            chats.mapValues(\.numberOfUnreadMessages)
          return .none

        case let .activeChatsResult(.failure(error)):
          logger.error(
            "Could not load active chats. \(error.localizedDescription, privacy: .public)"
          )
          return .none

        case let .presencesResult(.success(presences)):
          state.roster.presences = presences
          return .none

        case let .presencesResult(.failure(error)):
          logger.error(
            "Could not load presences. \(error.localizedDescription, privacy: .public)"
          )
          return .none

        case let .userInfosResult(.success(userInfos)):
          state.roster.userInfos = userInfos
          return .none

        case let .userInfosResult(.failure(error)):
          logger.error(
            "Could not load user infos. \(error.localizedDescription, privacy: .public)"
          )
          return .none

        case .onDisappear, .selection, .addContactButtonTapped, .addGroupButtonTapped,
             .footer, .toolbar, .addMember, .joinGroup, .showSheet:
          return .none
        }
      }
    )
  }
}
