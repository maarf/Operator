//
//  RoutersController.swift
//  Operator
//
//  Created by Martins on 03/12/2018.
//  Copyright © 2018 Good Gets Better. All rights reserved.
//

import UIKit

struct Router: Equatable {
  typealias Id = String
  var id: Id
  var hostname: String
  var port: Int
  var username: String
  var password: String
  var isConnected: Bool
}

final class RoutersController: UITableViewController, StateSubscriber {

  var statsController: StatsController? = nil

  // MARK: - Lifecycle

  override func viewDidLoad() {
    super.viewDidLoad()
    navigationItem.leftBarButtonItem = editButtonItem

    let addButton = UIBarButtonItem(
      barButtonSystemItem: .add,
      target: self,
      action: #selector(insertNewObject(_:)))
    navigationItem.rightBarButtonItem = addButton
    if let split = splitViewController {
      statsController = (split.viewControllers.last as? UINavigationController)?
        .topViewController as? StatsController
    }
  }

  override func viewWillAppear(_ animated: Bool) {
    clearsSelectionOnViewWillAppear = splitViewController!.isCollapsed
    stateStore?.subscribe(self)
    super.viewWillAppear(animated)
  }

  override func viewDidDisappear(_ animated: Bool) {
    stateStore?.unsubscribe(self)
  }

  // MARK: - State

  var stateStore: StateStore?
  
  func newState(_ state: State) {
    routers = state.routers
  }

  var routers = [Router]() {
    didSet {
      self.tableView.reloadData()
    }
  }

  // MARK: - Actions

  @objc
  func insertNewObject(_ sender: Any) {
//    objects.insert(NSDate(), at: 0)
//    let indexPath = IndexPath(row: 0, section: 0)
//    tableView.insertRows(at: [indexPath], with: .automatic)
  }

  // MARK: - Segues

  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    guard
      segue.identifier == "showDetail",
      let indexPath = tableView.indexPathForSelectedRow,
      let navigation = segue.destination as? UINavigationController,
      let stats = navigation.topViewController as? StatsController
    else { return }
    stats.stateStore = stateStore
    stateStore?.select(routerId: routers[indexPath.row].id)
    stats.navigationItem.leftBarButtonItem =
      splitViewController?.displayModeButtonItem
    stats.navigationItem.leftItemsSupplementBackButton = true
  }

  // MARK: - Table View

  override func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }

  override func tableView(
    _ tableView: UITableView,
    numberOfRowsInSection section: Int
  ) -> Int {
    return routers.count
  }

  override func tableView(
    _ tableView: UITableView,
    cellForRowAt indexPath: IndexPath
  ) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(
      withIdentifier: "Cell",
      for: indexPath)
    let router = routers[indexPath.row]
    cell.textLabel!.text = router.hostname + ":" + String(router.port)
    return cell
  }

  override func tableView(
    _ tableView: UITableView,
    canEditRowAt indexPath: IndexPath
  ) -> Bool {
    return true
  }

  override func tableView(
    _ tableView: UITableView,
    commit editingStyle: UITableViewCell.EditingStyle,
    forRowAt indexPath: IndexPath
  ) {
    if editingStyle == .delete {
      routers.remove(at: indexPath.row)
      tableView.deleteRows(at: [indexPath], with: .fade)
    }
  }
}
