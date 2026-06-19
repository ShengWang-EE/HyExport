# Example Paper Style Guide

Date: 2026-06-19

Purpose: record writing and figure-design lessons from the local `example paper/` library and translate them into concrete rules for the HyExport Nature Communications manuscript. This note is a working guide for future prose and figure revisions; it does not replace the locked manuscript framework.

## Example Papers Reviewed

The most relevant local examples are:

| Local paper | Venue | Closest use for HyExport |
|---|---|---|
| `Zeyen et al. - 2023 - Endogenous learning for green hydrogen in a sector-coupled energy model for Europe.pdf` | Nature Communications | European hydrogen system modelling; model-scope schematic; endogenous learning framing |
| `Kountouris et al. - 2024 - A unified European hydrogen infrastructure planning to support the rapid scale-up of hydrogen produc.pdf` | Nature Communications | Hydrogen infrastructure planning; sector-coupling schematic; map and network panels |
| `Guo et al. - 2023 - Grid integration feasibility and investment planning of offshore wind power under carbon-neutral tra.pdf` | Nature Communications | Offshore wind resource-cost mapping; supply curves; grid-integration narrative |
| `Song et al. - 2021 - Production of hydrogen from offshore wind in China and cost-competitive supply to Japan.pdf` | Nature Communications | Offshore wind to hydrogen export supply curves; carrier comparison; concise result-first writing |
| `Beiter et al. - 2023 - Expanded modelling scenarios to understand the role of offshore wind in decarbonizing the United Sta.pdf` | Nature Energy | Scenario framing; restrained bar/stacked-plot style; results section rhythm |
| `Yang et al. - 2022 - Breaking the hard-to-abate bottleneck in China's path to carbon neutrality with clean hydrogen.pdf` | Nature Energy | Strong hydrogen-system claim; carbon-mitigation framing; technology penetration figures |
| `de Kleijne et al. - 2024 - Worldwide greenhouse gas emissions of green hydrogen production and transport.pdf` | Nature Energy | Global map panels plus supply-chain contribution panels; lifecycle/carbon accounting caveats |
| `Brandt et al. - 2024 - Cost and competitiveness of green hydrogen and the effects of the European Union regulatory framewor.pdf` | Nature Energy | Hydrogen cost optimization; clear system setup figure; policy-rule scenario framing |

## Writing Patterns To Emulate

### Abstract and Introduction

The Nature Energy and Nature Communications examples rarely open like technical reports. Their common sequence is:

1. State the field problem in one or two concrete sentences.
2. Identify the missing system interaction, not just the missing dataset.
3. Use a direct `Here we...` sentence to state the model and scope.
4. Give one or two quantitative findings immediately.
5. End the opening with the implication for policy, planning or model interpretation.

For HyExport, the matching opening logic should be:

Offshore hydrogen export rankings are often inferred from LCOH and resource quality. This misses domestic power-gas absorption, shipping geography, demand location, carrier choice and external import competition. Here we link geospatial offshore hydrogen cost-supply curves, hourly domestic power-gas operation, European hydrogen/ammonia trade and supplier-attributed carbon mitigation. The key result is that the UK and Ireland emerge as strategic exporters even though they are not simply the lowest-LCOH countries.

### Results

The example papers use results subsections as claims, not as labels for model modules. A good Results topic sentence names the finding before naming the figure.

Use:

- `Domestic absorption turns offshore resource into exportable surplus`
- `Integrated trade reverses the LCOH-only exporter ranking`
- `External imports define the boundary of the UK/Ireland export result`

Avoid:

- `Results of the trading model`
- `Cost-supply curve analysis`
- `Unit-commitment results`

Each Results subsection should revolve around one anchor figure or one anchor panel. Secondary panels should be introduced only after the main claim is clear.

### Methods

The examples put mathematical and implementation detail in Methods and Supplementary Information, but the main Methods still begins with the scientific role of the model. The best pattern for HyExport is:

1. Explain what uncertainty or system interaction the model layer resolves.
2. Define the boundary and data sources.
3. State the minimal assumptions needed to interpret the result.
4. Send equations, parameters and secondary variants to the Supplementary Information.

This supports the current Methods direction: supply mapping, domestic absorption and European trade optimisation should be described by the question each layer answers, not by a list of variables.

## Figure Patterns To Emulate

### One Figure, One Dominant Claim

The strongest examples give each figure one scientific job:

- Guo Fig. 1: where offshore wind resource, cost and planning capacity sit geographically.
- Guo Fig. 2: how supply curves change by province and year.
- Kountouris Fig. 1: what the model boundary is.
- Beiter Fig. 1: how offshore wind deployment changes across policy/demand scenarios.
- de Kleijne Fig. 4: how production, conversion, transport and storage contribute to delivered emissions.

HyExport should keep the locked eight-figure sequence, but every figure should be edited around one sentence:

| HyExport figure | Dominant claim to preserve |
|---|---|
| Fig. 1 | Spatial LCOH and wind quality differ; Atlantic wind quality alone does not make Ireland/UK the lowest-cost producers. |
| Fig. 2 | Cost-supply curves show offshore hydrogen competitiveness but do not determine exporter ranking alone. |
| Fig. 3 | Average LCOH, marginal LCOH and blue-hydrogen-competitive capacity rank countries differently. |
| Fig. 4 | Export access reduces curtailment in the domestic power-gas operation model. |
| Fig. 5 | Domestic absorption leaves uneven exportable surplus, making the UK and Ireland high-surplus systems. |
| Fig. 6 | Integrated hydrogen/ammonia flows reallocate carbon-mitigation value across Europe. |
| Fig. 7 | LCOH-only allocation selects different leading exporters, proving why integration matters. |
| Fig. 8 | External import price defines the boundary condition for European offshore supply. |

### Visual Design Rules

Adopt these rules from the example papers:

- Keep panel letters small, bold and consistently placed.
- Use the same color for the same country or technology across figures where possible.
- Use muted colors for context and stronger colors only for the highlighted comparison.
- Use thin, light grid lines; avoid heavy boxes around every panel.
- Use direct axis labels with units; do not rely on caption text to define units.
- Keep legends close to the panels they explain or use a single shared legend when panels are aligned.
- Use panel titles to identify scenario/year, not to restate the full claim.
- Prefer vector plots for line, bar, map-boundary and schematic elements; use raster export only when vector complexity makes the PDF unstable.
- If a panel is dense, reduce the number of highlighted categories in the main figure and move the full-detail version to SI.

## Specific HyExport Figure Lessons

### Fig. 1

Current issue: the right-hand wind-speed density strips are too narrow and use colors that do not help the reader connect wind quality to the LCOH map.

Example-paper lesson: Guo Fig. 1 combines map, wind roses and a compact table, but all panels answer one geographic-cost question.

Action: keep the map, but either enlarge/reflow the wind-speed distributions below the map or convert them into a compact ranked distribution panel. Do not remove the wind-speed evidence.

### Fig. 2

Current issue: all 11 country curves compete visually.

Example-paper lesson: Guo Fig. 2 uses consistent axes and benchmark lines; Beiter uses muted scenario context with clear focus.

Action: keep all countries if needed, but highlight IE, GB, DK and NL; fade secondary countries. Keep benchmark lines fixed and ensure country colors match other figures.

### Fig. 4

Current issue: the detailed operational figure is scientifically useful but can read as a model-output dump.

Example-paper lesson: Nature-style operational figures need an anchor metric before dense dispatch detail.

Action: make curtailment reduction or export/no-export contrast the visual anchor. If full dispatch panels remain dense, move some detail to SI while keeping the original mechanism visible in the main figure.

### Fig. 5

Current issue: circular decomposition is distinctive but may require more reader effort than stacked bars or slope/rank panels.

Example-paper lesson: main figures should let the reader see the country ranking immediately.

Action: preserve the original circular design unless replacing it is explicitly approved, but improve labels and add a clearer visual emphasis on UK and Ireland by 2050.

### Fig. 6

Current issue: the chord/Sankey panels and carbon-mitigation bar panels are both important, but they compete for attention.

Example-paper lesson: de Kleijne separates supply-chain schematic and contribution bars into visually distinct groups; Kountouris separates network and capacity results.

Action: keep the original restored final figure. Improve it by using stronger group separation between trade-flow panels and carbon-mitigation panels, clearer color consistency, and a caption that states that flows and mitigation are linked but not the same metric.

### Fig. 7 and Fig. 8

Current issue: these are new diagnostic figures, not replacements for the original trade/carbon figure.

Example-paper lesson: diagnostic and robustness figures should have simple panel logic and make the boundary condition explicit.

Action: keep Fig. 7 and Fig. 8 visually simple. Their role is to defend the novelty claim and robustness boundary, not to carry the whole Results section.

## Prose Rules For The Next Revision

1. Replace report-like phrases such as `the model includes`, `decision variables include` and `the analysis links four layers` with scientific-role sentences.
2. Start each Results paragraph with the finding, then cite the figure.
3. Keep strong novelty wording, but immediately support it with the integrated feature set.
4. Avoid moving from LCOH directly to trade results without reminding the reader of domestic absorption.
5. Use `diagnostic baseline` and `outside option` consistently for Fig. 7 and Fig. 8.
6. Treat carbon mitigation as an attribution/displacement metric, not a lifecycle assessment.

## Immediate Use

The next manuscript-improvement pass should focus on the Results section and figure captions:

1. Rewrite Results topic sentences to be claim-led.
2. Tighten figure captions so each begins with the figure's dominant claim.
3. Improve Fig. 1 and Fig. 2 readability without removing the original evidence.
4. Improve Fig. 6 grouping and caption alignment while preserving the restored original trade/carbon figure.
