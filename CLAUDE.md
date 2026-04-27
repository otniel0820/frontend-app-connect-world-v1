# Connect World Flutter App

## Project Overview
Netflix-style IPTV player. Conecta **directamente** a cualquier proveedor Xtream Codes.
**No hay backend propio.** Todo el contenido viene del proveedor Xtream del usuario.
Targets: Android TV, Firestick, Android phones, iOS, tablets.

## Architecture
- Feature-first clean architecture
- State: flutter_riverpod (StateNotifier + FutureProvider)
- Navigation: go_router
- HTTP: dio (llama al `player_api.php` del proveedor Xtream)
- Storage: hive_flutter (credenciales, favoritos, continue watching, progreso series)
- Video: media_kit + media_kit_video

## Authentication Flow
1. Usuario ingresa: URL del servidor, nombre de usuario, contraseña
2. App llama `GET {url}/player_api.php?username=X&password=Y` directamente
3. Si válido → guarda credenciales en Hive box `auth`
4. En cada sesión → lee credenciales de Hive, carga contenido directamente del proveedor

## Stream ID Format
Todos los IDs de stream usan el formato codificado:
- Canales en vivo: `live:{stream_id}` → `/live/{user}/{pass}/{id}.m3u8`
- Películas:       `vod:{stream_id}:{ext}` → `/movie/{user}/{pass}/{id}.{ext}`
- Episodios:       `ep:{stream_id}:{ext}` → `/series/{user}/{pass}/{id}.{ext}`
- Series:          `{series_id}` (solo número — los episodios tienen su propio ID)

## Key Services
| Servicio | Propósito |
|---------|-----------|
| `XtreamService` | Cliente Xtream: auth, catálogo, stream URLs |
| `AuthService` | Login/logout — guarda credenciales en Hive |
| `CatalogService` | Wrapper sobre XtreamService para providers de catálogo |
| `StreamService` | Construye URL reproducible a partir del ID codificado (sin red) |
| `EpgService` | EPG corto desde Xtream `get_short_epg` |

## Raw Data Providers (cached)
```
rawLiveStreamsProvider  → List<Channel>   (todos los canales en vivo)
rawMoviesProvider       → List<Movie>     (todas las películas)
rawSeriesProvider       → List<Series>    (todas las series)
```
Se invalidan automáticamente al hacer login/logout mediante `providerVersionProvider`.

## Hive Boxes
| Box | Contenido |
|-----|-----------|
| `auth` | Credenciales Xtream (url, username, password), perfil, PIN parental |
| `favorites` | Lista de IDs favoritos |
| `continue_watching` | `{id: [positionMs, durationMs]}` |
| `series_progress` | `{seriesId: {season, episodeId}}` |

## Project Structure
```
lib/
  core/
    constants/   # StorageKeys, AppConstants
    theme/       # Colors, typography, app theme
    networking/  # (vacío — no hay backend)
    router/      # go_router configuration
    storage/     # Hive wrapper (LocalStorage)
  models/        # Freezed data classes
  services/      # XtreamService, AuthService, CatalogService, StreamService
  features/
    auth/        # Login (3 campos: URL + usuario + clave) + auth provider
    home/        # Home screen, hero banner, content rows
    live_tv/     # Grid de canales en vivo
    movies/      # Catálogo películas (búsqueda y filtro client-side)
    series/      # Catálogo series (búsqueda y filtro client-side)
    search/      # Búsqueda global sobre rawProviders
    player/      # media_kit video player
    profile/     # Perfil, favoritos, CW, PIN parental local
```

## Code Generation
Run after modifying models or providers:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

## TV Navigation
Use `FocusableControlBuilder` for custom focusable widgets.
All interactive cards must handle `onFocusChange` for TV remote D-pad navigation.
