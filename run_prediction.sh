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
cd $PATH_DATA_PROCESSED
# Copy source images and segmentations
mkdir -p data/derivatives/labels

cp -r $PATH_DATA/$SUBJECT ./
cp -r $PATH_DATA/derivatives/labels/$SUBJECT $PATH_DATA_PROCESSED/data/derivatives/labels

cd $PATH_DATA_PROCESSED/$SUBJECT/anat/
echo "file,error_mm,error_mse,contrast">> $PATH_RESULTS/"$SUBJECT"_result.csv
## Setup file names
contrast='T1 T2'
for i in $contrast; do
	file=${SUBJECT}_"$i"w
	file_seg=$PATH_DATA_PROCESSED/data/derivatives/labels/$SUBJECT/anat/${SUBJECT}_"$i"w_seg.nii.gz
	c_args=${i/T/t}

	## make predictions
	sct_label_vertebrae -i ${file}.nii.gz -s ${file_seg} -c "$c_args" -ofolder $PATH_DATA_PROCESSED/data/derivatives/labels/$SUBJECT/anat/

## compare 
	err=$(sct_label_utils -i $PATH_DATA_PROCESSED/data/derivatives/labels/$SUBJECT/anat/${file}_seg_labeled_discs.nii.gz -MSE $PATH_DATA_PROCESSED/data/derivatives/labels/$SUBJECT/anat/${file}_projected-gt.nii.gz)

## strip unneeded content
	err=${err#*)}

## get error in mm
	err_mm=${err#*=}
	err_mm=${err_mm%%mm*}

## get MSE error
	err_mse=${err#*: }

## create csv
	echo "$file,$err_mm,$err_mse,$c_args">>$PATH_RESULTS/"$SUBJECT"_result.csv
done

