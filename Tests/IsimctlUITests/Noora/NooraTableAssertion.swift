import Foundation
import Testing

struct NooraTableAssertion {
  let headerRow: String?
  let dataRows: [String]

  init(output: String) {
    let lines = output.split(separator: "\n").map { String($0) }
    // Filter out border lines (╭, ├, ╰)
    let contentLines = lines.filter { line in
      !line.hasPrefix("╭") && !line.hasPrefix("├") && !line.hasPrefix("╰")
    }

    // First content line is the header
    headerRow = contentLines.first
    // Remaining lines are data rows
    dataRows = Array(contentLines.dropFirst())
  }

  subscript(index: Int) -> String? {
    guard index >= 0, index < dataRows.count else {
      return nil
    }
    return dataRows[index]
  }

  func assertHeader(containsInOrder items: [String]) throws {
    let header = try #require(headerRow)
    assertRowContent(header, containsInOrder: items)
  }

  func assertRow(at index: Int, containsInOrder items: [String]) throws {
    let row = try #require(self[index])
    assertRowContent(row, containsInOrder: items)
  }

  private func assertRowContent(_ row: String, containsInOrder items: [String]) {
    var currentIndex = row.startIndex
    for item in items {
      guard let range = row.range(of: item, range: currentIndex ..< row.endIndex) else {
        Issue.record("Row does not contain '\(item)' after previous item")
        return
      }
      currentIndex = range.upperBound
    }
  }
}
