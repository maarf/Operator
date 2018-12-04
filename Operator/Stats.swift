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

struct Stats {
  var presentable = [Item]()
  var name = "Unknown"
  var transferData = [TransferDataPoint]()

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

  init(pairs: [(key: String, value: String)]) {
    for (key, value) in pairs {
      switch key {
        case "rx-byte": rxBytes = Int(value) ?? 0
        case "tx-byte": txBytes = Int(value) ?? 0
        case "rx-packet": rxPackets = Int(value) ?? 0
        case "tx-packets": txPackets = Int(value) ?? 0
        case "rx-drops": rxDrops = Int(value) ?? 0
        case "tx-drops": txDrops = Int(value) ?? 0
        case "rx-errors": rxErrors = Int(value) ?? 0
        case "tx-errors": txErrors = Int(value) ?? 0
        default: ()
      }
    }
  }
}
