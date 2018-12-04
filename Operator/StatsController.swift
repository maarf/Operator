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
  let name: String
  init(pairs: [(key: String, value: String)]) {
    var proposedName = "Unknown"
    presentable = pairs
      .filter { key, value in
        if key == ".id" {
          return false
        } else if key == "name" {
          proposedName = value
          return false
        } else if key == "default-name" && value == proposedName {
          return false
        }
        return true
      }
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
        let isCompact = key.contains("byte")
          || key.contains("packet")
          || key.contains("drop")
          || key.contains("error")
        return Item(
          title: title,
          value: value,
          size: isCompact ? .compact : .normal)
      }
    name = proposedName
  }
  struct Item: Equatable {
    let title: String
    let value: String
    let size: Size
    enum Size {
      case compact, normal
    }
  }
}

final class StatsController: UIViewController {

  @IBOutlet weak var collectionView: UICollectionView!

  override func viewDidLoad() {
    super.viewDidLoad()
    collectionView.dataSource = self
    collectionView.delegate = self
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
    let item = stats[indexPath.section].presentable[indexPath.item]

    guard
      let cell = collectionView.dequeueReusableCell(
        withReuseIdentifier: item.size == .compact
          ? "StatsCompactItemCell"
          : "StatsItemCell",
        for: indexPath) as? StatsItemCell
    else {
      fatalError("Unrecognized cell")
    }
    cell.titleLabel.text = item.title
    cell.valueLabel.text = item.value
    return cell
  }

  func collectionView(
    _ collectionView: UICollectionView,
    viewForSupplementaryElementOfKind kind: String,
    at indexPath: IndexPath
  ) -> UICollectionReusableView {
    guard let view = collectionView.dequeueReusableSupplementaryView(
      ofKind: kind,
      withReuseIdentifier: "StatsSectionHeader",
      for: indexPath) as? StatsSectionHeader
    else {
      return UICollectionReusableView()
    }
    view.titleLabel.text = stats[indexPath.section].name
    return view
  }
}

extension StatsController: UICollectionViewDelegate {
}

extension StatsController: UICollectionViewDelegateFlowLayout {
  func collectionView(
    _ collectionView: UICollectionView,
    layout collectionViewLayout: UICollectionViewLayout,
    sizeForItemAt indexPath: IndexPath
  ) -> CGSize {
    let item = stats[indexPath.section].presentable[indexPath.item]
    let safeWidth = collectionView.frame.size.width
      - (collectionView.window?.safeAreaInsets.left ?? 0)
      - (collectionView.window?.safeAreaInsets.right ?? 0)
    switch item.size {
      case .compact:
        let columns = min(safeWidth / 120, 4)
        return CGSize(
          width: floor(safeWidth / columns),
          height: 52)
      case .normal:
        return CGSize(
          width: safeWidth,
          height: 44)
    }
  }
}

final class StatsItemCell: UICollectionViewCell {

  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var valueLabel: UILabel!

  override init(frame: CGRect) {
    super.init(frame: frame)
    contentView.layer.addSublayer(borderLayer)
  }

  required init?(coder decoder: NSCoder) {
    super.init(coder: decoder)
    contentView.layer.addSublayer(borderLayer)
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    let contentFrame = contentView.layer.frame
    let hairline = 1.0 / UIScreen.main.scale
    borderLayer.frame = CGRect(
      x: contentFrame.minX + 12,
      y: contentFrame.maxY - hairline,
      width: contentFrame.width - 12,
      height: hairline)
  }

  let borderLayer: CALayer = {
    let layer = CALayer()
    layer.backgroundColor = UIColor(white: 0.84, alpha: 1).cgColor
    return layer
  }()
}

final class StatsSectionHeader: UICollectionReusableView {

  @IBOutlet weak var titleLabel: UILabel!

}
