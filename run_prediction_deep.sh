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
source ${SCT_DIR}/python/etc/profile.d/conda.sh
conda activate venv_sct

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

## Setup file names
Method='TM DL-Countception DL-Hourglass'
contrast='T1 T2'
for met in $Method; do
  for i in $contrast; do
    file=${SUBJECT}_"$i"w
    if test -f ${file}.nii.gz; then
      file_seg=$PATH_DATA_PROCESSED/data/derivatives/labels/$SUBJECT/anat/${SUBJECT}_"$i"w_seg.nii.gz
      c_args=${i/T/t}
      export SUBJECT=$SUBJECT
      export file=$file
      export met=$met

      ## make predictions
      sct_label_vertebrae -i ${file}.nii.gz -s ${file_seg} -c "$c_args" -method ${met} -ofolder $PATH_DATA_PROCESSED/data/derivatives/labels/$SUBJECT/anat/$met

      ## compare
      script_output=()
      while read -r line ; do
        script_output+=("${line}")
      done <<< "$(python /home/joshua/repos/vertebral-labeling-validation/check_missing_labels.py)"
      label_gt=${script_output[0]}
      label_pred=${script_output[1]}
      err=${script_output[2]}

      ## add csv line with the error and contrast.
      echo "$file;$label_gt;$label_pred;$err;$c_args;$met">>$PATH_RESULTS/results.csv
    fi
  done
done

