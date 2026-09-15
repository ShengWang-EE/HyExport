# NC Quality Upgrade Execution Plan

Date: 2026-06-18

Target: improve the paper's scientific quality and Nature Communications competitiveness, not merely submission formatting.

Working principle: keep the novelty strong, but make each strong claim traceable to evidence, methods, figures, or SI. Do not weaken the central claim unless evidence cannot be supplied.

## Current Quality Judgement

The current main manuscript has a defensible NC-style story:

> Strategic offshore hydrogen exporters in Europe cannot be inferred from LCOH alone; they emerge from the interaction of geospatial production cost, domestic power-gas absorption, shipping economics, national hydrogen/ammonia demand, and competing external imports.

The main text is now readable and coherent, but it remains borderline for NC because three quality issues could weaken editor or reviewer confidence:

1. The "first integrated European-scale" novelty claim is stated but not yet backed by an explicit literature-method comparison.
2. The Europe-wide domestic absorption estimate still depends on scaling the Ireland hourly model by national electricity and gas demand.
3. The figures still contain some diagnostic/report-style displays instead of a fully claim-led NC figure sequence.

## Upgrade Sequence

### Step 1: Lock Claim-Evidence Map

Purpose:
- Make every major claim in title, abstract, Introduction, Results topic sentences and Discussion map to a figure, table, Methods section, SI section, result table, or checkpoint.

Actions:
- Update `manuscript/notes/claim_evidence_map.md` from the current `sn-article.tex`.
- Add a short "submission-facing risk" column for claims that need SI support.
- Define canonical terms that must not drift:
  - LCOH-only baseline
  - integrated model
  - available export potential
  - net export
  - external import
  - outside-option price
  - carbon mitigation contribution

Acceptance criteria:
- No abstract claim is unsupported.
- Any partial claim has a concrete fix in Step 2, 3, 4 or 5.

Files likely changed:
- `manuscript/notes/claim_evidence_map.md`
- possibly `manuscript/sn-article.tex` if a claim is clearly phrased in a risky way.

### Step 2: Strengthen Novelty Evidence Without Weakening Novelty

Purpose:
- Support the "first integrated European-scale" claim with explicit comparison, instead of relying on assertion.

Actions:
- Add a main-text sentence or short paragraph in the Introduction making the novelty dimensions explicit.
- Add an SI table comparing prior study types with this work:
  - geospatial offshore hydrogen cost-supply curves
  - hourly domestic power-gas absorption
  - cross-border hydrogen/ammonia shipping
  - external import option
  - LCOH-only counterfactual
  - carbon mitigation attribution

Acceptance criteria:
- The phrase "first integrated European-scale" is backed by a visible feature-comparison argument.
- Novelty remains strong and specific.

Files likely changed:
- `manuscript/sn-article.tex`
- `manuscript/supplementary/sn-article.tex`
- `manuscript/sn-bibliography.bib` only if new references are needed.

### Step 3: Defend Domestic Absorption Extrapolation

Purpose:
- Prevent reviewers from dismissing the UK/Ireland export-potential story as an artefact of scaling Ireland to Europe.

Actions:
- Use existing `results/tables/NC_domestic_absorption_sensitivity.csv`.
- Add an SI subsection explaining the sensitivity design and what changes or remains robust.
- Add one cautious but confident sentence in the main Discussion pointing readers to the SI sensitivity.

Acceptance criteria:
- The domestic absorption assumption is acknowledged, stress-tested, and connected to the main conclusion.
- Main text does not overclaim country-specific operation for countries where no full unit-commitment model was run.

Files likely changed:
- `manuscript/sn-article.tex`
- SI `sn-article.tex`
- possibly a new SI figure or table copied from existing results.

### Step 4: Improve Figure Story Quality

Purpose:
- Make the figure sequence carry the NC story more directly.

Priority:
- First improve the domestic absorption/export-potential part, because it is the weakest bridge.
- The cost table has been restored to the main Results after the user requested the original figure sequence.

Actions:
- Audit each main figure for a one-sentence claim and panel role.
- Redesign or replace the most report-like figure among:
  - `fig_cost_table.pdf`
  - `fig_unit_commitment_main.pdf`
  - `fig_wind_decomposition.pdf`
- Keep dense dispatch diagnostics in SI.

Acceptance criteria:
- Each main figure can be summarized in one sentence.
- The first visual pass makes the central story obvious before reading the full Results.

Files likely changed:
- plotting scripts under `scripts/figures/` or `scripts/plotFigures.m`
- `manuscript/main/figs/*.pdf`
- `manuscript/sn-article.tex`

### Step 5: Clarify Carbon Mitigation And Source Numbers

Purpose:
- Make headline values such as 175.5 Mt CO2 yr^-1 and country contributions auditable.

Actions:
- Build or update `results/tables/NC_headline_numbers.csv`.
- Add clear Methods/SI explanation for:
  - displacement baseline
  - supplier-destination attribution
  - units and conversion
  - whether hydrogen and ammonia are combined as H2-equivalent energy.
- Align figure legends with this terminology.

Acceptance criteria:
- Every number in abstract and Discussion can be traced to one row in a headline-number table.
- A reviewer can reproduce the carbon-mitigation interpretation without reading MATLAB code.

Files likely changed:
- analysis script for headline numbers
- `results/tables/NC_headline_numbers.csv`
- `manuscript/sn-article.tex`
- SI `sn-article.tex`

### Step 6: SI Alignment And Final Quality Pass

Purpose:
- Make the SI support the current NC story rather than an older manuscript version.

Actions:
- Add SI sections for:
  - LCOH-only counterfactual
  - outside-option threshold scan
  - domestic absorption sensitivity
  - novelty comparison table
  - headline-number/source table
- Compile SI and main manuscript.
- Run final submission-audit checks for overclaim, figure-text mismatch, terminology drift and method anchoring.

Acceptance criteria:
- Main manuscript and SI use the same metric names and headline numbers.
- LaTeX compiles.
- `git diff --check` passes.
- The final quality judgement moves from borderline to ready-for-NC-initial-submission.

## Immediate Next Task

Start with Step 1. Update the claim-evidence map against the current main manuscript and mark each gap as one of:

- fixed already
- needs novelty comparison
- needs domestic sensitivity support
- needs figure redesign
- needs carbon-method/source-number support
