//
//  EditRouterController.swift
//  Operator
//
//  Created by Martins on 04/12/2018.
//  Copyright © 2018 Good Gets Better. All rights reserved.
//

import UIKit

/// Presents a form to edit a router details.
final class EditRouterController: UITableViewController {

  var stateStore: StateStore?

  @IBOutlet weak var hostnameField: UITextField!
  @IBOutlet weak var portField: UITextField!
  @IBOutlet weak var usernameField: UITextField!
  @IBOutlet weak var passwordField: UITextField!

  @IBAction func cancel() {
    dismiss(animated: true, completion: nil)
  }

  @IBAction func save() {
    stateStore?.addRouter(
      hostname: hostnameField.text ?? "",
      port: Int(portField.text ?? "") ?? 0,
      username: usernameField.text ?? "",
      password: passwordField.text ?? "")
    dismiss(animated: true, completion: nil)
  }

}
