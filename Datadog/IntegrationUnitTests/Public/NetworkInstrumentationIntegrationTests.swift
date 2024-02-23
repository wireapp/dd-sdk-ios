/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Datadog (https://www.datadoghq.com/).
 * Copyright 2019-Present Datadog, Inc.
 */

import XCTest
import TestUtilities
import DatadogInternal

@testable import DatadogRUM
@testable import DatadogTrace
@testable import DatadogCore

class NetworkInstrumentationIntegrationTests: XCTestCase {
    // swiftlint:disable implicitly_unwrapped_optional
    private var core: DatadogCoreProxy!
    // swiftlint:enable implicitly_unwrapped_optional

    override func setUp() {
        core = DatadogCoreProxy(
            context: .mockWith(
                env: "test",
                version: "1.1.1",
                serverTimeOffset: 123
            )
        )

        var config = Trace.Configuration(
            urlSessionTracking: Trace.Configuration.URLSessionTracking(
                firstPartyHostsTracing: .traceWithHeaders(
                    hostsWithHeaders: ["www.example.com": [.datadog]],
                    sampleRate: 100
                )
            )
        )
        config.traceIDGenerator = RelativeTracingUUIDGenerator(startingFrom: 1, advancingByCount: 1)

        Trace.enable(
            with: config,
            in: core
        )

        URLSessionInstrumentation.enable(
            with: URLSessionInstrumentation.Configuration(delegateClass: MockDelegate.self),
            in: core
        )
    }

    override func tearDown() {
        core.flushAndTearDown()
        core = nil
    }

    func testParentSpanPropagation() throws {
        let expectation = expectation(description: "request completes")
        // Given
        let request: URLRequest = .mockWith(url: "https://www.example.com")
        let span = Tracer.shared(in: core).startRootSpan(operationName: "root")
        let server = ServerMock(delivery: .success(response: .mockResponseWith(statusCode: 200), data: .mock(ofSize: 10)))
        let session = server.getInterceptedURLSession(delegate: MockDelegate())

        // When
        span.setActive() // start root span

        session
            .dataTask(with: request) { _,_,_ in
                span.finish() // finish root span
                expectation.fulfill()
            }
            .resume()

        // Then
        waitForExpectations(timeout: 1)
        let matchers = try core.waitAndReturnSpanMatchers()

        let matcher1 = try XCTUnwrap(matchers.first)
        try XCTAssertEqual(matcher1.operationName(), "root")
        try XCTAssertEqual(matcher1.traceID(), "1")
        try XCTAssertEqual(matcher1.spanID(), "2")
        try XCTAssertEqual(matcher1.metrics.isRootSpan(), 1)

        let matcher2 = try XCTUnwrap(matchers.last)
        try XCTAssertEqual(matcher2.operationName(), "urlsession.request")
        try XCTAssertEqual(matcher2.traceID(), "1")
        try XCTAssertEqual(matcher2.parentSpanID(), "2")
        try XCTAssertEqual(matcher2.spanID(), "3")
    }

    class MockDelegate: NSObject, URLSessionDataDelegate {
    }

    func testResourceAttributesProvider_givenURLSessionDataTaskRequest() {
        core = DatadogCoreProxy(
            context: .mockWith(
                env: "test",
                version: "1.1.1",
                serverTimeOffset: 123
            )
        )

        let providerExpectation = expectation(description: "provider called")
        var providerDataCount = 0
        RUM.enable(
            with: .init(
                applicationID: .mockAny(),
                urlSessionTracking: .init(
                    resourceAttributesProvider: { req, resp, data, err in
                        XCTAssertNotNil(data)
                        XCTAssertTrue(data!.count > 0)
                        providerDataCount = data!.count
                        providerExpectation.fulfill()
                        return [:]
                })
            ),
            in: core
        )

        URLSessionInstrumentation.enable(
            with: .init(
                delegateClass: InstrumentedSessionDelegate.self
            ),
            in: core
        )

        let session = URLSession(
            configuration: .ephemeral,
            delegate: InstrumentedSessionDelegate(),
            delegateQueue: nil
        )
        var request = URLRequest(url: URL(string: "https://www.datadoghq.com/")!)
        request.httpMethod = "GET"

        let task = session.dataTask(with: request)
        task.resume()

        wait(for: [providerExpectation], timeout: 10)
        XCTAssertTrue(providerDataCount > 0)
    }

    func testResourceAttributesProvider_givenURLSessionDataTaskRequestWithCompletionHandler() {
        core = DatadogCoreProxy(
            context: .mockWith(
                env: "test",
                version: "1.1.1",
                serverTimeOffset: 123
            )
        )

        let providerExpectation = expectation(description: "provider called")
        var providerDataCount = 0
        var providerData: Data?
        RUM.enable(
            with: .init(
                applicationID: .mockAny(),
                urlSessionTracking: .init(
                    resourceAttributesProvider: { req, resp, data, err in
                        XCTAssertNotNil(data)
                        XCTAssertTrue(data!.count > 0)
                        providerDataCount = data!.count
                        data.map { providerData = $0 }
                        providerExpectation.fulfill()
                        return [:]
                })
            ),
            in: core
        )

        URLSessionInstrumentation.enable(
            with: .init(
                delegateClass: InstrumentedSessionDelegate.self
            ),
            in: core
        )

        let session = URLSession(
            configuration: .ephemeral,
            delegate: InstrumentedSessionDelegate(),
            delegateQueue: nil
        )
        let request = URLRequest(url: URL(string: "https://www.datadoghq.com/")!)

        let taskExpectation = self.expectation(description: "task completed")
        var taskDataCount = 0
        var taskData: Data?
        let task = session.dataTask(with: request) { data, _, _ in
            XCTAssertNotNil(data)
            XCTAssertTrue(data!.count > 0)
            taskDataCount = data!.count
            data.map { taskData = $0 }
            taskExpectation.fulfill()
        }
        task.resume()

        wait(for: [providerExpectation, taskExpectation], timeout: 10)
        XCTAssertEqual(providerDataCount, taskDataCount)
        XCTAssertEqual(providerData, taskData)
    }

    class InstrumentedSessionDelegate: NSObject, URLSessionDataDelegate {
        func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
            print(data)
        }
    }
}
