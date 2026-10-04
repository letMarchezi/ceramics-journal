import XCTest
import SwiftUI
@testable import CeramicsJournal

// MARK: - Shape geometry

final class ShapeGeometryTests: XCTestCase {

    func testAllSilhouettesAreNonEmpty() {
        let rect = CGRect(x: 0, y: 0, width: 100, height: 100)
        for category in ShapeCategory.allCases {
            let path = ShapeGeometry.silhouette(category, in: rect)
            XCTAssertFalse(path.isEmpty, "\(category) silhouette is empty")
            let bounds = path.boundingRect
            XCTAssertGreaterThan(
                bounds.width * bounds.height,
                50,
                "\(category) silhouette is too small"
            )
        }
    }

    func testEntireRegionMatchesSilhouette() {
        let rect = CGRect(x: 0, y: 0, width: 200, height: 200)
        for category in ShapeCategory.allCases {
            let entire = ShapeGeometry.region(category, .entirePiece, in: rect)
            let silhouette = ShapeGeometry.silhouette(category, in: rect)
            XCTAssertEqual(
                entire.boundingRect,
                silhouette.boundingRect,
                accuracy: 0.5,
                "\(category): entire-piece region should match the silhouette"
            )
        }
    }

    func testBaseRegionSitsAtTheBottom() {
        let rect = CGRect(x: 0, y: 0, width: 100, height: 100)
        for category in ShapeCategory.allCases {
            let base = ShapeGeometry.region(category, .base, in: rect)
            XCTAssertFalse(base.isEmpty, "\(category): base region is empty")
            XCTAssertGreaterThanOrEqual(
                base.boundingRect.minY,
                rect.minY + 50,
                "\(category): base region should be in the lower half"
            )
        }
    }

    func testCustomRegionIsNeverEmpty() {
        let rect = CGRect(x: 0, y: 0, width: 120, height: 120)
        for category in ShapeCategory.allCases {
            let custom = ShapeGeometry.region(category, .custom, in: rect)
            XCTAssertFalse(custom.isEmpty, "\(category): custom region is empty")
        }
    }
}

// MARK: - Image store

final class ImageStoreTests: XCTestCase {

    func testSaveLoadCopyAndDelete() {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("ceramics-test-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: dir) }

        let store = ImageStore(baseDirectory: dir)
        let image = solidImage(color: .red)

        let name = store.save(image)
        XCTAssertNotNil(store.load(name))

        let copy = store.copy(name)
        XCTAssertNotNil(copy)
        XCTAssertNotEqual(name, copy)
        XCTAssertNotNil(store.load(copy))

        store.delete(name)
        XCTAssertNil(store.load(name))
    }

    func testAverageColorApproximatesSolidColor() {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("ceramics-test-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: dir) }

        let store = ImageStore(baseDirectory: dir)
        let image = solidImage(color: .systemGreen)
        let name = store.save(image)

        guard let color = store.averageColor(name) else {
            XCTFail("average color should not be nil")
            return
        }
        let red = CGFloat(color.redComponent)
        let green = CGFloat(color.greenComponent)
        XCTAssertGreaterThan(green, red, "average color of green should be greenish")
    }

    func testAverageColorOfMissingImageIsNil() {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("ceramics-test-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: dir) }

        let store = ImageStore(baseDirectory: dir)
        XCTAssertNil(store.averageColor("does-not-exist.jpg"))
        XCTAssertNil(store.load(nil))
    }

    private func solidImage(color: UIColor, size: Int = 32) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
        return renderer.image { context in
            color.setFill()
            context.fill(CGRect(x: 0, y: 0, width: size, height: size))
        }
    }
}

// MARK: - Domain defaults

final class ModelDefaultsTests: XCTestCase {

    func testFiringRecordUsesDefaultTargets() {
        let bisque = FiringRecord(type: .bisque)
        XCTAssertEqual(bisque.targetTemperature, 1000)

        let glaze = FiringRecord(type: .glaze)
        XCTAssertEqual(glaze.targetTemperature, 1240)

        let other = FiringRecord(type: .other)
        XCTAssertNil(other.targetTemperature)
    }

    func testProjectSnapshotsClayOnCreation() {
        let clay = Clay(name: "Egito", manufacturer: "Casa do Ceramista")
        clay.firedImagePath = "clay.jpg"

        let project = Project(name: "Dragon Mug", clay: clay)
        XCTAssertEqual(project.claySnapshotName, "Egito")
        XCTAssertEqual(project.claySnapshotManufacturer, "Casa do Ceramista")
        XCTAssertEqual(project.claySnapshotFiredPath, "clay.jpg")
        XCTAssertEqual(project.displayClayName, "Egito")
    }

    func testProjectWithoutClayFallsBackToPlaceholder() {
        let project = Project(name: "Bowl")
        XCTAssertEqual(project.displayClayName, "No clay")
        XCTAssertEqual(project.displayShapeName, "No shape")
        XCTAssertEqual(project.status, .idea)
    }
}
