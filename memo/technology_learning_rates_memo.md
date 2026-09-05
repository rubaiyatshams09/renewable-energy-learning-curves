# Technology learning rates and the limits of cost extrapolation

**Rubaiyat Shams | September 2026**

---

## Question

How much do clean energy build costs fall as global installed capacity grows, and
can that relationship be used to forecast costs to 2040?

## Method

I estimated experience curves for six technologies using IRENA's global
weighted-average total installed costs for 2010 to 2025, paired with IRENA's global
installed capacity stock over the same period. Installed capacity stock refers to
the generating capacity installed and connected at the end of each calendar year. It
should not be interpreted as cumulative historical deployment or cumulative
production.

Cost is regressed on installed capacity stock in logs. The estimated slope is then
converted into an implied learning rate, representing the percentage reduction in
total installed cost associated with a doubling of installed capacity stock.
Confidence intervals use the t distribution, which is appropriate for samples of
this size.

I then projected costs forward under three deployment scenarios per technology.
Growth rates are calculated from observed changes in installed capacity stock rather
than assumed independently, using compound annual growth over four historical
windows. The central case follows the 2015 to 2025 trend, the fast case uses the
strongest observed growth rate, and the slow case takes the weakest observed rate
and reduces it further.

All analysis is conducted in R and is reproducible from the project repository.

---

## Finding 1: learning rates are strong but vary widely by technology

| Technology | n | Learning rate | 95% interval | R² |
|---|---:|---:|---:|---:|
| Solar PV | 16 | 32.3% | 30.7 to 33.8 | 0.990 |
| Onshore wind | 16 | 27.1% | 21.5 to 32.3 | 0.857 |
| Battery storage | 11 | 23.5% | 18.2 to 28.6 | 0.899 |
| Offshore wind | 16 | 15.6% | 11.8 to 19.3 | 0.828 |
| Bioenergy | 16 | 2.4% | −27.7 to 25.4 | 0.003 |
| Hydropower | 16 | −214.6% | −389.2 to −102.3 | 0.689 |

Solar PV shows an exceptionally strong relationship between installed capacity stock
and total installed cost, with a narrow confidence interval. Onshore wind and battery
storage also show strong relationships, although onshore wind's interval spans more
than ten percentage points. Offshore wind has the weakest fit among the modular
technologies.

The results for bioenergy and hydropower are fundamentally different. Bioenergy shows
almost no relationship between installed capacity and cost, and its interval spans
zero. Hydropower shows a substantial relationship in the opposite direction, with
costs increasing as installed capacity stock grew. Its negative implied learning rate
should not be interpreted as conventional technological learning.

## Finding 2: learning curves fit modular technologies better than construction-led technologies

The experience curve specification performs considerably better for solar PV, wind
and battery storage than for hydropower and bioenergy in this dataset.

This pattern is consistent with structural differences between technologies. Solar
panels, turbines and battery cells contain modular components that can benefit from
manufacturing scale, standardisation, process improvement and supply chain learning.
Hydropower projects are far more dependent on site-specific civil engineering,
geography and project complexity. As suitable sites are developed, additional
capacity does not necessarily represent repetition of an increasingly standardised
production process.

The regression alone cannot establish why these differences occur. However, the
contrasting results show why the same learning curve interpretation should not
automatically be applied across all renewable technologies. Reporting the hydropower
and bioenergy results is therefore more informative than excluding them because they
do not fit the expected pattern.

## Finding 3: unconstrained extrapolation becomes implausible within a decade

The estimated learning relationships can be used mechanically to project future costs
by combining expected growth in installed capacity stock with the estimated learning
rates. The resulting forecasts become increasingly aggressive as the horizon expands.

**Projected total installed cost, USD/kW**

![Projected total installed cost](figures/07_forecast_table.png)

Compared with IRENA's own published outlook, the central case diverges substantially.

| | 2030 | 2035 |
|---|---:|---:|
| Onshore wind vs IRENA | −12.4% | −25.0% |
| Solar PV vs IRENA | −16.0% | −50.2% |

The gap increases with the forecast horizon, particularly for solar PV.

The model also eventually generates cost levels below the indicative floors used in
this analysis. Using assumptions of 700 USD/kW for onshore wind, 1 800 USD/kW for
offshore wind and 275 USD/kW for solar PV, the central case falls below these levels
in 2032 for onshore wind and solar PV, and in 2035 for offshore wind.

These floors are analytical assumptions rather than IRENA estimates. They are
included as a diagnostic to demonstrate what happens when a constant learning
relationship is extrapolated without a lower bound. The result should be interpreted
as evidence of the limitations of unconstrained extrapolation, not as a prediction of
when a technology will reach a physical minimum cost.

Two additional observations reinforce this interpretation. IRENA publishes both
modelled and refined projections. For onshore wind, its refined 2035 estimate is
792 USD/kW compared with a modelled value of 732 USD/kW, indicating that the
published outlook does not simply extend the underlying model indefinitely. In
addition, the modelled 2025 value of 1 022 USD/kW compares with an observed value of
973 USD/kW, showing that deviations occur even over short horizons.

---

## What the model cannot capture

The experience curve deliberately reduces a complex cost process to a relationship
between total installed cost and installed capacity stock. That simplicity is useful
for identifying historical patterns, but it leaves important cost drivers outside the
model.

Commodity prices, supply chain constraints, project location, permitting, labour
costs and changes in technology design can all affect renewable project costs
independently of installed capacity.

This distinction matters when interpreting total installed cost rather than levelised
cost of electricity. The dependent variable here is IRENA's total installed cost,
measured in USD/kW, which is a capital cost. Financing conditions should therefore
not be interpreted as a direct component of the regression in the way they enter an
LCOE calculation, although they influence investment decisions and so affect which
projects are built.

The 2010 to 2025 estimation period also contains a phase of exceptionally rapid
expansion in renewable manufacturing and deployment. There is no guarantee that the
historical relationship between installed capacity stock and costs will hold as these
technologies mature.

## Limitations

- **Installed capacity stock is used as the experience variable.** The analysis uses
  IRENA's published installed capacity stock, not cumulative production or cumulative
  deployment. Estimated learning rates should be interpreted specifically as the cost
  relationship associated with doubling installed capacity stock. Because retired and
  repowered capacity leaves the stock, installed capacity understates cumulative
  deployment by a margin that grows over time, which compresses the measured number of
  doublings and biases estimated learning rates upward. The direction of this bias is
  known; its magnitude is not estimated here, as no public retirement series exists and
  any adjustment would require an assumed asset life. That the series is a net stock is
  confirmed in the source data, where seven technologies including marine energy and
  concentrated solar power record year on year declines. Gross annual installation
  data, for example from GWEC, would resolve this.

- **Battery storage uses a different volume measure.** Its series is the cumulative
  sum of gross annual additions, which is cumulative deployment, whereas the other five
  technologies use net installed capacity stock. Its estimation window is also shorter,
  beginning in 2015, and capacity installed before then is treated as zero. The battery
  learning rate is therefore not strictly comparable with the others.

- **The log-log model assumes a constant relationship.** A single coefficient
  estimated from 2010 to 2025 is carried forward, although learning may slow as
  technologies mature.

- **The deployment scenarios assume continued exponential growth.** Historical annual
  growth rates are extended forward for fifteen years. A logistic or otherwise
  decelerating path may better represent market saturation.

- **Offshore wind has no external IRENA benchmark.** IRENA publishes forward cost
  projections for solar PV and onshore wind only. The offshore projection therefore
  cannot be validated in the same way, and it also has the weakest statistical fit and
  the most volatile deployment history, ranging from 10.6% to 25.4% annual growth
  across the windows examined.

- **The indicative cost floors are assumptions.** The 700, 1 800 and 275 USD/kW
  thresholds test the behaviour of the extrapolation and are not sourced from IRENA.
  They should not be read as estimated engineering or materials minimums.

- **The model is univariate.** It does not separately identify the effects of
  manufacturing learning, economies of scale, commodity prices, supply chain conditions
  or project characteristics that may move simultaneously with installed capacity.

## Conclusion

The analysis finds strong historical relationships between installed capacity stock
and total installed cost for solar PV, onshore wind, offshore wind and battery
storage, with the strength differing considerably across technologies. Bioenergy and
hydropower demonstrate that the same framework cannot be interpreted uniformly across
the energy system.

The forecasting exercise shows that a historical learning relationship can give
reasonable directional information while producing increasingly implausible cost
levels over long horizons. Experience curves are therefore useful for describing
technological progress, comparing technologies and building transparent scenarios,
but should not be treated as stand-alone long-term forecasting models.

A more defensible medium-term forecast would combine the estimated learning
relationship with an explicit lower cost constraint, a deployment path that slows as
markets mature, and additional variables representing cost drivers absent from the
simple experience curve.

## Next steps

Replace constant exponential growth in installed capacity with a logistic deployment
path that allows growth to decelerate as markets mature. Extend the model to
incorporate additional cost drivers rather than treating installed capacity as the
sole explanatory variable. Repeat the analysis at country or regional level to test
whether the global relationship holds across markets with different supply chains,
project characteristics and financing environments.

---

**Data.** IRENA (2026), *Renewable Power Generation Costs in 2025*, Abu Dhabi;
total installed costs from Figures 2.3 (onshore wind), 3.1 (solar PV), 4.3 (offshore
wind), 6.2 (hydropower), 8.2 (bioenergy) and 9.2 (battery storage), battery
deployment volumes from Figure 9.1, and published cost projections from Figures 1.6
and 1.7. IRENA (2026), *Renewable Energy Statistics 2026*, installed capacity series
processed by Our World in Data. Analysis in R.

**AI assistance.** R code development was assisted by Anthropic's Claude. The code
was reviewed, checked and executed by the author. Analytical decisions,
interpretation and conclusions are the responsibility of the author.
