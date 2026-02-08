import Testing
@testable import SimctlKit

struct DeviceSearchTermTests {
  @Test(arguments: [
    "booted",
    "available",
    "some-random-term",
  ])
  func init_shouldCreateInstanceWithValue(value: String) {
    let term = DeviceSearchTerm(value)
    #expect(term?.value == value)
  }

  @Test(arguments: [nil as String?, ""])
  func init_shouldReturnNil(value: String?) {
    let term = DeviceSearchTerm(value)
    #expect(term == nil)
  }

  @Test
  func booted_shouldReturnBootedInstance() {
    #expect(DeviceSearchTerm.booted.value == "booted")
  }

  @Test
  func available_shouldReturnAvailableInstance() {
    #expect(DeviceSearchTerm.available.value == "available")
  }
}
