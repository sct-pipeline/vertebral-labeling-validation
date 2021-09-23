The purpose of this repository is to evaluate the performance of sct\_vertebral\_labeling across the implementation of new methods.

### Requirements

- SCT version 5.0.0
- spine-generic multi-subject dataset [r20201001](https://github.com/spine-generic/data-multi-subject/releases/tag/r20201001)

### Getting started

Clone the repos

```bash
git clone https://github.com/sct-pipeline/vertebral-labeling-validation
cd vertebral-labeling-validation
```

Edit the parameter files to your local configuration:
- `parameters/prepare_seg_gt.yml`: This is the configuration file for the script `prepare_seg_and_gt.sh`. This script projects the manual disc labels (ground truth, single voxel located at the posterior side of each intervertebral disc) onto the center of the spinal cord. The reason we do that is because the output of `sct_label_vertebrae` are labels in the cord (not at the posterior tip of the disc).
- `parameters/run_prediction.yml`: This is the configuration file for the script `run_prediction.sh`. This script runs `sct_label_vertebrae` and compares outputs to the ground truth using `sct_label_utils`. The Mean Square Error is calculated. It also retrieve the value of the missing labels. Results are saved in a CSV file within the results/ folder.

Run the script:
```bash
sct_run_batch -c parameters/<CONFIG_FILE>
```

Perform statistics:
```bash
python concat_csv.py -p <PATH_OUTPUT>/results/
```
Where `PATH_OUTPUT` is the output of `run_prediction.sh

### Test on `sct_testing-large` (for internal lab user)
To test on subjects from `sct-testing-large`:
1. To download the list of test subjects (see [`testing_list.txt`](testing_list.txt)):
    - First, perform the [initial setup](https://github.com/neuropoly/data-management/blob/master/internal-server.md#initial-setup) to use the internal git annex server.
    - Then, run the following commands inside a separate folder:
      ```bash
      git clone git@data.neuro.polymtl.ca:datasets/sct-testing-large  
      cd sct-testing-large
      
      # copy-paste and run this as a single command
      xargs -a ${PATH_TO_vertebral-labeling-validation_REPO}/testing_list.txt -I '{}' \
        find . -type d -name "*{}*" -print | 
        xargs -L 1 git annex get
      ```
    - This will retrieve the test subjects inside the `sct-testing-large` git annex repo
2. Then, copy the subject files over to this repo:
    - Run the following commands:
      ```bash
      cd ${PATH_TO_vertebral-labeling-validation_REPO}
      python -m retrieve_large -l testing_list.txt -i <PATH_TO_sct-testing-large_REPO> -o data_large
      ```
    - This is done to be able to easily work on a "fresh copy" and avoid working inside the git annex repo directly, so that it can be wiped and re-run if needed.
- Run the processing on the output folder (`data_large`) 
