# Connect World Flutter App

## Project Overview
Netflix-style IPTV player. Consumes a NestJS backend that proxies IPTV providers.
Targets: Android TV, Firestick, Android phones, iOS, tablets.

## Architecture
- Feature-first clean architecture
- State: flutter_riverpod (code generation via riverpod_annotation)
- Navigation: go_router
- HTTP: dio with auth interceptor
- Storage: hive_flutter (favorites, continue watching, auth token)
- Video: media_kit + media_kit_video

## Project Structure
```
lib/
  core/
    constants/   # API endpoints, app-wide constants
    theme/       # Colors, typography, app theme
    networking/  # Dio client + interceptors
    router/      # go_router configuration
    storage/     # Hive wrapper
  models/        # Freezed data classes (JSON serializable)
  services/      # API service classes (wrap Dio calls)
  features/
    auth/        # Login screen + auth provider
    home/        # Home screen, hero banner, content rows
    live_tv/     # Live channels grid
    movies/      # Movies catalog
    series/      # Series catalog
    search/      # Search screen
    player/      # media_kit video player
```

## Code Generation
Run after modifying models or providers:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

## Backend API Base URL
Set in `lib/core/constants/app_constants.dart` — `ApiConstants.baseUrl`.

## TV Navigation
Use `FocusableControlBuilder` for custom focusable widgets.
All interactive cards must handle `onFocusChange` for TV remote D-pad navigation.
