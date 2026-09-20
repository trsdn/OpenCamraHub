import XCTest

/// Covers the arithmetic and the wire format for the Key Lights.
///
/// The colour temperature is the part worth guarding: the device speaks mired,
/// the user thinks in kelvin, and the two run in opposite directions. Getting
/// that backwards produces a control that warms the light when you ask it to
/// cool, which is easy to write and hard to spot in a diff.
final class KeyLightTests: XCTestCase {
    // MARK: - Colour temperature

    func testMiredAndKelvinAreReciprocal() {
        XCTAssertEqual(KeyLightState.kelvin(fromMired: 200), 5000)
        XCTAssertEqual(KeyLightState.mired(fromKelvin: 5000), 200)
    }

    /// The ends of the hardware range, as measured on a real lamp.
    func testHardwareRangeMapsToTheAdvertisedTemperatures() {
        XCTAssertEqual(KeyLightState.kelvin(fromMired: 143), 6993)
        XCTAssertEqual(KeyLightState.kelvin(fromMired: 344), 2907)
    }

    /// The direction that keeps catching people out.
    func testLowerMiredIsCoolerLight() {
        XCTAssertGreaterThan(
            KeyLightState.kelvin(fromMired: 150),
            KeyLightState.kelvin(fromMired: 300)
        )
    }

    func testKelvinRangeIsStatedTheWayAPersonReadsIt() {
        XCTAssertEqual(KeyLightState.kelvinRange.lowerBound, 2907)
        XCTAssertEqual(KeyLightState.kelvinRange.upperBound, 6993)
    }

    /// A kelvin value outside what the lamp can hold has to land inside the
    /// range rather than at a wrapped or negative mired value.
    func testKelvinOutsideTheRangeClampsToTheHardware() {
        XCTAssertEqual(KeyLightState.mired(fromKelvin: 20000), KeyLightState.miredRange.lowerBound)
        XCTAssertEqual(KeyLightState.mired(fromKelvin: 1000), KeyLightState.miredRange.upperBound)
        XCTAssertEqual(KeyLightState.mired(fromKelvin: 0), KeyLightState.miredRange.upperBound)
    }

    func testKelvinRoundTripsWithinTheHardwareStep() {
        // Not exact on purpose: several kelvin values share one mired step, so
        // reading back a different number is the resolution showing through
        // rather than a failed write.
        for kelvin in stride(from: 3000, through: 6900, by: 100) {
            var state = KeyLightState()
            state.kelvin = kelvin
            XCTAssertEqual(Double(state.kelvin), Double(kelvin), accuracy: 60)
        }
    }

    // MARK: - Clamping

    func testBrightnessClamps() {
        XCTAssertEqual(KeyLightState(brightness: -20).brightness, 0)
        XCTAssertEqual(KeyLightState(brightness: 500).brightness, 100)
        XCTAssertEqual(KeyLightState(brightness: 42).brightness, 42)
    }

    func testMiredClamps() {
        XCTAssertEqual(KeyLightState(mired: 10).mired, KeyLightState.miredRange.lowerBound)
        XCTAssertEqual(KeyLightState(mired: 9000).mired, KeyLightState.miredRange.upperBound)
    }

    // MARK: - Wire format

    /// The exact body a Key Light returns.
    func testLightsPayloadDecodesWhatTheDeviceSends() throws {
        let json = """
            {"numberOfLights":1,"lights":[{"on":1,"brightness":25,"temperature":154}]}
            """
        let data = try XCTUnwrap(json.data(using: .utf8))
        let payload = try JSONDecoder().decode(KeyLightClient.LightsPayload.self, from: data)

        let light = try XCTUnwrap(payload.lights.first)
        XCTAssertEqual(light.on, 1)
        XCTAssertEqual(light.brightness, 25)
        XCTAssertEqual(light.temperature, 154)

        let state = KeyLightClient.state(from: light)
        XCTAssertTrue(state.isOn)
        XCTAssertEqual(state.brightness, 25)
        XCTAssertEqual(state.kelvin, 6494)
    }

    /// `on` is 0 or 1, not a JSON boolean; decoding it as one would throw and
    /// make every lamp look unreachable.
    func testOnIsANumberRatherThanABoolean() throws {
        let json = """
            {"numberOfLights":1,"lights":[{"on":0,"brightness":100,"temperature":344}]}
            """
        let data = try XCTUnwrap(json.data(using: .utf8))
        let payload = try JSONDecoder().decode(KeyLightClient.LightsPayload.self, from: data)
        XCTAssertFalse(KeyLightClient.state(from: try XCTUnwrap(payload.lights.first)).isOn)
    }

    /// Firmware versions differ in what they echo, so a light object missing
    /// fields must still decode instead of dropping the response.
    func testAPartialLightObjectStillDecodes() throws {
        let json = """
            {"lights":[{"brightness":40}]}
            """
        let data = try XCTUnwrap(json.data(using: .utf8))
        let payload = try JSONDecoder().decode(KeyLightClient.LightsPayload.self, from: data)
        XCTAssertEqual(payload.lights.first?.brightness, 40)
        XCTAssertNil(payload.lights.first?.on)
    }

    func testAccessoryInfoDecodes() throws {
        let json = """
            {"productName":"Elgato Key Light","displayName":"Studio links",
             "serialNumber":"CW31L1A00160","firmwareVersion":"1.0.3"}
            """
        let data = try XCTUnwrap(json.data(using: .utf8))
        let info = try JSONDecoder().decode(KeyLightClient.AccessoryInfo.self, from: data)
        XCTAssertEqual(info.displayName, "Studio links")
        XCTAssertEqual(info.serialNumber, "CW31L1A00160")
    }

    // MARK: - URLs

    func testURLIsBuiltForTheDevicePort() throws {
        let url = try KeyLightClient.lightsURL(host: "192.168.2.75", port: 9123)
        XCTAssertEqual(url.absoluteString, "http://192.168.2.75:9123/elgato/lights")
    }

    /// Bonjour hands back IPv6 on plenty of networks and a bare literal has to
    /// end up bracketed or the request will not resolve.
    func testIPv6HostIsBracketed() throws {
        let url = try KeyLightClient.lightsURL(host: "fd00::1", port: 9123)
        XCTAssertEqual(url.absoluteString, "http://[fd00::1]:9123/elgato/lights")
    }

    /// The scope id on a link-local address names the interface it is
    /// reachable on. Dropping it leaves an address that parses cleanly and has
    /// no route at all, which is indistinguishable from an unplugged lamp.
    func testLinkLocalScopeIsKeptAndEscaped() throws {
        let url = try KeyLightClient.lightsURL(host: "fe80::1%en0", port: 9123)
        XCTAssertEqual(url.absoluteString, "http://[fe80::1%25en0]:9123/elgato/lights")
    }

    func testAnAddressNoURLCanBeBuiltFromThrowsInsteadOfTrapping() {
        XCTAssertThrowsError(try KeyLightClient.lightsURL(host: "not a host", port: 9123)) {
            XCTAssertEqual($0 as? KeyLightError, .invalidAddress)
        }
    }

    // MARK: - Typed-in addresses

    func testTypedAddressesAreReducedToABareHost() {
        XCTAssertEqual(KeyLightAddress.normalized("192.168.1.2"), "192.168.1.2")
        XCTAssertEqual(KeyLightAddress.normalized("  192.168.1.2 \n"), "192.168.1.2")
        XCTAssertEqual(KeyLightAddress.normalized("http://192.168.1.2"), "192.168.1.2")
        XCTAssertEqual(KeyLightAddress.normalized("HTTP://192.168.1.2:9123/elgato/lights"), "192.168.1.2")
        XCTAssertEqual(KeyLightAddress.normalized("elgato-key-light.local"), "elgato-key-light.local")
        XCTAssertEqual(KeyLightAddress.normalized("fd00::1"), "fd00::1")
        XCTAssertEqual(KeyLightAddress.normalized("[fd00::1]:9123"), "fd00::1")
        XCTAssertEqual(KeyLightAddress.normalized("fe80::1%en0"), "fe80::1%en0")
    }

    func testAddressesThatCannotBeHostsAreRefused() {
        for bad in [
            "", "   ", "not a host", "192.168.1.2 extra", "http://", "[fd00::1",
            "host\u{7}name", "höst.local", ":9123",
        ] {
            XCTAssertNil(KeyLightAddress.normalized(bad), "\(bad.debugDescription) should be refused")
        }
    }

    /// Whatever normalisation lets through must be buildable into a URL, since
    /// that is the step that used to trap.
    func testEveryAcceptedAddressBuildsAURL() throws {
        for input in [
            "192.168.1.2", "http://192.168.1.2:9123/", "fd00::1", "fe80::1%en0", "key-light_1.local",
        ] {
            let host = try XCTUnwrap(KeyLightAddress.normalized(input))
            XCTAssertNoThrow(try KeyLightClient.lightsURL(host: host, port: 9123), input)
        }
    }

    // MARK: - Manual entry visibility

    func testTheManualFormIsReachableOnceALightExists() {
        // No lights: always shown, nothing to click.
        XCTAssertTrue(LightController.showsManualEntry(hasLights: false, isAdding: false))
        // Lights present: hidden until asked for, then shown.
        XCTAssertFalse(LightController.showsManualEntry(hasLights: true, isAdding: false))
        XCTAssertTrue(LightController.showsManualEntry(hasLights: true, isAdding: true))
    }

    // MARK: - Devices

    func testDeviceIsIdentifiedBySerialNumberRatherThanAddress() {
        let before = KeyLightDevice(serialNumber: "ABC", displayName: "Left", host: "192.168.2.75")
        let after = KeyLightDevice(serialNumber: "ABC", displayName: "Left", host: "192.168.2.99")
        // Same lamp, new DHCP lease. Keying on the address would make this two
        // lamps, one of which never answers again.
        XCTAssertEqual(before.id, after.id)
        XCTAssertNotEqual(before, after)
    }

    func testDeviceRoundTripsThroughItsStoredForm() throws {
        var device = KeyLightDevice(serialNumber: "ABC", displayName: "Left", host: "10.0.0.4")
        device.isManual = true
        let data = try JSONEncoder().encode([device])
        let restored = try JSONDecoder().decode([KeyLightDevice].self, from: data)
        XCTAssertEqual(restored.first, device)
        XCTAssertEqual(restored.first?.port, KeyLightDevice.defaultPort)
    }
}

// MARK: - Writes

/// Answers a Key Light's endpoints in-process and records every `PUT`, so the
/// controller's write path can be checked without a lamp.
private final class KeyLightStubProtocol: URLProtocol {
    final class Recorder: @unchecked Sendable {
        private let lock = NSLock()
        private var stored: [KeyLightClient.LightsPayload] = []

        func record(_ payload: KeyLightClient.LightsPayload) {
            lock.lock(); defer { lock.unlock() }
            stored.append(payload)
        }

        func reset() {
            lock.lock(); defer { lock.unlock() }
            stored.removeAll()
        }

        var puts: [KeyLightClient.LightsPayload] {
            lock.lock(); defer { lock.unlock() }
            return stored
        }
    }

    static let recorder = Recorder()

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func stopLoading() {}

    override func startLoading() {
        let path = request.url?.path ?? ""
        if request.httpMethod == "PUT", let payload = Self.decodeBody(of: request) {
            Self.recorder.record(payload)
        }
        let body: String
        if path.hasSuffix("accessory-info") {
            body =
                #"{"productName":"Elgato Key Light","displayName":"Test","serialNumber":"SN1","firmwareVersion":"1"}"#
        } else {
            body = #"{"numberOfLights":1,"lights":[{"on":1,"brightness":30,"temperature":200}]}"#
        }
        let response = HTTPURLResponse(
            url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil
        )!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data(body.utf8))
        client?.urlProtocolDidFinishLoading(self)
    }

    /// A body set on a `URLRequest` reaches a protocol as a stream, not as `httpBody`.
    private static func decodeBody(of request: URLRequest) -> KeyLightClient.LightsPayload? {
        var data = request.httpBody
        if data == nil, let stream = request.httpBodyStream {
            stream.open()
            defer { stream.close() }
            var collected = Data()
            var buffer = [UInt8](repeating: 0, count: 1024)
            while stream.hasBytesAvailable {
                let count = stream.read(&buffer, maxLength: buffer.count)
                if count <= 0 { break }
                collected.append(buffer, count: count)
            }
            data = collected
        }
        return data.flatMap { try? JSONDecoder().decode(KeyLightClient.LightsPayload.self, from: $0) }
    }
}

/// A write carries what was asked for and nothing else. The cached state can be
/// twenty seconds old, and filling the other fields from it used to overwrite a
/// change made at the lamp's own switch with a value the lamp no longer had.
@MainActor
final class KeyLightWriteTests: XCTestCase {
    override func setUp() {
        super.setUp()
        KeyLightStubProtocol.recorder.reset()
    }

    private func makeController() async throws -> LightController {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [KeyLightStubProtocol.self]
        let suite = "KeyLightWriteTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        addTeardownBlock { defaults.removePersistentDomain(forName: suite) }

        let controller = LightController(
            client: KeyLightClient(session: URLSession(configuration: configuration)),
            defaults: defaults,
            debounce: .milliseconds(30)
        )
        let error = await controller.addManual(host: "192.0.2.1")
        XCTAssertNil(error)
        XCTAssertEqual(controller.lights.count, 1)
        return controller
    }

    private func puts(count: Int) async throws -> [KeyLightClient.LightsPayload] {
        for _ in 0..<100 {
            if KeyLightStubProtocol.recorder.puts.count >= count { break }
            try await Task.sleep(for: .milliseconds(20))
        }
        // Long enough for a second, unwanted write to arrive.
        try await Task.sleep(for: .milliseconds(150))
        return KeyLightStubProtocol.recorder.puts
    }

    func testChangingBrightnessSendsOnlyBrightness() async throws {
        let controller = try await makeController()
        controller.setBrightness(60, for: "SN1")

        let sent = try await puts(count: 1)
        XCTAssertEqual(sent.count, 1)
        let light = try XCTUnwrap(sent.first?.lights.first)
        XCTAssertEqual(light.brightness, 60)
        XCTAssertNil(light.on)
        XCTAssertNil(light.temperature)
    }

    func testChangesInsideTheDebounceWindowAreSentTogetherAndNothingElse() async throws {
        let controller = try await makeController()
        controller.setBrightness(60, for: "SN1")
        controller.setOn(false, for: "SN1")

        let sent = try await puts(count: 1)
        XCTAssertEqual(sent.count, 1)
        let light = try XCTUnwrap(sent.first?.lights.first)
        XCTAssertEqual(light.brightness, 60)
        XCTAssertEqual(light.on, 0)
        XCTAssertNil(light.temperature)
    }

    /// The merged change has to be forgotten once it reaches the lamp, or the
    /// next unrelated edit would resend a brightness nobody asked for.
    func testAFinishedWriteIsNotResentWithTheNextOne() async throws {
        let controller = try await makeController()
        controller.setBrightness(60, for: "SN1")
        _ = try await puts(count: 1)

        controller.setOn(false, for: "SN1")
        let sent = try await puts(count: 2)
        XCTAssertEqual(sent.count, 2)
        let light = try XCTUnwrap(sent.last?.lights.first)
        XCTAssertEqual(light.on, 0)
        XCTAssertNil(light.brightness)
        XCTAssertNil(light.temperature)
    }
}

/// A failed `NWBrowser` never becomes ready again, so discovery replaces it.
/// Without a ceiling the retry would turn a flaky network into a spin, and
/// without a reset a late failure would inherit a long delay for good.
@MainActor
final class KeyLightDiscoveryRetryTests: XCTestCase {
    func testTheRetryDelayDoublesUpToItsCeiling() {
        var delay = KeyLightDiscovery.firstRetryDelay
        var seen = [delay]
        for _ in 0..<8 {
            delay = KeyLightDiscovery.nextRetryDelay(after: delay)
            seen.append(delay)
        }
        XCTAssertEqual(Array(seen.prefix(4)), [2, 4, 8, 16])
        XCTAssertEqual(seen.last, KeyLightDiscovery.maximumRetryDelay)
        XCTAssertTrue(
            zip(seen, seen.dropFirst()).allSatisfy { $0 <= $1 },
            "The delay must never shrink on its own; only a ready browser resets it."
        )
    }
}
