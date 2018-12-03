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
  private let onReceive: ([Sentence]) -> Void
  private let onError: (Error) -> Void
  private let queue = DispatchQueue(
    label: "Interpreter.Client.queue",
    qos: DispatchQoS.utility)

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

  private func listen() {
    queue.async {
      var shouldKeepRunning = true
      repeat {
        var bytesRead = 0
        var data = Data()
        do {
          bytesRead = try self.socket.read(into: &data)
        } catch {
          self.onError(error)
        }
        if bytesRead > 0 {
          do {
            let decoded = try decode(data: data)
            self.onReceive(decoded)
          } catch {
            self.onError(error)
          }
        } else {
          shouldKeepRunning = false
        }
      } while shouldKeepRunning
    }
  }

  public func send(sentences: [Sentence]) throws {
    let encoded = try encode(sentences: sentences)
    try socket.write(from: encoded)
  }

  deinit {
    socket.close()
  }
}
