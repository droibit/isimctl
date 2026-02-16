import Testing
@testable import IsimctlUI

struct DeviceSelectionPurposeTests {
  // MARK: - listDevices Case

  @Test
  func listDevices_questions_shouldReturnCorrectText() {
    let purpose = DeviceSelectionPurpose.listDevices
    let questions = purpose.questions
    #expect(questions.runtime == "Which runtime's devices would you like to see?")
    #expect(questions.device == "Which device would you like to view?")
  }

  // MARK: - bootDevice Case

  @Test
  func bootDevice_questions_shouldReturnCorrectText() {
    let purpose = DeviceSelectionPurpose.bootDevice
    let questions = purpose.questions
    #expect(questions.runtime == "Which runtime contains the device to boot?")
    #expect(questions.device == "Which device would you like to boot?")
  }

  // MARK: - openDevice Case

  @Test
  func openDevice_questions_shouldReturnCorrectText() {
    let purpose = DeviceSelectionPurpose.openDevice
    let questions = purpose.questions
    #expect(questions.runtime == "Which runtime contains the device to open?")
    #expect(questions.device == "Which device would you like to open?")
  }
}
