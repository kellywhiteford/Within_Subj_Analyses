% Formats, preprocesses, and plots within-subject pilot data for /mi3/ 
% experiment at each university site location.

% All preprocessing matches Wong et al. (2007, Nature Neuro.). Script run
% using Matlab 2016b and the EEGLAB toolbox (version 4.1.2b). Download EEG
% Lab here: https://sccn.ucsd.edu/eeglab/downloadtoolbox.php

% Code written by Kelly L. Whiteford
% Last modified on 8-13-19

%% Clean and format data for each site
% This section only needs to be run onced, then it can be commented out.

run clean_mi3_BU.m
run clean_mi3_CMU.m
run clean_mi3_PU.m
run clean_mi3_UMN.m
run clean_mi3_UR.m
run clean_mi3_UWO

%% INFORMATION THAT NEEDS TO BE EDITED TO RUN ON YOUR COMPUTER
folderName = '/labs/apclab/Lab_Files/Neuroimaging/Kelly/EEG/Within_Subj_Pilot/Within_Subj_Data/12)EEG_mi3'; % This should be the name of the folder with the subfolders of pilot data.
eegLabFolder = '/labs/apclab/Lab_Files/Neuroimaging/Kelly/eeglab14_1_2b'; % Add path name for EEG Lab folder

%% Store orignal path
% Running this script will change the path, so we want to save the name of 
% the original path in order to restore it when the script is finished 
% running.
original_path = path; % This is your current path

%% Set path so folders we need are on top.
addpath(eegLabFolder,'-begin') % Add EEG Lab to top of search path

analysisFolder = '../AnalysisFunctions'; % The folder with the custom analysis functions to be used.
addpath(analysisFolder,'-begin'); % Analysis folder is now at the top of the path. Functions in this folder will take priority over all other functions with the same name.

%% Preprocess data for each site
% This section only needs to be run onced, then it can be commented out.
run preprocess_mi3

%% Plot within-subject, between-site data
siteNames = {'BU','CMU','PU','UMN','UR','UWO'};

% Plot time waveform averaged across epochs
figure
for uni = 1:size(siteNames,2)
    
    cd(['../../Within_Subj_Data/12)EEG_mi3/' siteNames{uni} '/mi3_Preprocessed_Cz/']) % Go to site folder with preprocessed data
    
    fileName = strcat('mi3_klw_', lower(siteNames{uni}), '_Cz.mat'); % Name of file for within-subject pilot
    
    load(fileName); % load preprocessed data

    subplot(3,2,uni)
    plotTime(Cz.SumAvg,Cz.Fs,'/mi3/',siteNames{uni})
    hold on
    cd '../../' % Go back to Data/12)EEG_mi3 folder
end

%% Plot within-site, within-subject data
siteNames = {'UMN','UMN2'};

% Plot time waveform averaged across epochs
figure
for uni = 1:size(siteNames,2)
    
    cd('./UMN/mi3_Preprocessed_Cz/') % Go to site folder with preprocessed data
    
    switch siteNames{uni}
        case 'UMN'
            fileName = 'mi3_klw_umn_Cz.mat'; % Name of file for first UMN recording
        case 'UMN2'
            fileName = 'mi3_klw2_umn_Cz.mat'; % Name of file for second UMN recording
    end
    
    load(fileName); % load preprocessed data
  
    subplot(2,1,uni)
    plotTime(Cz.SumAvg,Cz.Fs,'/mi3/',siteNames{uni})
    hold on
    cd '../../'  
end

%% Resample stimulus to have same sampling rate as EEG data
[stimulus, Fs_stim] = audioread('mi3.wav'); % load stimulus
stim = resample(stimulus,16384,Fs_stim); % Resampled stim has a sampling rate of Fs (16384)
stim = stim';

%% Plot Pitch Tracking for Between-Site, Within-Subject Data
siteNames = {'BU','CMU','PU','UMN','UR','UWO'};
all_f0Max = zeros(length(siteNames),238);
f0_stimToResp = zeros(1,length(siteNames));

figure
for uni = 1:size(siteNames,2)
    
    cd (['./' siteNames{uni} '/mi3_Preprocessed_Cz/']) % Go to site folder with preprocessed data
    
    fileName = strcat('mi3_klw_', lower(siteNames{uni}), '_Cz.mat'); % Name of file for within-subject pilot
    
    load(fileName); % load preprocessed data
    
    subplot(3,2,uni)
    [f0Max_stim, f0amp_avg_stim, allFFT_mag_stim] = slidingFFT_mi3(stim,0.*Cz.SumAvg_Baseline,Cz.Fs,0,'yes'); % sliding FFT on stimulus
    hold on
    [f0Max, f0amp_avg] = slidingFFT_mi3(Cz.SumAvg,Cz.SumAvg_Baseline,Cz.Fs,Cz.FixedDelay_ms,'no'); % sliding FFT on EEG response
    title(siteNames{uni},'FontSize',7)
    
    all_f0Max(uni,:) = f0Max; % store F0max for all sites
    
    cd '../../' 
    f0_stimToResp(uni) = round(corr(all_f0Max(uni,:)',f0Max_stim'),3); % F0 tracking stimulus-to-response correlation
end


%% Plot Pitch Tracking for Within-Site, Within-Subject Data
siteNames = {'UMN','UMN2'};
all_f0Max_W = zeros(length(siteNames),238);
f0_stimToResp_W = zeros(1,length(siteNames));

figure
for uni = 1:size(siteNames,2)
    cd('./UMN/mi3_Preprocessed_Cz/') % Go to site folder with preprocessed data
    
    switch siteNames{uni}
        case 'UMN'
            fileName = 'mi3_klw_umn_Cz.mat'; % Name of file for first UMN recording
        case 'UMN2'
            fileName = 'mi3_klw2_umn_Cz.mat'; % Name of file for second UMN recording
    end
    
    load(fileName); % load klw's preprocessed data
    
    subplot(2,1,uni)
    [f0Max_stim, f0amp_avg_stim, allFFT_mag_stim] = slidingFFT_mi3(stim,0.*Cz.SumAvg_Baseline,Cz.Fs,0,'yes'); % sliding FFT on stimulus
    hold on
    [f0Max, f0amp_avg, allFFT_mag] = slidingFFT_mi3(Cz.SumAvg,Cz.SumAvg_Baseline,Cz.Fs,Cz.FixedDelay_ms,'no'); % sliding FFT on EEG response
    title(siteNames{uni},'FontSize',7)
    
    all_f0Max_W(uni,:) = f0Max; % store F0max for all sites
    
    cd '../../'
    f0_stimToResp_W(uni) = round(corr(all_f0Max_W(uni,:)',f0Max_stim'),3); % F0 tracking stimulus-to-response correlation
end

    

%% Calculate response-to-response correlations 
siteNames = {'BU','CMU','PU','UMN','UMN2','UR','UWO'};

% Load preprocessed data and place into dataCz structure
for uni = 1:size(siteNames,2)
    
    switch siteNames{uni}
        case {'UMN','UMN2'}
            cd('./UMN/mi3_Preprocessed_Cz/') % Go to site folder with preprocessed data
            
            if strcmp(siteNames{uni},'UMN')
                fileName = 'mi3_klw_umn_Cz.mat'; % Name of file for  first UMN recording
            else
                fileName = 'mi3_klw2_umn_Cz.mat'; % Name of file for second UMN recording
            end
            
        case {'BU','CMU','PU','UR','UWO'}
            cd(['./' siteNames{uni} '/mi3_Preprocessed_Cz/']) % Go to site folder with preprocessed data
            fileName = strcat('mi3_klw_', lower(siteNames{uni}), '_Cz.mat'); % Name of file for between-subject pilot
    end
    
    load(fileName); % load klw's preprocessed data
    dataCz.(siteNames{uni}) = Cz.SumAvg;
    cd ../../ % Go back to EEG folder
end

corrMat = zeros(length(siteNames),length(siteNames));
for u = 1:length(siteNames)
    for uni = 1:length(siteNames)
        rs = xcorr(dataCz.(siteNames{u})',dataCz.(siteNames{uni})','coeff'); % Cross-correlations for all lag times
        best_corr = round(max(rs),3);
        corrMat(u,uni) = best_corr;
    end
end

cd ../../
%% Restore original path
path(original_path) % Now your path is back where you started. Hooray! :)