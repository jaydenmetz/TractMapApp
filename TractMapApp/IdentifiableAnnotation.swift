//
//  IdentifiableAnnotation.swift
//  TractMapApp
//
//  Created by Jayden Metz on 11/6/24.
//

import Foundation
import MapKit

class IdentifiableAnnotation: NSObject, Identifiable, MKAnnotation {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let title: String?

    init(coordinate: CLLocationCoordinate2D, title: String?) {
        self.coordinate = coordinate
        self.title = title
    }

    static func == (lhs: IdentifiableAnnotation, rhs: IdentifiableAnnotation) -> Bool {
        lhs.id == rhs.id
    }

    override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? IdentifiableAnnotation else { return false }
        return self.id == other.id
    }

    override var hash: Int {
        id.hashValue
    }
}
