/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Datadog (https://www.datadoghq.com/).
 * Copyright 2019-Present Datadog, Inc.
 */

import Foundation
import UIKit
@testable import DatadogSessionReplay
@testable import TestUtilities

// MARK: - ViewTreeSnapshot Mocks

extension ViewTreeSnapshot: AnyMockable, RandomMockable {
    public static func mockAny() -> ViewTreeSnapshot {
        return mockWith()
    }

    public static func mockRandom() -> ViewTreeSnapshot {
        return ViewTreeSnapshot(
            date: .mockRandom(),
            rumContext: .mockRandom(),
            viewportSize: .mockRandom(),
            nodes: .mockRandom(count: .random(in: (5..<50)))
        )
    }

    static func mockWith(
        date: Date = .mockAny(),
        rumContext: RUMContext = .mockAny(),
        viewportSize: CGSize = .mockAny(),
        nodes: [Node] = .mockAny()
    ) -> ViewTreeSnapshot {
        return ViewTreeSnapshot(
            date: date,
            rumContext: rumContext,
            viewportSize: viewportSize,
            nodes: nodes
        )
    }
}

extension ViewAttributes: AnyMockable, RandomMockable {
    /// Placeholder mock, not guaranteeing consistency of returned `ViewAttributes`.
    public static func mockAny() -> ViewAttributes {
        return mockWith()
    }

    /// Random mock, not guaranteeing consistency of returned `ViewAttributes`.
    public static func mockRandom() -> ViewAttributes {
        return .init(
            frame: .mockRandom(),
            backgroundColor: UIColor.mockRandom().cgColor,
            layerBorderColor: UIColor.mockRandom().cgColor,
            layerBorderWidth: .mockRandom(min: 0, max: 5),
            layerCornerRadius: .mockRandom(min: 0, max: 5),
            alpha: .mockRandom(min: 0, max: 1),
            isHidden: .mockRandom(),
            intrinsicContentSize: .mockRandom()
        )
    }

    /// Partial mock, not guaranteeing consistency of returned `ViewAttributes`.
    static func mockWith(
        frame: CGRect = .mockAny(),
        backgroundColor: CGColor? = .mockAny(),
        layerBorderColor: CGColor? = .mockAny(),
        layerBorderWidth: CGFloat = .mockAny(),
        layerCornerRadius: CGFloat = .mockAny(),
        alpha: CGFloat = .mockAny(),
        isHidden: Bool = .mockAny(),
        intrinsicContentSize: CGSize = .mockAny()
    ) -> ViewAttributes {
        return .init(
            frame: frame,
            backgroundColor: backgroundColor,
            layerBorderColor: layerBorderColor,
            layerBorderWidth: layerBorderWidth,
            layerCornerRadius: layerCornerRadius,
            alpha: alpha,
            isHidden: isHidden,
            intrinsicContentSize: intrinsicContentSize
        )
    }

    /// A fixture for mocking consistent state in `ViewAttributes`.
    enum Fixture: CaseIterable {
        static var allCases: [DatadogSessionReplay.ViewAttributes.Fixture] = [
            .invisible,
            .visible(.noAppearance),
            .visible(.someAppearance),
            .opaque
        ]

        enum Apperance: CaseIterable {
            // Some appearance.
            case someAppearance
            // No appearance (e.g. all colors are fully transparent).
            case noAppearance
        }
        /// A view that is not visible.
        case invisible
        /// A view that is visible.
        case visible(_ apperance: Apperance = .someAppearance)
        /// A view that is opaque.
        case opaque
    }

    /// Partial mock, guaranteeing consistency of returned `ViewAttributes`.
    static func mock(fixture: Fixture) -> ViewAttributes {
        var frame: CGRect?
        var backgroundColor: CGColor?
        var layerBorderColor: CGColor?
        var layerBorderWidth: CGFloat?
        var alpha: CGFloat?
        var isHidden: Bool?

        // swiftlint:disable opening_brace
        switch fixture {
        case .invisible:
            isHidden = true
            alpha = 0
            frame = .zero
        case .visible(.noAppearance):
            // visible:
            isHidden = false
            alpha = .mockRandom(min: 0.1, max: 1)
            frame = .mockRandom(minWidth: 10, minHeight: 10)
            // no appearance:
            oneOrMoreOf([
                { layerBorderWidth = 0 },
                { backgroundColor = UIColor.mockRandomWith(alpha: 0).cgColor }
            ])
        case .visible(.someAppearance):
            // visibile:
            isHidden = false
            alpha = .mockRandom(min: 0.1, max: 1)
            frame = .mockRandom(minWidth: 10, minHeight: 10)
            // some appearance:
            oneOrMoreOf([
                {
                    layerBorderWidth = .mockRandom(min: 1, max: 5)
                    layerBorderColor = UIColor.mockRandomWith(alpha: .mockRandom(min: 0.1, max: 1)).cgColor
                },
                { backgroundColor = UIColor.mockRandomWith(alpha: .mockRandom(min: 0.1, max: 1)).cgColor }
            ])
        case .opaque:
            // opaque:
            isHidden = false
            alpha = 1
            frame = .mockRandom(minWidth: 10, minHeight: 10)
            // some appearance:
            oneOrMoreOf([
                {
                    layerBorderWidth = .mockRandom(min: 1, max: 5)
                    layerBorderColor = UIColor.mockRandomWith(alpha: .mockRandom(min: 0.1, max: 1)).cgColor
                },
                { backgroundColor = UIColor.mockRandomWith(alpha: .mockRandom(min: 0.1, max: 1)).cgColor }
            ])
        }
        // swiftlint:enable opening_brace

        let mock = ViewAttributes(
            frame: frame ?? .mockRandom(minWidth: 10, minHeight: 10),
            backgroundColor: backgroundColor,
            layerBorderColor: layerBorderColor,
            layerBorderWidth: layerBorderWidth ?? .mockRandom(min: 1, max: 4),
            layerCornerRadius: .mockRandom(min: 0, max: 4),
            alpha: alpha ?? .mockRandom(min: 0.01, max: 1),
            isHidden: isHidden ?? .mockRandom(),
            intrinsicContentSize: (frame ?? .mockRandom(minWidth: 10, minHeight: 10)).size
        )

        // consistency check:
        switch fixture {
        case .invisible:
            assert(!mock.isVisible)
        case .visible(.noAppearance):
            assert(mock.isVisible && !mock.hasAnyAppearance)
        case .visible(.someAppearance):
            assert(mock.isVisible && mock.hasAnyAppearance)
        case .opaque:
            assert(mock.isVisible && mock.hasAnyAppearance && mock.alpha == 1)
        }

        return mock
    }
}

struct NOPWireframesBuilderMock: NodeWireframesBuilder {
    let wireframeRect: CGRect = .zero

    func buildWireframes(with builder: WireframesBuilder) -> [SRWireframe] {
        return []
    }
}

extension NodeSubtreeStrategy: AnyMockable, RandomMockable {
    public static func mockAny() -> NodeSubtreeStrategy {
        return .ignore
    }

    public static func mockRandom() -> NodeSubtreeStrategy {
        let all: [NodeSubtreeStrategy] = [
            .record,
            .replace(subtreeNodes: [.mockAny()]),
            .ignore,
        ]
        return all.randomElement()!
    }
}

func mockAnyNodeSemantics() -> NodeSemantics {
    return InvisibleElement.constant
}

func mockRandomNodeSemantics() -> NodeSemantics {
    let all: [NodeSemantics] = [
        UnknownElement.constant,
        InvisibleElement.constant,
        AmbiguousElement(wireframesBuilder: NOPWireframesBuilderMock()),
        SpecificElement(wireframesBuilder: NOPWireframesBuilderMock(), subtreeStrategy: .mockRandom()),
    ]
    return all.randomElement()!
}

struct ShapeWireframesBuilderMock: NodeWireframesBuilder {
    let wireframeRect: CGRect

    func buildWireframes(with builder: WireframesBuilder) -> [SRWireframe] {
        return [builder.createShapeWireframe(id: .mockAny(), frame: wireframeRect)]
    }
}

extension Node: AnyMockable, RandomMockable {
    public static func mockAny() -> Node {
        return mockWith()
    }

    static func mockWith(
        viewAttributes: ViewAttributes = .mockAny(),
        semantics: NodeSemantics = InvisibleElement.constant
    ) -> Node {
        return .init(
            viewAttributes: viewAttributes,
            semantics: semantics
        )
    }

    public static func mockRandom() -> Node {
        return .init(
            viewAttributes: .mockRandom(),
            semantics: mockRandomNodeSemantics()
        )
    }
}

extension SpecificElement {
    static func mockAny() -> SpecificElement {
        SpecificElement(wireframesBuilder: NOPWireframesBuilderMock(), subtreeStrategy: .mockRandom())
    }
    static func mock(
        wireframeRect: CGRect,
        subtreeStrategy: NodeSubtreeStrategy = .mockRandom()
    ) -> SpecificElement {
        SpecificElement(
            wireframesBuilder: ShapeWireframesBuilderMock(wireframeRect: wireframeRect),
            subtreeStrategy: subtreeStrategy
        )
    }
}

extension ViewTreeRecordingContext: AnyMockable, RandomMockable {
    public static func mockAny() -> ViewTreeRecordingContext {
        return .mockWith()
    }

    public static func mockRandom() -> ViewTreeRecordingContext {
        return .init(
            recorder: .mockRandom(),
            coordinateSpace: UIView.mockRandom(),
            ids: NodeIDGenerator(),
            textObfuscator: TextObfuscator()
        )
    }

    static func mockWith(
        recorder: Recorder.Context = .mockAny(),
        coordinateSpace: UICoordinateSpace = UIView.mockAny(),
        ids: NodeIDGenerator = NodeIDGenerator(),
        textObfuscator: TextObfuscator = TextObfuscator()
    ) -> ViewTreeRecordingContext {
        return .init(
            recorder: recorder,
            coordinateSpace: coordinateSpace,
            ids: ids,
            textObfuscator: textObfuscator
        )
    }
}

class NodeRecorderMock: NodeRecorder {
    var queriedViews: Set<UIView> = []
    var queryContexts: [ViewTreeRecordingContext] = []
    var resultForView: (UIView) -> NodeSemantics?

    init(resultForView: @escaping (UIView) -> NodeSemantics?) {
        self.resultForView = resultForView
    }

    func semantics(of view: UIView, with attributes: ViewAttributes, in context: ViewTreeRecordingContext) -> NodeSemantics? {
        queriedViews.insert(view)
        queryContexts.append(context)
        return resultForView(view)
    }
}

// MARK: - TouchSnapshot Mocks

extension TouchSnapshot: AnyMockable, RandomMockable {
    public static func mockAny() -> TouchSnapshot {
        return .mockWith()
    }

    public static func mockRandom() -> TouchSnapshot {
        return TouchSnapshot(
            date: .mockRandom(),
            touches: .mockRandom()
        )
    }

    static func mockWith(
        date: Date = .mockAny(),
        touches: [Touch] = .mockAny()
    ) -> TouchSnapshot {
        return TouchSnapshot(
            date: date,
            touches: touches
        )
    }
}

extension TouchSnapshot.Touch: AnyMockable, RandomMockable {
    public static func mockAny() -> TouchSnapshot.Touch {
        return .mockWith()
    }

    public static func mockRandom() -> TouchSnapshot.Touch {
        return TouchSnapshot.Touch(
            id: .mockRandom(),
            phase: [.down, .move, .up].randomElement()!,
            date: .mockRandom(),
            position: .mockRandom()
        )
    }

    static func mockWith(
        id: TouchIdentifier = .mockAny(),
        phase: TouchSnapshot.TouchPhase = .move,
        date: Date = .mockAny(),
        position: CGPoint = .mockAny()
    ) -> TouchSnapshot.Touch {
        return TouchSnapshot.Touch(
            id: id,
            phase: phase,
            date: date,
            position: position
        )
    }
}

// MARK: - Recorder Mocks

extension RUMContext: AnyMockable, RandomMockable {
    public static func mockAny() -> RUMContext {
        return .mockWith()
    }

    public static func mockRandom() -> RUMContext {
        return RUMContext(
            ids: .init(
                applicationID: .mockRandom(),
                sessionID: .mockRandom(),
                viewID: .mockRandom()
            ),
            viewServerTimeOffset: .mockRandom()
        )
    }

    static func mockWith(
        applicationID: String = .mockAny(),
        sessionID: String = .mockAny(),
        viewID: String = .mockAny(),
        serverTimeOffset: TimeInterval = .mockAny()
    ) -> RUMContext {
        return RUMContext(
            ids: .init(
                applicationID: applicationID,
                sessionID: sessionID,
                viewID: viewID
            ),
            viewServerTimeOffset: serverTimeOffset
        )
    }
}

extension Recorder.Context: AnyMockable, RandomMockable {
    public static func mockAny() -> Recorder.Context {
        return .mockWith()
    }

    public static func mockRandom() -> Recorder.Context {
        return Recorder.Context(
            date: .mockRandom(),
            privacy: .mockRandom(),
            rumContext: .mockRandom()
        )
    }

    static func mockWith(
        date: Date = .mockAny(),
        privacy: SessionReplayPrivacy = .mockAny(),
        rumContext: RUMContext = .mockAny()
    ) -> Recorder.Context {
        return Recorder.Context(
            date: date,
            privacy: privacy,
            rumContext: rumContext
        )
    }
}

extension UIApplicationSwizzler: AnyMockable {
    public static func mockAny() -> UIApplicationSwizzler {
        class HandlerMock: UIEventHandler {
            func notify_sendEvent(application: UIApplication, event: UIEvent) {}
        }

        return try! UIApplicationSwizzler(handler: HandlerMock())
    }
}

// MARK: - UIView mocks

/// Creates mocked instance of generic `UIView` subclass and configures its state with provided `attributes`. 
internal func mockUIView<View: UIView>(with attributes: ViewAttributes) -> View {
    let view = View(frame: attributes.frame)

    view.backgroundColor = attributes.backgroundColor.map { UIColor(cgColor: $0) }
    view.layer.borderColor = attributes.layerBorderColor
    view.layer.borderWidth = attributes.layerBorderWidth
    view.layer.cornerRadius = attributes.layerCornerRadius
    view.alpha = attributes.alpha
    view.isHidden = attributes.isHidden

    // Consistency check - to make sure computed properties in `ViewAttributes` captured
    // for mocked view are equal the these from requested `attributes`.
    let expectedAttributes = attributes
    let actualAttributes = ViewAttributes(frameInRootView: view.frame, view: view)

    assert(
        actualAttributes.isVisible == expectedAttributes.isVisible,
        """
        The `.isVisible` value in provided `attributes` will be resolved differently for mocked
        view than its original value passed to this function. Make sure that provided attributes
        are consistent and if nothing else in `\(type(of: view))` is not overriding visibility state.
        """
    )

    assert(
        actualAttributes.hasAnyAppearance == expectedAttributes.hasAnyAppearance,
        """
        The `.hasAnyAppearance` value in provided `attributes` will be resolved differently for mocked
        view than its original value passed to this function. Make sure that provided attributes
        are consistent and if nothing else in `\(type(of: view))` is not overriding appearance state.
        """
    )

    assert(
        actualAttributes.isTranslucent == expectedAttributes.isTranslucent,
        """
        The `.isTranslucent` value in provided `attributes` will be resolved differently for mocked
        view than its original value passed to this function. Make sure that provided attributes
        are consistent and if nothing else in `\(type(of: view))` is not overriding translucency state.
        """
    )

    return view
}

extension UIView {
    static func mock(withFixture fixture: ViewAttributes.Fixture) -> Self {
        return mockUIView(with: .mock(fixture: fixture))
    }
}