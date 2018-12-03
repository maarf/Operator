//
//  Interpreter.swift
//  Interpreter
//
//  Created by Martins on 03/12/2018.
//  Copyright © 2018 Good Gets Better. All rights reserved.
//

import Foundation

// MARK: - Encoding

public enum EncodingError: Error {
  case cantEncodeContentToData
}

public func encode(sentences: [Sentence]) throws -> Data {
  var data = Data()
  for sentence in sentences {
    for word in sentence.words {
      // Assume the content should be encoded in UTF-8.
      guard let content = word.rawValue.data(using: .utf8) else {
        throw EncodingError.cantEncodeContentToData
      }
      let length = encode(length: UInt32(content.count))
      data.append(length)
      data.append(content)
    }
  }
  return data
}

private func encode(length: UInt32) -> Data {
  if length < 0x80 {
    return Data(bytes: [UInt8(length)])
  } else if length < 0x4000 {
    let lowered = length | 0x8000;
    return Data(bytes: [
      UInt8(lowered >> 8),
      UInt8(lowered)])
  } else if length < 0x20000 {
    let lowered = length | 0xC00000;
    return Data(bytes: [
      UInt8(lowered >> 16),
      UInt8(lowered >> 8),
      UInt8(lowered)])
  } else if length < 0x10000000 {
    let lowered = length | 0xE0000000;
    return Data(bytes: [
      UInt8(lowered >> 24),
      UInt8(lowered >> 16),
      UInt8(lowered >> 8),
      UInt8(lowered)])
  } else {
    return Data(bytes: [
      0xF0,
      UInt8(length >> 24),
      UInt8(length >> 16),
      UInt8(length >> 8),
      UInt8(length)])
  }
}

// MARK: - Decoding

public enum DecodingError: Error {
  case unexpectedEndOfWordLength
  case unexpectedEndOfWordContent
  case unexpectedControlByte
  case unexpectedFirstByte
  case cantDecodeWordContent
  case unrecognizedWord
}

public func decode(data: Data) throws -> [Sentence] {
  var iterator = data.makeIterator()
  var sentences = [Sentence]()
  var currentSentence = Sentence()
  while let length = try decodeLength(iterator: &iterator) {
    var content = [UInt8]()
    for _ in (0..<length) {
      guard let next = iterator.next() else {
        throw DecodingError.unexpectedEndOfWordContent
      }
      content.append(next)
    }
    guard let contentString = String(bytes: content, encoding: .utf8) else {
      throw DecodingError.cantDecodeWordContent
    }
    guard let word = Word(rawValue: contentString) else {
      throw DecodingError.unrecognizedWord
    }
    currentSentence.words.append(word)
    if word == .empty {
      sentences.append(currentSentence)
      currentSentence = Sentence()
    }
  }
  if !currentSentence.words.isEmpty {
    sentences.append(currentSentence)
  }
  return sentences
}

private func decodeLength(iterator: inout Data.Iterator) throws -> UInt32? {
  guard let first = iterator.next() else { return nil }
  var length: UInt32 = 0
  if first < 0x80 {
    return UInt32(first)
  } else if first < 0xC0 {
    length = UInt32(first) << 8
    guard let m = iterator.next() else {
      throw DecodingError.unexpectedEndOfWordLength
    }
    length += UInt32(m)
    return length ^ 0x8000
  } else if first < 0xE0 {
    length = UInt32(first)
    for _ in (0...1) {
      length = length << 8
      guard let m = iterator.next() else {
        throw DecodingError.unexpectedEndOfWordLength
      }
      length += UInt32(m)
    }
    return length ^ 0xC00000
  } else if first < 0xF0 {
    length = UInt32(first)
    for _ in (0...2) {
      length = length << 8
      guard let m = iterator.next() else {
        throw DecodingError.unexpectedEndOfWordLength
      }
      length += UInt32(m)
    }
    return length ^ 0xE0000000
  } else if first == 0xF0 {
    for _ in (0...3) {
      length = length << 8
      guard let m = iterator.next() else {
        throw DecodingError.unexpectedEndOfWordLength
      }
      length += UInt32(m)
    }
    return length
  } else if first >= 0xF8 {
    throw DecodingError.unexpectedControlByte
  } else {
    throw DecodingError.unexpectedFirstByte
  }
}
