"""
analyze_predictions.py: Compute metrics by comparing predictions and ground truth.

This script is intended to be called via `sct_run_batch -c run_prediction_deep.yml
"""

import os
import numpy as np
from operator import attrgetter
from spinalcordtoolbox import labels, image

# Sometimes NeuroPoly's GT label files will include additional labels for
# the pontomedullary junction and groove. However, sct_label_vertebrae won't
# detect this by default, so it's OK to not detect these labels.
ALLOWABLE_FN = [49, 50]

# Many of NeuroPoly's GT label files start at the C2/C3 disc (val=3). But,
# sct_label_vertebrae will also try to place labels above/below the C1
# vertebrae. This is OK and expected, so we don't want these to be included as
# false positives.
ALLOWABLE_FP = [1, 2]


def compare_coord_values(coord_list_1, coord_list_2):
    value_set_1 = set([coord.value for coord in coord_list_1])
    value_set_2 = set([coord.value for coord in coord_list_2])

    value_shared = value_set_1.intersection(value_set_2)

    coord_shared_1 = [c for c in coord_list_1 if c.value in value_shared]
    coord_shared_2 = [c for c in coord_list_2 if c.value in value_shared]
    coord_extra_1 = [c for c in coord_list_1 if c.value not in value_shared]
    coord_extra_2 = [c for c in coord_list_2 if c.value not in value_shared]

    return coord_shared_1, coord_shared_2, coord_extra_1, coord_extra_2


def compute_mean_euclidean_distance(coord_list_1, coord_list_2,
                                    zooms=(1, 1, 1), z_only=False):
    """
    Compute mean Euclidean distance between pairs of matching labels.

    - zooms: (x, y, z) conversion factor between voxel and mm. Use to compute
             distance in mm, rather than voxels.
    - z_only: Whether to compute the distance using the z dimension (typically
              IS axis i.e. axial plane) only.
    """
    assert len(coord_list_1) == len(coord_list_2)
    assert len(zooms) == 3

    result = 0.0
    for c_1, c_2 in zip(coord_list_1, coord_list_2):
        assert c_1.value == c_2.value
        if z_only:
            result += np.abs(c_1.z - c_2.z)*zooms[2]
        else:
            result += np.sqrt(((c_1.x - c_2.x)*zooms[0])**2 +
                              ((c_1.y - c_2.y)*zooms[1])**2 +
                              ((c_1.z - c_2.z)*zooms[2])**2)

    return result / len(coord_list_1)


def compute_mse(coord_list_1, coord_list_2,
                zooms=(1, 1, 1), z_only=False):
    """
    Compute mean squared error between pairs of matching labels.

    - z_only: Whether to compute the MSE using the z dimension (typically
              IS axis i.e. axial plane) only.
    """
    assert len(coord_list_1) == len(coord_list_2)

    result = 0.0
    for c_1, c_2 in zip(coord_list_1, coord_list_2):
        assert c_1.value == c_2.value
        if z_only:
            result += ((c_1.z - c_2.z)*zooms[2])**2
        else:
            result += (((c_1.x - c_2.x)*zooms[0])**2 +
                       ((c_1.y - c_2.y)*zooms[1])**2 +
                       ((c_1.z - c_2.z)*zooms[2])**2)

    return result / len(coord_list_1)


def compute_metrics(coord_gt, coord_pred, zooms):
    """
    Compute metrics based on predicted and actual disc labels.
    """
    (coord_gt_shared, coord_pred_shared, coord_gt_extra, coord_pred_extra) = \
        compare_coord_values(coord_gt, coord_pred)

    # Compute label-based metrics
    tp = [c.value for c in coord_pred_shared]
    fn = [c.value for c in coord_gt_extra if c.value not in ALLOWABLE_FN]
    fp = [c.value for c in coord_pred_extra if c.value not in ALLOWABLE_FP]

    # Compute coordinate-based metrics
    mse_vox_z = compute_mse(coord_gt_shared, coord_pred_shared, z_only=True)
    mse_mm_z = compute_mse(coord_gt_shared, coord_pred_shared, zooms=zooms,
                           z_only=True)
    dist_vox_z = compute_mean_euclidean_distance(coord_gt_shared,
                                                 coord_pred_shared,
                                                 z_only=True)
    dist_mm_z = compute_mean_euclidean_distance(coord_gt_shared,
                                                coord_pred_shared, zooms=zooms,
                                                z_only=True)

    ### Alternatively, we could use the full 3D distance in our metrics
    # mse_vox_xyz = compute_mse(coord_gt_shared, coord_pred_shared)
    # mse_mm_xyz = compute_mse(coord_gt_shared, coord_pred_shared, zooms=zooms)
    # dist_vox_xyz = compute_mean_euclidean_distance(coord_gt_shared, coord_pred_shared)
    # dist_mm_xyz = compute_mean_euclidean_distance(coord_gt_shared, coord_pred_shared, zooms=zooms)

    return tp, fn, fp, round(dist_mm_z, 2)



def main():
    im_pred = image.Image(
        os.environ["PATH_DATA_PROCESSED"]+"/data/derivatives/labels/"+
        os.environ["SUBJECT"]+"/anat/"+os.environ["met"]+"/"+
        os.environ["file"]+"_seg_labeled_discs.nii.gz"
    ).change_orientation("RPI")

    im_gt = image.Image(
        os.environ["PATH_DATA_PROCESSED"]+"/data/derivatives/labels/"+
        os.environ["SUBJECT"]+"/anat/"+
        os.environ["file"]+"_projected-gt.nii.gz"
    ).change_orientation("RPI")

    zooms = im_gt.im_file.header.get_zooms()
    assert im_pred.im_file.header.get_zooms() == zooms

    coord_pred = sorted(im_pred.getNonZeroCoordinates(), key=attrgetter('value'))
    coord_gt = sorted(im_gt.getNonZeroCoordinates(), key=attrgetter('value'))

    for coords in [coord_pred, coord_gt]:
        for coord in coords:
            if int(coord.value) == coord.value:
                coord.value = int(coord.value)  # Convert float labels to ints
            else:
                raise ValueError(f"Non-integer label {coord.value} encountered!")

    # Each computed metric will be printed as a separate line, to be put into
    # a .csv file using
    for metric in compute_metrics(coord_gt, coord_pred, zooms):
        print(metric)


if __name__ == "__main__":
    main()