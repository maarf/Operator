//
//  Sentence.swift
//  Interpreter
//
//  Created by Martins on 03/12/2018.
//  Copyright © 2018 Good Gets Better. All rights reserved.
//

public struct Sentence: Equatable {
  public var words: [Word]

  public init() {
    words = []
  }

  public init(words: [Word]) {
    self.words = words
  }
}

public enum Word: RawRepresentable, Equatable {
  case command(String)
  case reply(String)
  case attribute(key: String, value: String?)
  case apiAttribute(key: String, value: String)
  case query(String)
  case empty

  public var rawValue: String {
    switch self {
      case .command(let command):
        return "/" + command
      case .reply(let reply):
        return "!" + reply
      case .attribute(let key, let value):
        return "=" + key + "=" + (value ?? "")
      case .apiAttribute(let key, let value):
        return "." + key + "=" + value
      case .query(let query):
        return "?" + query
      case .empty:
        return ""
    }
  }

  public init?(rawValue: String) {
    guard let first = rawValue.first else {
      self = .empty
      return
    }
    let rest = rawValue.dropFirst()
    switch first {
      case "/":
        self = .command(String(rest))
      case "!":
        self = .reply(String(rest))
      case "=":
        guard let separatorIndex = rest.firstIndex(of: "=") else { return nil }
        let key = rest[..<separatorIndex]
        let value = rest[rest.index(after: separatorIndex)...]
        self = .attribute(
          key: String(key),
          value: value.isEmpty ? nil : String(value))
      case ".":
        guard let separatorIndex = rest.firstIndex(of: "=") else { return nil }
        let key = rest[..<separatorIndex]
        let value = rest[rest.index(after: separatorIndex)...]
        self = .apiAttribute(
          key: String(key),
          value: String(value))
      case "?":
        self = .query(String(rest))
      default:
        return nil
    }
  }

  var tag: String? {
    switch self {
      case .apiAttribute(let key, let value): return key == "tag" ? value : nil
      default: return nil
    }
  }
}
