import SwiftUI
import UIKit

struct SelectableTextEditor: UIViewRepresentable {
    @Binding var text: String
    var onSelectionAction: ((String, String) -> Void)?

    func makeUIView(context: Context) -> UITextView {
        let view = UITextView()
        view.backgroundColor = .clear
        view.font = .systemFont(ofSize: 17)
        view.textColor = .white
        view.delegate = context.coordinator
        view.isEditable = true
        view.isSelectable = true
        view.textContainerInset = UIEdgeInsets(top: 8, left: 4, bottom: 8, right: 4)
        return view
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        if uiView.text != text {
            uiView.text = text
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, onSelectionAction: onSelectionAction)
    }

    final class Coordinator: NSObject, UITextViewDelegate {
        @Binding var text: String
        var onSelectionAction: ((String, String) -> Void)?

        init(text: Binding<String>, onSelectionAction: ((String, String) -> Void)?) {
            _text = text
            self.onSelectionAction = onSelectionAction
        }

        func textViewDidChange(_ textView: UITextView) {
            text = textView.text
        }

        func textViewDidChangeSelection(_ textView: UITextView) {
            guard textView.selectedRange.length > 0 else { return }
            let selected = (textView.text as NSString).substring(with: textView.selectedRange)
            guard selected.count >= 3 else { return }

            let menu = UIMenuController.shared
            if !menu.isMenuVisible {
                textView.becomeFirstResponder()
            }
        }
    }
}

struct NOCOTextContextToolbar: View {
    let selectedText: String
    let onCopy: () -> Void
    let onAI: (String) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                contextButton("Kopieren", icon: "doc.on.doc") { onCopy() }
                contextButton("Zusammenfassen", icon: "text.alignleft") { onAI("summarize") }
                contextButton("Erklären", icon: "questionmark.circle") { onAI("explain") }
                contextButton("Umformulieren", icon: "arrow.triangle.2.circlepath") { onAI("rewrite") }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .background(Color.black.opacity(0.35))
    }

    private func contextButton(_ title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .nocoGlass(cornerRadius: 10, opacity: 0.1)
        }
        .buttonStyle(.plain)
    }
}
