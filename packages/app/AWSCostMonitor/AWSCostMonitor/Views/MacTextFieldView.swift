//
//  MacTextFieldView.swift
//  AWSCostMonitor
//
//  Custom NSTextField wrapper for proper keyboard support
//

import SwiftUI
import AppKit

struct MacTextField: NSViewRepresentable {
    var placeholder: String
    @Binding var text: String
    var onCommit: (() -> Void)?
    
    func makeNSView(context: Context) -> NSTextField {
        let textField = NSTextField()
        textField.placeholderString = placeholder
        textField.stringValue = text
        textField.isBordered = true
        textField.bezelStyle = .roundedBezel
        textField.delegate = context.coordinator
        textField.isEditable = true
        textField.isSelectable = true
        textField.allowsEditingTextAttributes = false
        textField.importsGraphics = false
        
        // Ensure proper focus and editing behavior
        textField.refusesFirstResponder = false
        
        return textField
    }
    
    func updateNSView(_ nsView: NSTextField, context: Context) {
        if nsView.stringValue != text {
            nsView.stringValue = text
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, NSTextFieldDelegate {
        var parent: MacTextField
        
        init(_ parent: MacTextField) {
            self.parent = parent
        }
        
        func controlTextDidChange(_ obj: Notification) {
            if let textField = obj.object as? NSTextField {
                parent.text = textField.stringValue
            }
        }
        
        func control(_ control: NSControl, textShouldEndEditing fieldEditor: NSText) -> Bool {
            parent.onCommit?()
            return true
        }
        
        // Ensure standard edit menu items work
        override func responds(to aSelector: Selector!) -> Bool {
            if aSelector == #selector(NSText.copy(_:)) ||
               aSelector == #selector(NSText.paste(_:)) ||
               aSelector == #selector(NSText.cut(_:)) ||
               aSelector == #selector(NSText.selectAll(_:)) {
                return true
            }
            return super.responds(to: aSelector)
        }
    }
}