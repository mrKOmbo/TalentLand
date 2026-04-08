## Atenea-Specific Overrides

### Context
- Primary use: outdoors, sunlight, walking
- Users: tourists (low Spanish), local customers, street vendors
- Device: iPhone, one-handed use, motion while walking

### Color Adjustments
- All text must pass 7:1 contrast ratio (outdoor legibility > WCAG AA minimum)
- Map UI: semi-transparent cards with blur backdrop (iOS native feel)
- Vendor pins: high saturation colors distinguishable in all 4 daltonism modes

### Typography (SwiftUI)
- Use SF Pro (system font) — never import external fonts in native iOS
- Headlines: .largeTitle / .title — SF Pro Rounded for warmth
- Map labels: .caption2 minimum, never smaller

### Motion
- Page transitions: .easeInOut(duration: 0.3) max
- Map annotations: spring animation
- Never block map interaction with animations
