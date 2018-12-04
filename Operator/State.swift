//
//  State.swift
//  Operator
//
//  Created by Martins on 04/12/2018.
//  Copyright © 2018 Good Gets Better. All rights reserved.
//

import Foundation
import os.log

/// Represents most of the app's state.
struct State {
  var routers: [Router]
  var stats: [Router.Id: [Stats]]
  var selectedRouterId: Router.Id?
}

/// Model struct for a router.
struct Router: Equatable, Codable {
  typealias Id = String
  var id: Id
  var hostname: String
  var port: Int
  var username: String
  var password: String
}

protocol StateSubscriber: NSObjectProtocol {
  func newState(_ state: State)
}

/// Wrapper around subscriber to own it weakly.
private class SubscriberBox {
  weak var subscriber: StateSubscriber?
  init(_ subscriber: StateSubscriber) {
    self.subscriber = subscriber
  }
}

/// Very minimal Redux-inspired state store.
///
/// The core idea is to have a single source of truth for state, that is only
/// mutable by calling actions on the store. Everything that consumes or
/// presents state can get it by subscribing to state using store.
final class StateStore {

  private var state: State {
    didSet {
      updateSubscribers()
    }
  }

  init(initialState: State) {
    state = initialState
  }

  // MARK: - Subscription

  private var subscribers = [SubscriberBox]()

  func subscribe(_ subscriber: StateSubscriber) {
    subscribers.append(SubscriberBox(subscriber))
    subscriber.newState(state)
  }

  func unsubscribe(_ subscriber: StateSubscriber) {
    subscribers = subscribers.filter { box in
      guard let existing = box.subscriber else { return false }
      return !existing.isEqual(subscriber)
    }
  }

  private func updateSubscribers() {
    for box in subscribers {
      box.subscriber?.newState(state)
    }
  }

  // MARK: - Actions

  /// Adds a router to state.
  func addRouter(
    hostname: String,
    port: Int,
    username: String,
    password: String
  ) {
    state.routers.append(Router(
      id: UUID().uuidString,
      hostname: hostname,
      port: port,
      username: username,
      password: password))
    store(routers: state.routers)
  }

  /// Removes a router from state.
  func removeRouter(id: Router.Id) {
    if let index = state.routers.index(where: { $0.id == id }) {
      state.routers.remove(at: index)
      store(routers: state.routers)
    }
  }

  /// Sets stats for a specific router.
  func set(stats: [Stats], forRouterId routerId: Router.Id) {
    if let existing = state.stats[routerId] {
      var updated = stats
      for one in existing {
        if let index = updated.index(where: { $0.name == one.name }) {
          var data = one.transferData
          data.append(contentsOf: updated[index].transferData)
          updated[index].transferData = data
        }
      }
      state.stats[routerId] = updated
    } else {
      state.stats[routerId] = stats
    }
  }

  /// Sets selected router.
  func select(routerId: Router.Id) {
    state.selectedRouterId = routerId
  }
}

// MARK: - Router persistence

private func store(routers: [Router]) {
  do {
    var url = try FileManager.default.url(
      for: .applicationSupportDirectory,
      in: .userDomainMask,
      appropriateFor: nil,
      create: true)
    url.appendPathComponent("routers.json")
    let encoder = JSONEncoder()
    let data = try encoder.encode(routers)
    try data.write(to: url)
  } catch {
    os_log("Can't store routers, error %@", error as CVarArg)
  }
}
