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

  init(window: UIWindow) {
    self.window = window

    if let split = splitController, let top = split.topViewController {
      top.navigationItem.leftBarButtonItem = split.displayModeButtonItem
      split.delegate = self
    }

    logIn(username: "ios", password: "developer")
  }

  // MARK: - View controllers

  var splitController: UISplitViewController? {
    return window.rootViewController as? UISplitViewController
  }

  var routersController: RoutersController? {
    return (splitController?.viewControllers.first as? UINavigationController)?
      .viewControllers.first as? RoutersController
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

  private func logIn(username: String, password: String) {
    do {
      let login = Sentence(words: [
        .command("login"),
        .attribute(key: "name", value: username),
        .attribute(key: "password", value: password),
      ])
      try client?.send(sentence: login, onResponse: handleLoginResponse)
    } catch {
      os_log("Error when logging in: %@", error as CVarArg)
    }
  }

  private func handleLoginResponse(_ sentences: [Sentence]) {
    if sentences.first?.words.first == .reply("done") {
      getStats()
    }
  }

  private func getStats() {
    do {
      let getStats = Sentence(words: [
        .command("interface/print"),
        .attribute(key: "stats", value: nil),
      ])
      try client?.send(sentence: getStats, onResponse: updateStats)
    } catch {
      os_log("Error when printing status: %@", error as CVarArg)
    }
  }

  private func updateStats(from sentences: [Sentence]) {
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
    let router = Router(
      hostname: "77.38.162.131",
      port: 8728,
      isConnected: true,
      stats: stats)
    DispatchQueue.main.async {
      self.routersController?.routers.append(router)
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
