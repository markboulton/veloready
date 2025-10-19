//
//  VeloReadyWidgetBundle.swift
//  VeloReadyWidget
//
//  Created by Mark Boulton on 30/09/2025.
//

import WidgetKit
import SwiftUI

@main
struct VeloReadyWidgetBundle: WidgetBundle {
    var body: some Widget {
        VeloReadyWidget()
        VeloReadyWidgetControl()
        VeloReadyWidgetLiveActivity()
    }
}
