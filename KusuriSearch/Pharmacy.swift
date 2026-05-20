import Foundation
import CoreLocation
import MapKit

struct Pharmacy: Identifiable, Codable {
    enum OpenStatus {
        case open
        case closed
        case unknown
    }

    let id: String
    let name: String
    let address: String
    let phone: String?
    let coordinate: CLLocationCoordinate2D
    let isOpen: Bool
    let rating: Double
    let totalRatings: Int
    let hours: [String: String]
    var distance: Double? = nil

    var currentStatus: OpenStatus {
        openStatus(at: Date())
    }

    var isCurrentlyOpen: Bool {
        currentStatus == .open
    }

    enum CodingKeys: String, CodingKey {
        case id, name, address, phone, latitude, longitude, isOpen, rating, totalRatings, hours, distance
    }

    init(
        id: String,
        name: String,
        address: String,
        phone: String?,
        coordinate: CLLocationCoordinate2D,
        isOpen: Bool,
        rating: Double,
        totalRatings: Int,
        hours: [String: String],
        distance: Double? = nil
    ) {
        self.id = id
        self.name = name
        self.address = address
        self.phone = phone
        self.coordinate = coordinate
        self.isOpen = isOpen
        self.rating = rating
        self.totalRatings = totalRatings
        self.hours = hours
        self.distance = distance
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        address = try container.decode(String.self, forKey: .address)
        phone = try container.decodeIfPresent(String.self, forKey: .phone)
        let latitude = try container.decode(CLLocationDegrees.self, forKey: .latitude)
        let longitude = try container.decode(CLLocationDegrees.self, forKey: .longitude)
        coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        isOpen = try container.decode(Bool.self, forKey: .isOpen)
        rating = try container.decode(Double.self, forKey: .rating)
        totalRatings = try container.decode(Int.self, forKey: .totalRatings)
        hours = try container.decode([String: String].self, forKey: .hours)
        distance = try container.decodeIfPresent(Double.self, forKey: .distance)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(address, forKey: .address)
        try container.encodeIfPresent(phone, forKey: .phone)
        try container.encode(coordinate.latitude, forKey: .latitude)
        try container.encode(coordinate.longitude, forKey: .longitude)
        try container.encode(isOpen, forKey: .isOpen)
        try container.encode(rating, forKey: .rating)
        try container.encode(totalRatings, forKey: .totalRatings)
        try container.encode(hours, forKey: .hours)
        try container.encodeIfPresent(distance, forKey: .distance)
    }

    static func from(mapItem: MKMapItem, userLocation: CLLocation?) -> Pharmacy {
        // iOS 26: Use mapItem.location instead of deprecated mapItem.placemark
        let coord = mapItem.location.coordinate
        var dist: Double? = nil
        if let ul = userLocation {
            dist = CLLocation(latitude: coord.latitude, longitude: coord.longitude).distance(from: ul) / 1000.0
        }
        // iOS 26: Use MKAddress / MKAddressRepresentations for formatted address
        let address = mapItem.address?.fullAddress
            ?? mapItem.addressRepresentations?.fullAddress(includingRegion: false, singleLine: true)
            ?? mapItem.name
            ?? ""
        return Pharmacy(
            id: mapItem.name ?? UUID().uuidString,
            name: mapItem.name ?? "不明",
            address: address,
            phone: mapItem.phoneNumber,
            coordinate: coord,
            isOpen: true,
            rating: 0,
            totalRatings: 0,
            hours: [:],
            distance: dist
        )
    }

    func openStatus(at date: Date) -> OpenStatus {
        guard !hours.isEmpty else { return .unknown }
        guard let todayHours = todaysBusinessHours(for: date) else { return .unknown }

        let normalized = todayHours
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "　", with: "")

        if normalized.isEmpty { return .unknown }
        if normalized.contains("休") || normalized.contains("定休日") || normalized.contains("休業") {
            return .closed
        }
        if normalized.contains("24時間") {
            return .open
        }

        let currentMinutes = minutesSinceMidnight(for: date)
        let ranges = normalized
            .split(whereSeparator: { $0 == "、" || $0 == "," || $0 == "\n" || $0 == "／" || $0 == ";" })
            .compactMap { parseHourRange(String($0)) }

        guard !ranges.isEmpty else { return .unknown }

        let isOpen = ranges.contains { start, end in
            if end >= start {
                return currentMinutes >= start && currentMinutes < end
            } else {
                return currentMinutes >= start || currentMinutes < end
            }
        }
        return isOpen ? .open : .closed
    }

    private func todaysBusinessHours(for date: Date) -> String? {
        let weekday = Calendar.current.component(.weekday, from: date)

        switch weekday {
        case 7:
            return hours["土曜"] ?? hours["土"] ?? hours["土曜日"] ?? hours["週末"] ?? hours["毎日"] ?? hours["全日"]
        case 1:
            return hours["日祝"] ?? hours["日曜"] ?? hours["日"] ?? hours["日曜日"] ?? hours["祝日"] ?? hours["週末"] ?? hours["毎日"] ?? hours["全日"]
        default:
            return hours["平日"] ?? hours["月〜金"] ?? hours["月-金"] ?? hours["毎日"] ?? hours["全日"]
        }
    }

    private func minutesSinceMidnight(for date: Date) -> Int {
        let comps = Calendar.current.dateComponents([.hour, .minute], from: date)
        return (comps.hour ?? 0) * 60 + (comps.minute ?? 0)
    }

    private func parseHourRange(_ text: String) -> (Int, Int)? {
        let separators = ["〜", "-", "－", "~", "–", "—", "―"]
        guard let separator = separators.first(where: { text.contains($0) }) else { return nil }

        let parts = text.components(separatedBy: separator)
        guard parts.count >= 2,
              let start = parseHour(parts[0]),
              let end = parseHour(parts[1]) else {
            return nil
        }
        return (start, end)
    }

    private func parseHour(_ text: String) -> Int? {
        let cleaned = text
            .replacingOccurrences(of: "時", with: ":")
            .replacingOccurrences(of: "分", with: "")
            .replacingOccurrences(of: "：", with: ":")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let parts = cleaned.split(separator: ":")
        guard let hourText = parts.first, let hour = Int(hourText) else { return nil }
        let minute = parts.count > 1 ? (Int(parts[1]) ?? 0) : 0
        return hour * 60 + minute
    }
}

let mockPharmacies: [Pharmacy] = [
    Pharmacy(id: "ph1", name: "スギ薬局 新宿西口店", address: "東京都新宿区西新宿1-3-13",
             phone: "03-3346-1234", coordinate: CLLocationCoordinate2D(latitude: 35.6901, longitude: 139.6924),
             isOpen: true, rating: 4.2, totalRatings: 247,
             hours: ["平日": "9:00〜21:00", "土曜": "9:00〜19:00", "日祝": "10:00〜18:00"],
             distance: 0.3),
    Pharmacy(id: "ph2", name: "東京調剤薬局 新宿店", address: "東京都新宿区新宿3-3-5",
             phone: "03-3354-5678", coordinate: CLLocationCoordinate2D(latitude: 35.6907, longitude: 139.6997),
             isOpen: true, rating: 4.5, totalRatings: 183,
             hours: ["平日": "9:00〜20:00", "土曜": "10:00〜18:00", "日祝": "休診"],
             distance: 0.5),
    Pharmacy(id: "ph3", name: "マツモトキヨシ 新宿南口店", address: "東京都新宿区新宿4-1-6",
             phone: "03-3358-9012", coordinate: CLLocationCoordinate2D(latitude: 35.6880, longitude: 139.7007),
             isOpen: false, rating: 3.9, totalRatings: 312,
             hours: ["平日": "10:00〜22:00", "土曜": "10:00〜22:00", "日祝": "10:00〜21:00"],
             distance: 0.8),
    Pharmacy(id: "ph4", name: "クオール薬局 新宿店", address: "東京都新宿区西新宿7-20-1",
             phone: "03-3366-3456", coordinate: CLLocationCoordinate2D(latitude: 35.6922, longitude: 139.6888),
             isOpen: true, rating: 4.0, totalRatings: 98,
             hours: ["平日": "9:00〜19:00", "土曜": "9:00〜17:00", "日祝": "休診"],
             distance: 1.1),
    Pharmacy(id: "ph5", name: "ウエルシア薬局 新宿大久保店", address: "東京都新宿区大久保2-5-1",
             phone: "03-3202-7890", coordinate: CLLocationCoordinate2D(latitude: 35.6945, longitude: 139.7018),
             isOpen: true, rating: 4.1, totalRatings: 156,
             hours: ["平日": "8:00〜22:00", "土曜": "9:00〜21:00", "日祝": "10:00〜20:00"],
             distance: 1.4)
]
