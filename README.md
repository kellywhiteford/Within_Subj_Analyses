# Within_Subj_Analyses
Single-channel EEG preprocessing and analysis code for one subject at 6 site locations. The raw data and preregistration protocol associated with this code are available at https://osf.io/duq34/. 

# Requirements
- [EEGLAB (version 14.1.2b)](https://sccn.ucsd.edu/eeglab/download.php)  
- [Matlab 2016b](https://www.mathworks.com/)  
- mi3.wav is required for the F0-tracking analysis from Wong et al. (2007, Nature Neuroscience) and is not provided here. Contact the [Auditory Neuroscience Laboratory](https://brainvolts.northwestern.edu/) if you would like to request access to their stimulus. This stimulus should be saved in the `AnalysisFunctions` folder before running `12)EEG_mi3/run_withinPilot_mi3.m`. 

# Getting Started
1. Read the methods and single-channel analysis plan in the preregistration for background details (https://osf.io/duq34/).
2. Download the within-subject pilot data from OSF (https://osf.io/duq34/). 
3. The code assumes the folder `Within_Subj_Data`, along with its subfolders, is stored in the same directory as the `Within_Subj_Analyses` folder. 
4. Start with the script `11)EEG_da/run_withinPilot_da.m` for the phoneme in noise experiment and `12)EEG_mi3/run_withinPilot_mi3.m` for the linguistic pitch experiment. Note that the variables `folderName` and `eegLabFolder` will need to be edited to run on your computer. You may want to comment out the "Clean and format" and "Preprocess data" sections if running on a computer with less than 64 GB of RAM.

