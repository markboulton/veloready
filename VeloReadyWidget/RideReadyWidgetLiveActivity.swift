//
//  VeloReadyWidgetLiveActivity.swift
//  VeloReadyWidget
//
//  Created by Mark Boulton on 30/09/2025.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct VeloReadyWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct VeloReadyWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: VeloReadyWidgetAttributes.self) { context in
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

extension VeloReadyWidgetAttributes {
    fileprivate static var preview: VeloReadyWidgetAttributes {
        VeloReadyWidgetAttributes(name: "World")
    }
}

extension VeloReadyWidgetAttributes.ContentState {
    fileprivate static var smiley: VeloReadyWidgetAttributes.ContentState {
        VeloReadyWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: VeloReadyWidgetAttributes.ContentState {
         VeloReadyWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: VeloReadyWidgetAttributes.preview) {
   VeloReadyWidgetLiveActivity()
} contentStates: {
    VeloReadyWidgetAttributes.ContentState.smiley
    VeloReadyWidgetAttributes.ContentState.starEyes
}
