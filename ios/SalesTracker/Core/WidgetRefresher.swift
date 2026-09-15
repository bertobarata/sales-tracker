import Foundation
import WidgetKit

enum WidgetRefresher {
    static let kind = "SalesTrackerWeeklyWidget"

    static func reload() {
        WidgetCenter.shared.reloadAllTimelines()
    }
}
