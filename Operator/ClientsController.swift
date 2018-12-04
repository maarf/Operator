//
//  ClientsController.swift
//  Operator
//
//  Created by Martins on 04/12/2018.
//  Copyright © 2018 Good Gets Better. All rights reserved.
//

import Interpreter
import os.log

private struct ClientState {
  var client: Client
  var router: Router
  var timer: Timer
}

final class ClientsController: NSObject, StateSubscriber {

  private let stateStore: StateStore
  private var clients = [Router.Id: ClientState]()

  init(stateStore: StateStore) {
    self.stateStore = stateStore
    super.init()
    stateStore.subscribe(self)
  }

  // MARK: - State

  func newState(_ state: State) {
    for router in state.routers {
      if !clients.keys.contains(router.id) {
        do {
          let client = try Client(
            hostname: router.hostname,
            port: UInt(router.port),
            onError: logError)
          let timer = Timer.scheduledTimer(
            withTimeInterval: 2,
            repeats: true,
            block: { timer in
              self.pull(client: client, router: router)
            })
          clients[router.id] = ClientState(
            client: client,
            router: router,
            timer: timer)
        } catch {
          os_log("Error when logging in: %@", error as CVarArg)
        }
      }
    }
    for routerId in clients.keys {
      if !state.routers.contains(where: { $0.id == routerId}) {
        let clientState = clients.removeValue(forKey: routerId)
        clientState?.timer.invalidate()
      }
    }
  }

  // MARK: -

  private func pull(client: Client, router: Router) {
    if !client.isConnected {
      do {
        try client.conntect()
      } catch {
        os_log("Can't connect, error: %@", error as CVarArg)
        return
      }
    }
    if !client.isLoggedIn {
      do {
        try client.logIn(
          username: router.username,
          password: router.password,
          onResponse: { sentences in
            self.handleLoginResponse(
              sentences,
              client: client,
              routerId: router.id)
        })
      } catch {
        os_log("Can't logging in: %@", error as CVarArg)
      }
    } else {
      getStats(client: client, routerId: router.id)
    }
  }


  private func handleLoginResponse(
    _ sentences: [Sentence],
    client: Client,
    routerId: String
  ) {
    if sentences.first?.words.first == .reply("done") {
      getStats(client: client, routerId: routerId)
    }
  }

  private func getStats(client: Client, routerId: String) {
    do {
      let getStats = Sentence(words: [
        .command("interface/print"),
        .attribute(key: "stats", value: nil),
      ])
      try client.send(
        sentence: getStats,
        onResponse: { sentences in
          self.updateStats(from: sentences, routerId: routerId)
        })
    } catch {
      os_log("Can't get stats: %@", error as CVarArg)
    }
  }

  private func updateStats(from sentences: [Sentence], routerId: String) {
    let stats = sentences
      .compactMap { sentence -> Stats? in
        guard sentence.words.first == .reply("re") else { return nil }
        let pairs = sentence.words
          .compactMap { word -> (key: String, value: String)? in
            guard
              case let .attribute(key, maybeValue) = word,
              let value = maybeValue
            else { return nil }
            return (key: key, value: value)
          }
        return Stats(pairs: pairs)
      }
    DispatchQueue.main.async {
      self.stateStore.set(stats: stats, forRouterId: routerId)
    }
  }

  private func logError(_ error: Error) {
    os_log("Error: %@", type: .error, error as CVarArg)
  }
}
