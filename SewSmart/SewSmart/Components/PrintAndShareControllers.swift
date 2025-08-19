import SwiftUI
import UIKit

struct PrintController: UIViewControllerRepresentable {
    let data: Data
    let fileName: String
    let fileType: PatternFileType
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let tempURL = createTempFile(data: data, fileName: fileName, fileType: fileType)
        let activityViewController = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
        
        // For iPad
        if let popover = activityViewController.popoverPresentationController {
            popover.sourceView = UIApplication.shared.windows.first?.rootViewController?.view
            popover.sourceRect = CGRect(x: UIScreen.main.bounds.midX, y: UIScreen.main.bounds.midY, width: 0, height: 0)
        }
        
        activityViewController.completionWithItemsHandler = { _, _, _, _ in
            // Clean up temp file
            try? FileManager.default.removeItem(at: tempURL)
            presentationMode.wrappedValue.dismiss()
        }
        
        return activityViewController
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
    
    private func createTempFile(data: Data, fileName: String, fileType: PatternFileType) -> URL {
        let tempDirectory = FileManager.default.temporaryDirectory
        let tempURL = tempDirectory.appendingPathComponent(fileName)
        
        try? data.write(to: tempURL)
        return tempURL
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let activityViewController = UIActivityViewController(activityItems: items, applicationActivities: nil)
        
        // For iPad
        if let popover = activityViewController.popoverPresentationController {
            popover.sourceView = UIApplication.shared.windows.first?.rootViewController?.view
            popover.sourceRect = CGRect(x: UIScreen.main.bounds.midX, y: UIScreen.main.bounds.midY, width: 0, height: 0)
        }
        
        activityViewController.completionWithItemsHandler = { _, _, _, _ in
            presentationMode.wrappedValue.dismiss()
        }
        
        return activityViewController
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}