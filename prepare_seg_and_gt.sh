#!/bin/bash
#
# Pipeline for spinal cord tumor data.
#
# Generate sc segmentation. project ground truth label from posterior part of disc to center of spinal cord. 
# we can the retrieve ground truth in the middle of the spinal cord to compare with predictions.
#
# Note: All images have .nii.gz extension.
#
# Usage:
#   sct_run_batch <FILEPARAM> process_data.sh
#
# Author: lucas rouhier

# Uncomment for full verbose
# set -v

# Immediately exit if error

set -e

# Exit if user presses CTRL+C (Linux) or CMD+C (OSX)
trap "echo Caught Keyboard Interrupt within script. Exiting now.; exit" INT

# Retrieve input params
SUBJECT=$1
FILEPARAM=$2
# SCRIPT STARTS HERE
# ==============================================================================
# Go to results folder, where most of the outputs will be located
cd $PATH_DATA_PROCESSED
# Copy source images and segmentations
mkdir -p data/derivatives/labels
cd data

mkdir -p $SUBJECT/anat
cp -r $PATH_DATA/derivatives/labels/$SUBJECT $PATH_DATA_PROCESSED/data/derivatives/labels

cd $PATH_DATA_PROCESSED/data/$SUBJECT/anat/
## Setup file names
file_t2w=${SUBJECT}_T2w
file_t1w=${SUBJECT}_T1w

## copy needed file (t1w and T2w other are not needed) 
cp $PATH_DATA/$SUBJECT/anat/${file_t2w}.nii.gz ./
cp $PATH_DATA/$SUBJECT/anat/${file_t1w}.nii.gz ./
## Deepseg to get needed segmentation. 
sct_deepseg_sc -i ${file_t2w}.nii.gz -c t2 -ofolder $PATH_RESULTS/data/derivatives/labels/$SUBJECT/anat/
sct_deepseg_sc -i ${file_t1w}.nii.gz -c t1 -ofolder $PATH_RESULTS/data/derivatives/labels/$SUBJECT/anat/

## seg file name
file_seg_t2=$PATH_DATA_PROCESSED/data/derivatives/labels/$SUBJECT/anat/${SUBJECT}_T2w_seg.nii.gz
file_seg_t1=$PATH_DATA_PROCESSED/data/derivatives/labels/$SUBJECT/anat/${SUBJECT}_T1w_seg.nii.gz
label_file_t1=$PATH_DATA_PROCESSED/data/derivatives/labels/$SUBJECT/anat/${SUBJECT}_T1w_labels-disc-manual.nii.gz
label_file_t2=$PATH_DATA_PROCESSED/data/derivatives/labels/$SUBJECT/anat/${SUBJECT}_T2w_labels-disc-manual.nii.gz

sct_label_vertebrae -i ${file_t2w}.nii.gz -s ${file_seg_t2} -c t2 -discfile ${label_file_t2} -ofolder $PATH_DATA_PROCESSED/data/derivatives/labels/$SUBJECT/anat/

sct_label_vertebrae -i ${file_t1w}.nii.gz -s ${file_seg_t1} -c t1 -discfile ${label_file_t1} -ofolder $PATH_DATA_PROCESSED/data/derivatives/labels/$SUBJECT/anat/

## Change the name to avoid overwriting files output by sct_label_vertebrae during prediction later. 
mv $PATH_DATA_PROCESSED/data/derivatives/labels/$SUBJECT/anat/${SUBJECT}_T2w_seg_labeled_discs.nii.gz $PATH_DATA_PROCESSED/data/derivatives/labels/$SUBJECT/anat/${SUBJECT}_T2w_projected-gt.nii.gz


mv $PATH_DATA_PROCESSED/data/derivatives/labels/$SUBJECT/anat/${SUBJECT}_T1w_seg_labeled_discs.nii.gz $PATH_DATA_PROCESSED/data/derivatives/labels/$SUBJECT/anat/${SUBJECT}_T1w_projected-gt.nii.gz
