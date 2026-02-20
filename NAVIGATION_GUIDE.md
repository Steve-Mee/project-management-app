# Responsive Navigation Guide

## Architecture Overview

This Flutter app implements a responsive navigation system that adapts to different screen sizes:

### Desktop (width > 600px)
- **NavigationRail**: Fixed sidebar on the left with icons and labels
- **AppBar**: Top bar with theme toggle
- **Content Area**: Main content panel that expands to fill available space

### Mobile (width ≤ 600px)
- **BottomNavigationBar**: Navigation items at the bottom
- **AppBar**: Top bar with theme toggle
- **Content Area**: Full-width main content

## File Structure

```
lib/
├── main.dart                          # App entry point with MaterialApp.router
├── core/
│   ├── theme.dart                    # Dark/light theme configuration
│   ├── providers.dart                # Riverpod providers (theme, navigation)
│   └── routes.dart                   # GoRouter configuration & navigation config
├── features/
│   ├── dashboard/
│   │   └── dashboard_screen.dart    # Home page with stats & projects overview
│   ├── project/
│   │   ├── project_screen.dart      # Projects list with filtering
│   │   └── project_detail_screen.dart # Individual project details
│   ├── ai_chat/
│   │   └── ai_chat_screen.dart      # AI chat interface
│   └── settings/
│       └── settings_screen.dart     # Application settings
```

## Navigation Configuration

### Routes Defined (routes.dart)
- `/dashboard` - Home page
- `/projects` - Projects list
- `/projects/:id` - Project details
- `/ai-chat` - AI Chat interface
- `/settings` - Settings page

### Navigation Items (NavigationConfig)
```dart
- Home (dashboard)
- Projects (projects)
- AI Chat (ai-chat)
- Settings (settings)
```

## Key Components

### 1. **ResponsiveNavigationLayout** (main.dart)
- Wraps all screen content
- Uses `LayoutBuilder` to detect screen size
- Shows `NavigationRail` on desktop, `BottomNavigationBar` on mobile
- All navigation items have `Tooltip` for accessibility

### 2. **Navigation State (providers.dart)**
- `navigationIndexProvider` - Tracks selected navigation item
- Updates when user navigates to a different section
- Manages selection state across routes

### 3. **Routing System (routes.dart)**
- Uses `GoRouter` with `ShellRoute` for consistent navigation UI
- `ShellRoute` wraps all routes with `ResponsiveNavigationLayout`
- Named routes for easy programmatic navigation
- Error route handler for invalid paths

## How to Add New Navigation Items

1. **Add NavigationItem** in `NavigationConfig` (routes.dart):
```dart
NavigationItem(
  label: 'New Feature',
  icon: Icons.new_icon,
  routeName: 'new-feature',
  routePath: '/new-feature',
),
```

2. **Create GoRoute** in `AppRoutes.createRouter()` (routes.dart):
```dart
GoRoute(
  path: '/new-feature',
  name: 'new-feature',
  builder: (context, state) => const NewFeatureScreen(),
),
```

3. **Create Screen** widget in `lib/features/new_feature/` folder

## Responsive Behavior

### NavigationRail (Desktop)
- Fixed width: 250.w (screen units)
- Shows icons + labels
- Supports selected state highlighting
- Auto-closes for mobile view

### BottomNavigationBar (Mobile)
- Fixed at bottom of screen
- Compact icon-based design
- Dynamic item count support
- Type: `.fixed` for all items visible

## Theme Toggle Integration
- Accessible from AppBar on both layouts
- Cycles: System → Dark → Light → System
- Icons change based on current mode
- Fully responsive with flutter_screenutil

## Testing Responsive Behavior

### Simulate Desktop
- Run with `--device-id chrome` or web platform
- Device width > 600px

### Simulate Mobile
- Run on physical device or emulator
- Default device width ≤ 600px

## Future Expansion Ideas

- Add deep linking support for direct route access
- Implement navigation history with back button handling
- Add animated transitions between screens
- Create navigation guards for authentication
- Add route-specific AppBar customization
- Implement tab-based navigation for wider tablets
