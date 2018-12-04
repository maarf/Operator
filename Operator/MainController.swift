//
//  MainController.swift
//  Operator
//
//  Created by Martins on 03/12/2018.
//  Copyright © 2018 Good Gets Better. All rights reserved.
//

import Interpreter
import UIKit

final class MainController {

  let window: UIWindow
  let stateStore: StateStore
  let clientsController: ClientsController

  init(window: UIWindow) {
    self.window = window

    let initialState = State(
      routers: loadRouters(),
      stats: [:],
      selectedRouterId: nil)
    stateStore = StateStore(initialState: initialState)

    clientsController = ClientsController(stateStore: stateStore)

    routersController?.stateStore = stateStore

    if let split = splitController, let top = split.topViewController {
      top.navigationItem.leftBarButtonItem = split.displayModeButtonItem
      split.delegate = self
    }
  }

  // MARK: - View controllers

  var splitController: UISplitViewController? {
    return window.rootViewController as? UISplitViewController
  }

  var routersController: RoutersController? {
    return (splitController?.viewControllers.first as? UINavigationController)?
      .viewControllers.first as? RoutersController
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

// MARK: - Router persistence

private func loadRouters() -> [Router] {
  do {
    var url = try FileManager.default.url(
      for: .applicationSupportDirectory,
      in: .userDomainMask,
      appropriateFor: nil,
      create: false)
    url.appendPathComponent("routers.json")
    let data = try Data(contentsOf: url)
    let decoder = JSONDecoder()
    return try decoder.decode([Router].self, from: data)
  } catch {
    return [Router(
      id: UUID().uuidString,
      hostname: "77.38.162.131",
      port: 8728,
      username: "ios",
      password: "developer")]
  }
}
