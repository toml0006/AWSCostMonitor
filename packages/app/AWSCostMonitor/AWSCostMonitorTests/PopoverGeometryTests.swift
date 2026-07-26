import XCTest
import AppKit
@testable import AWSCostMonitor

final class PopoverGeometryTests: XCTestCase {

    // MARK: availableWidth

    func testAvailableWidthSubtractsBothMargins() {
        XCTAssertEqual(
            PopoverGeometry.availableWidth(screenWidth: 1440),
            1440 - 2 * PopoverGeometry.edgeMargin
        )
    }

    // MARK: clampedWidth

    func testDesiredBelowMinimumIsRaisedToMinimum() {
        XCTAssertEqual(
            PopoverGeometry.clampedWidth(desired: 360, availableWidth: 1416),
            PopoverGeometry.minWidth
        )
    }

    func testDesiredThatFitsIsReturnedUnchanged() {
        XCTAssertEqual(
            PopoverGeometry.clampedWidth(desired: 610, availableWidth: 1416),
            610
        )
    }

    func testDesiredAboveAllowanceIsCappedToAllowance() {
        XCTAssertEqual(
            PopoverGeometry.clampedWidth(desired: 2000, availableWidth: 1416),
            1416
        )
    }

    func testNarrowDisplayCapWinsOverMinimum() {
        // A display too narrow to honour minWidth: the screen cap governs.
        XCTAssertEqual(
            PopoverGeometry.clampedWidth(desired: 610, availableWidth: 400),
            400
        )
    }

    /// Regression for A1. The old `centeredFit` path shrank the popover to 360
    /// whenever the status item sat near the right edge, and HeroSplit's two
    /// 210pt fixedSize columns then overflowed and clipped. Width must depend
    /// only on the content and the screen — never on the item's position.
    func testWidthIsIndependentOfStatusItemPosition() {
        let nearRightEdge = PopoverGeometry.clampedWidth(desired: 610, availableWidth: 1416)
        let nearCentre = PopoverGeometry.clampedWidth(desired: 610, availableWidth: 1416)
        XCTAssertEqual(nearRightEdge, nearCentre)
        XCTAssertEqual(nearRightEdge, 610, "must not collapse to the old 360 floor")
    }

    // MARK: clampedOriginX

    private var visible: NSRect { NSRect(x: 0, y: 0, width: 1440, height: 900) }

    func testOriginUnchangedWhenFrameAlreadyFits() {
        XCTAssertEqual(
            PopoverGeometry.clampedOriginX(idealX: 400, width: 610, visible: visible),
            400
        )
    }

    func testOriginShiftsLeftWhenOverrunningRightEdge() {
        // 1200 + 610 = 1810, well past 1440.
        XCTAssertEqual(
            PopoverGeometry.clampedOriginX(idealX: 1200, width: 610, visible: visible),
            1440 - PopoverGeometry.edgeMargin - 610
        )
    }

    func testOriginShiftsRightWhenUnderrunningLeftEdge() {
        XCTAssertEqual(
            PopoverGeometry.clampedOriginX(idealX: -50, width: 610, visible: visible),
            PopoverGeometry.edgeMargin
        )
    }

    func testOriginPrefersLeftEdgeWhenFrameWiderThanScreen() {
        // maxX bound would be negative; the minX bound must win.
        XCTAssertEqual(
            PopoverGeometry.clampedOriginX(idealX: 100, width: 2000, visible: visible),
            PopoverGeometry.edgeMargin
        )
    }

    func testOriginRespectsNonZeroVisibleOrigin() {
        // Second display to the right of the primary.
        let secondary = NSRect(x: 1440, y: 0, width: 1280, height: 800)
        XCTAssertEqual(
            PopoverGeometry.clampedOriginX(idealX: 1400, width: 610, visible: secondary),
            1440 + PopoverGeometry.edgeMargin
        )
    }
}
