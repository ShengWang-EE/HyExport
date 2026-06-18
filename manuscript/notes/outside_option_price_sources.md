# Outside-Option Price Sources

Date: 2026-06-17

Purpose: document the evidence base for the outside-option import-price scan used in the NC robustness analysis.

## Current Modelling Choice

The current scan uses an external low-carbon hydrogen/ammonia outside-option price grid of:

| Model price | Approximate hydrogen-equivalent price |
|---:|---:|
| 60 EUR/MWh | 2 EUR/kg-H2 |
| 90 EUR/MWh | 3 EUR/kg-H2 |
| 120 EUR/MWh | 4 EUR/kg-H2 |
| 150 EUR/MWh | 5 EUR/kg-H2 |
| 180 EUR/MWh | 6 EUR/kg-H2 |

Conversion used in code:

`1 kg H2 = 33.333 kWh_LHV = 0.033333 MWh_LHV`.

This should be described as a threshold scan, not as a probability-weighted forecast.

## Source Evidence

| Source | BibTeX key | Relevant evidence | Use in this paper |
|---|---|---|---|
| European Commission hydrogen page | `EuropeanCommissionHydrogen2026` | REPowerEU aims for 10 Mt domestic renewable hydrogen production and 10 Mt imports by 2030; renewable hydrogen is expected to cover around 10% of EU energy needs by 2050. URL: https://energy.ec.europa.eu/topics/eus-energy-system/hydrogen_en | Justifies treating non-European import availability as a first-order outside option, not a minor sensitivity. |
| IEA Global Hydrogen Review 2025 | `IEAGlobalHydrogenReview2025` | IEA describes the report as tracking hydrogen production, demand, trade, investment and policy. It also states that cost, infrastructure readiness and regulation remain barriers. URL: https://www.iea.org/reports/global-hydrogen-review-2025 | Supports the framing that future low-emission hydrogen trade is uncertain enough to need a price-threshold robustness check. |
| IEA Global Hydrogen Review 2025, trade and infrastructure | `IEAGlobalHydrogenReviewTrade2025` | Nearly 45% of low-emissions hydrogen from announced production projects is intended for export by 2030 if all materialise, but only 5% of export-oriented projects have reached investment stage. URL: https://www.iea.org/reports/global-hydrogen-review-2025/trade-and-infrastructure | Supports a broad external-import uncertainty range rather than a single deterministic import price. |
| IRENA Global Hydrogen Trade Outlook, Part I | `IRENAGlobalHydrogenTradeOutlook2022` | Delivered hydrogen is discussed at approximately USD 1.5-2/kg in 2050 under favourable assumptions; ammonia shipping costs are projected to decline strongly by 2050. URL: https://www.irena.org/Publications/2022/Jul/Global-Hydrogen-Trade-Outlook | Provides the low outside-option anchor. In our current results, this low-price range displaces most European offshore supply, so the manuscript must not overclaim unconditional robustness. |
| IRENA Green Hydrogen Cost and Potential, Part III | `IRENAGreenHydrogenCostPotential2022` | In the most optimistic scenario, green hydrogen production costs could reach USD 0.65/kg-H2 in the best locations by 2050; less optimistic assumptions reach around USD 1.15/kg-H2. URL: https://www.irena.org/publications/2022/May/Global-hydrogen-trade-Cost | Reinforces that very low production costs outside Europe are plausible in optimistic 2050 cases, before transport and delivery costs. |
| IRENA Global Hydrogen Trade Outlook, Part I | `IRENAGlobalHydrogenTradeOutlook2022` | The 2021 green hydrogen cost range is given as USD 3-6/kg-H2; even pessimistic 2050 assumptions can still produce USD 1.1-1.2/kg-H2 in the best locations, but the amount available below USD 1.5/kg-H2 is limited. | Provides a rationale for retaining 3-6 EUR/kg-H2 as a stress/transition range rather than cutting the grid to only 1.5-2. |
| European Commission Innovation Fund hydrogen auction | `EuropeanCommissionIF23HydrogenAuction2024` | IF23 winning fixed-premium bids were EUR 0.37-0.48/kg-H2; all submitted bids ranged from EUR 0.37 to the EUR 4.5/kg-H2 ceiling. URL: https://climate.ec.europa.eu/eu-action/eu-funding-climate-action/innovation-fund/calls-proposals/if23-auction-renewable-hydrogen-production_en | This is a subsidy-premium signal, not a delivered hydrogen price. Use only as evidence of market formation and cost-gap uncertainty, not as an outside-option price input. |

## Interpretation For The Manuscript

The current model result should be framed as:

> European offshore hydrogen exports become strategically important when the external low-carbon import option is not available at ultra-low delivered prices. In the current threshold scan, external prices near 2-3 EUR/kg-H2 displace much of the European offshore supply, whereas prices near and above 4 EUR/kg-H2 restore the integrated trade pattern in which Ireland and the UK become major net exporters by 2050.

This is stronger and more defensible than claiming that the Ireland/UK export conclusion is robust under all import-price assumptions.

## Consequences For Figure Design

- The outside-option panel should show a threshold, not a generic sensitivity band.
- The x-axis should be labelled as a delivered hydrogen-equivalent outside-option price.
- The caption must state that the low end is informed by optimistic global trade/cost assumptions, while the high end represents a broader stress range covering less favourable delivery, infrastructure, finance or policy conditions.
- If this panel goes in the main text, the Results paragraph must explicitly say that the Ireland/UK export conclusion is conditional on external import prices.

## Current Recommendation

Keep the 2-6 EUR/kg-H2 grid for now because it spans the useful threshold. Do not narrow it until the figure is redesigned. The most important result is not the exact price point, but the break point around which European offshore supply re-enters the solution.
