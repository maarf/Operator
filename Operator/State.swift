//
//  State.swift
//  Operator
//
//  Created by Martins on 04/12/2018.
//  Copyright © 2018 Good Gets Better. All rights reserved.
//

import Foundation

struct State {
  var routers: [Router]
  var stats: [Router.Id: [Stats]]
  var selectedRouterId: Router.Id?
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

  func set(stats: [Stats], forRouterId routerId: Router.Id) {
    state.stats[routerId] = stats
  }

  func select(routerId: Router.Id) {
    state.selectedRouterId = routerId
  }
}
