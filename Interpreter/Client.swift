//
//  Client.swift
//  Interpreter
//
//  Created by Martins on 03/12/2018.
//  Copyright © 2018 Good Gets Better. All rights reserved.
//

import Socket
import Foundation

public enum ClientError: Error {
  case missingSocket
}

public class Client {

  public typealias ResponseBlock = ([Sentence]) -> Void
  public typealias ErrorBlock = (Error) -> Void

  private let signature: Socket.Signature
  private var socket: Socket?
  private let onReceive: ResponseBlock?
  private let onError: ErrorBlock?
  private let queue = DispatchQueue(
    label: "Interpreter.Client.queue",
    qos: DispatchQoS.utility)
  private var lastTag = 0
  private var taggedOnResponse = [Int: ResponseBlock]()
  public var isLoggedIn = false

  public init(
    hostname: String,
    port: UInt,
    onReceive: ResponseBlock? = nil,
    onError: ErrorBlock? = nil
  ) throws {
    self.onReceive = onReceive
    self.onError = onError
    signature = try Socket.Signature(
      protocolFamily: .inet,
      socketType: .stream,
      proto: .tcp,
      hostname: hostname,
      port: Int32(port))!
  }

  deinit {
    if socket?.isConnected == true {
      socket?.close()
    }
  }

  public func conntect() throws {
    socket = try Socket.create(family: .inet)
    try socket?.connect(using: signature)
    listen()
  }

  private func listen() {
    queue.async { [unowned self] in
      guard let socket = self.socket else { return }
      // TODO: Ownership here is quite funky, this might crash.
      while true {
        var bytesRead = 0
        var data = Data()
        do {
          bytesRead = try socket.read(into: &data)
        } catch {
          self.onError?(error)
        }
        if bytesRead > 0 {
          do {
            let decoded = try decode(data: data)
            self.onReceive?(decoded)
            for (tag, sentences) in self.groupByTags(sentences: decoded) {
              if let onResponse = self.taggedOnResponse.removeValue(forKey: tag) {
                onResponse(sentences)
              }
            }
          } catch {
            self.onError?(error)
          }
        } else {
          self.disconnected()
          return
        }
      }
    }
  }

  public func send(
    sentence: Sentence,
    onResponse: (([Sentence]) -> Void)? = nil
  ) throws {
    guard let socket = socket else { throw ClientError.missingSocket }
    var sentence = sentence
    if let onResponse = onResponse {
      lastTag += 1
      taggedOnResponse[lastTag] = onResponse
      sentence.words.append(.apiAttribute(key: "tag", value: String(lastTag)))
    }
    sentence.words.append(.empty)
    let encoded = try encode(sentences: [sentence])
    try socket.write(from: encoded)
  }

  public var isConnected: Bool {
    return socket?.isConnected ?? false
  }

  private func disconnected() {
    socket?.close()
    socket = nil
    taggedOnResponse = [:]
    isLoggedIn = false
  }

  public func logIn(
    username: String,
    password: String,
    onResponse: ResponseBlock?
  ) throws {
    let login = Sentence(words: [
      .command("login"),
      .attribute(key: "name", value: username),
      .attribute(key: "password", value: password),
    ])
    try send(
      sentence: login,
      onResponse: { sentences in
        self.isLoggedIn = true
        onResponse?(sentences)
    })
  }

  private func groupByTags(sentences: [Sentence]) -> [Int: [Sentence]] {
    return sentences.reduce([Int: [Sentence]]()) { result, sentence in
      var result = result
      if
        let tag = sentence.words
          .first(where: { $0.tag != nil })?
          .tag
          .flatMap({ Int($0) })
      {
        if result[tag] != nil {
          result[tag]!.append(sentence)
        } else {
          result[tag] = [sentence]
        }
      }
      return result
    }
  }
}
