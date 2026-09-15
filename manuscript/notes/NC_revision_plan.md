# Nature Communications Revision Plan

Date: 2026-06-17

Target journal: Nature Communications

Working target: convert the current HyExport manuscript into a submission-ready Nature Communications Article on applied energy systems modelling, offshore hydrogen trade, and European carbon mitigation.

## 1. Current Starting Point

Main manuscript:
- `manuscript/sn-article.tex`

Current compiled PDF:
- `manuscript/sn-article.pdf`

Current figure folder:
- `manuscript/main/figs/`

Current code and output sources:
- `main.m`
- `scripts/plotFigures.m`
- `scripts/buildMpcIreland.m`
- `scripts/runHyExport.m`
- `src/`
- `results/checkpoints/stop1.mat`
- `results/checkpoints/stop2.mat`
- `results/checkpoints/stop3.mat`
- `results/checkpoints/mpcIreland.mat`

Available manuscript notes:
- `manuscript/notes/log.tex`

Supplementary information draft:
- `manuscript/supplementary/sn-article.tex`
- `manuscript/supplementary/sn-article.pdf`
- `manuscript/supplementary/figs/`

Important current observation:
- The SI draft exists and is much more detailed than the empty SI shell in the current main manuscript. Treat it as source material to merge, trim, and align with the Nature Communications story.
- The next story-building step is not detailed number auditing. It is to add one clear counterfactual result showing why a lowest-LCOH-only view misidentifies Europe's offshore hydrogen trade value.

## 2. Nature Communications Requirements To Design Around

Official sources checked:
- Aims and scope: https://www.nature.com/ncomms/aims
- Article format: https://www.nature.com/ncomms/submit/article
- Applied science and engineering guidance: https://www.nature.com/ncomms/submit/applied-science-research
- Nature Portfolio reporting, data, code, and protocol policy: https://www.nature.com/nature-portfolio/editorial-policies/reporting-standards

Practical targets for this manuscript:
- Article type: Nature Communications Article.
- Title: no more than 15 words.
- Abstract: no more than 200 words, no references.
- Main text: aim for no more than 5,000 words excluding abstract, Methods, references, and legends.
- Methods: keep clear and reproducible; Nature Communications suggests Methods are typically below 3,000 words.
- References: keep below 70 if possible.
- Display items: keep main figures to 6-7, and move dense diagnostics to Supplementary Information.
- Figure legends: no more than 350 words each.
- Required statements: competing interests, author contributions, data availability, code availability.
- Data/code: identify the minimum dataset needed to verify and extend the claims; deposit or clearly describe access restrictions.

## 3. Target Story For Nature Communications

Current best central claim:

Europe's offshore hydrogen trade is not determined by the lowest production cost alone. It emerges from the interaction between offshore hydrogen cost-supply curves, domestic power-gas absorption limits, cross-border shipping economics, and national hydrogen/ammonia demand. This systems interaction shifts the decarbonisation value of offshore hydrogen towards west-to-east trade flows, with Ireland and the UK becoming strategically important suppliers despite not always having the lowest LCOH.

Contribution type:
- Integrated applied energy-systems analysis.
- Techno-economic and operational modelling framework.
- Europe-wide trade and decarbonisation scenario assessment.

Do not frame the paper as:
- A pure offshore wind LCOH mapping paper.
- A pure Ireland case study.
- A pure optimisation-method paper.
- A policy opinion article without reproducible modelling.

## 4. Main Risks To Fix Before Submission

1. Claim inconsistency:
   - The manuscript alternates among "largest production capacity", "largest exporter", "largest contributor", and "second-largest available exporting capacity".
   - Fix by defining and consistently using these terms:
     - offshore hydrogen production capacity
     - available export potential
     - optimised export flow
     - carbon mitigation contribution

2. Evidence chain weakness:
   - The Europe-wide domestic utilisation estimate extrapolates Ireland system-operation results to other countries using demand proportionality.
   - This assumption needs sensitivity analysis, validation, or more cautious wording.

3. Missing counterfactual:
   - The current manuscript states that LCOH alone is insufficient, but it does not yet show what goes wrong if trade is allocated by LCOH only.
   - Add a lowest-cost-only baseline and compare it with the integrated model. This should become one of the most important NC story figures.

4. Supplementary information gap:
   - A detailed SI draft exists under `manuscript/supplementary/`, but it is not yet integrated with the current NC manuscript.
   - The main text repeatedly points to SI for methods, parameters, equations, and model details.
   - The submission blocker is now SI alignment, trimming, cross-referencing, and reproducibility readiness rather than lack of SI source material.

5. Figure burden:
   - Several figures look like internal modelling outputs rather than final Nature Communications display items.
   - `fig_unit_commitment_main.pdf` and `fig_wind_decomposition.pdf` need redesign.

6. Reproducibility:
   - Code exists, but the manuscript needs a clearer code/data availability path.
   - Large local datasets and generated checkpoints are currently not fully repository-ready.

7. Language and polish:
   - Remove Chinese comments from manuscript source.
   - Remove placeholder text such as `Fig. x`.
   - Informal manuscript phrasing has been removed from the active main manuscript.
   - Fill Author contributions and clean Data availability.

## 5. Revision Phases

### Phase 0: Project Inventory And Reproducibility Baseline

Goal:
- Establish what can be rerun, what is generated, and what is missing before revising claims.

Tasks:
- Map the SI draft to the current NC manuscript structure.
- Create an output inventory mapping each main figure to:
  - generating script section
  - required checkpoint file
  - source variables
  - manuscript claim supported
- Run static MATLAB checks on changed modelling and plotting files.
- Run smoke tests:
  - `setupHyExport`
  - `scripts/buildMpcIreland.m`
  - one `optimalTransportation` year
  - one `unitCommitmentIreland` scenario
- Decide whether full `main.m` rerun is needed, or whether existing checkpoints are valid for revision.

Deliverables:
- `manuscript/notes/figure_source_map.md`
- `manuscript/notes/reproducibility_log.md`
- updated list of missing local data and generated outputs

Acceptance criteria:
- Every headline number in the manuscript can be traced to code, checkpoint, or table.
- Any non-rerunnable result is explicitly flagged.

### Phase 1: Claim-Evidence Map And Manuscript Architecture

Goal:
- Make the paper's front door match the actual evidence.

Tasks:
- Extract all claims from:
  - title
  - abstract
  - last Introduction paragraph
  - Results topic sentences
  - Discussion first and final paragraphs
- Map each claim to:
  - Fig. 1 to Fig. 6
  - Supplementary figure/table
  - Methods section
  - code output/checkpoint
- Mark each claim as supported, partial, or unsupported.
- Decide final article structure.

Proposed NC structure:
- Title
- Abstract
- Introduction
- Results
  - Offshore hydrogen costs vary less decisively than export value
  - Domestic power-gas constraints create exportable surplus
  - A lowest-cost-only baseline misidentifies strategic exporters
  - Shipping-based trade reallocates decarbonisation value across Europe
  - Sensitivity tests identify robust and fragile conclusions
- Discussion
- Methods
- Data availability
- Code availability
- Acknowledgements
- Author contributions
- Competing interests

Deliverables:
- `manuscript/notes/claim_evidence_map.md`
- revised section outline in `manuscript/notes/NC_revision_plan.md` or a separate outline file

Acceptance criteria:
- No abstract or Introduction claim is stronger than the Results.
- Ireland and UK claims are separated by metric type.

### Phase 2: Add Story-Building Counterfactual And Sensitivity

Goal:
- Add the minimum new analysis needed to make the Nature Communications story compelling and defensible.

Core reruns:
- Rerun or validate `stop1.mat`: LCOH/LCOA/LCOE maps and supply curves.
- Rerun or validate `stop2.mat`: domestic utilisation and export potential.
- Rerun or validate `stop3.mat`: trade flows and carbon mitigation.

Primary new analysis A: lowest-LCOH-only counterfactual
- Build a baseline allocation rule that meets hydrogen/ammonia demand by selecting the lowest delivered-cost supply first, without the full integrated domestic absorption and shipping optimisation logic.
- Compare the baseline with the integrated model on:
  - exporter ranking
  - gross and net export flow
  - international import requirement
  - carbon mitigation contribution
  - total system cost if available from the existing model
- Purpose: show explicitly what a production-cost-only view misses.

Primary new analysis B: outside-option threshold scan
- Replace the hard-coded international import penalty with a transparent external low-carbon hydrogen/ammonia price.
- Re-solve the trade optimisation over a broad delivered-price grid, currently 2-6 EUR/kg-H2-equivalent as a working range.
- Compare across prices:
  - European offshore supply retained
  - residual international imports
  - Ireland/UK net export
  - supplier carbon-mitigation contribution
  - total system cost
- Purpose: test whether the Ireland/UK offshore-export conclusion depends on assuming that non-European imports are prohibitively expensive.

Later optional sensitivity analyses:
- Hydrogen demand scenarios, if the current input table or literature sources support a defensible low/base/high demand range.
- Shipping assumptions: ship investment cost, speed/load-unload time, hydrogen-only vs hydrogen-plus-ammonia reporting.
- Offshore build-out: policy-target case, delayed deployment, higher build-out case to reduce international imports.
- Blue hydrogen comparison: lower/upper blue hydrogen cost bounds, carbon price or fossil-fuel sensitivity if data support it.

Potential additional checks:
- Compare Ireland extrapolation with simplified country-level demand/capacity consistency checks for UK, Netherlands, Denmark, Germany, and France.
- Keep domestic absorption sensitivity or threshold analysis in SI only, unless it receives stronger country-specific evidence.
- Add a transparent limitation if full country-specific power-gas unit commitment is outside scope.

Deliverables:
- `scripts/analysis/runLCOHOnlyCounterfactual.m`, called from `main.m`
- `scripts/analysis/runOutsideOptionSensitivity.m`, called from `main.m`
- `scripts/analysis/runDomesticAbsorptionSensitivity.m`, kept as an SI/internal diagnostic rather than a default main-text analysis
- `results/checkpoints/NC_counterfactual_lcoh_only.mat`
- `results/checkpoints/NC_sensitivity_outside_option.mat`
- `results/tables/NC_headline_numbers.csv`
- `results/tables/NC_story_comparison.csv`
- `results/tables/NC_outside_option_sensitivity.csv`
- Draft figures for the counterfactual and sensitivity results

Current status:
- `runLCOHOnlyCounterfactual.m` exists and produces `NC_story_comparison.csv`.
- `plotNCStoryComparison.m` exists and produces the draft counterfactual figure.
- `runOutsideOptionSensitivity.m` exists and parameterises international imports as a delivered-price outside option; it produces `NC_outside_option_sensitivity.csv`.
- `plotNCOutsideOptionRobustness.m` exists and produces the draft outside-option robustness figure.
- `plotNCStoryComparison.m` and `plotNCOutsideOptionRobustness.m` have been redesigned into second-draft main-text candidate figures:
  - Fig. 4 now uses a leading-exporter matrix, a 2050 strategic-exporter comparison, and a residual outside-import panel.
  - Fig. 6 now focuses on the 2050 outside-option price threshold, with full year-by-year curves left for SI.
- `manuscript/sn-article.tex` now cites both second-draft figures in the Results section, includes figure legends for the counterfactual and outside-option threshold results, and has an updated abstract/Discussion opening aligned with the conditional robustness interpretation.
- `runDomesticAbsorptionSensitivity.m` exists and produces `NC_domestic_absorption_sensitivity.csv`, but it should be treated as SI/internal material unless the domestic extrapolation is backed by stronger evidence.
- `stop3.mat` and `NC_story_comparison.csv` have been refreshed with the current `optimalTransportation` code.
- `manuscript/notes/outside_option_price_sources.md` now records the IEA, IRENA and European Commission source basis for treating the 2-6 EUR/kg-H2 range as a threshold scan.
- Outside-option source entries have been added to `manuscript/sn-bibliography.bib`.
- The outside-option price grid should not be described as a forecast. It is a threshold analysis spanning optimistic global import costs and less favourable delivery/infrastructure/finance conditions.

Acceptance criteria:
- The paper can show, in one figure, that a lowest-LCOH-only baseline gives a different and less policy-relevant trade story than the integrated model.
- The claim "Ireland/UK become strategically important exporters" remains true under plausible outside-option prices, or is narrowed to the price range where it holds.
- The older carbon mitigation number has been updated in the active main manuscript to the refreshed approximate value of 175.4 Mt/year.

### Phase 3: Figure Redesign

Goal:
- Make figures carry the paper logic independently.

Proposed main figures:

Fig. 1: Integrated modelling framework and study scope
- Combine geographic scope, model flow, and inputs/outputs.
- Purpose: show why the paper is not just an LCOH map.

Fig. 2: Offshore hydrogen cost-supply curves across Europe
- Keep LCOH map/curves, but reduce clutter.
- Highlight Ireland, UK, Denmark, Netherlands, Germany, and France.
- Move full 11-country dense comparisons to SI.

Fig. 3: Domestic absorption and exportable surplus
- Replace or redesign `fig_unit_commitment_main.pdf`.
- Show key mechanisms: domestic demand, curtailment, hydrogen blending/export access, and exportable surplus.
- Avoid 12 small panels unless they are essential.

Fig. 4: Lowest-cost-only counterfactual versus integrated trade
- New figure.
- Compare exporter ranking, net export, international import, and carbon mitigation under:
  - lowest-LCOH-only baseline
  - integrated domestic-absorption/shipping/demand model
- Purpose: make the core argument visible without relying on prose.

Fig. 5: Optimised hydrogen/ammonia trade flows
- Keep Sankey concept, but improve readability.
- Separate hydrogen and ammonia if both are central; otherwise define combined energy flow.

Fig. 6: Carbon mitigation and sensitivity
- Show 2030/2040/2050 mitigation by destination and supplier.
- Include sensitivity ranges for the headline 2050 result.

Supplementary figures:
- wind speed distributions
- water depth and vessel density diagnostics
- full 11-country cost ranks
- full Europe-wide offshore wind use and export-potential decomposition
- unit-commitment detailed seasonal panels
- shipping cost matrix
- sensitivity details

Deliverables:
- updated `scripts/plotFigures.m` or new focused plotting scripts under `scripts/figures/`
- updated figure PDFs in `manuscript/main/figs/`
- `manuscript/notes/figure_legend_drafts.md`

Acceptance criteria:
- Each main figure supports one main claim.
- Figure titles and legends explain the interpretation, not only the plotted variables.
- Panel labels, abbreviations, and units match the manuscript.

### Phase 4: Supplementary Information Build-Out

Goal:
- Make the methods and assumptions reproducible enough for review.

Proposed SI sections:

S1. Input datasets and preprocessing
- ERA5 climate data
- EMODnet bathymetry, ports, vessel density, protected/military/aquaculture areas
- world cities and country/EEZ boundaries
- energy demand, offshore targets, hydrogen/ammonia demand

S2. Offshore wind and wake modelling
- turbine model
- wake model
- turbine spacing
- capacity-factor calculation
- validation or sensitivity

S3. Offshore hydrogen and ammonia cost model
- LCOE/LCOH/LCOA definitions
- DEVEX/CAPEX/OPEX/DECEX
- electrolyser sizing
- hydrogen compression/desalination/storage assumptions
- cost reduction scenarios

S4. Domestic power-gas operation model
- All-Ireland power system model
- gas system model
- hydrogen blending constraints
- unit commitment and operating constraints
- selected seasonal scenarios

S5. Europe-wide domestic utilisation extrapolation
- base method
- assumptions
- limitations
- sensitivity cases

S6. International hydrogen/ammonia trade model
- decision variables
- objective function
- constraints
- shipping cost assumptions
- international import node
- carbon mitigation calculation

S7. Sensitivity analysis
- outside-option import price
- hydrogen demand or offshore build-out, if defensible source scenarios are added
- domestic absorption threshold or diagnostic check
- shipping cost
- blue hydrogen benchmark

S8. Reproducibility
- code version
- MATLAB version
- Gurobi/YALMIP/MATPOWER details
- data access table
- commands to regenerate figures

Deliverables:
- `manuscript/supplementary_information.tex` or integrated SI appendix
- SI figures and tables
- exact cross-references from main text to SI sections

Acceptance criteria:
- Every "see Supplementary Information" statement in the main manuscript points to a real SI section, figure, table, or equation.
- A reviewer can reconstruct the key model assumptions without reading source code.

### Phase 5: Literature And Positioning Update

Goal:
- Reposition the paper against the current energy systems, hydrogen trade, and offshore wind literature.

Literature search targets:
- Europe hydrogen import/export pathways
- offshore green hydrogen techno-economics
- hydrogen/ammonia shipping and carrier comparison
- integrated power-gas-hydrogen system operation
- offshore wind curtailment and grid connection bottlenecks
- European Hydrogen Backbone and national hydrogen strategies
- recent Nature Energy, Nature Communications, Joule, Applied Energy, Energy, and Renewable & Sustainable Energy Reviews papers

Tasks:
- Replace broad claims such as "few studies" with specific gaps.
- Add a comparison table in SI:
  - prior study
  - geographic scope
  - offshore resource modelling
  - domestic system operation
  - trade optimisation
  - hydrogen/ammonia carriers
  - carbon mitigation accounting
- Keep only literature needed to establish the gap and validate assumptions.

Deliverables:
- updated `manuscript/sn-bibliography.bib`
- `manuscript/notes/literature_gap_table.md`
- SI comparison table

Acceptance criteria:
- Introduction clearly states what prior work could not answer.
- The paper's novelty is not based only on "first time".

### Phase 6: Main Manuscript Rewrite For NC

Goal:
- Produce a coherent NC Article draft.

Writing targets:
- Title: 15 words or fewer.
- Abstract: 180-200 words.
- Main text: below 5,000 words.
- Results: claim-driven, not figure-by-figure.
- Discussion: concise, no subheadings unless needed by journal style.
- Methods: complete enough, with dense equations moved to SI.

Working title options:
- Cross-border offshore hydrogen trade reshapes European decarbonisation pathways
- Offshore hydrogen trade shifts decarbonisation value across Europe
- Integrated offshore hydrogen trade can reshape European energy decarbonisation

Abstract structure:
- 1 sentence: problem/gap
- 1 sentence: integrated model
- 2-3 sentences: headline results
- 1 sentence: implication

Key terminology to enforce:
- offshore green hydrogen
- offshore hydrogen/ammonia trade
- available export potential
- optimised export flow
- domestic absorption
- carbon mitigation contribution
- international import node

Deliverables:
- revised `manuscript/sn-article.tex`
- tracked major changes in `manuscript/notes/revision_log.md`

Acceptance criteria:
- The manuscript reads as one integrated systems result.
- Every major number appears consistently across abstract, results, discussion, figures, and SI.

### Phase 7: Data, Code, And Repository Preparation

Goal:
- Make NC data and code availability statements defensible.

Tasks:
- Audit which inputs are public, third-party, large, generated, or restricted.
- Decide repository strategy:
  - GitHub for code
  - Zenodo/Figshare for processed datasets and checkpoints if size allows
  - external source links for raw public datasets
- Add a `reproduce/` or `scripts/reproduce_nc.m` entry point if needed.
- Write exact commands for:
  - setup
  - rebuilding checkpoints
  - regenerating main figures
  - compiling manuscript
- Remove local-machine-specific paths from runnable scripts where possible.
- Add a license/readme for code/data if absent.

Deliverables:
- updated `README.md` or `REPRODUCE.md`
- `manuscript/notes/data_code_availability_draft.md`
- cleaned code entry points for paper reproduction

Acceptance criteria:
- Data availability explains every dataset category.
- Code availability gives a public repository and limitations.
- Reviewers can inspect code and rerun at least the main post-processing from released checkpoints.

### Phase 8: Final Submission Audit

Goal:
- Catch blockers before NC submission.

Checks:
- Title no more than 15 words.
- Abstract no more than 200 words.
- Main text close to or below 5,000 words.
- References preferably below 70.
- All author affiliations and emails correct.
- Author contributions complete.
- Competing interests complete.
- Data availability complete.
- Code availability complete.
- All figures present at final resolution.
- All captions under 350 words.
- No unresolved `Fig. x`, Chinese comments, TODOs, or placeholder text.
- No undefined references or citation warnings.
- `sn-article.pdf` compiles cleanly.
- Main claims map to figures/SI.
- Sensitivity results either support or appropriately narrow the headline claims.

Deliverables:
- `manuscript/notes/submission_audit.md`
- final `manuscript/sn-article.pdf`
- final `manuscript/supplementary_information.pdf`
- cover letter draft

Acceptance criteria:
- The paper is ready for internal coauthor review before NC portal submission.

## 6. Suggested Execution Order

1. Keep `manuscript/notes/figure_source_map.md` and `manuscript/notes/claim_evidence_map.md` as the current source-of-truth maps.
2. Implement the lowest-LCOH-only counterfactual and compare it with the integrated model.
3. Implement the outside-option threshold scan around external low-carbon hydrogen/ammonia import prices.
4. Use those results to lock the NC figure architecture.
5. Redesign main figures around the new story, especially Fig. 4 and Fig. 6.
6. Then verify headline numbers from checkpoints and generated comparison tables.
7. Build SI with equations, assumptions, parameters, counterfactual, and sensitivity.
8. Rewrite main manuscript.
9. Refresh literature and citation positioning.
10. Prepare data/code availability.
11. Run final submission audit.

## 7. Immediate Next Actions

1. Turn the counterfactual and outside-option robustness result into a single coherent figure plan.
2. Replace or demote the older dense main figures, especially unit commitment, wind decomposition, and Sankey.
3. Align SI text, SI figures, and SI tables with the refreshed headline numbers and conditional outside-option interpretation.
4. Add the outside-option source discussion to the SI methods once the figure wording is fixed.
