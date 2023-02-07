//
// This file is part of prose-app-macos.
// Copyright (c) 2022 Prose Foundation
//

import Foundation
import ProseCore

public struct MessagingContext {
  public let setAccountJID: JSFunc1<BareJid, Void>
  public let setStyleTheme: JSFunc1<StyleTheme?, Void>

  public init(evaluator: @escaping JSEvaluator) {
    let cls = JSClass(name: "MessagingContext", evaluator: evaluator)
    self.setAccountJID = cls.setAccountJID
    self.setStyleTheme = cls.setStyleTheme
  }
}
