Repository containing scripts to evaluate sct\_vertebral\_labeling due to new changes. 
Evaluation will be performed on spine-generic/data-multi-subjects

to use run sct_run_batch -c parameters/<name of config file>
  
  
The first script named `prepare_seg_and_gt.sh` is used with the `parameters/prepare_seg_gt.yml` config file. It aims at projecting the ground truth, which are label on the posterior side of the disc, to the center of the spinal cord. 
The second script named `run_prediction.sh` is used with the `parameters/run_prediction.yml` config file. It aims at running sct_label_vertebrae prediction and comparing that to the ground truth using `sct_label_utils`'s MSE option. The results is then saved in a csv file in the derivatives.

