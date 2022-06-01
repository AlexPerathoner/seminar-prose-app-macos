//
//  OtherContactsSection.swift
//  Prose
//
//  Created by Valerian Saliou on 11/28/21.
//

import ComposableArchitecture
import PreviewAssets
import SwiftUI

// swiftlint:disable file_types_order

// MARK: - View

struct OtherContactsSection: View {
    typealias State = OtherContactsSectionState
    typealias Action = OtherContactsSectionAction

    let store: Store<State, Action>
    private var actions: ViewStore<Void, Action> { ViewStore(self.store.stateless) }

    @Binding var route: Route?

    var body: some View {
        Section("sidebar_section_other_contacts".localized()) {
            WithViewStore(self.store.scope(state: \State.items)) { items in
                ForEach(items.state) { item in
                    NavigationLink(tag: item.id, selection: $route) {
                        NavigationDestinationView(selection: item.id)
                    } label: {
                        ContactRow(
                            title: item.title,
                            avatar: item.image,
                            count: item.count
                        )
                    }
                }
            }

            ActionRow(
                title: "sidebar_other_contacts_add",
                systemImage: "plus.square.fill"
            ) { actions.send(.addContactTapped) }
        }
    }
}

// MARK: - The Composabe Architecture

// MARK: Reducer

let otherContactsSectionReducer: Reducer<
    OtherContactsSectionState,
    OtherContactsSectionAction,
    Void
> = Reducer { _, action, _ in
    switch action {
    case .addContactTapped:
        // TODO: [Rémi Bardon] Handle action
        print("Add contact tapped")
    }

    return .none
}

// MARK: State

public struct OtherContactsSectionState: Equatable {
    let items: [SidebarItem] = [
        .init(
            id: .person(id: "id-baptiste"),
            title: "Baptiste",
            image: PreviewImages.Avatars.baptiste.rawValue,
            count: 0
        ),
    ]

    public init() {}
}

// MARK: Actions

public enum OtherContactsSectionAction: Equatable {
    case addContactTapped
}

// MARK: - Previews

struct OtherContactsSection_Previews: PreviewProvider {
    private struct Preview: View {
        @State var route: Route?

        var body: some View {
            NavigationView {
                List {
                    OtherContactsSection(
                        store: Store(
                            initialState: .init(),
                            reducer: otherContactsSectionReducer,
                            environment: ()
                        ),
                        route: $route
                    )
                }
                .frame(width: 256)
            }
        }
    }

    static var previews: some View {
        Preview(route: nil)
    }
}