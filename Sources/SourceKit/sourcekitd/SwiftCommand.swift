//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2019 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import SKSupport
import LanguageServerProtocol
import Foundation

/// The set of known Swift commands.
///
/// All commands from the Swift LSP should be listed here.
public let builtinSwiftCommands: [String] = [
  SemanticRefactorCommand.self
].map { $0.identifier }

/// A `Command` that should be executed by Swift's language server.
public protocol SwiftCommand: Codable, Hashable {
  var title: String { get set }
  static var swiftCommandIdentifier: String { get }
}

extension SwiftCommand {
  public static var identifier: String {
    return Command.swiftCommandIdentifierPrefix + Self.swiftCommandIdentifier
  }

  /// Converts this `SwiftCommand` to a generic LSP `Command` object.
  public func asCommand() throws -> Command {
    let data = try JSONEncoder().encode(self)
    let argument = try JSONDecoder().decode(CommandArgumentType.self, from: data)
    return Command(title: title, command: Self.identifier, arguments: [argument])
  }
}

extension Command {
  /// The prefix applied to the identifier of Swift-specific LSP `Command`s.
  fileprivate static var swiftCommandIdentifierPrefix: String {
    return "swift.lsp."
  }

  /// Returns true if the provided command identifier should be handled by Swift's language server.
  ///
  /// - Parameters:
  ///   - command: The command identifier.
  public static func isCommandIdentifierFromSwiftLSP(_ command: String) -> Bool {
    return command.hasPrefix(Command.swiftCommandIdentifierPrefix)
  }
}

extension ExecuteCommandRequest {
  /// Attempts to convert the underlying `Command` metadata from this request
  /// to a specific Swift language server `SwiftCommand`.
  ///
  /// - Parameters:
  ///   - type: The `SwiftCommand` metatype to convert to.
  public func swiftCommand<T: SwiftCommand>(ofType type: T.Type) -> T? {
    guard type.identifier == command else {
      return nil
    }
    guard let argument = arguments?.first else {
      return nil
    }
    guard case let .dictionary(dictionary) = argument else {
      return nil
    }
    guard let data = try? JSONEncoder().encode(dictionary) else {
      return nil
    }
    return try? JSONDecoder().decode(type, from: data)
  }
}

public struct SemanticRefactorCommand: SwiftCommand {
  public static var swiftCommandIdentifier: String {
    return "semantic.refactor.command"
  }

  /// The name of this refactoring action.
  public var title: String

  /// The sourcekitd identifier of the refactoring action.
  public var actionString: String

  /// The starting line of the range to refactor.
  public var line: Int

  /// The starting column of the range to refactor.
  public var column: Int

  /// The length of the range to refactor.
  public var length: Int

  /// The text document related to the refactoring action.
  public var textDocument: TextDocumentIdentifier

  public init(title: String, actionString: String, line: Int, column: Int, length: Int, textDocument: TextDocumentIdentifier) {
    self.title = title
    self.actionString = actionString
    self.line = line
    self.column = column
    self.length = length
    self.textDocument = textDocument
  }
}
