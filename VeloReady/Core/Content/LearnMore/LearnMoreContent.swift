import Foundation

/// Content structure for Learn More educational content
struct LearnMoreContent {
    let title: String
    let sections: [Section]
    
    struct Section {
        let heading: String?
        let body: String
    }
}
