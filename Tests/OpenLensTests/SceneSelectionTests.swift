import Combine
import XCTest

/// Guards the selection publisher against `@Published`'s `willSet` timing.
///
/// A subscriber to `$selectedSceneID` runs before the property holds the new
/// value. `AppModel` used to ignore the emitted ID and read `selectedScene`,
/// which applied the scene being left: pick B and A was applied, pick A again
/// and B was.
@MainActor
final class SceneSelectionTests: XCTestCase {
    private var defaults: UserDefaults!
    private var suiteName: String!
    private var cancellables = Set<AnyCancellable>()

    override func setUp() {
        super.setUp()
        suiteName = "openlens.tests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
    }

    override func tearDown() {
        cancellables.removeAll()
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        suiteName = nil
        super.tearDown()
    }

    private let device = CaptureDeviceInfo(id: "cam-link-4k", name: "Cam Link 4K", isBuiltIn: false)

    /// A store holding two scenes, "A" and "B", with A selected.
    private func storeWithTwoScenes() -> SceneStore {
        let store = SceneStore(defaults: defaults)
        store.addScene(device: device)
        store.addScene(device: device)
        store.rename(id: store.scenes[0].id, to: "A")
        store.rename(id: store.scenes[1].id, to: "B")
        store.select(store.scenes[0])
        return store
    }

    private func names(emittedBy store: SceneStore, while body: () -> Void) -> [String?] {
        var emitted: [String?] = []
        store.selectedSceneChanges
            .dropFirst()
            .sink { emitted.append($0?.name) }
            .store(in: &cancellables)
        body()
        return emitted
    }

    func testSelectingASceneEmitsThatScene() {
        let store = storeWithTwoScenes()

        let emitted = names(emittedBy: store) {
            store.select(store.scenes[1])
        }

        XCTAssertEqual(emitted, ["B"])
    }

    func testSwitchingBackAndForthEmitsTheSceneBeingSelectedEachTime() {
        let store = storeWithTwoScenes()

        let emitted = names(emittedBy: store) {
            store.select(store.scenes[1])
            store.select(store.scenes[0])
            store.select(store.scenes[1])
        }

        XCTAssertEqual(emitted, ["B", "A", "B"])
    }

    /// The trap itself. If this ever starts returning "B", `@Published` changed
    /// its timing and the ID-based resolution has become unnecessary, which is
    /// worth knowing rather than silently relying on.
    func testReadingTheSelectionInsideTheSinkStillSeesTheSceneBeingLeft() {
        let store = storeWithTwoScenes()
        var seenByNaiveReader: [String?] = []
        store.$selectedSceneID
            .dropFirst()
            .removeDuplicates()
            .sink { _ in seenByNaiveReader.append(store.selectedScene?.name) }
            .store(in: &cancellables)

        store.select(store.scenes[1])

        XCTAssertEqual(seenByNaiveReader, ["A"])
    }

    func testAddingASceneEmitsTheNewScene() {
        let store = storeWithTwoScenes()

        let emitted = names(emittedBy: store) {
            store.addScene(device: device)
        }

        XCTAssertEqual(emitted, ["Scene 3"])
    }

    func testRemovingTheSelectedSceneEmitsTheOneThatTakesItsPlace() {
        let store = storeWithTwoScenes()
        store.select(store.scenes[1])

        let emitted = names(emittedBy: store) {
            store.remove(store.scenes[1])
        }

        XCTAssertEqual(emitted, ["A"])
    }

    func testRemovingTheLastSceneEmitsNothingToApply() {
        let store = SceneStore(defaults: defaults)
        store.addScene(device: device)

        let emitted = names(emittedBy: store) {
            store.remove(store.scenes[0])
        }

        XCTAssertEqual(emitted, [nil])
    }

    func testAnUnknownIDResolvesToNoScene() {
        let store = storeWithTwoScenes()

        XCTAssertNil(store.scene(for: nil))
        XCTAssertNil(store.scene(for: UUID()))
        XCTAssertEqual(store.scene(for: store.scenes[1].id)?.name, "B")
    }

    // MARK: - Renaming by ID

    func testRenamingByIDLeavesTheSelectedSceneAlone() {
        let store = storeWithTwoScenes()
        let first = store.scenes[0].id
        store.select(store.scenes[1])

        store.rename(id: first, to: "Desk")

        XCTAssertEqual(store.scenes[0].name, "Desk")
        XCTAssertEqual(store.scenes[1].name, "B")
        XCTAssertEqual(store.selectedScene?.name, "B")
    }

    func testARenameIsWrittenToDisk() {
        let store = storeWithTwoScenes()
        store.rename(id: store.scenes[0].id, to: "Desk")

        let reloaded = SceneStore(defaults: defaults)

        XCTAssertEqual(reloaded.scenes.map(\.name), ["Desk", "B"])
    }

    func testAnEmptyNameIsRefused() {
        let store = storeWithTwoScenes()
        let first = store.scenes[0].id

        store.rename(id: first, to: "")
        store.rename(id: first, to: "   ")

        XCTAssertEqual(store.scenes[0].name, "A")
    }

    func testRenamingAnUnknownSceneChangesNothing() {
        let store = storeWithTwoScenes()

        store.rename(id: UUID(), to: "Ghost")

        XCTAssertEqual(store.scenes.map(\.name), ["A", "B"])
    }

    // MARK: - Reordering

    func testMovingASceneRightSwapsItWithItsNeighbour() {
        let store = storeWithTwoScenes()

        store.move(store.scenes[0], by: 1)

        XCTAssertEqual(store.scenes.map(\.name), ["B", "A"])
    }

    func testMovingTheFirstSceneLeftDoesNothing() {
        let store = storeWithTwoScenes()

        store.move(store.scenes[0], by: -1)

        XCTAssertEqual(store.scenes.map(\.name), ["A", "B"])
    }

    func testMovingTheLastSceneRightDoesNothing() {
        let store = storeWithTwoScenes()

        store.move(store.scenes[1], by: 1)

        XCTAssertEqual(store.scenes.map(\.name), ["A", "B"])
    }

    func testMovingAnUnknownSceneChangesNothing() {
        let store = storeWithTwoScenes()
        let ghost = CameraScene(name: "Ghost", deviceID: device.id, deviceName: device.name)

        store.move(ghost, by: 1)

        XCTAssertEqual(store.scenes.map(\.name), ["A", "B"])
    }

    /// Selection follows the scene by ID, so reordering the array must not
    /// silently select whatever ends up at the old index instead.
    func testMovingTheSelectedSceneLeavesItSelected() {
        let store = storeWithTwoScenes()
        store.select(store.scenes[0])

        store.move(store.scenes[0], by: 1)

        XCTAssertEqual(store.selectedScene?.name, "A")
    }

    func testAMoveIsWrittenToDisk() {
        let store = storeWithTwoScenes()
        store.move(store.scenes[0], by: 1)

        let reloaded = SceneStore(defaults: defaults)

        XCTAssertEqual(reloaded.scenes.map(\.name), ["B", "A"])
    }

    // MARK: - Reordering to an arbitrary index (drag and drop)

    /// A three-scene store, "A", "B" and "C", with A selected.
    private func storeWithThreeScenes() -> SceneStore {
        let store = SceneStore(defaults: defaults)
        store.addScene(device: device)
        store.addScene(device: device)
        store.addScene(device: device)
        store.rename(id: store.scenes[0].id, to: "A")
        store.rename(id: store.scenes[1].id, to: "B")
        store.rename(id: store.scenes[2].id, to: "C")
        store.select(store.scenes[0])
        return store
    }

    func testMovingToAnIndexPastItPushesTheOthersLeft() {
        let store = storeWithThreeScenes()

        store.move(store.scenes[0], toIndex: 2)

        XCTAssertEqual(store.scenes.map(\.name), ["B", "C", "A"])
    }

    func testMovingToAnIndexBeforeItPushesTheOthersRight() {
        let store = storeWithThreeScenes()

        store.move(store.scenes[2], toIndex: 0)

        XCTAssertEqual(store.scenes.map(\.name), ["C", "A", "B"])
    }

    func testMovingToItsOwnIndexChangesNothing() {
        let store = storeWithThreeScenes()

        store.move(store.scenes[1], toIndex: 1)

        XCTAssertEqual(store.scenes.map(\.name), ["A", "B", "C"])
    }

    func testMovingToAnOutOfRangeIndexChangesNothing() {
        let store = storeWithThreeScenes()

        store.move(store.scenes[0], toIndex: 3)
        store.move(store.scenes[0], toIndex: -1)

        XCTAssertEqual(store.scenes.map(\.name), ["A", "B", "C"])
    }

    func testMovingAnUnknownSceneToAnIndexChangesNothing() {
        let store = storeWithThreeScenes()
        let ghost = CameraScene(name: "Ghost", deviceID: device.id, deviceName: device.name)

        store.move(ghost, toIndex: 1)

        XCTAssertEqual(store.scenes.map(\.name), ["A", "B", "C"])
    }

    func testMovingTheSelectedSceneToAnIndexLeavesItSelected() {
        let store = storeWithThreeScenes()
        store.select(store.scenes[0])

        store.move(store.scenes[0], toIndex: 2)

        XCTAssertEqual(store.selectedScene?.name, "A")
    }

    func testAMoveToAnIndexIsWrittenToDisk() {
        let store = storeWithThreeScenes()
        store.move(store.scenes[0], toIndex: 2)

        let reloaded = SceneStore(defaults: defaults)

        XCTAssertEqual(reloaded.scenes.map(\.name), ["B", "C", "A"])
    }
}
