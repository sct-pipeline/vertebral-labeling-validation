import os 
import shutil

def main(path_file, path_data, path_output):
    os.makedirs(path_output, exist_ok = True)
    with open(path_file, 'r') as f:
        subject = f.readlines()
        print(subject)
    for sub in subject:
        sub = sub.strip()
        print(sub)
        path_out_derivatives_tmp = os.path.join(path_output,'derivatives/labels/', sub, 'anat')
        path_out_tmp = os.path.join(path_output, sub, 'anat/')
        path_tmp_derivatives = os.path.join(path_data,'derivatives/labels/', sub, 'anat')
        path_tmp = os.path.join(path_data, sub, 'anat/')
        tmp = os.listdir(path_tmp_derivatives)
        os.makedirs(path_out_derivatives_tmp, exist_ok=True)
        os.makedirs(path_out_tmp, exist_ok=True)
        for x in tmp:
            if 'labels-disc-manual.nii.gz' in x:
                name_im_in = x[:-26]+'.nii.gz'
                print(x)
                if 't2' or 'T2' in x:
                    name_im_out = sub[:-1] +'_T2w.nii.gz'
                    name_gt_out = sub[:-1] + '_T2w_labels-disc-manual.nii.gz'
                elif 't1' or 'T1' in x:
                    name_im_out = sub[:-1] +'_T1w.nii.gz'
                    name_gt_out = sub[:-1] + '_T1w_labels-disc-manual.nii.gz'
                print(name_gt_out)
                shutil.copy(os.path.join(path_tmp_derivatives,x),os.path.join(path_out_derivatives_tmp,name_gt_out))
                shutil.copy(os.path.join(path_tmp,name_im_in), os.path.join(path_out_tmp,name_im_out))
