//
//  StatsController.swift
//  Operator
//
//  Created by Martins on 03/12/2018.
//  Copyright © 2018 Good Gets Better. All rights reserved.
//

import UIKit

final class StatsController: UIViewController, StateSubscriber {

  @IBOutlet weak var collectionView: UICollectionView!

  override func viewDidLoad() {
    super.viewDidLoad()
    collectionView.dataSource = self
    collectionView.delegate = self
  }

  override func viewWillAppear(_ animated: Bool) {
    stateStore?.subscribe(self)
  }

  override func viewDidDisappear(_ animated: Bool) {
    stateStore?.unsubscribe(self)
  }

  // MARK: - State

  var stateStore: StateStore?

  func newState(_ state: State) {
    if let routerId = state.selectedRouterId {
      stats = state.stats[routerId] ?? []
      title = state.routers
        .first(where: { $0.id == routerId })?
        .hostname
        ?? "Stats"
    }
  }

  var stats = [Stats]() {
    didSet {
      if collectionView != nil {
        collectionView.reloadData()
      }
    }
  }
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
