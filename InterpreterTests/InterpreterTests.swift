//
//  InterpreterTests.swift
//  InterpreterTests
//
//  Created by Martins on 03/12/2018.
//  Copyright © 2018 Good Gets Better. All rights reserved.
//

import XCTest
import Interpreter

class InterpreterTests: XCTestCase {
  func testEncodedSentenceIsDecodable() {
    let commands = [Sentence(words: [
      .command("example"),
      .attribute(key: "key", value: "value"),
      .attribute(key: "valueless", value: nil),
      .query("some"),
      .empty,
    ])]

    let encoded: Data
    do {
      encoded = try encode(sentences: commands)
    } catch {
      XCTFail("Can't encode sentence, error: \(error)")
      return
    }

    let decoded: [Sentence]
    do {
      decoded = try decode(data: encoded)
    } catch {
      XCTFail("Can't decode data, error: \(error)")
      return
    }

    XCTAssertEqual(commands, decoded)
  }
}
