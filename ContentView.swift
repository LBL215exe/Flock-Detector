import SwiftUI
import CoreLocation
import MapKit

struct CameraLocation: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let name: String
}

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    @Published var userLocation: CLLocationCoordinate2D?
    @Published var nearbyAlerts: [String] = []
    
    // Sample coordinate points mimicking crowdsourced DeFlock data arrays
    let knownCameras = [
        CameraLocation(coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194), name: "ALPR Node - Sector Alpha"),
        CameraLocation(coordinate: CLLocationCoordinate2D(latitude: 37.7833, longitude: -122.4167), name: "ALPR Node - Sector Beta")
    ]
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        userLocation = location.coordinate
        checkProximity(to: location)
    }
    
    func checkProximity(to userLoc: CLLocation) {
        var alerts: [String] = []
        for cam in knownCameras {
            let camLoc = CLLocation(latitude: cam.coordinate.latitude, longitude: cam.coordinate.longitude)
            let distance = userLoc.distance(from: camLoc) // distance in meters
            if distance <= 150 { // trigger within 150 meters
                alerts.append("PROXIMITY ALERT: \(cam.name) [\(Int(distance))m]")
            }
        }
        DispatchQueue.main.async {
            self.nearbyAlerts = alerts
        }
    }
}

struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 20) {
                Text("SURVEILLANCE SHIELD")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.red)
                
                if let location = locationManager.userLocation {
                    Map(coordinateRegion: .constant(MKCoordinateRegion(
                        center: location,
                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                    )), showsUserLocation: true)
                    .frame(height: 350)
                    .cornerRadius(12)
                } else {
                    Text("Acquiring GPS Signal...")
                        .foregroundColor(.gray)
                }
                
                List(locationManager.nearbyAlerts, id: \.self) { alert in
                    Text(alert)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.red.opacity(0.85))
                        .cornerRadius(8)
                }
                .scrollContentBackground(.hidden)
            }
            .padding()
        }
    }
}
