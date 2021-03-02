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

### Test on sct\_testing/large (for internal lab user)
To test on subject from sct_testing/large:
- The list of used subjects is in `testing_list.txt`
- For easier git-annex download, the list of folder to download is available in `list\_download.txt` 
