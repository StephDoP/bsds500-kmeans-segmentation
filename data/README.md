# Data

The scripts use the **Berkeley Segmentation Data Set 500 (BSDS500)**: 500 natural images
(200 train, 100 validation, 200 test) with 4 to 9 human segmentations each, stored as MATLAB
files. The dataset is not redistributed here; download it from Berkeley.

1. Download `BSR_bsds500.tgz` (about 70 MB) from the
   [BSDS500 resources page](https://www2.eecs.berkeley.edu/Research/Projects/CS/vision/grouping/resources.html).
2. Extract it and copy the contents of `BSR/BSDS500/data/` here, so that the folder looks like:

```
data/
├── images/
│   ├── train/   200 .jpg
│   ├── val/     100 .jpg
│   └── test/    200 .jpg
└── groundTruth/
    ├── train/   200 .mat
    ├── val/     100 .mat
    └── test/    200 .mat
```

Each ground-truth file holds a cell array `groundTruth`; `groundTruth{k}.Segmentation` is the
label image drawn by annotator `k` and `groundTruth{k}.Boundaries` its boundary map. The
scripts use the first annotator only.

Citation: D. Martin, C. Fowlkes, D. Tal and J. Malik, "A database of human segmented natural
images and its application to evaluating segmentation algorithms and measuring ecological
statistics," *Proc. 8th IEEE International Conference on Computer Vision (ICCV)*, 2001.
BSDS500 itself is described in P. Arbeláez, M. Maire, C. Fowlkes and J. Malik, "Contour
detection and hierarchical image segmentation," *IEEE TPAMI*, 33(5), 2011.
