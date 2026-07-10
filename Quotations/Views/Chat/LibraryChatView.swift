//
//  LibraryChatView.swift
//  Quotations
//

import SwiftData
import SwiftUI

struct LibraryChatView: View {
    let quotations: [Quotation]
    @Bindable var chatState: ChatState
    var onSelectCitation: (PersistentIdentifier, PersistentIdentifier?) -> Void

    @FocusState private var isComposerFocused: Bool
    @State private var draft = ""

    var body: some View {
        VStack(spacing: 0) {
            messageList
            composer
        }
        .onAppear {
            isComposerFocused = true
        }
    }

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    if chatState.messages.isEmpty {
                        emptyState
                    }

                    ForEach(chatState.messages) { message in
                        ChatMessageBubbleView(
                            message: message,
                            onSelectCitation: onSelectCitation
                        )
                        .id(message.id)
                    }

                    if chatState.isGenerating {
                        HStack(spacing: 8) {
                            ProgressView()
                                .controlSize(.small)
                            Text("Thinking…")
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 4)
                        .id("thinking")
                    }

                    if let errorMessage = chatState.errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)
                            .padding(.horizontal, 4)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .onChange(of: chatState.messages.count) { _, _ in
                scrollToBottom(proxy: proxy)
            }
            .onChange(of: chatState.isGenerating) { _, isGenerating in
                if isGenerating {
                    scrollToBottom(proxy: proxy, anchor: "thinking")
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Ask about your library")
                .font(.title3.weight(.semibold))

            Text(
                """
                Ask natural-language questions grounded in your quotations. \
                Try a stylistic profile, recurring themes, or a topic you care about.
                """
            )
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)

            if !chatState.isAvailable {
                Text(AppleIntelligenceAvailability.unavailabilityMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            suggestedPrompts
        }
        .padding(.bottom, 8)
    }

    private var suggestedPrompts: some View {
        FlowLayout(spacing: 8) {
            ForEach(ChatSuggestedPrompt.allCases) { prompt in
                Button(prompt.title) {
                    draft = ""
                    chatState.runSuggestedPrompt(prompt, quotations: quotations)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .disabled(!chatState.isAvailable || chatState.isGenerating)
            }
        }
    }

    private var composer: some View {
        HStack(alignment: .bottom, spacing: 8) {
            TextField("Ask about your quotations…", text: $draft, axis: .vertical)
                .textFieldStyle(.plain)
                .lineLimit(1...4)
                .focused($isComposerFocused)
                .onSubmit(sendDraft)
                .disabled(!chatState.isAvailable || chatState.isGenerating)

            Button("Send", action: sendDraft)
                .keyboardShortcut(.return, modifiers: [.command])
                .disabled(
                    draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        || !chatState.isAvailable
                        || chatState.isGenerating
                )
        }
        .padding(12)
        .background(.bar)
        .overlay(alignment: .top) {
            Divider()
        }
    }

    private func sendDraft() {
        let trimmed = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        draft = ""
        chatState.send(trimmed, quotations: quotations)
    }

    private func scrollToBottom(proxy: ScrollViewProxy, anchor: String? = nil) {
        withAnimation(.easeOut(duration: 0.2)) {
            if let anchor {
                proxy.scrollTo(anchor, anchor: .bottom)
            } else if let last = chatState.messages.last {
                proxy.scrollTo(last.id, anchor: .bottom)
            }
        }
    }
}

private struct ChatMessageBubbleView: View {
    let message: ChatMessage
    var onSelectCitation: (PersistentIdentifier, PersistentIdentifier?) -> Void

    var body: some View {
        VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 8) {
            Group {
                if message.role == .assistant {
                    Text(ChatMarkdown.attributedString(from: message.text))
                } else {
                    Text(message.text)
                }
            }
            .font(.body)
            .foregroundStyle(.primary)
            .textSelection(.enabled)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(bubbleBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .frame(maxWidth: 560, alignment: message.role == .user ? .trailing : .leading)

            if message.role == .assistant, !message.citations.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Sources")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)

                    FlowLayout(spacing: 6) {
                        ForEach(message.citations) { citation in
                            Button(citation.label) {
                                onSelectCitation(citation.quotationId, citation.sourceId)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.mini)
                            .lineLimit(1)
                        }
                    }
                }
                .frame(maxWidth: 560, alignment: .leading)
            }
        }
        .frame(maxWidth: .infinity, alignment: message.role == .user ? .trailing : .leading)
    }

    private var bubbleBackground: some ShapeStyle {
        message.role == .user
            ? AnyShapeStyle(AppColors.highlightColor.opacity(0.18))
            : AnyShapeStyle(Color.secondary.opacity(0.12))
    }
}

/// Simple left-to-right wrapping layout for prompt chips and citations.
private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for placement in result.placements {
            subviews[placement.index].place(
                at: CGPoint(x: bounds.minX + placement.origin.x, y: bounds.minY + placement.origin.y),
                proposal: .unspecified
            )
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> Arrangement {
        let maxWidth = proposal.width ?? .infinity
        var placements: [Placement] = []
        var cursorX: CGFloat = 0
        var cursorY: CGFloat = 0
        var rowHeight: CGFloat = 0
        var size = CGSize.zero

        for index in subviews.indices {
            let sizeThatFits = subviews[index].sizeThatFits(.unspecified)
            if cursorX > 0, cursorX + sizeThatFits.width > maxWidth {
                cursorX = 0
                cursorY += rowHeight + spacing
                rowHeight = 0
            }

            placements.append(Placement(index: index, origin: CGPoint(x: cursorX, y: cursorY)))
            rowHeight = max(rowHeight, sizeThatFits.height)
            cursorX += sizeThatFits.width + spacing
            size.width = max(size.width, cursorX - spacing)
            size.height = max(size.height, cursorY + rowHeight)
        }

        return Arrangement(size: size, placements: placements)
    }

    private struct Placement {
        let index: Int
        let origin: CGPoint
    }

    private struct Arrangement {
        let size: CGSize
        let placements: [Placement]
    }
}
