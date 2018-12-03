//
//  Client.swift
//  Interpreter
//
//  Created by Martins on 03/12/2018.
//  Copyright © 2018 Good Gets Better. All rights reserved.
//

import Socket
import Foundation

public class Client {

  private let socket: Socket
  private let onReceive: (([Sentence]) -> Void)?
  private let onError: ((Error) -> Void)?
  private let queue = DispatchQueue(
    label: "Interpreter.Client.queue",
    qos: DispatchQoS.utility)
  private var lastTag = 0
  private var taggedOnResponse = [Int: ([Sentence]) -> Void]()

  public init(
    hostname: String,
    port: UInt,
    onReceive: @escaping ([Sentence]) -> Void,
    onError: @escaping (Error) -> Void
  ) throws {
    self.onReceive = onReceive
    self.onError = onError
    let signature = try Socket.Signature(
      protocolFamily: .inet,
      socketType: .stream,
      proto: .tcp,
      hostname: hostname,
      port: Int32(port))!
    socket = try Socket.create(family: .inet)
    try socket.connect(using: signature)
    listen()
  }

  deinit {
    socket.close()
  }

  private func listen() {
    queue.async { [unowned self] in
      // TODO: Ownership here is quite funky, this might crash.
      while true {
        var bytesRead = 0
        var data = Data()
        do {
          bytesRead = try self.socket.read(into: &data)
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
          return
        }
      }
    }
  }

  public func send(
    sentence: Sentence,
    onResponse: (([Sentence]) -> Void)? = nil
  ) throws {
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
