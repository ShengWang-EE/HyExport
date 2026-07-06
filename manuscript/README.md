# HyExport Manuscript Workspace

Target journal: Nature Communications

## Active Sources

- Main manuscript: `hyexport-main.tex`
- Main bibliography: `sn-bibliography.bib`
- Current compiled main PDF: `hyexport-main.pdf`
- Main manuscript figures: `figs/`

Keep these files at the manuscript root for now so the existing LaTeX paths continue to work.

## Supplementary Information

- SI draft source: `supplementary/J14___Supplementary_Information_v0_2/hyexport-si.tex`
- SI draft PDF: `supplementary/J14___Supplementary_Information_v0_2/hyexport-si.pdf`
- SI draft figures: `supplementary/J14___Supplementary_Information_v0_2/figs/`

This is the imported SI draft. Treat it as source material for the NC revision, not as final submission-ready SI yet.

## Notes And Planning

- NC revision plan: `notes/NC_revision_plan.md`
- Legacy manuscript notes: `notes/log.tex`
- Project source-of-truth: `notes/project_truth.md`
- Durable decisions: `notes/decision_log.md`
- Manuscript-facing result tracker: `notes/result_summary.md`
- Handoff and next-step tracker: `notes/paper_handoff.md`

New claim maps, figure maps, revision logs, and audit files should go in `notes/`.

## Build Outputs

- LaTeX intermediate files: `build/latex/`
- Final exported versions can go in `output/`

The `build/` folder is ignored by Git.

## Current Organization Rule

The active main manuscript remains `hyexport-main.tex`. Do not create competing active manuscript drafts without recording the source of truth in this README and the revision plan.
