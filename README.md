 <img src="./AdoraFoundation_logo.jpeg" alt="LLM Energy Lab" width="20%" />
<p>

 ---
# Model for Carbon-aware Geographic Load Shifting of Compute Workloads

An analytical Haskell model for estimating how much CO₂e emissions can be reduced by shifting compute workloads between data centres in high- and low-carbon-intensity regions.

This repository implements the model presented in:

- **Wim Vanderbauwhede**, *Modelling Scenarios for Carbon-aware Geographic Load Shifting of Compute Workloads*.
  - Local copy: [`documentation/Modelling Scenarios for Carbon-aware Geographic Load Shifting of Compute Workloads.pdf`](documentation/Modelling%20Scenarios%20for%20Carbon-aware%20Geographic%20Load%20Shifting%20of%20Compute%20Workloads.pdf)
  - Online: <https://arxiv.org/abs/2509.07043>

The original code for this model is maintained at:

- <https://codeberg.org/wimvanderbauwhede/carbon-aware-geographic-load-shifting-model>

This repository provides a ready-to-run Docker environment and a quick-start for reproducing the paper's tables and scenario results.

---

## 1. Paper highlights

### 1.1 Why geographic load shifting?

- **ICT emissions** are estimated at around 4% of global greenhouse gas emissions and are rising rapidly, with AI data centres as a key driver.
- McKinsey projects strong growth in AI data centre capacity, which could increase data centre energy use by an order of magnitude.
- In this context, reductions of only a few percent per year are quickly overwhelmed by growth; to "buy time" we would need **reductions of tens of percent**.

Geographic (or carbon-aware) load shifting aims to reduce emissions by moving work from **high-carbon-intensity (high-CI)** regions to **low-CI** regions, while accounting for data centre utilisation and overheads.

### 1.2 Research question

> *Even if we ignore grid constraints and assume spare capacity exists, what level of emissions reduction is realistically achievable through geographic load shifting?*

The paper addresses this by:

- Building a **simple but expressive analytical model** of two "twin" data centres (high- and low-CI).
- Using **up-to-date Life Cycle Assessment (LCA)** data to quantify both:
  - **Embodied emissions** (manufacturing + infrastructure), and
  - **Operational emissions** (electricity use × carbon intensity of the grid).
- Evaluating **realistic scenarios** for both:
  - Large **commercial AI data centres**, and
  - **HPC centres** (supercomputers) in different countries.

### 1.3 Core model (what the Haskell code implements)

The main Haskell type is `LocationShiftingModelData`, corresponding to the analytical model in the paper, with parameters such as:

- **`n_n`** – number of nodes in the data centre.
- **`n_hi`, `n_lo`** – number of high- and low-emission sites.
- **`c_em`** – embodied emissions per node (including infrastructure), in kgCO₂e/year.
- **`c_hi`, `c_lo`** – operational emissions per node at high- and low-CI sites.
- **`lambda_hi`, `lambda_lo`** – average load at each site.
- **`gamma`** – idle power factor.
- **`alpha`** – fraction of workload that can be moved.
- **`beta`** – fraction of time that workload is movable.
- **`eta`** – overhead factor (extra emissions from networking, copying data, etc.).

From these parameters, the code computes:

- `emissionsBaseline` – yearly emissions without geographic load shifting.
- `emissionsWithLocationShifting` – yearly emissions with shifting.
- `emissionsEmbodied` and `emissionsOverhead` – to break down the sources of emissions.

The **relative reduction** is the difference between baseline and shifted emissions divided by the baseline. The paper also analyses an "ideal" case (no embodied carbon, no idle power, zero overhead, full flexibility) to derive an **upper bound** on achievable reductions.

Key insight from this ideal case:

- With realistic carbon intensities (e.g. moving all load from the US to the UK), **even perfect shifting cannot reduce emissions by more than about 27%**.

### 1.4 Scenario results (very briefly)

- **Commercial AI data centres**: scenarios combining solar or wind-dominated regions with high-CI regions show that realistic assumptions (load, limited flexibility, overheads) bring reductions down to **single-digit percentages**.
- **HPC centres** (e.g. ASGC in Taiwan to HPC2N in Sweden, or BNL in the US to EPCC in the UK):
  - Highly optimistic scenario (lots of spare capacity, no overheads): about **30%** reduction.
  - More realistic scenarios (partial flexibility, overhead, moderate CI differences): **3–14%** reduction.

### 1.5 Conclusion

For realistic commercial AI and HPC data centre scenarios, **emission reductions from geographic load shifting alone are typically below 5%**. Given the projected growth in AI data centre capacity, geographic load shifting is **not sufficient on its own** to counteract the increase in emissions; it has to be combined with other measures (efficiency, demand reduction, low-carbon generation, etc.).

---

## 2. Repository structure

- **`src/LocationShiftingModel.hs`** – core analytical model and emission calculation functions.
- **`src/LocationShiftingModelCommon.hs`** – predefined **design-of-experiment (DOE)** scenarios:
  - `doeCommercial` – commercial AI data centre scenarios (solar / wind, different loads and CIs).
  - `doeHPC` – HPC centre scenarios (e.g. ASGC → HPC2N, BNL → EPCC).
- **`src/runLocationShiftingModel.hs`** – default executable:
  - Computes emission reductions as a function of load for representative commercial AI data centre scenarios.
  - Prints CSV to standard output (load and reduction metrics).
- **`src/runLocationShiftingModel-effect-load.hs`** – explores effect of load across multiple scenarios (commercial + HPC), outputs CSV.
- **`src/runLocationShiftingModel-effect-load-opt.hs`** – variant focused on optimised HPC scenarios.
- **`src/runLocationShiftingModel-tables.hs`** – generates LaTeX tables for the paper.
- **`src/runLocationShiftingModel-*.gnuplot`** – gnuplot scripts to turn CSV data into figures.
- **`src/job.hs`** – convenience file listing commands used to generate tables and plots.
- **`documentation/Modelling Scenarios for Carbon-aware Geographic Load Shifting of Compute Workloads.pdf`** – the paper (local copy).
- **`Dockerfile`** – containerised environment with GHC and gnuplot.

---

## 3. Quick start

### 3.1 Option A – Run with Docker (recommended)

**Prerequisites**

- Docker installed and running.

**Build the image** (from the repository root):

```bash
docker build -t carbon-aware-location-shifting .
```

**Run the main model** and capture the CSV output:

```bash
docker run --rm carbon-aware-location-shifting > results.csv
```

This will:

- Run `runhaskell runLocationShiftingModel.hs` inside the container.
- Write CSV data with emission reductions vs load for the commercial AI data centre scenarios.

**Interactive use inside Docker**

If you want to regenerate tables or run alternative entry points:

```bash
docker run -it --rm -v "$(pwd)":/app carbon-aware-location-shifting bash
```

Inside the container:

```bash
cd /app/src
runhaskell runLocationShiftingModel-tables.hs > tables.tex
runhaskell runLocationShiftingModel-effect-load.hs > runLocationShiftingModel-effect-load.csv
gnuplot runLocationShiftingModel-effect-load.gnuplot
gnuplot runLocationShiftingModel-effect-load-HPC.gnuplot
```

The `-v "$(pwd)":/app` bind-mount ensures that generated files (e.g. `tables.tex`, `*.csv`, `*.pdf`) appear in your local checkout.

### 3.2 Option B – Run locally with GHC

**Prerequisites**

- A working Haskell toolchain providing `ghc` and `runhaskell`.
  - For example via [GHCup](https://www.haskell.org/ghcup/) or [The Haskell Tool Stack](https://docs.haskellstack.org/en/stable/).
- Optional: `gnuplot` to render plots.

From the repository root:

```bash
cd src
runhaskell runLocationShiftingModel.hs > results.csv
```

This mirrors the default Docker behaviour and produces CSV output with emission reductions vs load.

---

## 4. Reproducing the paper's tables and figures

All commands below can be run either:

- **Locally** (after `cd src`), or
- **Inside the Docker container** (see the Docker instructions above and ensure you're in `/app/src`).

### 4.1 Generate LaTeX tables

```bash
runhaskell runLocationShiftingModel-tables.hs > tables.tex
```

This writes LaTeX tables summarising the commercial AI data centre scenarios and the HPC scenarios described in the paper.

### 4.2 Explore the effect of load

```bash
runhaskell runLocationShiftingModel-effect-load.hs > runLocationShiftingModel-effect-load.csv
runhaskell runLocationShiftingModel-effect-load-opt.hs > runLocationShiftingModel-effect-load-opt.csv
```

These CSV files contain emission reductions as a function of load for multiple scenario families, including:

- Commercial AI data centres (solar/wind variants).
- HPC centres under different assumptions about flexibility and overhead.

### 4.3 Plot the results (gnuplot)

With `gnuplot` installed:

```bash
gnuplot runLocationShiftingModel-effect-load.gnuplot
gnuplot runLocationShiftingModel-effect-load-HPC.gnuplot
```

These scripts read the CSV outputs and produce the figures used in the paper (e.g. emission reduction vs load for AI data centre and HPC scenarios).

---

## 5. Embodied carbon model

Embodied emissions for the servers and infrastructure used in these scenarios are calculated using a separate LCA model:

- <https://codeberg.org/wimvanderbauwhede/datacentre-LCA-model>

That model provides the embodied carbon estimates used as inputs (`c_em`) in `LocationShiftingModelCommon.hs`.

---

## 6. Attribution and licensing

- **Author of the model and paper**: Wim Vanderbauwhede, University of Glasgow, UK.
- **Original Haskell implementation**: <https://codeberg.org/wimvanderbauwhede/carbon-aware-geographic-load-shifting-model>
- **This repository** packages the model with Docker and provides an extended, user-friendly README.

For licensing terms, see `LICENSE.txt` in this repository.
