//
//  NCViewerImageDetailView.swift
//  Nextcloud
//
//  Created by Marino Faggiana on 31/10/2020.
//  Copyright © 2020 Marino Faggiana. All rights reserved.
//

import Foundation
import MapKit

class NCViewerImageDetailView: UIView {
    
    @IBOutlet weak var detailViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var locationButton: UIButton!

    var latitude: Double = 0
    var longitude: Double = 0
    var location: String?
    var date: NSDate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
           
        mapView.layer.cornerRadius = 6
        mapView.isZoomEnabled = false
        mapView.isScrollEnabled = false
        mapView.isUserInteractionEnabled = false
    }
    
    func hasData() -> Bool {
        if latitude > 0 && longitude > 0 {
            return true
        } else {
            return false
        }
    }
    
    func show(height: CGFloat, textColor: UIColor) {
        detailViewHeightConstraint.constant = height
        dateLabel.textColor = textColor
        isHidden = false
    }
    
    func hide() {
        isHidden = true
    }
    
    func isShow() -> Bool {
        return !isHidden
    }
    
    //MARK: - EXIF
    
    func updateExifLocal(metadata: tableMetadata) {
                    
        if metadata.typeFile == k_metadataTypeFile_image {
            CCUtility.setExif(metadata) { (latitude, longitude, location, date) in
                if latitude > 0 && longitude > 0 {
                    self.latitude = latitude
                    self.longitude = longitude
                    self.location = location
                    self.date = date as NSDate?
                    self.setMapCoordinate()
                }
            };
        }
    
        if let localFile = NCManageDatabase.sharedInstance.getTableLocalFile(predicate: NSPredicate(format: "ocId == %@", metadata.ocId)) {
            
            let latitudeString = localFile.exifLatitude
            let longitudeString = localFile.exifLongitude
            self.latitude = Double(localFile.exifLatitude) ?? 0
            self.longitude = Double(localFile.exifLongitude) ?? 0
            self.date = localFile.exifDate
            
            if let locationDB = NCManageDatabase.sharedInstance.getLocationFromGeoLatitude(latitudeString, longitude: longitudeString) {
                location = locationDB
            }
           
            self.setMapCoordinate()
        }
    }
    
    //MARK: - Map
    
    func setMapCoordinate() {
        
        let annotation = MKPointAnnotation()
        
        if let date = self.date {
            let formatter = DateFormatter()
            formatter.dateStyle = .full
            let dateString = formatter.string(from: date as Date)
            formatter.dateFormat = "HH:mm"
            let timeString = formatter.string(from: date as Date)
            self.dateLabel.text = dateString + ", " + timeString
        }
        
        annotation.coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        mapView.addAnnotation(annotation)
        mapView.setRegion(MKCoordinateRegion(center: annotation.coordinate, latitudinalMeters: 500, longitudinalMeters: 500), animated: false)
        locationButton.setTitle(location, for: .normal)
    }
    
    //MARK: - Action

    @IBAction func touchLocation(_ sender: Any) {
        
        if self.latitude > 0 && self.longitude > 0 {
            
            let latitude: CLLocationDegrees = self.latitude
            let longitude: CLLocationDegrees = self.longitude

            let regionDistance:CLLocationDistance = 10000
            let coordinates = CLLocationCoordinate2DMake(latitude, longitude)
            let regionSpan = MKCoordinateRegion(center: coordinates, latitudinalMeters: regionDistance, longitudinalMeters: regionDistance)
            let options = [
                MKLaunchOptionsMapCenterKey: NSValue(mkCoordinate: regionSpan.center),
                MKLaunchOptionsMapSpanKey: NSValue(mkCoordinateSpan: regionSpan.span)
            ]
            let placemark = MKPlacemark(coordinate: coordinates, addressDictionary: nil)
            let mapItem = MKMapItem(placemark: placemark)
            mapItem.name = location
            mapItem.openInMaps(launchOptions: options)
        }
    }
}
