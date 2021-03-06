#!/bin/bash
#$ -cwd -S /bin/bash
#$ -l mem=10G
#$ -l time=:10000:
#$ -M eag2186@cumc.columbia.edu

$MODULESHOME/init/bash
module load matlab/2018a

clear

matlab -nojvm -nodisplay -nosplash  -singleCompThread -nodesktop  -logfile "/ifs/scratch/msph/ehs/eag2186/pcp/log-all{$SGE_TASK_ID}"  -r "run /ifs/scratch/msph/ehs/eag2186/pcp/pcp_ad_rho.m"


