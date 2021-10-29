"""
analyze_predictions.py: Compute metrics by comparing predictions and ground truth.

This script is intended to be called via `sct_run_batch -c run_prediction_deep.yml
"""

import os
from spinalcordtoolbox import labels, image

im_pred = image.Image(os.environ["PATH_DATA_PROCESSED"]+
                         "/data/derivatives/labels/"+
                         os.environ["SUBJECT"]+"/anat/"+os.environ["met"]+"/"+
                         os.environ["file"]+"_seg_labeled_discs.nii.gz")

im_gt = image.Image(os.environ["PATH_DATA_PROCESSED"]+
                       "/data/derivatives/labels/"+
                       os.environ["SUBJECT"]+"/anat/"+
                       os.environ["file"]+"_projected-gt.nii.gz")

# Print detected label #'s
print([int(coord.value) for coord in im_gt.getNonZeroCoordinates()])
print([int(coord.value) for coord in im_pred.getNonZeroCoordinates()])

# Print error
print(labels.compute_mean_squared_error(im_pred, im_gt))
