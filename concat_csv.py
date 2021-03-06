import pandas as pd 
import os
import argparse


def get_parser():
    parser = argparse.ArgumentParser()
    parser.add_argument("-p", "--path", required=True, help="Input folder (derivatives/labels obtained after run_prediction.sh).")
    return parser


def concat_csv(path):
    # path should be path to $PATH_RESULT/results/data/ following run_prediction 
    os.chdir(path)
    t = os.listdir("./")
    df_results = pd.concat([pd.read_csv(f, index_col="file", delimiter=';') for f in t ])
    df_t1 = df_results.loc[df_results['contrast'] == 't1']
    df_t2 = df_results.loc[df_results['contrast'] == 't2']
    df_t1['number_missed'] = df_t1.apply(lambda row : get_missed_total(row['label_missing']), axis=1)
    df_t2['number_missed'] = df_t2.apply(lambda row : get_missed_total(row['label_missing']), axis=1)
    x = df_t1['method'].iloc[0]
    df_t1.to_csv("metrics_t1_"+ x +".csv")
    df_t2.to_csv("metrics_t2_"+ x +".csv")
    x = df_t1['method'].iloc[0]
    print('Metric T1 '+ x)
    print(df_t1.describe())
    print('________________________________________\n')
    print('Metric T2 '+ x)
    print(df_t2.describe())


def get_missed_total(x):
    splited = x.split()
    for i in range (len(splited)):
        splited[i] = splited[i].strip('()[],')
    res = 0 
    for i in range(len(splited)):
        try:
            float(splited[i])
            res +=1
        except:
            pass
    return res



def main():
    parser = get_parser()
    args = parser.parse_args()
    concat_csv(args.path)


if __name__ == '__main__':
    main()

