\# Renewable Energy Learning Curves and Cost Forecasting



An R-based analysis of renewable energy technology learning rates, historical cost trends, and the limits of long-term cost forecasting using IRENA data.



\## Research question



How much do clean energy build costs fall as global installed capacity grows, and can that relationship be used to forecast costs to 2040?



\## Project overview



This project estimates historical experience curves for six renewable energy and storage technologies and explores how those relationships behave when projected forward to 2040.



The analysis has three stages:



1\. Estimate historical technology learning rates.

2\. Forecast costs to 2040 under alternative deployment scenarios.

3\. Compare the forecasts with IRENA's published outlook and examine the limits of long-term extrapolation.



\## Technologies analysed



\- Solar PV

\- Onshore wind

\- Offshore wind

\- Battery storage

\- Bioenergy

\- Hydropower



\## Data



The analysis uses:



\- IRENA global weighted-average total installed cost data.

\- IRENA installed capacity data processed by Our World in Data.

\- IRENA battery deployment data.

\- IRENA published forward cost projections for comparison.



Raw source files are not redistributed in this repository.



See \[`data/README.md`](data/README.md) for the original data sources and instructions for obtaining the datasets.



\## Method



For solar PV, onshore wind, offshore wind, hydropower and bioenergy, total installed cost is related to global installed capacity stock using a log-log regression.



The estimated regression slope is converted into an implied learning rate: the percentage reduction in total installed cost associated with a doubling of installed capacity stock.



Battery storage is treated differently because its available volume series represents cumulative deployment derived from gross annual additions rather than the installed capacity stock measure used for the other technologies.



The estimated relationships are then projected to 2040 under slow, central and fast deployment scenarios derived from historical growth rates.



\## Key results



| Technology | Learning rate | R² |

|---|---:|---:|

| Solar PV | 32.3% | 0.990 |

| Onshore wind | 27.1% | 0.857 |

| Battery storage | 23.5% | 0.899 |

| Offshore wind | 15.6% | 0.828 |

| Bioenergy | 2.4% | 0.003 |

| Hydropower | -214.6% | 0.689 |



Solar PV shows the strongest historical cost relationship, while onshore wind and battery storage also show substantial implied learning.



Bioenergy shows almost no relationship between deployment and cost. Hydropower moves in the opposite direction, demonstrating why the same experience-curve interpretation should not automatically be applied across all renewable technologies.



The forecasting exercise also shows that unconstrained learning-curve extrapolation becomes increasingly aggressive over longer horizons. By 2035, the central model forecast is approximately 25% below IRENA's published outlook for onshore wind and 50% below it for solar PV.



The results suggest that experience curves are useful for describing historical technological progress and constructing transparent scenarios, but should not be treated as stand-alone long-term forecasting models.



\## Selected figures



\### Historical learning curves



!\[Historical learning curves](figures/01\_learning\_curves.png)



\### Estimated learning rates



!\[Estimated learning rates](figures/02\_learning\_rates.png)



\### Forecast to 2040



!\[Forecast to 2040](figures/05\_forecast.png)



\### Learning-curve model vs IRENA outlook



!\[Learning curve model vs IRENA outlook](figures/06\_vs\_irena.png)



\## Repository structure



```text

Energy Project Analysis/

│

├── README.md

├── analysis.R

│

├── data/

│   └── README.md

│

├── figures/

│   ├── 01\_learning\_curves.png

│   ├── 02\_learning\_rates.png

│   ├── 03\_residuals.png

│   ├── 04\_contrast.png

│   ├── 05\_forecast.png

│   ├── 06\_vs\_irena.png

│   └── 07\_forecast\_table.png

│

└── output/

&#x20;   ├── learning\_rates.csv

&#x20;   ├── observed\_growth.csv

&#x20;   ├── comparison\_vs\_irena.csv

&#x20;   ├── floor\_breach.csv

&#x20;   ├── forecast\_table.csv

&#x20;   └── session\_info.txt

