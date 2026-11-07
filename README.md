# Nanoparticle drug circulation

I built a simulator of drug levels in the blood because I wanted to learn how to turn measurements into a model of how long a drug stays in circulation. The example follows a cancer drug carried inside tiny fat-based shells, which change how the drug travels through the body. These shells are called liposomes, a type of nanoparticle, or very small particle. I wanted to understand what a few published measurements could tell me about the drug still inside those carriers over time.

I represent circulation as connected, well-mixed pools, fit their settings to a published graph, and plot where the model agrees or disagrees with the measurements. I can run the example below or change the dose and pool settings for my own exploration. This is my learning project, not a way to choose anyone's treatment. The maintained code and merged changes are in [this repository](https://github.com/jackaI1/nanoparticle-pk-octave).

## Try the example

Install GNU Octave and a plotting backend. On Ubuntu:

```sh
sudo apt-get update
sudo apt-get install octave gnuplot-nox ghostscript fonts-freefont-otf
octave --no-gui --quiet scripts/run_tests.m
octave --no-gui --quiet scripts/check_worked_example.m
octave --no-gui --quiet scripts/regenerate_all.m
octave --no-gui --quiet scripts/check_results.m
```

Run these commands from this project folder. On macOS I use `brew install octave gnuplot`. The regeneration writes graphs to `figures/` and tables to `results/` without downloading data.

## A worked fit

I fitted clearance (the rate at which drug leaves the central pool) and central volume (the apparent size of that pool) to six rounded group means read from a published liposomal doxorubicin graph. For the one-pool model, the fitted clearance is about 0.0120 L/h/m² and the central volume is about 1.55 L/m². At 25.5 hours the observed concentration is 26.2 µg/mL and the prediction is 26.57 µg/mL, an error of +0.37 µg/mL. The [full table](results/fit_residuals.csv) lists every observation, prediction and error for each model.

![Fitted concentration curves and residuals](figures/fits.png)

The plot compares the fits and shows residuals, the differences between predictions and observations. These are in-sample comparisons, not independent predictions. The data are approximate group means, not individual patient measurements; only six rounded points were read, and the exchange parameters in the multi-pool models are assumed. These limits mean the fits cannot describe individual patients or establish clinical dosing. The [data notes](data/README.md) identify the paper and explain the digitization.

## Use different inputs

```matlab
addpath('src');
p = pk_parameters(2);       % two pools
p.dose = 50;               % mg
p.infusion = 1.5;          % hours; zero gives an immediate dose
p.V = [2, 1];              % litres
p.CL = 0.02;               % L/h
p.Q = 0.01;                % L/h between pools
s = pk_simulate(p, [0 1 2 24 48 96]);
plot(s.time, s.concentration);
xlabel('Time (h)'); ylabel('Concentration (mg/L)');
% Synthetic example observations:
f = pk_fit([2 24 48 96], [24 18 14 8], p, {'CL', 'V1'});
rows = pk_fit_residuals([2 24 48 96], [24 18 14 8], f)
```

`pk_parameters(1)`, `(2)` and `(3)` select one, two or three compartments. Units are mg, L and hours; mg/L and µg/mL have the same numerical value. The published example uses a dose per square metre of body surface area, so its fitted volumes and clearances use that same scaling. See [methods](docs/methods.md) for assumptions and equations.

## Implementation and checks

The MATLAB-language functions in `src/` use `ode45` to integrate the compartment equations and `fminsearch` to fit parameters. The regeneration script also calculates sensitivity, mass balance and simulated variability. The 33 Octave tests cover analytical solutions, mass balance, parameter recovery, diagnostics and rejection of altered exports; CI runs the suite and worked checks, regenerates the outputs and checks the exported tables and figures.

`scripts/check_worked_example.m` prints two numerical checks so I can see what passed:

| Check | Inputs | Expected | Obtained (rounded) | Pass tolerance |
| --- | --- | --- | --- | --- |
| Known one-pool decay at 4 h | Immediate 10 mg dose, 2 L pool, 0.4 L/h clearance | 2.24664482 mg/L from `5*exp(-0.2*4)` | 2.24664482 mg/L | Absolute difference ≤ 0.000002 mg/L |
| Refit published first measurement at 25.5 h | 50 mg/m² over 1.5 h; fit all six group means | Stored reference 26.5695 µg/mL | 26.5695 µg/mL versus observed 26.2 µg/mL; error +0.3695 µg/mL | Within 0.005 µg/mL of reference |

The first check compares the numerical solver with an exact equation. The second catches changes to the worked fit; its tolerance is for software repeatability, not measurement accuracy. The root-mean-square error, a typical concentration difference across all six points, is 0.24535 µg/mL (checked within 0.005 µg/mL of that reference). The export checks also recompute each model from its saved parameters and compare all 18 prediction rows within 0.000001 µg/mL.
