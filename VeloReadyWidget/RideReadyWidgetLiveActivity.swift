//
//  RideReadyWidgetLiveActivity.swift
//  RideReadyWidget
//
//  Created by Mark Boulton on 30/09/2025.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct RideReadyWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct RideReadyWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: RideReadyWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color(.sRGB, red: 0.957, green: 0.325, blue: 0.384, opacity: 1.0))
        }
    }
}

extension RideReadyWidgetAttributes {
    fileprivate static var preview: RideReadyWidgetAttributes {
        RideReadyWidgetAttributes(name: "World")
    }
}

extension RideReadyWidgetAttributes.ContentState {
    fileprivate static var smiley: RideReadyWidgetAttributes.ContentState {
        RideReadyWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: RideReadyWidgetAttributes.ContentState {
         RideReadyWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: RideReadyWidgetAttributes.preview) {
   RideReadyWidgetLiveActivity()
} contentStates: {
    RideReadyWidgetAttributes.ContentState.smiley
    RideReadyWidgetAttributes.ContentState.starEyes
}
