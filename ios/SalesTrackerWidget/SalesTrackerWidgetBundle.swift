import WidgetKit
import SwiftUI

@main
struct SalesTrackerWidgetBundle: WidgetBundle {
    var body: some Widget {
        WeekProgressWidget()
        QuickLogControl()
    }
}
