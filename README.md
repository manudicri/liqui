# Liqui

iOS-styled liquid sheets and buttons for Flutter with elegant spring animations.

[![pub package](https://img.shields.io/badge/pub-0.1.0-blue)](https://pub.dev/packages/liqui)

## Features

- **Liquid Bottom Sheets**: Smooth, spring-animated bottom sheets with iOS-style feel
- **Popover Modals**: Context menus and popovers anchored to source widgets
- **Interactive Buttons**: Circle buttons with liquid scale animations
- **Spring Physics**: Natural, elastic animations using spring simulation
- **Responsive Design**: Adaptive layouts for mobile and tablet
- **Drag to Dismiss**: Interactive dismissal with fluid feedback

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  liqui: ^0.1.0
```

## Usage

### Bottom Sheets

Show a liquid bottom sheet that slides from the bottom on mobile, or appears centered on tablets:

```dart
import 'package:liqui/liqui.dart';

showLiquiSheet(
  context: context,
  child: Container(
    padding: EdgeInsets.all(20),
    child: Text('Sheet Content'),
  ),
).whenComplete(() {
  print('Sheet dismissed');
});
```

### Popover Menus

Display a popover menu anchored to a button or widget:

```dart
showLiquiPopover(
  context: context,
  sourceContext: buttonContext, // Context of the button that triggered the popover
  child: YourCustomWidget(),
);
```

### Context Menus

Show a list of menu items with interactive highlighting:

```dart
showLiquiMenu(
  context: context,
  sourceContext: buttonContext,
  items: [
    LiquiMenuItem(
      title: 'Edit',
      icon: Icons.edit,
      onTap: () => print('Edit tapped'),
    ),
    LiquiMenuItem(
      title: 'Share',
      icon: Icons.share,
      onTap: () => print('Share tapped'),
    ),
    LiquiMenuItem(
      title: 'Delete',
      icon: Icons.delete,
      destructive: true,
      onTap: () => print('Delete tapped'),
    ),
  ],
);
```

### Menu Button

Create a button that opens a menu when tapped:

```dart
LiquiMenuButton(
  items: [
    LiquiMenuItem(
      title: 'Option 1',
      icon: Icons.star,
      onTap: () => print('Option 1'),
    ),
    LiquiMenuItem(
      title: 'Option 2',
      icon: Icons.favorite,
      onTap: () => print('Option 2'),
    ),
  ],
  builder: (context, showMenu) => GestureDetector(
    onTap: showMenu,
    child: Icon(Icons.more_horiz),
  ),
)
```

### Circular Buttons

Beautiful circular buttons with liquid scale animations:

```dart
LiquiCircleButton(
  icon: Icons.add,
  onPressed: () => print('Button pressed'),
  size: 32,
  dark: false,
)
```

Create a group of circular buttons:

```dart
LiquiCircleButtonGroup(
  buttons: [
    LiquiCircleButton(icon: Icons.edit, onPressed: () {}),
    LiquiCircleButton(icon: Icons.share, onPressed: () {}),
    LiquiCircleButton(icon: Icons.delete, onPressed: () {}),
  ],
)
```

Close button:

```dart
LiquiCloseButton(
  onPressed: () => Navigator.pop(context),
  size: 32,
)
```

### Scale Tap Animation

Add liquid scale animations to any widget:

```dart
LiquiScaleTap(
  onPressed: () => print('Tapped'),
  child: Container(
    width: 100,
    height: 100,
    decoration: BoxDecoration(
      color: Colors.blue,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Center(child: Text('Tap Me')),
  ),
)
```

With custom scale and stretch settings:

```dart
LiquiScaleTap(
  onPressed: () => print('Tapped'),
  scaleOnPress: 1.2,
  autoScaleBySize: false,
  stretchSpringDamping: 10.0,
  stretchSensitivity: 1.0,
  translateSensitivity: 1.0,
  child: YourWidget(),
)
```

## Customization

### Bottom Sheet Options

```dart
showLiquiSheet(
  context: context,
  child: YourWidget(),
  backgroundColor: Colors.white,
  barrierColor: Colors.black.withOpacity(0.5),
  enableDrag: true,
  width: 450,
  borderRadius: 28,
  useRootNavigator: false,
);
```

### Popover Options

```dart
showLiquiPopover(
  context: context,
  sourceContext: buttonContext,
  child: YourWidget(),
  backgroundColor: Colors.white,
  barrierColor: Colors.transparent,
  width: 300,
  borderRadius: 20,
);
```

### Menu Items

```dart
LiquiMenuItem(
  title: 'Menu Item',
  icon: Icons.star,
  onTap: () => print('Tapped'),
  destructive: false, // Red color for destructive actions
  selected: false,    // Show checkmark if selected
  imageAsset: 'assets/icon.png', // Use image instead of icon
)
```

### Button Customization

```dart
LiquiCircleButton(
  icon: Icons.favorite,
  onPressed: () {},
  size: 40,
  dark: true, // White icon on dark background
  backgroundColor: Colors.blue,
)
```

## Animation Configuration

The library uses spring physics for natural, elastic animations. You can customize the behavior through the `BottomSheetConfig` class constants or by adjusting widget parameters.

### Scale Tap Parameters

- `scaleOnPress`: Scale factor when pressed (default: 1.1)
- `autoScaleBySize`: Auto-calculate scale based on widget size
- `basePixelIncrease`: Pixel increase for auto-scale (default: 10.0)
- `stretchSpringDamping`: Damping for stretch animation (5.0-30.0)
- `stretchSensitivity`: Stretch responsiveness (0.5-2.0)
- `translateSensitivity`: Movement during drag (0.0-2.0)

## Dependencies

- `elegant_spring_animation`: ^2.0.2
- `screen_corner_radius`: ^3.0.0

## Platform Support

- iOS
- Android
- Web
- macOS
- Windows
- Linux

## License

This project is licensed under the MIT License.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Issues

If you encounter any issues or have suggestions, please file them in the [issue tracker](https://github.com/manudicri/liqui/issues).
