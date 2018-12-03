//
//  StatsController.swift
//  Operator
//
//  Created by Martins on 03/12/2018.
//  Copyright © 2018 Good Gets Better. All rights reserved.
//

import UIKit

private let inputFormatter: DateFormatter = {
  let inputFormatter = DateFormatter()
  inputFormatter.dateFormat = "MMM/dd/yyyy HH:mm:ss"
  inputFormatter.locale = Locale(identifier: "en_US_POSIX")
  return inputFormatter
}()

private let dateFormatter: DateFormatter = {
  let dateFormatter = DateFormatter()
  dateFormatter.dateStyle = .medium
  dateFormatter.timeStyle = .medium
  return dateFormatter
}()

struct Stats: Equatable {
  let presentable: [Item]
  init(pairs: [(key: String, value: String)]) {
    presentable = pairs
      .filter { key, _ in key != ".id" }
      .map { pair in
        var (key, value) = pair
        if
          key == "last-link-up-time",
          let date = inputFormatter.date(from: value)
        {
          value = dateFormatter.string(from: date)
        }
        var title = key
        title = title.capitalized
        title = title.replacingOccurrences(of: "-", with: " ")
        title = title.replacingOccurrences(of: "Mtu", with: "MTU")
        title = title.replacingOccurrences(of: "Mac", with: "MAC")
        title = title.replacingOccurrences(of: "Up Time", with: "Uptime")
        title = title.replacingOccurrences(of: "Rx", with: "RX")
        title = title.replacingOccurrences(of: "Tx", with: "TX")
        title = title.replacingOccurrences(of: "Fp", with: "FP")
        title = title.replacingOccurrences(of: "Byte", with: "Bytes")
        title = title.replacingOccurrences(of: "Packet", with: "Packets")
        title = title.replacingOccurrences(of: "Drop", with: "Drops")
        title = title.replacingOccurrences(of: "Error", with: "Errors")
        return Item(title: title, value: value)
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
