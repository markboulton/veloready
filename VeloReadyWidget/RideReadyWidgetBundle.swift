//
//  RideReadyWidgetBundle.swift
//  RideReadyWidget
//
//  Created by Mark Boulton on 30/09/2025.
//

import WidgetKit
import SwiftUI

@main
struct RideReadyWidgetBundle: WidgetBundle {
    var body: some Widget {
        RideReadyWidget()
        RideReadyWidgetControl()
        RideReadyWidgetLiveActivity()
    }
}
