//
//  AppLayoutDirectionController.swift
//  DeFilms
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

enum AppLayoutDirectionController {
    @MainActor
    static func apply(_ direction: LayoutDirection) {
        #if canImport(UIKit)
        let semanticAttribute: UISemanticContentAttribute = direction == .rightToLeft ? .forceRightToLeft : .forceLeftToRight
        UIView.appearance().semanticContentAttribute = semanticAttribute
        UIView.appearance(whenContainedInInstancesOf: [UIAlertController.self]).semanticContentAttribute = semanticAttribute
        UINavigationBar.appearance().semanticContentAttribute = semanticAttribute
        UITabBar.appearance().semanticContentAttribute = semanticAttribute
        UITableView.appearance().semanticContentAttribute = semanticAttribute
        UICollectionView.appearance().semanticContentAttribute = semanticAttribute

        for scene in UIApplication.shared.connectedScenes {
            guard let windowScene = scene as? UIWindowScene else { continue }
            for window in windowScene.windows {
                window.semanticContentAttribute = semanticAttribute
                window.rootViewController?.applySemanticContentAttribute(semanticAttribute)
                window.rootViewController?.view.setNeedsLayout()
                window.rootViewController?.view.layoutIfNeeded()
            }
        }
        #endif
    }
}

#if canImport(UIKit)
private extension UIViewController {
    func applySemanticContentAttribute(_ semanticAttribute: UISemanticContentAttribute) {
        view.semanticContentAttribute = semanticAttribute
        navigationController?.navigationBar.semanticContentAttribute = semanticAttribute
        tabBarController?.tabBar.semanticContentAttribute = semanticAttribute

        if let alertController = self as? UIAlertController {
            alertController.view.semanticContentAttribute = semanticAttribute
        }

        children.forEach { $0.applySemanticContentAttribute(semanticAttribute) }
        presentedViewController?.applySemanticContentAttribute(semanticAttribute)
    }
}
#endif
