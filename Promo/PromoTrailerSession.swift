//
//  PromoTrailerSession.swift
//  Number Reef
//
//  Owns a dedicated UIWindow sized to the logical gameplay layout (real phone /
//  pad proportions). The recorder scales frames up to App Store export pixels.
//

import SwiftUI
import UIKit

@MainActor
final class PromoTrailerSession {
    static let shared = PromoTrailerSession()

    private var window: UIWindow?
    private var host: UIHostingController<PromoTrailerHostView>?
    private(set) var exportURL: URL?

    func start(layoutSize: CGSize, exportSize: CGSize, usesPadMetrics: Bool) {
        guard window == nil else { return }
        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first else {
            print("PROMO_TRAILER_ERROR no window scene")
            return
        }

        // CoreSimulator's real-time recorder captures the physical screen, so
        // fill that screen. The in-app encoder retains the fixed logical sizes
        // above for off-screen, pixel-exact exports.
        let resolvedLayoutSize = PromoTrailerRuntime.usesExternalCapture
            ? scene.screen.bounds.size
            : layoutSize

        let hostView = PromoTrailerHostView(
            layoutSize: resolvedLayoutSize,
            exportSize: exportSize,
            usesPadMetrics: usesPadMetrics,
            captureProvider: { [weak self] in self?.host?.view },
            onFinished: { [weak self] url in
                self?.exportURL = url
                if let url {
                    print("PROMO_TRAILER_EXPORT \(url.path)")
                }
            }
        )

        let controller = UIHostingController(rootView: hostView)
        controller.view.backgroundColor = .black
        controller.view.frame = CGRect(origin: .zero, size: resolvedLayoutSize)
        controller.view.bounds = CGRect(origin: .zero, size: resolvedLayoutSize)
        controller.view.insetsLayoutMarginsFromSafeArea = false
        if #available(iOS 16.0, *) {
            controller.safeAreaRegions = []
        }

        let window = UIWindow(windowScene: scene)
        // On-screen origin so drawHierarchy stays reliable; may extend past the
        // device bezel when layout is taller than the simulator.
        window.frame = CGRect(origin: .zero, size: resolvedLayoutSize)
        window.backgroundColor = .black
        window.rootViewController = controller
        window.windowLevel = .alert + 1
        window.makeKeyAndVisible()

        controller.additionalSafeAreaInsets = .zero
        controller.view.setNeedsLayout()
        controller.view.layoutIfNeeded()

        self.window = window
        self.host = controller
        print("PROMO_TRAILER_WINDOW layout=\(Int(resolvedLayoutSize.width))x\(Int(resolvedLayoutSize.height)) export=\(Int(exportSize.width))x\(Int(exportSize.height))")
    }
}

/// Tiny on-screen launcher that boots the capture window.
struct PromoTrailerBootstrapView: View {
    var body: some View {
        Color.black
            .ignoresSafeArea()
            .overlay(
                Text("Rendering App Store teaser…")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.7))
            )
            .onAppear {
                PromoTrailerSession.shared.start(
                    layoutSize: PromoTrailerRuntime.layoutSize,
                    exportSize: PromoTrailerRuntime.exportSize,
                    usesPadMetrics: PromoTrailerRuntime.usesPadMetrics
                )
            }
    }
}
