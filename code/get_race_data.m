
clear; clc; close all;


disp('--- Section 2: Loading Data ---');

json_text_laps = fileread('race_data.json');
raw_data_laps = jsondecode(json_text_laps);
disp('Lap data loaded successfully.');

json_text_pits = fileread('pit_data.json');
raw_data_pits = jsondecode(json_text_pits);
disp('Pit stop data loaded successfully.');


disp('--- Section 3: Processing & Combining Data ---');
laps_raw = raw_data_laps.MRData.RaceTable.Races.Laps;
lap_numbers = []; driver_ids = []; positions = []; lap_times_sec = [];
for i = 1:numel(laps_raw)
    lap = laps_raw(i);
    for j = 1:numel(lap.Timings)
        timing = lap.Timings(j);
        lap_numbers = [lap_numbers; str2double(lap.number)];
        driver_ids = [driver_ids; string(timing.driverId)];
        positions = [positions; str2double(timing.position)];
        parts = split(timing.time, ':');
        lap_times_sec = [lap_times_sec; str2double(parts{1})*60 + str2double(parts{2})];
    end
end
race_data = table(lap_numbers, driver_ids, positions, lap_times_sec, 'VariableNames', {'Lap', 'DriverID', 'Position', 'LapTime'});


start_compound = "soft";


race_data.Stint = zeros(height(race_data), 1);
race_data.Compound = strings(height(race_data), 1);

drivers = unique(race_data.DriverID);
for i = 1:numel(drivers)
    driver = drivers(i);
    driver_laps = race_data(race_data.DriverID == driver, :);
    

    driver_pits = [];
    for p = 1:numel(raw_data_pits.MRData.RaceTable.Races.PitStops)
        if strcmp(raw_data_pits.MRData.RaceTable.Races.PitStops(p).driverId, driver)
            driver_pits = [driver_pits; str2double(raw_data_pits.MRData.RaceTable.Races.PitStops(p).lap)];
        end
    end
    

    stint_boundaries = [0; sort(driver_pits); max(driver_laps.Lap)];
    
    for s = 1:numel(stint_boundaries)-1
        stint_num = s;
        start_lap = stint_boundaries(s) + 1;
        end_lap = stint_boundaries(s+1);
        
        lap_indices = (race_data.DriverID == driver & race_data.Lap >= start_lap & race_data.Lap <= end_lap);
        race_data.Stint(lap_indices) = stint_num;
        
        if stint_num == 1
            race_data.Compound(lap_indices) = start_compound;
        else 
            race_data.Compound(lap_indices) = "hard";
        end
    end
end
disp('Stint and compound data assigned.');

disp('--- Section 4: Cleaning Data ---');
raw_race_data = race_data;
drivers = unique(race_data.DriverID);
clean_race_data = [];
for i = 1:numel(drivers)
    driver_data = race_data(race_data.DriverID == drivers(i), :);
    median_lap_time = median(driver_data.LapTime);
    cutoff_time = median_lap_time * 1.07;
    good_laps = driver_data(driver_data.LapTime < cutoff_time, :);
    clean_race_data = [clean_race_data; good_laps];
end
disp('Data cleaned.');


disp('--- Section 5: Applying Fuel Correction ---');
start_fuel_kg = 110; fuel_burn_per_lap_kg = 1.8; time_effect_per_kg_s = 0.035;
total_laps_in_race = max(clean_race_data.Lap);
clean_race_data.CorrectedLapTime = zeros(height(clean_race_data), 1);
for i = 1:height(clean_race_data)
    lap_num = clean_race_data.Lap(i);
    fuel_remaining = start_fuel_kg - ((lap_num - 1) * fuel_burn_per_lap_kg);
    fuel_correction = fuel_remaining * time_effect_per_kg_s;
    clean_race_data.CorrectedLapTime(i) = clean_race_data.LapTime(i) + fuel_correction;
end
disp('Fuel correction applied.');


disp('--- Section 6: Training Multi-Compound Models ---');
compounds_to_model = unique(clean_race_data.Compound);
models = struct(); % Use a struct to hold our different models

for i = 1:numel(compounds_to_model)
    compound = compounds_to_model(i);
    
   
    compound_data = clean_race_data(clean_race_data.Compound == compound, :);
    
  
    tyre_age = [];
    stints = unique(compound_data(:, {'DriverID', 'Stint'}));
    for j = 1:height(stints)
        stint_data = compound_data(compound_data.DriverID == stints.DriverID(j) & ...
                                    compound_data.Stint == stints.Stint(j), :);
        tyre_age = [tyre_age; (1:height(stint_data))'];
    end
    
    Y = compound_data.CorrectedLapTime;
    X = tyre_age;
    
   
    models.(compound) = polyfit(X, Y, 2);
    fprintf('Model for %s compound trained.\n', compound);
end


disp('--- Section 7: Visualizing All Models ---');
figure;
hold on;

colors = containers.Map({'soft', 'hard'}, {'r', 'k'}); % Assign colors

for i = 1:numel(compounds_to_model)
    compound = compounds_to_model(i);
    

    compound_data = clean_race_data(clean_race_data.Compound == compound, :);
    tyre_age = [];
    stints = unique(compound_data(:, {'DriverID', 'Stint'}));
    for j = 1:height(stints)
        stint_data = compound_data(compound_data.DriverID == stints.DriverID(j) & ...
                                    compound_data.Stint == stints.Stint(j), :);
        stint_tyre_age = (1:height(stint_data))';
        plot(stint_tyre_age, stint_data.CorrectedLapTime, '.', 'Color', [colors(compound) 0.3]);
    end

    max_age = max(tyre_age);
    x_fit = (1:max_age)';
    y_fit = polyval(models.(compound), x_fit);
    plot(x_fit, y_fit, '-', 'Color', colors(compound), 'LineWidth', 3, 'DisplayName', [compound ' model']);
end

title('Tyre Degradation Models by Compound');
xlabel('Tyre Age (Laps into Stint)');
ylabel('Fuel-Corrected Lap Time (s)');
legend;
grid on;
hold off;

disp('--- Script Finished ---');


disp('--- Section 8: Running Upgraded Strategy Simulation ---');


total_race_laps = 57;
pit_stop_time_s = 22;
possible_pit_laps = 15:40;

stint1_compound = "soft";
stint2_compound = "hard";


model_stint1 = models.(stint1_compound);
model_stint2 = models.(stint2_compound);


strategy_results = [];
strategy_pit_laps = [];


for pit_lap = possible_pit_laps
    
  
    stint1_laps = pit_lap;
    stint1_tyre_ages = (1:stint1_laps)';
    stint1_predicted_times = polyval(model_stint1, stint1_tyre_ages);
    stint1_total_time = sum(stint1_predicted_times);
    
    
    stint2_laps = total_race_laps - pit_lap;
    stint2_tyre_ages = (1:stint2_laps)';
    stint2_predicted_times = polyval(model_stint2, stint2_tyre_ages);
    stint2_total_time = sum(stint2_predicted_times);
    
    total_time = stint1_total_time + pit_stop_time_s + stint2_total_time;
    

    strategy_pit_laps = [strategy_pit_laps; pit_lap];
    strategy_results = [strategy_results; total_time];
end


[fastest_time, index] = min(strategy_results);
optimal_pit_lap = strategy_pit_laps(index);


fprintf('\n--- STRATEGY SIMULATION COMPLETE ---\n');
fprintf('Strategy: %s -> %s\n', upper(stint1_compound), upper(stint2_compound));
fprintf('Optimal Pit Lap: %d\n', optimal_pit_lap);
fprintf('Fastest Possible Race Time: %.2f seconds\n', fastest_time);
fprintf('------------------------------------\n');


figure;
plot(strategy_pit_laps, strategy_results, 'm-o', 'LineWidth', 2);
title(['Strategy Comparison: ' upper(stint1_compound) ' -> ' upper(stint2_compound)]);
xlabel('Pit Stop Lap');
ylabel('Total Race Time (seconds)');
grid on;

hold on;
plot(optimal_pit_lap, fastest_time, 'g*', 'MarkerSize', 15, 'LineWidth', 2, 'DisplayName', 'Optimal Strategy');
legend('Strategy Times', 'Optimal Strategy', 'Location', 'north');
hold off;

disp('--- Project Finished ---');


disp('--- Section : Running 2-Stop Strategy Simulation ---');



strategy_compounds = ["soft", "hard", "hard"];


model_stint1 = models.(strategy_compounds(1));
model_stint2 = models.(strategy_compounds(2));
model_stint3 = models.(strategy_compounds(3));

pit_laps_1 = 15:25;
pit_laps_2 = 35:48;


results_matrix = NaN(max(pit_laps_1), max(pit_laps_2));


for p1 = pit_laps_1
    for p2 = pit_laps_2
       
        if p2 <= p1
            continue; 
        end
        
   
        stint1_laps = p1;
        stint1_tyre_ages = (1:stint1_laps)';
        stint1_total_time = sum(polyval(model_stint1, stint1_tyre_ages));
        
         stint2_laps = p2 - p1;
        stint2_tyre_ages = (1:stint2_laps)';
        stint2_total_time = sum(polyval(model_stint2, stint2_tyre_ages));
        
   
        stint3_laps = total_race_laps - p2;
        stint3_tyre_ages = (1:stint3_laps)';
        stint3_total_time = sum(polyval(model_stint3, stint3_tyre_ages));
        
    
        total_time = stint1_total_time + stint2_total_time + stint3_total_time + (2 * pit_stop_time_s);
        
       
        results_matrix(p1, p2) = total_time;
    end
end


[fastest_time, min_idx] = min(results_matrix, [], 'all', 'linear');
[opt_p1, opt_p2] = ind2sub(size(results_matrix), min_idx);



fprintf('\n--- 2-STOP STRATEGY SIMULATION COMPLETE ---\n');
fprintf('Strategy: %s -> %s -> %s\n', upper(strategy_compounds(1)), upper(strategy_compounds(2)), upper(strategy_compounds(3)));
fprintf('Optimal Pit Laps: %d and %d\n', opt_p1, opt_p2);
fprintf('Fastest Possible Race Time: %.2f seconds\n', fastest_time);
fprintf('-------------------------------------------\n');

figure;
contourf(pit_laps_2, pit_laps_1, results_matrix(pit_laps_1, pit_laps_2), 20);
colorbar;
title('2-Stop Strategy Landscape (Soft -> Hard -> Hard)');
xlabel('Second Pit Stop Lap');
ylabel('First Pit Stop Lap');
hold on;
plot(opt_p2, opt_p1, 'g*', 'MarkerSize', 15, 'LineWidth', 2, 'DisplayName', 'Optimal Strategy');
legend('', 'Optimal Strategy'); % Empty first entry to hide contour legend
hold off;

disp('--- Project Finished ---');

disp('--- Section 10: Running Monte Carlo Simulation ---');


num_simulations = 5000; 


total_race_laps = 57;
avg_pit_stop_time_s = 22;
safety_car_probability_per_lap = 0.05; % 5% chance of a safety car on any given lap
time_loss_under_sc_s = 10; 


strategy_compounds = ["soft", "hard", "hard"];
model_stint1 = models.(strategy_compounds(1));
model_stint2 = models.(strategy_compounds(2));
model_stint3 = models.(strategy_compounds(3));
pit_laps_1 = 15:25;
pit_laps_2 = 35:48;


winning_strategies = [];

fprintf('Running %d race simulations...\n', num_simulations);
for sim_num = 1:num_simulations
    
    
    current_pit_time = avg_pit_stop_time_s + 0.5 * randn(); 
    
  
    safety_car_laps = find(rand(1, total_race_laps) < safety_car_probability_per_lap);
    
 
    results_matrix = NaN(max(pit_laps_1), max(pit_laps_2));

 
    for p1 = pit_laps_1
        for p2 = pit_laps_2
            if p2 <= p1, continue; end
            
            % Stint 1
            stint1_laps = p1;
            stint1_tyre_ages = (1:stint1_laps)';
            stint1_base_time = sum(polyval(model_stint1, stint1_tyre_ages));
            % Add safety car time loss
            stint1_sc_loss = sum(ismember(1:p1, safety_car_laps)) * time_loss_under_sc_s;
            stint1_total_time = stint1_base_time + stint1_sc_loss;

            % Stint 2
            stint2_laps = p2 - p1;
            stint2_tyre_ages = (1:stint2_laps)';
            stint2_base_time = sum(polyval(model_stint2, stint2_tyre_ages));
            stint2_sc_loss = sum(ismember(p1+1:p2, safety_car_laps)) * time_loss_under_sc_s;
            stint2_total_time = stint2_base_time + stint2_sc_loss;

            % Stint 3
            stint3_laps = total_race_laps - p2;
            stint3_tyre_ages = (1:stint3_laps)';
            stint3_base_time = sum(polyval(model_stint3, stint3_tyre_ages));
            stint3_sc_loss = sum(ismember(p2+1:total_race_laps, safety_car_laps)) * time_loss_under_sc_s;
            stint3_total_time = stint3_base_time + stint3_sc_loss;
            
            total_time = stint1_total_time + stint2_total_time + stint3_total_time + (2 * current_pit_time);
            results_matrix(p1, p2) = total_time;
        end
    end

    [~, min_idx] = min(results_matrix, [], 'all', 'linear');
    [win_p1, win_p2] = ind2sub(size(results_matrix), min_idx);
    
   
    winning_strategies = [winning_strategies; win_p1, win_p2];
    

    if mod(sim_num, 500) == 0
        fprintf('...simulation %d of %d complete.\n', sim_num, num_simulations);
    end
end


fprintf('\n--- MONTE CARLO SIMULATION COMPLETE ---\n');

figure;

h = histogram2(winning_strategies(:,2), winning_strategies(:,1), ...
               pit_laps_2, pit_laps_1, 'FaceColor','flat');
h.ShowEmptyBins = 'off';
colorbar;
title('Monte Carlo Result: Most Frequent Winning Strategy');
xlabel('Second Pit Stop Lap');
ylabel('First Pit Stop Lap');
fprintf('Analysis of %d simulations complete.\n', num_simulations);

disp('--- Project Finished ---');