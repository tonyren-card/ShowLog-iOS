import SwiftUI

struct DiaryView: View {
    @Environment(AppState.self) var state
    @State private var editingEntry: DiaryEntry?
    @State private var selectedShow: Show?
    @State private var entryToDelete: DiaryEntry?

    var body: some View {
        NavigationStack {
            Group {
                if state.diary.isEmpty {
                    ContentUnavailableView(
                        "No diary entries",
                        systemImage: "book",
                        description: Text("Log a show to get started.")
                    )
                } else {
                    List {
                        ForEach(state.diary) { entry in
                            DiaryRow(entry: entry)
                                .onTapGesture { selectedShow = entry.showData }
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button("Delete", role: .destructive) {
                                        entryToDelete = entry
                                    }
                                    .tint(.red)
                                    Button("Edit") { editingEntry = entry }
                                        .tint(.blue)
                                }
                                .listRowBackground(Color.surface)
                                .listRowSeparatorTint(Color.border)
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .background(Color.background)
            .navigationTitle("Diary")
            .confirmationDialog(
                "Delete this entry?",
                isPresented: Binding(
                    get: { entryToDelete != nil },
                    set: { if !$0 { entryToDelete = nil } }
                ),
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    if let entry = entryToDelete {
                        Task { try? await state.deleteDiaryEntry(id: entry.id) }
                    }
                    entryToDelete = nil
                }
            }
        }
        .sheet(item: $editingEntry) { entry in
            EditDiaryEntryView(entry: entry).environment(state)
        }
        .sheet(item: $selectedShow) { show in
            ShowDetailView(show: show).environment(state)
        }
    }
}

struct DiaryRow: View {
    let entry: DiaryEntry

    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: entry.showData.posterURL) { phase in
                if case .success(let img) = phase {
                    img.resizable().scaledToFill()
                } else {
                    Color.border
                }
            }
            .frame(width: 40, height: 56)
            .clipShape(RoundedRectangle(cornerRadius: 6))

            VStack(alignment: .leading, spacing: 4) {
                Text(entry.showData.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.textPrimary)
                    .lineLimit(1)

                Text(entry.formattedDate)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.textMuted)

                StarRatingSmall(rating: entry.rating)

                if !entry.notes.isEmpty {
                    Text(entry.notes)
                        .font(.system(size: 12))
                        .foregroundStyle(Color.textMuted)
                        .lineLimit(2)
                }
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Edit form

struct EditDiaryEntryView: View {
    @Environment(AppState.self) var state
    @Environment(\.dismiss) var dismiss

    @State private var entry: DiaryEntry
    @State private var date: Date
    @State private var confirmDelete = false
    @State private var loading = false

    init(entry: DiaryEntry) {
        _entry = State(initialValue: entry)
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"
        _date = State(initialValue: f.date(from: entry.watchedAt) ?? Date())
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Date Watched") {
                    DatePicker("", selection: $date, in: ...Date(), displayedComponents: .date)
                        .datePickerStyle(.graphical)
                        .tint(Color.showGreen)
                }

                Section("Rating") {
                    StarRatingPicker(rating: $entry.rating).padding(.vertical, 4)
                }

                Section("Notes") {
                    TextEditor(text: $entry.notes).frame(minHeight: 80)
                }

                Section {
                    Button("Delete Entry", role: .destructive) { confirmDelete = true }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.background)
            .navigationTitle("Edit Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { Task { await save() } }
                        .disabled(entry.rating == 0 || loading)
                        .tint(Color.showGreen)
                }
            }
            .confirmationDialog("Delete this entry?", isPresented: $confirmDelete) {
                Button("Delete", role: .destructive) { Task { await delete() } }
            }
        }
    }

    private func save() async {
        loading = true; defer { loading = false }
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"
        entry.watchedAt = f.string(from: date)
        try? await state.updateDiaryEntry(entry)
        dismiss()
    }

    private func delete() async {
        try? await state.deleteDiaryEntry(id: entry.id)
        dismiss()
    }
}
