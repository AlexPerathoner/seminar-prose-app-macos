//
//  Sidebar+Footer.swift
//  Prose
//
//  Created by Valerian Saliou on 11/28/21.
//

import ComposableArchitecture
import PreviewAssets
import SwiftUI

extension SidebarView {
    
    struct Footer: View {
        let store: Store<SidebarState, SidebarAction>
        
        let avatar: String = PreviewImages.Avatars.valerian.rawValue
        let teamName: String = "Crisp"
        let statusIcon: Character = "🚀"
        let statusMessage: String = "Building new features."
        
        var body: some View {
            WithViewStore(self.store) { viewStore in
                VStack(spacing: 0) {
                    Divider()
                    
                    HStack(spacing: 12) {
                        // User avatar
                        SidebarFooterAvatar(
                            avatar: avatar,
                            status: .online
                        )
                        
                        // Team name + user status
                        SidebarFooterDetails(
                            teamName: viewStore.credentials.jid,
                            statusIcon: statusIcon,
                            statusMessage: statusMessage
                        )
                        .layoutPriority(1)
                        
                        Spacer()
                        
                        // Quick action button
                        SidebarFooterActionButton()
                    }
                    .padding(.leading, 20.0)
                    .padding(.trailing, 14.0)
                    .frame(maxHeight: 64)
                }
                .frame(height: 64)
            }
        }
        
    }
    
}
