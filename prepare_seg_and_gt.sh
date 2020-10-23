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
contrast = '"T1" "T2"'
for i in $contrast; do
	file=${SUBJECT}_"$i"w
	c_arg = ${i/T/t}

	## copy needed file (t1w and T2w other are not needed) 
	cp $PATH_DATA/$SUBJECT/anat/${file}.nii.gz ./
	## Deepseg to get needed segmentation. 
	sct_deepseg_sc -i ${file}.nii.gz -c "$c_arg"  -ofolder $PATH_RESULTS/data/derivatives/labels/$SUBJECT/anat/

	## seg file name
	file_seg=$PATH_DATA_PROCESSED/data/derivatives/labels/$SUBJECT/anat/${SUBJECT}_"$i"w_seg.nii.gz
	label_file=$PATH_DATA_PROCESSED/data/derivatives/labels/$SUBJECT/anat/${SUBJECT}_"$i"w_labels-disc-manual.nii.gz

	sct_label_vertebrae -i ${file}.nii.gz -s ${file_seg} -c t2 -discfile ${label_file} -ofolder $PATH_DATA_PROCESSED/data/derivatives/labels/$SUBJECT/anat/

	## Change the name to avoid overwriting files output by sct_label_vertebrae during prediction later. 
	mv $PATH_DATA_PROCESSED/data/derivatives/labels/$SUBJECT/anat/${SUBJECT}_"$i"w_seg_labeled_discs.nii.gz $PATH_DATA_PROCESSED/data/derivatives/labels/$SUBJECT/anat/${SUBJECT}_"$i"_projected-gt.nii.gz
done

