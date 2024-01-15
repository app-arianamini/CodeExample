import UIKit
import CoreMotion

fileprivate struct EventData {
    var timestamp: Date
    var eventType: String
    var data: Any
}

public class EventTracker: NSObject {
    @objc public static let shared = EventTracker()
    private override init() {}
    
    private var motionManager = CMMotionManager()
    private var eventsData: [EventData] = []
    
    @objc public func start(application: UIApplication) {
        if motionManager.isAccelerometerAvailable {
            motionManager.accelerometerUpdateInterval = 0.2
            motionManager.startAccelerometerUpdates(
                to: .main
            ) { [weak self] (accelerometerData, error) in
                guard let data = accelerometerData else { return }
                
                let eventData = EventData(
                    timestamp: Date(),
                    eventType: "Accelerometer",
                    data: data
                )
                
                self?.eventsData.append(eventData)
            }
        }
        
        if #available(iOS 13.0, *) {
            let scene = application.connectedScenes.first
            guard let windowScene = scene as? UIWindowScene else { return }
            
            let window = windowScene.windows.first { $0.isKeyWindow }
            window?.addGestureRecognizer(
                UITapGestureRecognizer(target: self,
                action: #selector(handleTapGesture(gesture:)))
            )
        }
    }
    
    @objc public func stopAndResetAndReturnCSV() -> String {
        var copyEventsData = eventsData
        motionManager.stopAccelerometerUpdates()
        
        copyEventsData.sort { $0.timestamp < $1.timestamp }
        eventsData.removeAll()
        
        return convertToCSV(eventDataArray: copyEventsData)
    }
    
    @objc private func handleTapGesture(gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: gesture.view)
        let eventData = EventData(
            timestamp: Date(),
            eventType: "Touch",
            data: location
        )
        eventsData.append(eventData)
    }
    
    private func convertToCSV(eventDataArray: [EventData]) -> String {
        var csvString = "CreatedAt,Event,Data\n"
        for eventData in eventDataArray {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            let timestampString = dateFormatter.string(from: eventData.timestamp)
            
            let dataDescription = String(describing: eventData.data)
            let rowString = "\(timestampString),\(eventData.eventType),\(dataDescription)\n"
            csvString += rowString
        }
        return csvString
    }
}
