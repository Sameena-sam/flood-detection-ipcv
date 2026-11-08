# Flood Detection from Aerial Images

A classical computer vision pipeline in MATLAB that finds flooded areas in aerial images and scores the result against ground-truth masks. Built for the Image Processing and Computer Vision module (CT103-3-M) of the MSc in Artificial Intelligence at Asia Pacific University (2026).

## Method

1. **Noise reduction:** Gaussian filtering (`imgaussfilt`), so sensor noise and compression artefacts don't distort the threshold.
2. **Colour features:** conversion to HSV (`rgb2hsv`), which separates colour from brightness better than RGB does for water.
3. **Segmentation:** automatic Otsu thresholding (`graythresh`, `imbinarize`).
4. **Clean-up:** morphological opening and closing (`imopen`, `imclose`, `strel`) and removal of small regions (`bwareaopen`).
5. **Boundaries:** edge detection (`edge`) and a flood overlay on the original image.
6. **Evaluation:** accuracy, precision, recall, F1, IoU and Dice against the ground-truth mask.

## Findings

- Works well when floodwater contrasts clearly with the land around it.
- Shadows and dense trees have low saturation like water, so they are sometimes marked as flooded.
- On low-contrast images the threshold under-segments: precision stays high but recall drops.
- Morphology improves how the mask looks but cannot fix a wrong threshold, which shows the limits of hand-crafted rules compared with learned models.

## Project structure

```
flood-detection-ipcv/
├── flood_detection.m   # full pipeline: load, segment, evaluate, plot
├── Image/              # aerial images (not included)
├── Mask/               # ground-truth masks (not included)
└── README.md
```

## Run

1. Download the **Flood Area Segmentation** dataset from Kaggle.
2. Put the images in `Image/` and the masks in `Mask/`, keeping matching file names.
3. Open MATLAB in this folder, run `flood_detection.m` and pick an image from `Image/`.

Requires MATLAB R2016b or later and the Image Processing Toolbox.

## Author

Sameena Siddiqua
