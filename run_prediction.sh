#!/bin/bash
#
# Pipeline for spinal cord tumor data.
#
# predict disc position and compute MSE with groundtruth. 
# 
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
cd $PATH_RESULTS
# Copy source images and segmentations
mkdir -p data/derivatives/labels
cd data

cp -r $PATH_DATA/$SUBJECT ./
cp -r $PATH_DATA/derivatives/labels/$SUBJECT $PATH_RESULTS/data/derivatives/labels

cd $PATH_RESULTS/data/$SUBJECT/anat/
## Setup file names
file_t2w=${SUBJECT}_T2w
file_t1w=${SUBJECT}_T1w
file_seg_t2=$PATH_RESULTS/data/derivatives/labels/$SUBJECT/anat/${SUBJECT}_T2w_seg.nii.gz
file_seg_t1=$PATH_RESULTS/data/derivatives/labels/$SUBJECT/anat/${SUBJECT}_T1w_seg.nii.gz

## make predictions
sct_label_vertebrae -i ${file_t2w}.nii.gz -s ${file_seg_t2} -c t2 -ofolder $PATH_RESULTS/data/derivatives/labels/$SUBJECT/anat/

sct_label_vertebrae -i ${file_t1w}.nii.gz -s ${file_seg_t1} -c t1 -ofolder $PATH_RESULTS/data/derivatives/labels/$SUBJECT/anat/
## compare 
cd $PATH_RESULTS/data/derivatives/labels/$SUBJECT/anat/

t2_err=$(sct_label_utils -i ${file_t2w}_seg_labeled_discs.nii.gz -MSE ${file_t2w}_projected-gt.nii.gz)
t1_err=$(sct_label_utils -i ${file_t1w}_seg_labeled_discs.nii.gz -MSE ${file_t1w}_projected-gt.nii.gz)

## strip unneeded content
t2_err=${t2_err#*)}
t1_err=${t1_err#*)}

## get error in mm
t2_err_mm=${t2_err#*=}
t2_err_mm=${t2_err_mm%%mm*}

t1_err_mm=${t1_err#*=}
t1_err_mm=${t1_err_mm%%mm*}

## get MSE error
echo $t2_err
t2_err_mse=${t2_err#*: }
echo $t2_err_mse
t1_err_mse=${t1_err#*: }

## create csv
echo "file,error_mm,error_mse,contrast">> result.csv
echo "$file_t2w,$t2_err_mm,$t2_err_mse,t2">>result.csv
echo "$file_t1w,$t1_err_mm,$t1_err_mse,t1">>result.csv


