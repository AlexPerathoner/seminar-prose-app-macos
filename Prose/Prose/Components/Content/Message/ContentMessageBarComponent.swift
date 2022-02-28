//
//  ContentMessageBarComponent.swift
//  Prose
//
//  Created by Valerian Saliou on 11/21/21.
//

import SwiftUI

struct ContentMessageBarComponent: View {
    private static let height: CGFloat = 64
    
    @State private var message: String = ""
    
    var firstName: String
    
    var body: some View {
        VStack(spacing: 0) {
            Divider()
            
            HStack(spacing: 16) {
                leadingButtons()
                
                ZStack {
                    ContentMessageBarFieldComponent(
                        firstName: firstName,
                        message: message
                    )
                    
                    ContentMessageBarComposeComponent(
                        firstName: firstName
                    )
                        .offset(y: -Self.height/2)
                }
                
                trailingButtons()
            }
            .font(.title2)
            .padding(.horizontal, 20)
            .frame(maxHeight: Self.height)
        }
        .frame(height: Self.height)
        .foregroundColor(.secondary)
        // TODO: [Rémi Bardon] Maybe add a material background here, to make it more beautiful with content going under
//        .background(.ultraThinMaterial)
        .background(.background)
    }
    
    @ViewBuilder
    private func leadingButtons() -> some View {
        HStack(spacing: 12) {
            Button(action: {}) {
                Image(systemName: "textformat.alt")
            }
        }
        .buttonStyle(.plain)
    }
    
    @ViewBuilder
    private func trailingButtons() -> some View {
        HStack(spacing: 12) {
            Button(action: {}) {
                Image(systemName: "paperclip")
            }
            Button(action: {}) {
                Image(systemName: "face.smiling")
            }
        }
        .buttonStyle(.plain)
    }
}

struct ContentMessageBarComponent_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ContentMessageBarComponent(
                firstName: "Valerian"
            )
                .previewDisplayName("Simple username")
            ContentMessageBarComponent(
                firstName: "Very \(Array(repeating: "very", count: 20).joined(separator: " ")) long username"
            )
                .previewDisplayName("Long username")
            ContentMessageBarComponent(
                firstName: ""
            )
                .previewDisplayName("Empty")
            ContentMessageBarComponent(
                firstName: "Valerian"
            )
                .padding()
                .background(Color.pink)
                .previewDisplayName("Colorful background")
        }
        .preferredColorScheme(.light)
        Group {
            ContentMessageBarComponent(
                firstName: "Valerian"
            )
                .previewDisplayName("Simple username / Dark")
            ContentMessageBarComponent(
                firstName: ""
            )
                .previewDisplayName("Empty / Dark")
            ContentMessageBarComponent(
                firstName: "Valerian"
            )
                .padding()
                .background(Color.pink)
                .previewDisplayName("Colorful background / Dark")
        }
        .preferredColorScheme(.dark)
    }
}