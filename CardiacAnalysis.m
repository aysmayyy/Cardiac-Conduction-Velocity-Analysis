%% 1. PARAMETERS & CONFIGURATION
% Move "Magic Numbers" here for easy adjustment
FILE_NAME = '21P70 Post Sinus.mat';
VOLT_SCAR_THRESHOLD = 0.5;
VOLT_HEALTHY_THRESHOLD = 1.5;
NUM_REGIONS = 10;
DENSITY_SAMPLING = 3;
COV_STDEV_MULTIPLIER = 1.5;

%% 2. INITIALIZATION & DATA LOADING
load(FILE_NAME);

%% 3. POSITION DATA PROCESSING (UNIT: MM)
position_arr = [data.surfaceElectrodes(:).surfaceLocation_mm]; 
x_points = position_arr(1,:);
y_points = position_arr(2,:);
z_points = position_arr(3,:);

% Vectorized distance calculation (Replaces the loop for efficiency)
dist_vec = vecnorm(position_arr); 
num_points = length(data.surfaceElectrodes);

%% 4. TIME & VOLTAGE EXTRACTION
time_vec = zeros(1, num_points); 
volt_vec = zeros(1, num_points); 

time_struct = [data.surfaceElectrodes(:).activation]; 
time_cell = struct2cell(time_struct); 

volt_struct = [data.surfaceElectrodes(:).voltage]; 
volt_cell = struct2cell(volt_struct); 

for i = 1:num_points
    % Time extraction (Bipolar)
    t_point = time_cell(:,:,i); 
    time_vec(i) = cell2mat(t_point(1)); 
    
    % Voltage extraction (Bipolar)
    v_point = volt_cell(:,:,i); 
    volt_vec(i) = cell2mat(v_point(1)); 
end

% Data Cleaning
volt_vec_new = filloutliers(volt_vec, 'nearest', 'mean'); 

%% 5. VOLTAGE CLASSIFICATION
rgb_volt = zeros(num_points, 3); 
arrythmia_volt = zeros(1, num_points); 

for i = 1:num_points
   if volt_vec_new(i) < VOLT_SCAR_THRESHOLD 
       rgb_volt(i,:) = [1 0 0]; % Red
       arrythmia_volt(i) = 1; 
   elseif volt_vec_new(i) < VOLT_HEALTHY_THRESHOLD 
       rgb_volt(i,:) = [1 1 0]; % Yellow
       arrythmia_volt(i) = 1; 
   else 
       rgb_volt(i,:) = [0 1 0]; % Green
   end
end

figure(2)
scatter3(x_points, y_points, z_points, 2, rgb_volt)
xlabel('x'); ylabel('y'); zlabel('z');
title('Voltage Classification Map');

%% 6. REGIONAL ANALYSIS (POINT DENSITY)
max_dist = max(dist_vec); 
min_dist = min(dist_vec);
dist_samp_int = (max_dist - min_dist) / NUM_REGIONS; 

point_concentration = zeros(1, NUM_REGIONS); 
which_region = zeros(1, num_points); 

for r = 1:NUM_REGIONS
    lower_bound = min_dist + (r-1) * dist_samp_int;
    upper_bound = min_dist + r * dist_samp_int;
    
    % Use logical indexing to find points in this distance slice
    mask = (dist_vec >= lower_bound) & (dist_vec < upper_bound);
    which_region(mask) = r;
    point_concentration(r) = sum(mask);
end

%% 7. VELOCITY CALCULATION (ROI)
density_descend = sort(point_concentration, 'descend');
volt_interest = zeros(NUM_REGIONS, num_points);

for ind_region = 1:NUM_REGIONS
    slice_idx = find(point_concentration == density_descend(ind_region), 1);
    mask = (which_region == slice_idx);
    volt_interest(ind_region, mask) = volt_vec(mask);
end

ave_volt = zeros(1, NUM_REGIONS);
for ind_region = 1:NUM_REGIONS
    if density_descend(ind_region) > 0
        ave_volt(ind_region) = sum(volt_interest(ind_region,:)) / density_descend(ind_region);
    end
end

[~, select_region_rank] = min(ave_volt(1:min(DENSITY_SAMPLING, length(ave_volt)))); 
target_region = find(point_concentration == density_descend(select_region_rank), 1);
indices_interest = find(which_region == target_region);

% Pre-allocate velocity array
v = zeros(1, length(indices_interest) - 1);
for i = 1:length(indices_interest) - 1 
    idx1 = indices_interest(i);
    idx2 = indices_interest(i+1);
    
    dist_step = norm(position_arr(:,idx2) - position_arr(:,idx1));
    time_step = time_vec(idx2) - time_vec(idx1);
    v(i) = dist_step / time_step;
end

v_final = abs(v(isfinite(v) & v ~= 0)); 
fprintf('The conduction velocity within ROI is: %f m/s\n', mean(v_final));

%% 8. DISPERSION ANALYSIS
max_pts_in_region = max(point_concentration);
v_each_section = zeros(NUM_REGIONS, max_pts_in_region); 
row_means = zeros(NUM_REGIONS, 1);
row_stds = zeros(NUM_REGIONS, 1);

for r = 1:NUM_REGIONS
    region_pts = find(which_region == r);
    if length(region_pts) > 1
        % Calculate velocities for this section
        section_v = zeros(1, length(region_pts)-1);
        for i = 1:length(region_pts)-1
            p1 = region_pts(i);
            p2 = region_pts(i+1);
            section_v(i) = norm(position_arr(:,p2) - position_arr(:,p1)) / (time_vec(p2) - time_vec(p1));
        end
        
        valid_v = abs(section_v(isfinite(section_v) & section_v ~= 0));
        if ~isempty(valid_v)
            row_means(r) = mean(valid_v);
            row_stds(r) = std(valid_v);
        end
    end
end

% CoV Calculation and Abnormal detection
row_cov = zeros(NUM_REGIONS, 1);
nonzero_idx = row_means ~= 0;
row_cov(nonzero_idx) = row_stds(nonzero_idx) ./ row_means(nonzero_idx);

abnormal_threshold = mean(row_cov) + (COV_STDEV_MULTIPLIER * std(row_cov));
abnormal_regions = find(row_cov > abnormal_threshold);

%% 9. FINAL VISUALIZATIONS
% Dispersion Chart
figure(3)
bar_handle = bar(row_cov, 'FaceColor', 'b');
hold on;
title('Coefficient of Variation (CoV) Across Regions');
xlabel('Region'); ylabel('CoV');
if ~isempty(abnormal_regions)
    % Highlight abnormal bars in red
    bar_handle.CData(abnormal_regions, :) = repmat([1 0 0], length(abnormal_regions), 1);
    bar_handle.FaceColor = 'flat';
end

% Activation Map
figure(1)
k = boundary(x_points', y_points', z_points');
trisurf(k, x_points', y_points', z_points', time_vec', 'FaceAlpha', 0.2, 'EdgeColor', 'none');
colormap jet; colorbar;
title('Activation Time Propagation Map');
xlabel('X (mm)'); ylabel('Y (mm)'); zlabel('Z (mm)');