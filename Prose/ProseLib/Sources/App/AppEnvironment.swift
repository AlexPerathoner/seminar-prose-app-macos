////
//// This file is part of prose-app-macos.
//// Copyright (c) 2022 Prose Foundation
////
//
//import AuthenticationFeature
//import ComposableArchitecture
//import CredentialsClient
//import Foundation
//import MainWindowFeature
//import NotificationsClient
//import PasteboardClient
//import struct ProseCoreTCA.AvatarImageCache
//import struct ProseCoreTCA.ProseClient
//import Toolbox
//import ProseBackend
//
//#if canImport(AppKit)
//  import AppKit
//
//  public typealias OpenURLConfiguration = NSWorkspace.OpenConfiguration
//#else
//  public typealias OpenURLConfiguration = Void
//#endif
//
//public enum URLOpeningError: Error, Equatable {
//  case failedToOpen(EquatableError)
//}
//
//public struct AppEnvironment {
//  public var credentials: CredentialsClient
//
//  public var proseClient: ProseClient
//  public var pasteboard: PasteboardClient
//  public var notifications: NotificationsClient
//
//  public var mainQueue: AnySchedulerOf<DispatchQueue>
//
//  public var openURL: (URL, OpenURLConfiguration) -> EffectPublisher<Void, URLOpeningError>
//
//  public init(
//    credentials: CredentialsClient,
//    proseClient: ProseClient,
//    pasteboard: PasteboardClient,
//    notifications: NotificationsClient,
//    mainQueue: AnySchedulerOf<DispatchQueue>,
//    openURL: @escaping (URL, OpenURLConfiguration) -> EffectPublisher<Void, URLOpeningError>
//  ) {
//    self.credentials = credentials
//    self.proseClient = proseClient
//    self.pasteboard = pasteboard
//    self.notifications = notifications
//    self.mainQueue = mainQueue
//    self.openURL = openURL
//  }
//}
//
//public extension AppEnvironment {
//  static var live: Self {
//    let imageCache = (try? AvatarImageCache.live(
//      cacheDirectory: URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(
//        "avatar-cache",
//        conformingTo: .directory
//      )
//    )).expect("Could not initialize AvatarImageCache")
//
//    return Self(
//      credentials: .live(service: "org.prose.app"),
//      proseClient: .live(provider: ProseBackend.ProseClient.init, imageCache: imageCache),
//      pasteboard: .live(),
//      notifications: .live,
//      mainQueue: .main,
//      openURL: { url, openConfig -> EffectPublisher<Void, URLOpeningError> in
//        EffectPublisher.future { callback in
//          #if canImport(AppKit)
//            NSWorkspace.shared.open(url, configuration: openConfig) { _, error in
//              if let error = error {
//                callback(.failure(.failedToOpen(EquatableError(error))))
//              } else {
//                callback(.success(()))
//              }
//            }
//          #else
//            #error("AppKit is not available, find another way to open an URL.")
//          #endif
//        }
//      }
//    )
//  }
//}
//
//extension AppEnvironment {
//  var auth: AuthenticationEnvironment {
//    AuthenticationEnvironment(
//      proseClient: self.proseClient,
//      credentials: self.credentials,
//      mainQueue: self.mainQueue
//    )
//  }
//
//  var main: MainScreenEnvironment {
//    MainScreenEnvironment(
//      proseClient: self.proseClient,
//      pasteboard: self.pasteboard,
//      mainQueue: self.mainQueue
//    )
//  }
//}
