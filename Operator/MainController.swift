//
//  AppController.swift
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

    if
      let split = window.rootViewController as? UISplitViewController,
      let top = split.topViewController
    {
      top.navigationItem.leftBarButtonItem = split.displayModeButtonItem
      split.delegate = self
    }

    logIn(username: "ios", password: "developer")
  }

  // MARK: - RouterOS client

  private lazy var client: Client? = {
    do {
      return try Client(
        hostname: "77.38.162.131",
        port: 8728,
        onReceive: handleResponse,
        onError: handleError)
    } catch {
      os_log("Error when logging in: %@", error as CVarArg)
      return nil
    }
  }()

  private func logIn(username: String, password: String) {
    do {
      try client?.send(sentences: [Sentence(words: [
        .command("login"),
        .attribute(key: "name", value: username),
        .attribute(key: "password", value: password),
        .empty,
      ])])
    } catch {
      os_log("Error when logging in: %@", error as CVarArg)
    }
  }

  private func printStatus() {
    do {
      try client?.send(sentences: [Sentence(words: [
        .command("interface/print"),
        .attribute(key: "stats", value: nil),
        .empty,
      ])])
    } catch {
      os_log("Error when printing status: %@", error as CVarArg)
    }
  }

  private func handleResponse(_ sentences: [Sentence]) {
    os_log("Received: %@", sentences)
    if sentences.first?.words.first == .reply("done") {
      printStatus()
    }
  }

  private func handleError(_ error: Error) {
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
      let top = secondary.topViewController as? DetailViewController,
      top.detailItem == nil
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
