//
// Copyright (c) Vatsal Manot
//

import Swift
import SwiftUI

#if os(iOS) || os(macOS) || targetEnvironment(macCatalyst)

/// A specialized view for receiving search-related information from the user.
public struct SearchBar: DefaultTextInputType {
    @Binding fileprivate var text: String
    
    #if os(iOS) || targetEnvironment(macCatalyst)
    @available(macCatalystApplicationExtension, unavailable)
    @available(iOSApplicationExtension, unavailable)
    @available(tvOSApplicationExtension, unavailable)
    @ObservedObject private var keyboard = Keyboard.main
    #endif
    
    private let onEditingChanged: (Bool) -> Void
    private let onCommit: () -> Void
    
    private var placeholder: String?
    
    #if os(iOS) || targetEnvironment(macCatalyst)
    private var appKitOrUIKitFont: UIFont?
    private var appKitOrUIKitForegroundColor: UIColor?
    private var appKitOrUIKitSearchFieldBackgroundColor: UIColor?
    private var searchBarStyle: UISearchBar.Style = .minimal
    private var iconImageConfiguration: [UISearchBar.Icon: AppKitOrUIKitImage] = [:]
    #endif
    
    private var showsCancelButton: Bool?
    private var onCancel: () -> Void = { }
    
    var customAppKitOrUIKitClass: AppKitOrUIKitSearchBar.Type?
    
    #if os(iOS) || targetEnvironment(macCatalyst)
    private var returnKeyType: UIReturnKeyType?
    private var enablesReturnKeyAutomatically: Bool?
    private var isSecureTextEntry: Bool = false
    private var textContentType: UITextContentType? = nil
    private var keyboardType: UIKeyboardType?
    #endif
    
    public init<S: StringProtocol>(
        _ title: S,
        text: Binding<String>,
        onEditingChanged: @escaping (Bool) -> Void = { _ in },
        onCommit: @escaping () -> Void = { }
    ) {
        self.placeholder = String(title)
        self._text = text
        self.onCommit = onCommit
        self.onEditingChanged = onEditingChanged
    }
    
    public init(
        text: Binding<String>,
        onEditingChanged: @escaping (Bool) -> Void = { _ in },
        onCommit: @escaping () -> Void = { }
    ) {
        self._text = text
        self.onCommit = onCommit
        self.onEditingChanged = onEditingChanged
    }
}

#if os(iOS) || targetEnvironment(macCatalyst)

@available(macCatalystApplicationExtension, unavailable)
@available(iOSApplicationExtension, unavailable)
@available(tvOSApplicationExtension, unavailable)
extension SearchBar: UIViewRepresentable {
    public typealias UIViewType = UISearchBar
    
    public func makeUIView(context: Context) -> UIViewType {
        let uiView = UIViewType()
        
        uiView.delegate = context.coordinator
        
        return uiView
    }
    
    public func updateUIView(_ uiView: UIViewType, context: Context) {
        context.coordinator.base = self
        
        _updateUISearchBar(uiView, environment: context.environment)
    }
    
    func _updateUISearchBar(
        _ uiView: UIViewType,
        environment: EnvironmentValues
    ) {
        style: do {
            if (appKitOrUIKitFont != nil || environment.font != nil) || appKitOrUIKitForegroundColor != nil || appKitOrUIKitSearchFieldBackgroundColor != nil {
                if let font = appKitOrUIKitFont ?? environment.font?.toUIFont() {
                    uiView.searchTextField.font = font
                }
                
                if let foregroundColor = appKitOrUIKitForegroundColor {
                    uiView.searchTextField.textColor = foregroundColor
                }
                
                if let backgroundColor = appKitOrUIKitSearchFieldBackgroundColor {
                    uiView.searchTextField.backgroundColor = backgroundColor
                }
            }
            
            if let placeholder = placeholder {
                uiView.placeholder = placeholder
            }
            
            uiView.searchBarStyle = searchBarStyle
            
            for (icon, image) in iconImageConfiguration {
                if uiView.image(for: icon, state: .normal) == nil { // FIXME: This is a performance hack.
                    uiView.setImage(image, for: icon, state: .normal)
                }
            }
            
            uiView.tintColor = environment.tintColor?.toUIColor()
            
            if let showsCancelButton = showsCancelButton {
                if uiView.showsCancelButton != showsCancelButton {
                    uiView.setShowsCancelButton(showsCancelButton, animated: true)
                }
            }
        }
        
        keyboard: do {
            if let returnKeyType = returnKeyType {
                uiView.returnKeyType = returnKeyType
            } else {
                uiView.returnKeyType = .default
            }
            
            if let keyboardType = keyboardType {
                uiView.keyboardType = keyboardType
            } else {
                uiView.keyboardType = .default
            }
            
            if let enablesReturnKeyAutomatically = enablesReturnKeyAutomatically {
                uiView.enablesReturnKeyAutomatically = enablesReturnKeyAutomatically
            } else {
                uiView.enablesReturnKeyAutomatically = false
            }
        }
        
        data: do {
            if uiView.text != text {
                uiView.text = text
            }
        }
    }
    
    public class Coordinator: NSObject, UISearchBarDelegate {
        var base: SearchBar
        
        init(base: SearchBar) {
            self.base = base
        }
        
        public func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
            base.onEditingChanged(true)
        }
        
        public func searchBar(_ searchBar: UIViewType, textDidChange searchText: String) {
            base.text = searchText
        }
        
        public func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
            base.onEditingChanged(false)
        }
        
        public func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
            searchBar.endEditing(true)
            
            base.onCancel()
        }
        
        public func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
            searchBar.endEditing(true)
            
            base.onCommit()
        }
    }
    
    public func makeCoordinator() -> Coordinator {
        return Coordinator(base: self)
    }
}

#elseif os(macOS)

@available(macCatalystApplicationExtension, unavailable)
@available(iOSApplicationExtension, unavailable)
@available(tvOSApplicationExtension, unavailable)
extension SearchBar: NSViewRepresentable {
    public typealias NSViewType = NSSearchField
    
    public func makeNSView(context: Context) -> NSViewType {
        let nsView = NSSearchField(string: placeholder ?? "")
        
        nsView.delegate = context.coordinator
        nsView.target = context.coordinator
        nsView.action = #selector(context.coordinator.performAction(_:))
        
        nsView.bezelStyle = .roundedBezel
        nsView.cell?.sendsActionOnEndEditing = false
        nsView.isBordered = false
        nsView.isBezeled = true
        
        return nsView
    }
    
    public func updateNSView(_ nsView: NSSearchField, context: Context) {
        context.coordinator.base = self
        
        if nsView.stringValue != text {
            nsView.stringValue = text
        }
    }
    
    final public class Coordinator: NSObject, NSSearchFieldDelegate {
        var base: SearchBar
        
        init(base: SearchBar) {
            self.base = base
        }
        
        public func controlTextDidChange(_ notification: Notification) {
            guard let textField = notification.object as? NSTextField else {
                return
            }
            
            base.text = textField.stringValue
        }
        
        public func controlTextDidBeginEditing(_ notification: Notification) {
            base.onEditingChanged(true)
        }
        
        public func controlTextDidEndEditing(_ notification: Notification) {
            base.onEditingChanged(false)
        }
        
        @objc
        fileprivate func performAction(_ sender: NSTextField?) {
            base.onCommit()
        }
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(base: self)
    }
}

#endif

// MARK: - API -

@available(macCatalystApplicationExtension, unavailable)
@available(iOSApplicationExtension, unavailable)
@available(tvOSApplicationExtension, unavailable)
extension SearchBar {
    public func customAppKitOrUIKitClass(_ cls: AppKitOrUIKitSearchBar.Type) -> Self {
        then({ $0.customAppKitOrUIKitClass = cls })
    }
}

@available(macCatalystApplicationExtension, unavailable)
@available(iOSApplicationExtension, unavailable)
@available(tvOSApplicationExtension, unavailable)
extension SearchBar {
    #if os(iOS) || os(macOS) || targetEnvironment(macCatalyst)
    public func placeholder(_ placeholder: String) -> Self {
        then({ $0.placeholder = placeholder })
    }
    #endif
    
    #if os(iOS) || targetEnvironment(macCatalyst)
    public func font(_ font: UIFont) -> Self {
        then({ $0.appKitOrUIKitFont = font })
    }
    
    public func foregroundColor(_ foregroundColor: AppKitOrUIKitColor) -> Self {
        then({ $0.appKitOrUIKitForegroundColor = foregroundColor })
    }
    
    @_disfavoredOverload
    public func foregroundColor(_ foregroundColor: Color) -> Self {
        then({ $0.appKitOrUIKitForegroundColor = foregroundColor.toUIColor() })
    }
    
    public func textFieldBackgroundColor(_ backgroundColor: UIColor) -> Self {
        then({ $0.appKitOrUIKitSearchFieldBackgroundColor = backgroundColor })
    }

    @_disfavoredOverload
    public func textFieldBackgroundColor(_ backgroundColor: Color) -> Self {
        then({ $0.appKitOrUIKitSearchFieldBackgroundColor = backgroundColor.toUIColor() })
    }
    
    public func searchBarStyle(_ searchBarStyle: UISearchBar.Style) -> Self {
        then({ $0.searchBarStyle = searchBarStyle })
    }
    
    public func iconImage(_ icon: UISearchBar.Icon, _ image: AppKitOrUIKitImage) -> Self {
        then({ $0.iconImageConfiguration[icon] = image })
    }
    
    public func showsCancelButton(_ showsCancelButton: Bool) -> Self {
        then({ $0.showsCancelButton = showsCancelButton })
    }
    
    public func onCancel(perform action: @escaping () -> Void) -> Self {
        then({ $0.onCancel = action })
    }
    
    public func returnKeyType(_ returnKeyType: UIReturnKeyType) -> Self {
        then({ $0.returnKeyType = returnKeyType })
    }
    
    public func enablesReturnKeyAutomatically(_ enablesReturnKeyAutomatically: Bool) -> Self {
        then({ $0.enablesReturnKeyAutomatically = enablesReturnKeyAutomatically })
    }
    
    public func isSecureTextEntry(_ isSecureTextEntry: Bool) -> Self {
        then({ $0.isSecureTextEntry = isSecureTextEntry })
    }
    
    public func textContentType(_ textContentType: UITextContentType?) -> Self {
        then({ $0.textContentType = textContentType })
    }
    
    public func keyboardType(_ keyboardType: UIKeyboardType) -> Self {
        then({ $0.keyboardType = keyboardType })
    }
    #endif
}

// MARK: - Auxiliary Implementation -

#if os(iOS) || targetEnvironment(macCatalyst)
extension UISearchBar {
    /// Retrieves the UITextField contained inside the UISearchBar.
    ///
    /// - Returns: the UITextField inside the UISearchBar
    func _retrieveTextField() -> UITextField? {
        findSubview(ofKind: UITextField.self)
    }
}
#endif

#endif

// MARK: - Development Preview -

#if os(iOS) || targetEnvironment(macCatalyst)
@available(macCatalystApplicationExtension, unavailable)
@available(iOSApplicationExtension, unavailable)
@available(tvOSApplicationExtension, unavailable)
struct SearchBar_Previews: PreviewProvider {
    static var previews: some View {
        SearchBar("Search...", text: .constant(""))
            .searchBarStyle(.minimal)
    }
}
#endif
