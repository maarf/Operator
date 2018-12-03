//
//  AppDelegate.swift
//  Operator
//
//  Created by Martins on 03/12/2018.
//  Copyright © 2018 Good Gets Better. All rights reserved.
//

import UIKit

@UIApplicationMain
final class AppDelegate:
  UIResponder,
  UIApplicationDelegate
{
  var mainController: MainController?
  var window: UIWindow?

  func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    guard let window = window else { fatalError("There is no window") }
    mainController = MainController(window: window)
    return true
  }

}

