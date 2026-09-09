### Project Overview

This project focuses on the quantitative image analysis of a water droplet impacting a superhydrophobic surface.
The analysis is performed using MATLAB and a high-speed experimental video. The main objective is to extract meaningful physical information from the video by processing the droplet frame-by-frame.
The analysis includes video calibration, droplet detection, centroid calculation, half-droplet area measurement, half-area centroid determination, and droplet volume estimation using the Pappus–Guldinus theorem.

## Experimental Information

| Parameter | Value |
|---|---|
| Camera acquisition rate | 3000 fps |
| Video playback rate | 30 fps |
| Substrate front-edge length | 15 mm |

The physical time corresponding to each frame is calculated using the original camera acquisition rate.


## Methodology
The MATLAB code follows these main steps:

1. **Video Properties**
   - Read the experimental video.
   - Determine the number of frames.
   - Determine the frame width and height.
   - Obtain the frame rate stored in the video.

2. **Image Calibration**
   - Identify the known scale/reference in the video.
   - Determine its length in pixels.
   - Use the known physical length to calculate the calibration factor in mm/pixel.

3. **Droplet Detection**
   - Convert each video frame to grayscale.
   - Apply intensity thresholding to identify the droplet.
   - Exclude the substrate from the detected region.
   - Identify the largest suitable connected component as the droplet.

4. **Axis of Symmetry**
   - Determine the leftmost and rightmost droplet pixels.
   - Calculate the vertical axis of symmetry from the detected droplet boundary.

5. **Droplet Centroid**
   - Calculate the centroid of the complete droplet for every usable frame.
   - Determine the vertical centroid position, `yc(t)`.
   - Determine the horizontal centroid position, `xc(t)`, relative to the symmetry axis.

6. **Half-Droplet Area**
   - Divide the droplet into left and right halves using the symmetry axis.
   - Select the left half consistently throughout the analysis.
   - Calculate its cross-sectional area from the detected pixels.
   - Convert the area from pixels² to mm².

7. **Half-Area Centroid**
   - Determine the centroid of the selected half-droplet.
   - Calculate its horizontal distance from the symmetry axis, `x̄(t)`.

8. **Droplet Volume**
   - Estimate the three-dimensional droplet volume using the Pappus–Guldinus theorem:
     `V(t) = 2π x̄(t) Ah(t)`
   - Calculate the volume for both left and right halves.
   - Convert the volume from mm³ to µL.

## Required Plots
The MATLAB code generates the following plots:

### Figure 1
**Droplet Centroid Vertical Position vs Time**
Shows the vertical motion of the droplet centroid with physical time.

### Figure 2
**Droplet Centroid Horizontal Position vs Time**
Shows the horizontal centroid position relative to the droplet's axis of symmetry.

### Figure 3
**Half-Droplet Cross-Sectional Area vs Time**
Shows how the selected half of the droplet deforms during impact.

### Figure 4
**Half-Area Centroid Distance from Axis of Symmetry vs Time**
Shows how the cross-sectional area is distributed away from the symmetry axis.

### Figure 5
**Droplet Volume vs Time**
Compares the volume calculated from the left and right halves using the Pappus–Guldinus theorem.

## Numerical Results
The MATLAB code reports:

- Number of frames
- Video dimensions
- Frame rate stored in the video
- Calibration factor
- Maximum half-droplet area
- Minimum half-droplet area
- Mean half-droplet area
- Initial calculated volume
- Maximum calculated volume
- Minimum calculated volume
- Mean calculated volume

## Physical Interpretation

For an approximately axisymmetric droplet, the horizontal centroid position `xc(t)` should remain close to zero because the centroid should lie near the symmetry axis.
The half-droplet area does not necessarily remain constant because the droplet can deform significantly during impact. The two-dimensional side-view area can therefore change even though the actual three-dimensional volume of the water droplet should remain approximately constant.
The calculated volume is also used to evaluate the reliability of the image-processing method. Variations in calculated volume can result from segmentation errors, incorrect boundary detection, thresholding, pixel resolution, an incorrectly determined symmetry axis, parts of the droplet being hidden, perspective effects, or limitations of the axisymmetric assumption.

## Representative Frames
The MATLAB code also produces annotated frames showing:

- The detected droplet boundary
- The calculated axis of symmetry

These frames provide a visual check that the image-processing method is correctly identifying the droplet.

## Files
- `code.m` – MATLAB code used for the complete image-processing and quantitative analysis.
- `Test.mp4` – High-speed experimental video used as the input dataset.



## Software Used

**MATLAB**
Image-processing functions are used for grayscale conversion, thresholding, connected-component analysis, droplet detection, centroid calculation, and area measurement.


## Conclusion

This project demonstrates how image-processing techniques can be applied to an experimental droplet-impact problem to obtain quantitative information about droplet motion, deformation, geometry, and volume.
The analysis also highlights the importance of proper calibration, accurate segmentation, and physically meaningful interpretation of image-derived measurements.
