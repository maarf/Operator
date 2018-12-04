//
//  MainController.swift
//  Operator
//
//  Created by Martins on 03/12/2018.
//  Copyright © 2018 Good Gets Better. All rights reserved.
//

import Interpreter
import os.log
import UIKit

final class MainController {

  let window: UIWindow

  let stateStore: StateStore

  init(window: UIWindow) {
    self.window = window

    let defaultRouter = Router(
      id: UUID().uuidString,
      hostname: "77.38.162.131",
      port: 8728,
      username: "ios",
      password: "developer",
      isConnected: true)

    let initialState = State(
      routers: [defaultRouter],
      stats: [:],
      selectedRouterId: nil)
    stateStore = StateStore(initialState: initialState)

    routersController?.stateStore = stateStore

    if let split = splitController, let top = split.topViewController {
      top.navigationItem.leftBarButtonItem = split.displayModeButtonItem
      split.delegate = self
    }

    logIn(
      username: defaultRouter.username,
      password: defaultRouter.password,
      routerId: defaultRouter.id)
  }

  // MARK: - View controllers

  var splitController: UISplitViewController? {
    return window.rootViewController as? UISplitViewController
  }

  var routersController: RoutersController? {
    return (splitController?.viewControllers.first as? UINavigationController)?
      .viewControllers.first as? RoutersController
  }

  var statsController: StatsController? {
    return (splitController?.viewControllers.last as? UINavigationController)?
      .viewControllers.first as? StatsController
  }

  // MARK: - RouterOS client

  private lazy var client: Client? = {
    do {
      return try Client(
        hostname: "77.38.162.131",
        port: 8728,
        onReceive: logResponse,
        onError: logError)
    } catch {
      os_log("Error when logging in: %@", error as CVarArg)
      return nil
    }
  }()

  private func logIn(username: String, password: String, routerId: String) {
    do {
      let login = Sentence(words: [
        .command("login"),
        .attribute(key: "name", value: username),
        .attribute(key: "password", value: password),
      ])
      try client?.send(
        sentence: login,
        onResponse: { sentences in
          self.handleLoginResponse(sentences, routerId: routerId)
        })
    } catch {
      os_log("Error when logging in: %@", error as CVarArg)
    }
  }

  private func handleLoginResponse(
    _ sentences: [Sentence],
    routerId: String
  ) {
    if sentences.first?.words.first == .reply("done") {
      getStats(routerId: routerId)
    }
  }

  private func getStats(routerId: String) {
    do {
      let getStats = Sentence(words: [
        .command("interface/print"),
        .attribute(key: "stats", value: nil),
      ])
      try client?.send(
        sentence: getStats,
        onResponse: { sentences in
          self.updateStats(from: sentences, routerId: routerId)
        })
    } catch {
      os_log("Error when printing status: %@", error as CVarArg)
    }
  }

  private func updateStats(from sentences: [Sentence], routerId: String) {
    os_log("Received stats: %@", sentences)

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

  private func logResponse(_ sentences: [Sentence]) {
    os_log("Received: %@", sentences)
  }

  private func logError(_ error: Error) {
    os_log("Error: %@", type: .error, error as CVarArg)
  }
}

extension MainController: UISplitViewControllerDelegate {
  func splitViewController(
    _ splitViewController: UISplitViewController,
    collapseSecondary secondary: UIViewController,
    onto primary: UIViewController
  ) -> Bool {
    if
      let secondary = secondary as? UINavigationController,
      let top = secondary.topViewController as? StatsController,
      top.stats == []
    {
      return true
    }
    return false
  }
}

extension UISplitViewController {
  var topViewController: UIViewController? {
    return (viewControllers.last as? UINavigationController)?.topViewController
  }
}
