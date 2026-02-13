//
//  This file is part of the 2FAS iOS app (https://github.com/twofas/2fas-ios)
//  Copyright © 2023 Two Factor Authentication Service, Inc.
//  Contributed by Zbigniew Cisiński. All rights reserved.
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program. If not, see <https://www.gnu.org/licenses/>
//

import Foundation
import Common

// MARK: - iCloud Drive Auto-Export
// Writes a .2fas backup file to iCloud Drive whenever services change,
// enabling one-way sync to Authme macOS.

extension MainRepositoryImpl {

    private static let syncSubdirectory = "Authme"
    private static let syncFilename = "sync.2fas"
    private static let debounceInterval: TimeInterval = 5.0

    private static var debounceTimer: Timer?
    private static var iCloudSyncObserver: NSObjectProtocol?

    /// Call this once during app initialization to start observing service changes
    func startICloudSyncObserver() {
        // Remove any existing observer
        stopICloudSyncObserver()

        MainRepositoryImpl.iCloudSyncObserver = notificationCenter.addObserver(
            forName: .servicesWereUpdated,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.scheduleSyncExport()
        }

        // Also observe section changes (groups)
        notificationCenter.addObserver(
            forName: .sectionsWereUpdated,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.scheduleSyncExport()
        }

        Log("iCloud Sync: Observer started", module: .cloudSync)

        // Perform an initial export
        scheduleSyncExport()
    }

    func stopICloudSyncObserver() {
        if let observer = MainRepositoryImpl.iCloudSyncObserver {
            notificationCenter.removeObserver(observer)
            MainRepositoryImpl.iCloudSyncObserver = nil
        }
        MainRepositoryImpl.debounceTimer?.invalidate()
        MainRepositoryImpl.debounceTimer = nil
    }

    /// Debounce exports to avoid excessive writes during rapid changes
    private func scheduleSyncExport() {
        MainRepositoryImpl.debounceTimer?.invalidate()
        MainRepositoryImpl.debounceTimer = Timer.scheduledTimer(
            withTimeInterval: MainRepositoryImpl.debounceInterval,
            repeats: false
        ) { [weak self] _ in
            self?.performSyncExport()
        }
    }

    /// Export current services to iCloud Drive as an unencrypted .2fas file
    private func performSyncExport() {
        // Get iCloud Drive container URL
        guard let containerURL = FileManager.default.url(
            forUbiquityContainerIdentifier: nil
        ) else {
            Log("iCloud Sync: iCloud Drive not available", module: .cloudSync)
            return
        }

        let documentsURL = containerURL
            .appendingPathComponent("Documents")
            .appendingPathComponent(MainRepositoryImpl.syncSubdirectory)

        // Ensure the directory exists
        do {
            try FileManager.default.createDirectory(
                at: documentsURL,
                withIntermediateDirectories: true,
                attributes: nil
            )
        } catch {
            Log("iCloud Sync: Cannot create directory: \(error)", module: .cloudSync)
            return
        }

        let fileURL = documentsURL.appendingPathComponent(MainRepositoryImpl.syncFilename)

        // Reuse the existing export logic (unencrypted)
        export(with: nil) { exportedURL in
            guard let exportedURL else {
                Log("iCloud Sync: Export failed", module: .cloudSync)
                return
            }

            do {
                let data = try Data(contentsOf: exportedURL)

                // Write atomically using a temp file + rename
                let tempURL = fileURL.deletingLastPathComponent()
                    .appendingPathComponent(".\(MainRepositoryImpl.syncFilename).tmp")
                try data.write(to: tempURL, options: .atomic)

                // Replace existing file
                let fm = FileManager.default
                if fm.fileExists(atPath: fileURL.path) {
                    try fm.removeItem(at: fileURL)
                }
                try fm.moveItem(at: tempURL, to: fileURL)

                Log("iCloud Sync: Exported to \(fileURL.path)", module: .cloudSync)

                // Clean up the temp export file
                try? fm.removeItem(at: exportedURL)
            } catch {
                Log("iCloud Sync: Failed to write to iCloud Drive: \(error)", module: .cloudSync)
            }
        }
    }
}
