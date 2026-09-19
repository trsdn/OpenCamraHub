import Carbon.HIToolbox
import XCTest

final class GlobalHotKeysTests: XCTestCase {
    func testEveryDefaultCarriesControlAndOption() {
        for binding in HotKeyBinding.defaults {
            XCTAssertEqual(
                binding.modifiers & UInt32(controlKey | optionKey),
                UInt32(controlKey | optionKey),
                "key code \(binding.keyCode) must not be Option-only: on a German layout that types a character"
            )
        }
    }

    func testNoDefaultIsOptionOnly() {
        for binding in HotKeyBinding.defaults {
            XCTAssertNotEqual(binding.modifiers, UInt32(optionKey))
        }
    }

    func testNineScenesAndPauseAreBound() {
        XCTAssertEqual(HotKeyBinding.defaults.count, 10)
        XCTAssertEqual(HotKeyBinding.defaults.filter { $0.id == HotKeyBinding.pauseID }.count, 1)
    }

    func testIdsAndKeyCodesAreUnique() {
        let ids = HotKeyBinding.defaults.map(\.id)
        let codes = HotKeyBinding.defaults.map(\.keyCode)
        XCTAssertEqual(Set(ids).count, ids.count)
        XCTAssertEqual(Set(codes).count, codes.count)
    }

    func testSceneIdsAreZeroBasedIndices() {
        let sceneIDs = HotKeyBinding.defaults.filter { $0.id != HotKeyBinding.pauseID }.map(\.id)
        XCTAssertEqual(sceneIDs, Array(0..<9).map(UInt32.init))
    }
}
