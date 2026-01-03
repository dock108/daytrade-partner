//
//  SafariView.swift
//  TradeLens
//
//  SFSafariViewController wrapper for opening news links.
//

import SafariServices
import SwiftUI

struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}

#Preview {
    Group {
        if let url = URL(string: "https://example.com") {
            SafariView(url: url)
        } else {
            Text("Invalid preview URL")
        }
    }
}
