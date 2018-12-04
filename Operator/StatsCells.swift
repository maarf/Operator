//
//  StatsCells.swift
//  Operator
//
//  Created by Martins on 04/12/2018.
//  Copyright © 2018 Good Gets Better. All rights reserved.
//

import UIKit

final class StatsSectionHeader: UICollectionReusableView {

  @IBOutlet weak var titleLabel: UILabel!

}

final class StatsItemCell: UICollectionViewCell {

  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var valueLabel: UILabel!

  override init(frame: CGRect) {
    super.init(frame: frame)
    contentView.layer.insertSublayer(graphLayer, at: 0)
    contentView.layer.addSublayer(borderLayer)
  }

  required init?(coder decoder: NSCoder) {
    super.init(coder: decoder)
    contentView.layer.insertSublayer(graphLayer, at: 0)
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
    graphLayer.frame = CGRect(
      x: contentFrame.minX + 12,
      y: contentFrame.minY,
      width: contentFrame.width - 12,
      height: contentFrame.height)
  }

  let graphLayer: GraphLayer = {
    let layer = GraphLayer()
    // Don't implicitly animate hiding because cells are reused and constantly
    // change the state.
    layer.actions = ["hidden": NSNull()]
    layer.fillColor = UIColor.clear.cgColor
    layer.isHidden = true
    layer.strokeColor = UIColor(white: 0.7, alpha: 1).cgColor
    return layer
  }()

  let borderLayer: CALayer = {
    let layer = CALayer()
    layer.backgroundColor = UIColor(white: 0.84, alpha: 1).cgColor
    return layer
  }()
}

final class GraphLayer: CAShapeLayer {
  var values = [Int]() {
    didSet {
      setNeedsDisplay()
    }
  }

  override func display() {
    path = makePath()
    super.display()
  }

  private func makePath() -> CGPath {
    let width = Int(frame.width)
    let height = frame.height
    let usableValues = values.suffix(width)
    let min = usableValues.min() ?? 0
    let max = usableValues.max() ?? 0
    let delta = max - min
    let path = CGMutablePath()
    let firstValue = usableValues.first ?? 0
    let relative: CGFloat = delta == 0
      ? 0
      : CGFloat(firstValue - min) / CGFloat(delta)
    path.move(to: CGPoint(
      x: 0,
      y: height - height * relative))
    for (i, value) in usableValues.enumerated() {
      let relative: CGFloat = delta == 0
        ? 0
        : CGFloat(value - min) / CGFloat(delta)
      path.addLine(to: CGPoint(
        x: CGFloat(i),
        y: height - height * relative))
    }
    return path
  }
}
