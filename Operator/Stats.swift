//
//  Stats.swift
//  Operator
//
//  Created by Martins on 04/12/2018.
//  Copyright © 2018 Good Gets Better. All rights reserved.
//

import Foundation

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

private let numberFormatter: NumberFormatter = {
  let formatter = NumberFormatter()
  formatter.numberStyle = .decimal
  return formatter
}()

/// Model struct for router's statistics.
struct Stats {
  var presentable = [Item]()
  var name = "Unknown"
  var transferData = [TransferDataPoint]()

  struct Item: Equatable {
    let key: String
    let title: String
    let value: String
    let size: Size

    enum Size {
      case compact, normal
    }
  }

  init(pairs: [(key: String, value: String)]) {
    transferData.append(TransferDataPoint(pairs: pairs))
    presentable = pairs
      .filter { key, value in
        if key == ".id" {
          return false
        } else if key == "name" {
          name = value
          return false
        } else if key == "default-name" && value == name {
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
        } else if
          let int = Int(value),
          let formatted = numberFormatter.string(
            from: NSNumber(integerLiteral: int))
        {
          value = formatted
        }
        return Item(
          key: key,
          title: format(title: key),
          value: value,
          size: isCompact(key: key) ? .compact : .normal)
      }
  }

  func graphValues(forKey key: String) -> [Int]? {
    switch key {
      case "rx-byte": return transferData.map { $0.rxBytes }
      case "tx-byte": return transferData.map { $0.txBytes }
      case "rx-packet": return transferData.map { $0.rxPackets }
      case "tx-packet": return transferData.map { $0.txPackets }
      case "rx-drop": return transferData.map { $0.rxDrops }
      case "tx-drop": return transferData.map { $0.txDrops }
      case "rx-error": return transferData.map { $0.rxErrors }
      case "tx-error": return transferData.map { $0.txErrors }
      case "tx-queue-drop": return transferData.map { $0.txQueueDrops }
      case "fp-rx-byte": return transferData.map { $0.fpRxBytes }
      case "fp-tx-byte": return transferData.map { $0.fpTxBytes }
      case "fp-rx-packet": return transferData.map { $0.fpRxPackets }
      case "fp-tx-packet": return transferData.map { $0.fpTxPackets }
      default: return nil
    }
  }

  private func format(title: String) -> String {
    var title = title.capitalized
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
    return title.replacingOccurrences(of: "Error", with: "Errors")
  }

  private static let compactKeywords = Set(["byte", "packet", "drop", "error"])

  private func isCompact(key: String) -> Bool {
    for keyword in Stats.compactKeywords {
      if key.contains(keyword) {
        return true
      }
    }
    return false
  }
}

extension Stats: Equatable {
  /// Compares two instances of stats by ignoring transfer data.
  static func == (lhs: Stats, rhs: Stats) -> Bool {
    return lhs.presentable == rhs.presentable && lhs.name == rhs.name
  }
}

struct TransferDataPoint {
  var rxBytes = 0
  var txBytes = 0
  var rxPackets = 0
  var txPackets = 0
  var rxDrops = 0
  var txDrops = 0
  var rxErrors = 0
  var txErrors = 0
  var txQueueDrops = 0
  var fpRxBytes = 0
  var fpTxBytes = 0
  var fpRxPackets = 0
  var fpTxPackets = 0

  init(pairs: [(key: String, value: String)]) {
    for (key, value) in pairs {
      switch key {
        case "rx-byte": rxBytes = Int(value) ?? 0
        case "tx-byte": txBytes = Int(value) ?? 0
        case "rx-packet": rxPackets = Int(value) ?? 0
        case "tx-packet": txPackets = Int(value) ?? 0
        case "rx-drop": rxDrops = Int(value) ?? 0
        case "tx-drop": txDrops = Int(value) ?? 0
        case "rx-error": rxErrors = Int(value) ?? 0
        case "tx-error": txErrors = Int(value) ?? 0
        case "tx-queue-drop": txQueueDrops = Int(value) ?? 0
        case "fp-rx-byte": fpRxBytes = Int(value) ?? 0
        case "fp-tx-byte": fpTxBytes = Int(value) ?? 0
        case "fp-rx-packet": fpRxPackets = Int(value) ?? 0
        case "fp-tx-packet": fpTxPackets = Int(value) ?? 0
        default: ()
      }
    }
  }
}
