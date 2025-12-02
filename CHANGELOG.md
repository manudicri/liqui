# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2024-12-02

### Added
- Initial release of Liqui
- `showLiquiSheet()` - iOS-styled bottom sheets with spring animations
- `showLiquiPopover()` - Context popovers anchored to source widgets
- `showLiquiMenu()` - Interactive menu with selectable items
- `LiquiMenuButton` - Button widget that opens menu on tap
- `LiquiCircleButton` - Circular button with liquid scale animation
- `LiquiCircleButtonGroup` - Group of circular buttons
- `LiquiCloseButton` - Pre-configured close button
- `LiquiScaleTap` - Wrapper widget for liquid scale animations
- `LiquiMenuItem` - Data class for menu items
- Spring physics animations using `elegant_spring_animation`
- Automatic screen corner radius detection using `screen_corner_radius`
- Adaptive layouts for mobile and tablet devices
- Drag-to-dismiss gesture support
- Interactive menu highlighting with haptic feedback
- Liquid stretch and translate effects on drag
- Popover auto-positioning (above/below source)
- Custom animation configuration through `BottomSheetConfig`
- `CustomBottomSheetController` for managing sheet lifecycle

### Features
- Natural, elastic spring animations
- iOS-style visual design
- Responsive behavior across screen sizes
- Smooth transitions and physics-based motion
- Interactive gesture controls
- Customizable colors, sizes, and behaviors
- Support for destructive and selected menu item states
