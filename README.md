# 🏎️ F1 Race Strategy Optimizer with Monte Carlo Analysis
### A Data-Driven Engineering Project in MATLAB

![MATLAB](https://img.shields.io/badge/MATLAB-0076A8?style=for-the-badge&logo=mathworks&logoColor=white)

This project was built to answer a critical Formula 1 question: **"What is the fastest and most robust pit stop strategy?"** It does so by creating a full data-to-decision pipeline in MATLAB, featuring machine learning models for tyre wear and a Monte Carlo engine to simulate and analyze race-day uncertainty.

---

## 📊 Final Result: The Optimal Strategy

The final output of the analysis is a probability map generated from **5,000 full-race simulations**. The heat map below shows the most frequent winning strategies when accounting for real-world chaos like Safety Cars and pit stop variance. The brightest square represents the most resilient and statistically most likely path to victory.

![Monte Carlo Result](URL_FOR_YOUR_MONTE_CARLO_HEATMAP_HERE)

---

## Key Features

* **End-to-End Data Pipeline:** Ingests and processes raw, real-world lap-by-lap and pit stop data into a clean, structured format ready for analysis.

* **Physics-Informed Modeling:** Applies a fuel-load correction to lap times, demonstrating an understanding of vehicle dynamics by isolating pure tyre degradation from the effects of a lightening car.

* **Multi-Compound Performance Prediction:** Trains separate machine learning models (polynomial regression) for each tyre compound (Soft, Hard, etc.) to accurately predict performance degradation and create distinct wear curves.

* **Advanced 2-Stop Simulation:** A sophisticated simulator built with nested loops to calculate and visualize the "strategy landscape" for complex 2-stop scenarios, identifying the deterministic optimum.

* **Probabilistic Risk Analysis (Monte Carlo Engine):** The core of the project. It runs thousands of race simulations with stochastic variables (Safety Car probability, pit stop time variance) to move beyond a single "perfect race" optimum and find the most robust, high-probability winning strategy.

---

## Visual Analysis Showcase

### Tyre Degradation Models
The models correctly identify the performance trade-off between the Soft (red) and Hard (black) tyres. The Softs are faster initially but degrade at a much steeper rate.

![Tyre Degradation Plot](URL_FOR_YOUR_MULTI_COMPOUND_PLOT_HERE)

### 2-Stop Strategy Landscape
The contour map visualizes every possible 2-stop strategy, with the color representing the total race time. The "coolest" (dark blue) areas represent the fastest race times, providing a clear map of competitive strategies.

![2-Stop Strategy Plot](https://github.com/shredfwd/Machine-Learning-for-Tire-Degradation-and-Strategy-Prediction/blob/main/figures/2%20Stop%20Stratergy.png)

---

## ⚙️ Technologies Used

* **MATLAB**
* **Statistics and Machine Learning Toolbox**

---

## 🚀 How to Run

1.  Ensure you have MATLAB and the required toolbox installed.
2.  Clone this repository or download the `.m` and `.json` files.
3.  Place all files (`main_analysis.m`, `race_data.json`, `pit_data.json`) in the same folder.
4.  Open the main script in MATLAB.
5.  Click the **"Run"** button. The script will execute the full, end-to-end analysis and generate all three plots.
