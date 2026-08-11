import ExtensionFoundation
import MovoWallpaperSPI

@main
final class MovoWallpaperExtension: AppExtension {
    required init() {}

    var configuration: some AppExtensionConfiguration {
        ConnectionHandler { connection in
            WallpaperExtensionBoundary().accept(connection: connection)
        }
    }
}
