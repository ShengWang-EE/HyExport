# Decision Log

## 2026-06-17

- Target venue set to Nature Communications rather than Nature Energy for the current revision path.
- Active main manuscript remains `manuscript/sn-article.tex` to avoid breaking existing LaTeX paths.
- Imported SI draft moved into `manuscript/supplementary/`.
- Working notes and plans moved into `manuscript/notes/`.
- LaTeX build artifacts moved into `manuscript/build/latex/` and ignored by `manuscript/.gitignore`.
- Current revision should prioritize evidence structure, sensitivity analysis, SI alignment, and figure redesign before sentence-level polishing.

## 2026-07-06

- Active manuscript files were renamed for clarity: main text is `manuscript/main/hyexport-main.tex` and SI is `manuscript/supplementary/hyexport-si.tex`.
- Main manuscript source, PDF, bibliography/class files and main figures were moved into `manuscript/main/`; SI source, PDF, bibliography/class files and SI figures remain in `manuscript/supplementary/`.

## 2026-06-18

- Current NC manuscript framework is locked in `manuscript/notes/NC_locked_framework_and_submission_tasks.md`.
- The restored original main figure sequence is the baseline. New diagnostic figures may support the story but must not replace or demote the original main figures without explicit user approval.
- Main Results sequence is fixed as: cost evidence; domestic absorption/export potential; integrated trade and carbon mitigation; LCOH-only diagnostic; outside-option robustness.
