import pandas as pd 
import os
import argparse


def get_parser():
    parser = argparse.ArgumentParser()
    parser.add_argument("-p", "--path", required=True, help="Input folder (derivatives/labels obtained after run_prediction.sh).")
    return parser


def concat_csv(path):
    # path should be path to $PATH_RESULT/results/data/derivatives/labels following run_prediction 
    os.chdir(path)
    t = os.listdir("./")
    df_results = pd.concat([pd.read_csv(os.path.join(f,"anat","result.csv"), index_col="file") for f in t ])
    df_t1 = df_results.loc[df_results['contrast'] == 't1']
    df_t2 = df_results.loc[df_results['contrast'] == 't2']
    df_t1.to_csv("metrics_t1.csv")
    df_t2.to_csv("metrics_t2.csv")


def main():
    parser = get_parser()
    args = parser.parse_args()
    concat_csv(args.path)


if __name__ == '__main__':
    main()

