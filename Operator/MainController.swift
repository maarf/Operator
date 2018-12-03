//
//  AppController.swift
//  Operator
//
//  Created by Martins on 03/12/2018.
//  Copyright © 2018 Good Gets Better. All rights reserved.
//

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
