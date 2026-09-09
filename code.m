clear;
clc;
close all;

%% TASK 1: Read the video and get its basic properties

videoFile = 'Test.mp4';

v = VideoReader(videoFile);

numFrames  = v.NumFrames;
frameWidth = v.Width;
frameHeight = v.Height;

storedFrameRate = v.FrameRate;

fprintf('Task 1: Video properties\n');
fprintf('Number of frames : %d\n', numFrames);
fprintf('Frame width (pixels): %d\n', frameWidth);
fprintf('Frame height (pixels): %d\n', frameHeight);
fprintf('Frame rate stored in file: %.2f fps\n', storedFrameRate);


%% TASK 2: Calibrate the image

% The video was recorded at a high acquisition rate.
% The playback rate is only used to describe how the video is viewed.

acquisitionRate = 3000;
playbackRate    = 30;

dt = 1/acquisitionRate;

% Read the first frame and use it for calibration
calibFrame = read(v, 1);

% Convert the frame to grayscale
grayCalib = im2gray(calibFrame);

% Threshold used to identify the dark substrate
darkThresh = 110;

darkMask0 = grayCalib < darkThresh;

% Find the top row of the substrate
rowDarkCount = sum(darkMask0, 2);
topRow = find(rowDarkCount > 0.5*frameWidth, 1, 'first');

% Take a row slightly below the detected top edge
rowMeasure = topRow + 3;

% Find the dark pixels along this row
colsDark = find(darkMask0(rowMeasure, :));

% Calculate the substrate width in pixels
pxWidth = max(colsDark) - min(colsDark);

% Known physical length of the substrate
substrateLength_mm = 15;

% Calculate the conversion factor from pixels to millimetres
C = substrateLength_mm / pxWidth;

fprintf('\nTask 2: Calibration\n');
fprintf('Substrate top row (pixel): %d\n', topRow);
fprintf('Substrate pixel width : %d px\n', pxWidth);
fprintf('Calibration factor C : %.5f mm/pixel\n', C);


%% TASK 3: Create a mask for the substrate and initialize variables

% Create a mask containing the substrate region
substrateMask = false(frameHeight, frameWidth);
substrateMask(topRow-2:end, :) = darkMask0(topRow-2:end, :);

% Slightly expand the mask to make sure the substrate is removed
substrateMask = imdilate(substrateMask, strel('disk', 3));


% Pre-allocate arrays for the measurements
t = nan(numFrames,1);

yc_mm = nan(numFrames,1);
xc_rel_mm = nan(numFrames,1);

Ah_left = nan(numFrames,1);
Ah_right = nan(numFrames,1);

xbar_left = nan(numFrames,1);
xbar_right = nan(numFrames,1);


% Frames that will later be displayed with their detected boundaries
annotFrames = [1, 31];
annotStore = struct();


%% TASK 4: Detect the droplet in every frame

for k = 1:numFrames

    % Read the current frame
    frame = read(v, k);

    % Convert the frame to grayscale
    gray = im2gray(frame);

    % Identify dark regions
    darkMask = gray < darkThresh;

    % Remove the substrate from the possible droplet region
    dropletCandidate = darkMask & ~substrateMask;

    % Find connected regions in the remaining image
    CC = bwconncomp(dropletCandidate);

    % If no object is detected, move to the next frame
    if CC.NumObjects == 0
        continue;
    end

    % Calculate the area of each detected object
    areas = cellfun(@numel, CC.PixelIdxList);

    % Assume the largest suitable object is the droplet
    [maxArea, idx] = max(areas);

    % Ignore very small objects
    if maxArea < 30
        continue;
    end

    % Create the final binary mask for the detected droplet
    mask = false(frameHeight, frameWidth);
    mask(CC.PixelIdxList{idx}) = true;

    % Get the row and column coordinates of the droplet pixels
    [rows, cols] = find(mask);


    %% Determine the droplet's horizontal axis of symmetry

    xMin = min(cols);
    xMax = max(cols);

    axisX = (xMin + xMax) / 2;


    %% Calculate the droplet centroid

    ycPix = mean(rows);
    xcPix = mean(cols);

    % Convert frame number into physical time
    t(k) = (k-1) * dt;

    % Convert centroid coordinates from pixels to millimetres
    yc_mm(k) = ycPix * C;

    % Horizontal position relative to the symmetry axis
    xc_rel_mm(k) = (xcPix - axisX) * C;


    %% Separate the droplet into left and right halves

    leftIdx = cols < axisX;
    rightIdx = cols >= axisX;

    % Calculate the cross-sectional area of each half
    Ah_left(k) = nnz(leftIdx) * C^2;
    Ah_right(k) = nnz(rightIdx) * C^2;


    %% Find the centroid distance of each half from the axis

    if any(leftIdx)
        xbar_left(k) = mean(axisX - cols(leftIdx)) * C;
    end

    if any(rightIdx)
        xbar_right(k) = mean(cols(rightIdx) - axisX) * C;
    end


    %% Save selected frames for later visualization

    if ismember(k, annotFrames)

        annotStore.(sprintf('f%d', k)) = struct( ...
            'frame', frame, ...
            'mask', mask, ...
            'axisX', axisX);

    end

end


%% TASK 5: Keep only frames with valid measurements

usable = ~isnan(t);

t = t(usable);
yc_mm = yc_mm(usable);
xc_rel_mm = xc_rel_mm(usable);

Ah_left = Ah_left(usable);
Ah_right = Ah_right(usable);

xbar_left = xbar_left(usable);
xbar_right = xbar_right(usable);

fprintf('\nUsable frames for analysis: %d / %d\n', ...
    nnz(usable), numFrames);


%% FIGURE 1: Droplet centroid vertical position

figure('Name','Figure 1');

plot(t, yc_mm, 'LineWidth', 1.3);

xlabel('Physical time, t (s)');
ylabel('y_c (mm)');

title('Figure 1: Droplet Centroid Vertical Position vs Time');

grid on;


%% FIGURE 2: Droplet centroid horizontal position

figure('Name','Figure 2');

plot(t, xc_rel_mm, 'LineWidth', 1.3);

xlabel('Physical time, t (s)');
ylabel('x_c (mm), relative to axis of symmetry');

title('Figure 2: Droplet Centroid Horizontal Position vs Time');

grid on;


%% FIGURE 3: Half-droplet cross-sectional area

figure('Name','Figure 3');

plot(t, Ah_left, 'LineWidth', 1.3);

xlabel('Physical time, t (s)');
ylabel('A_h (mm^2)');

title('Figure 3: Half-Droplet Cross-Sectional Area vs Time');

grid on;

yline(0, 'k--');


%% Display the minimum and maximum half-droplet area

fprintf('\nHalf-droplet area (left half)\n');

fprintf('Maximum half-area : %.3f mm^2\n', max(Ah_left));
fprintf('Minimum half-area : %.3f mm^2\n', min(Ah_left));
fprintf('Mean half-area    : %.3f mm^2\n', mean(Ah_left));


%% FIGURE 4: Centroid distance of the half-area

figure('Name','Figure 4');

plot(t, xbar_left, 'LineWidth', 1.3);

xlabel('Physical time, t (s)');
ylabel('x-bar (mm)');

title('Figure 4: Half-Area Centroid Distance from Axis of Symmetry vs Time');

grid on;


%% TASK 6: Estimate droplet volume using Pappus-Guldinus theorem

V_left_uL  = 2*pi .* xbar_left  .* Ah_left;
V_right_uL = 2*pi .* xbar_right .* Ah_right;


%% FIGURE 5: Droplet volume variation with time

figure('Name','Figure 5');

plot(t, V_left_uL, 'b-', 'LineWidth', 1.3);
hold on;

plot(t, V_right_uL, 'r--', 'LineWidth', 1.3);

xlabel('Physical time, t (s)');
ylabel('Volume, V (\muL)');

legend('Left half', 'Right half', 'Location', 'best');

title('Figure 5: Droplet Volume vs Time (Pappus-Guldinus)');

grid on;


%% Display the calculated volume values

fprintf('\nVolume (left half), Pappus-Guldinus\n');

fprintf('Initial volume : %.3f uL\n', V_left_uL(1));
fprintf('Maximum volume : %.3f uL\n', max(V_left_uL));
fprintf('Minimum volume : %.3f uL\n', min(V_left_uL));
fprintf('Mean volume    : %.3f uL\n', mean(V_left_uL));


%% TASK 7: Display selected frames with the detected droplet boundary

fn = fieldnames(annotStore);

figure('Name','Annotated frames');

for i = 1:numel(fn)

    s = annotStore.(fn{i});

    subplot(1, numel(fn), i);

    imshow(s.frame);
    hold on;

    % Find and draw the boundary of the detected droplet
    boundaries = bwboundaries(s.mask);

    for b = 1:numel(boundaries)

        plot(boundaries{b}(:,2), boundaries{b}(:,1), ...
            'g-', 'LineWidth', 1.5);

    end

    % Show the calculated axis of symmetry
    xline(s.axisX, 'r-', 'LineWidth', 1.5);

    title(sprintf('Frame %s: boundary + axis of symmetry', ...
        fn{i}(2:end)));

end

%% Questions and Answers

% Answer 1: ...
...If the droplet is detected correctly and remains nearly symmetric, \(x_c(t)\) should stay close to **zero**, since the centroid should remain around the symmetry axis...

...If it changes a lot, it could be due to **incorrect droplet detection, an incorrectly identified symmetry axis, image noise, droplet deformation, pixel limitations, or thresholding errors**...

...Overall, \(x_c(t)\approx0\) indicates that the droplet detection and symmetry-axis calculation are working properly.

% Answer 2:...
... No, the half-area does not have to stay constant. During impact, the droplet can change its shape, causing the **2D side-view area to increase or decrease**. However, its actual **3D volume should remain nearly constant** because the amount of liquid does not change significantly...

... In short, **the droplet can change shape and 2D area while its overall volume stays almost the same**.

% Answer3: ...
... \(\bar{x}(t)\) is the centroid of **only one half of the droplet**, measured from the symmetry axis, so it is different from the centroid of the whole droplet...

... It tells us **how far the cross-sectional area is spread from the centerline**. A larger \(\bar{x}\) means the area is spread farther out, while a smaller value means it is concentrated closer to the axis.

% Answer 4: ...
... Since water is nearly incompressible, the actual 3D volume of the droplet should remain approximately constant. If the calculated \(V(t)\) changes, it is mainly due to **image-processing and measurement errors**...

... Possible reasons include imperfect boundary detection, an incorrectly identified symmetry axis, missing or extra pixels, parts of the droplet being hidden by the substrate or nozzle, limited image resolution, thresholding errors, perspective effects, and the assumption that the droplet is axisymmetric...

... Therefore, the **variation in the calculated \(V(t)\)** should be used to judge how accurately the image-processing method measures the droplet volume. If the variation is small, the method is reasonably reliable; larger variations indicate that the segmentation or geometric assumptions may need improvement.
