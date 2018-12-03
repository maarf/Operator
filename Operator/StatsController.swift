//
//  StatsController.swift
//  Operator
//
//  Created by Martins on 03/12/2018.
//  Copyright © 2018 Good Gets Better. All rights reserved.
//

import UIKit

struct Stats: Equatable {
  let presentable: [Item]
  init(pairs: [(key: String, value: String)]) {
    presentable = pairs
      .filter { key, _ in key != ".id" }
      .map { pair in
        let (key, value) = pair
        return Item(title: key, value: value)
      }
  }
  struct Item: Equatable {
    let title: String
    let value: String
  }
}

final class StatsController: UIViewController {

  @IBOutlet weak var collectionView: UICollectionView!

  override func viewDidLoad() {
    super.viewDidLoad()
    collectionView.dataSource = self
  }

  var stats = [Stats]()
}

extension StatsController: UICollectionViewDataSource {

  func numberOfSections(in collectionView: UICollectionView) -> Int {
    return stats.count
  }

  func collectionView(
    _ collectionView: UICollectionView,
    numberOfItemsInSection section: Int
  ) -> Int {
    return stats[section].presentable.count
  }

  func collectionView(
    _ collectionView: UICollectionView,
    cellForItemAt indexPath: IndexPath
  ) -> UICollectionViewCell {
    guard
      let cell = collectionView.dequeueReusableCell(
        withReuseIdentifier: "StatsTitleValueCell",
        for: indexPath) as? StatsTitleValueCell
    else {
      fatalError("Unrecognized cell")
    }
    let item = stats[indexPath.section].presentable[indexPath.item]
    cell.titleLabel.text = item.title
    cell.valueLabel.text = item.value
    return cell
  }
}

final class StatsTitleValueCell: UICollectionViewCell {

  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var valueLabel: UILabel!

}
