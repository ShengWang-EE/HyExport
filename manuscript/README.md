# HyExport Manuscript Workspace

Target journal: Nature Communications

## Active Sources

- Main manuscript: `main/hyexport-main.tex`
- Main bibliography: `main/sn-bibliography.bib`
- Current compiled main PDF: `main/hyexport-main.pdf`
- Main manuscript figures: `main/figs/`

The main manuscript is kept as an independent LaTeX folder. Compile it from `main/`.

## Supplementary Information

- SI draft source: `supplementary/hyexport-si.tex`
- SI draft PDF: `supplementary/hyexport-si.pdf`
- SI draft figures: `supplementary/figs/`

The SI is kept as a separate LaTeX folder. Compile it from `supplementary/`.

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

The active main manuscript remains `main/hyexport-main.tex`, and the active SI remains `supplementary/hyexport-si.tex`. Do not create competing active manuscript drafts without recording the source of truth in this README and the revision plan.
