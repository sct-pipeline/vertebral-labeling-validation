# vertebral-labeling-validation

The purpose of this repository is to evaluate the performance of `sct_label_vertebrae` across the implementation of new methods.

### Prerequisites

1. Install `spinalcordtoolbox` from `git` and check out the disc labeling PR:

    ```bash
    git clone https://github.com/spinalcordtoolbox/spinalcordtoolbox
    cd spinalcordtoolbox
    ./install_sct
    git checkout lr/Deep_vertebral_labeling
    ```
    
    **Important**: You will want to make sure you are checked out to this branch each time you run `sct_run_batch`. This will only be necessary during the development of the SCT/ivadomed integration. Once [`spinalcordtoolbox`@PR#2679](https://github.com/spinalcordtoolbox/spinalcordtoolbox/pull/2679) has been merged, this step will change.

2. Manually reinstall `ivadomed` in the SCT conda environment, specifically using the "HourglassNet" branch:

    ```bash
    cd $SCT_DIR
    source python/etc/profile.d/conda.sh
    conda activate venv_sct
    pip uninstall ivadomed -y
    pip install git+https://github.com/ivadomed/ivadomed.git@jn/539-intervertebral-disc-labeling-pose-estimation
    ```
    
    This will only be necessary during the development of the HourglassNet model. Once [`ivadomed`@PR#852](https://github.com/ivadomed/ivadomed/pull/852) has been merged, this step will change.

3. Download a dataset of your choice:

    - spine-generic multi-subject dataset [r20201001](https://github.com/spine-generic/data-multi-subject/releases/tag/r20201001)
    - For internal datasets (such as `sct-testing-large`, see [`neuropoly/data-management/internal-server.md`](https://github.com/neuropoly/data-management/blob/master/internal-server.md)

4. Clone this repo, and open it in your terminal

    ```bash
    git clone https://github.com/sct-pipeline/vertebral-labeling-validation
    cd vertebral-labeling-validation
    ```

### Running the preprocessing scripts

1. First, edit `testing_list.txt` to include a list of subjects you want to process. Here, `testing_list.txt` is includes subjects from the `sct_testing_large` dataset. However, if you're using a different dataset, you will want to specify a different list of subjects.

2. (Optional) If you are using a `git-annex` dataset, you will want to make sure the files for these subjects are actually downloaded. For example:

    ```bash
    git clone git@data.neuro.polymtl.ca:datasets/sct-testing-large  
    cd sct-testing-large
    
    # copy and paste these 3 lines and run as a single command
    xargs -a testing_list.txt -I '{}' \
    find . -type d -name "*{}*" -print | 
    xargs -L 1 git annex get
    ```
    
    This will pipe the subjects from `testing_list.txt` into `git annex get` to fetch all of the files that match each subject.

3. Next, run the `retrieve_large.py` script as follows:

    ```bash
    python3 retrieve_large.py -l testing_list.txt -i {PATH_TO_DATASET} -o {PATH_TO_STORE_RAW_TESTING_FILES}
    ```
    
    This script simply copies the T1w/T2w anat and label files from the original dataset folder (`-i`) to a new folder (`-o`). We do this to avoid working in the original dataset folder:

    - This guarantees that the original folder will always have a "fresh" copy of the raw/unprocessed files if we ever want to start over. 
    - It also means we can apply `sct_run_batch` on the entire folder without having to explicitly specify a list of subjects using `include_list`.

4. After that, edit the config file `prepare_seg_and_gt.yml` to match the filepaths on your computer.

    - NB: You may also want to update `jobs` if you have a more capable workstation (i.e. you are working on a lab server).

5. Next, run the preprocessing script:

    ```bash
    sct_run_batch -c prepare_seg_and_gt.yml
    ```

    The corresponding bash script (`prepare_seg_and_gt.sh`) projects the manual disc labels (ground truth, single voxel located at the posterior side of each intervertebral disc) onto the center of the spinal cord. The reason we do that is because the output of `sct_label_vertebrae` are labels in the cord (not at the posterior tip of the disc).

### Testing the disc labeling approaches on the preprocessed data

1. First, edit the config file `run_prediction.yml` to match the filepaths on your computer.

    - NB: You may also want to update `jobs` if you have a more capable workstation (i.e. you are working on a lab server).

2. Next, run the processing script:

    ```bash
    sct_run_batch -c run_prediction.yml
    ```
   
    The corresponding bash script (`run_prediction.sh`) will call `sct_label_vertebrae` for each method. Then, it will invoke the `analyze_predictions.py` script to compare the predictions and ground truth. Finally, it will output metrics into a `results.csv` file, which you can then use to gauge the performance of all three methods.