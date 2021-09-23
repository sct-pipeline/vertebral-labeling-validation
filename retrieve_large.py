import os 
import shutil
import argparse
import sys


def get_anat_dir(sub_dir):
    """
    This function takes a subject directory and retrieves the first `anat` directory it finds. (This is needed
    because sometimes the anat subdirectory is `sub-001/anat` and sometimes it's `sub-001/ses-001/anat`.)
    
    :return: subdirectory containing the string 'anat'
    :rtype: str
    """
    for root, dirs, _ in os.walk(sub_dir):
        for d in dirs:
            if 'anat' in os.path.join(root, d):
                return os.path.join(root, d)
    raise FileNotFoundError(f"No 'anat' directory found for {sub_dir}")


def main(path_file, path_data, path_output):
    os.makedirs(path_output, exist_ok = True)
    with open(path_file, 'r') as f:
        subject = f.readlines()
    for sub in subject:
        sub = sub.strip()
        path_in_derivatives = get_anat_dir(os.path.join(path_data, 'derivatives/labels/', sub))
        path_in = get_anat_dir(os.path.join(path_data, sub))
        for x in os.listdir(path_in_derivatives):
            if 'labels-disc-manual.nii.gz' in x:
                name_im_in = x[:-26]+'.nii.gz'
                if 't2' in x.lower():
                    name_im_out = sub + '_T2w.nii.gz'
                    name_gt_out = sub + '_T2w_labels-disc-manual.nii.gz'
                elif 't1' in x.lower():
                    name_im_out = sub + '_T1w.nii.gz'
                    name_gt_out = sub + '_T1w_labels-disc-manual.nii.gz'
                print(f"Copying files for {sub}.")
                path_out_derivatives_tmp = os.path.join(path_output, 'derivatives/labels/', sub, 'anat')
                path_out_tmp = os.path.join(path_output, sub, 'anat')
                os.makedirs(path_out_derivatives_tmp, exist_ok=True)
                os.makedirs(path_out_tmp, exist_ok=True)
                shutil.copy(os.path.join(path_in_derivatives, x),
                            os.path.join(path_out_derivatives_tmp, name_gt_out))
                shutil.copy(os.path.join(path_in, name_im_in),
                            os.path.join(path_out_tmp, name_im_out))


def get_parser():
    parser = argparse.ArgumentParser()
    parser.add_argument("-i", "--input", required=True, dest="i", type=str, help="""path to the sct_testing/large folder with downloaded folder """)
    parser.add_argument("-l",'--list', required=True, dest="list", help="""Path to the list of subjects that have been downloaded""")
    parser.add_argument("-o", "--output", required=False, dest="o", type=str, help="""Output path.""")
    return parser


if __name__ == '__main__':
    parser = get_parser()
    args = parser.parse_args(args=None if sys.argv[1:] else ['--help'])
    main(args.list,args.i,args.o)
