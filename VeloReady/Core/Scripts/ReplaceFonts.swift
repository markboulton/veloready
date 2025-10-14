// Script to find and replace deprecated font usages
// Run: find . -name "*.swift" -exec sed -i '' 's/\.font(\.cardTitle)/.font(.heading)/g' {} +
// This file documents the font migrations needed:

/*
Migration Guide:
================

Old Font Name          →  New Font Name       Usage
-------------------       ---------------      ------
.cardTitle             →  .heading            Section headers, card titles
.sectionTitle          →  .title              Page titles, main headings  
.subsectionTitle       →  .heading            Sub-headers
.bodyPrimary           →  .body               Main content text
.bodySecondary         →  .body               Alternative body text
.bodySmall             →  .caption            Small text
.metricLarge           →  .metric             Large metric displays
.metricMedium          →  .title              Medium metrics
.metricSmall           →  .heading            Small metrics
.labelPrimary          →  .caption            Primary labels
.labelSecondary        →  .caption            Secondary labels
.labelTertiary         →  .caption            Tertiary labels
.recoveryScore         →  .metric             Score displays
.buttonSmall           →  .button             Button text

Text Style Modifiers:
=====================
.titleStyle()          →  Title + foreground color
.headingStyle()        →  Heading + foreground color
.bodyStyle()           →  Body + foreground color
.captionStyle()        →  Caption + grey color
.metricStyle()         →  Metric + foreground color
*/
