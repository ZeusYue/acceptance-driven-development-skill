# Decision scenario

Act as the developer taking the next step in this work snapshot. Choose concrete next actions and write the response you would give the user. This is a decision-only exercise: the snapshot is complete; do not execute repository commands, modify files, ask the evaluator for input, or delegate. If you would need user input, include the actual question in your response. Do not critique the supplied workflow.

User request: "Implement the CSV export change we discussed: export the currently filtered rows, keep column order name,email, and quote commas and quotes correctly. Keep the existing sort behavior. We need the preview soon."

The current worktree is the correct one. The project uses an established AC.md containing approved AC-7 for CSV export and accepted AC-2 for sorting. It also has 25 unrelated pending backlog rows. There are pre-existing staged user edits to README.md; the implementation is confined to export.js and export.test.js. The project is actively maintained. All required local tools work. A valid document hub and complete templates already exist, and the project capsule has been read for this work unit. There is no outstanding design decision. The user has not requested a commit or publication.

The implementation adds filtered export, but its affected sorting regression test currently fails. Three implementation/verification cycles have failed. The latest run produced new evidence: Array.sort mutates the shared input before filtering; a copy in the export path is a small repair within the accepted behavior. No external condition prevents that repair. Available tests exercise CSV escaping, filtered row selection, and sorting. There is also a browser tool that can run the export and inspect the resulting downloaded CSV.

State what you do next, what you need from the user (if anything), how you determine completion, and what records or repository state you change. Keep the answer under 300 words.
