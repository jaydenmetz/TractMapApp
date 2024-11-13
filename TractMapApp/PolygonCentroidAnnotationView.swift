//
//  PolygonCentroidAnnotationView.swift
//  TractMapApp
//
//  Created by Jayden Metz on 11/12/24.
//

import MapKit
import UIKit

class PolygonCentroidAnnotation: NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D
    var title: String?

    init(coordinate: CLLocationCoordinate2D, title: String?) {
        self.coordinate = coordinate
        self.title = title
    }
}

class PolygonCentroidAnnotationView: MKAnnotationView {
    weak var parentMapView: MKMapView? // Injected from Coordinator

    override var annotation: MKAnnotation? {
        willSet {
            guard let polygonAnnotation = newValue as? PolygonCentroidAnnotation else {
                print("Failed to cast annotation to PolygonCentroidAnnotation.")
                return
            }

            // Clear existing labels
            subviews.forEach { $0.removeFromSuperview() }

            guard let mapView = parentMapView ?? self.retrieveMapView() else {
                print("Failed to retrieve MKMapView.")
                return
            }

            // Match the polygon using its title
            if let polygon = mapView.overlays
                .compactMap({ $0 as? MKPolygon })
                .first(where: { $0.title == polygonAnnotation.title }) {

                print("Matched polygon for annotation: \(polygon.title ?? "Unknown")")

                // Add only the middle label with fixed font size
                addMiddleLabel(polygonAnnotation: polygonAnnotation)
                print("Middle label added successfully.")
            } else {
                print("No matching polygon found for annotation titled \(polygonAnnotation.title ?? "Unknown").")
            }

            // Remove the default red pin image
            image = nil
        }
    }

    // Adds only the middle label with fixed font size
    private func addMiddleLabel(polygonAnnotation: PolygonCentroidAnnotation) {
        let middleLabel = createLabel(
            text: polygonAnnotation.title,
            fontSize: 18, // Fixed font size
            backgroundColor: UIColor.black.withAlphaComponent(0.8),
            font: UIFont.systemFont(ofSize: 18, weight: .medium)
        )
        middleLabel.alpha = 0
        UIView.animate(withDuration: 0.3) {
            middleLabel.alpha = 1
        }
        positionLabel(middleLabel, xOffset: 0, yOffset: 0)

        addSubview(middleLabel)
    }

    // Helper to create a styled label
    private func createLabel(text: String?, fontSize: CGFloat, backgroundColor: UIColor?, font: UIFont) -> UILabel {
        let label = UILabel()
        label.text = text
        label.textAlignment = .center
        label.font = font.withSize(fontSize)
        label.textColor = .white
        label.backgroundColor = backgroundColor
        label.layer.cornerRadius = 8
        label.clipsToBounds = true
        label.sizeToFit()
        label.frame.size = CGSize(width: label.frame.width + 12, height: label.frame.height + 8) // Add padding
        print("Created label with size: \(label.frame.size), text: \(text ?? "nil")")
        return label
    }

    // Helper to position labels
    private func positionLabel(_ label: UILabel, xOffset: CGFloat, yOffset: CGFloat) {
        label.frame.origin = CGPoint(x: xOffset - label.frame.width / 2, y: yOffset - label.frame.height / 2)
        print("Positioning label at: \(label.frame.origin)")
    }

    // Dynamically retrieve MKMapView if parentMapView is nil
    private func retrieveMapView() -> MKMapView? {
        var parentView = self.superview
        while let view = parentView {
            if let mapView = view as? MKMapView {
                return mapView
            }
            parentView = view.superview
        }
        print("MapView not found in superview hierarchy.")
        return nil
    }
}
