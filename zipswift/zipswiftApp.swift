//
//  zipswiftApp.swift
//  zipswift
//
//  Created by brianchew on 7/1/26.
//

import SwiftUI
import UIKit

@main
struct zipswiftApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    handleDeepLink(url)
                }
        }
    }

    private func handleDeepLink(_ url: URL) {
        guard url.scheme == "zipswift" else { return }

        switch url.host {
        case "daily":
            NotificationCenter.default.post(name: .openDailyChallenge, object: nil)
        case "easy":
            NotificationCenter.default.post(name: .startEasyGame, object: nil)
        case "hard":
            NotificationCenter.default.post(name: .startHardGame, object: nil)
        default:
            break
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        setupQuickActions()
        GameCenterManager.shared.authenticatePlayer()
        return true
    }

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        if let shortcutItem = options.shortcutItem {
            handleShortcutItem(shortcutItem)
        }
        let config = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        config.delegateClass = SceneDelegate.self
        return config
    }

    private func setupQuickActions() {
        UIApplication.shared.shortcutItems = [
            UIApplicationShortcutItem(
                type: "com.zipswift.daily",
                localizedTitle: "Daily Challenge",
                localizedSubtitle: nil,
                icon: UIApplicationShortcutIcon(systemImageName: "calendar"),
                userInfo: nil
            ),
            UIApplicationShortcutItem(
                type: "com.zipswift.easy",
                localizedTitle: "New Easy Game",
                localizedSubtitle: nil,
                icon: UIApplicationShortcutIcon(systemImageName: "leaf"),
                userInfo: nil
            ),
            UIApplicationShortcutItem(
                type: "com.zipswift.hard",
                localizedTitle: "New Hard Game",
                localizedSubtitle: nil,
                icon: UIApplicationShortcutIcon(systemImageName: "flame"),
                userInfo: nil
            )
        ]
    }

    private func handleShortcutItem(_ shortcutItem: UIApplicationShortcutItem) {
        switch shortcutItem.type {
        case "com.zipswift.daily":
            NotificationCenter.default.post(name: .openDailyChallenge, object: nil)
        case "com.zipswift.easy":
            NotificationCenter.default.post(name: .startEasyGame, object: nil)
        case "com.zipswift.hard":
            NotificationCenter.default.post(name: .startHardGame, object: nil)
        default:
            break
        }
    }
}

class SceneDelegate: NSObject, UIWindowSceneDelegate {
    func windowScene(_ windowScene: UIWindowScene, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        switch shortcutItem.type {
        case "com.zipswift.daily":
            NotificationCenter.default.post(name: .openDailyChallenge, object: nil)
            completionHandler(true)
        case "com.zipswift.easy":
            NotificationCenter.default.post(name: .startEasyGame, object: nil)
            completionHandler(true)
        case "com.zipswift.hard":
            NotificationCenter.default.post(name: .startHardGame, object: nil)
            completionHandler(true)
        default:
            completionHandler(false)
        }
    }
}

extension Notification.Name {
    static let openDailyChallenge = Notification.Name("openDailyChallenge")
    static let startEasyGame = Notification.Name("startEasyGame")
    static let startHardGame = Notification.Name("startHardGame")
}
