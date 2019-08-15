% Formats, preprocesses, and plots within-subject pilot data for /da/ 
% experiment at each university site location.

% All preprocessing matches Parbery-Clark et al. (2009, JNeuro). Script run
% using Matlab 2016b and the EEGLAB toolbox (version 4.1.2b). Download EEG
% Lab here: https://sccn.ucsd.edu/eeglab/downloadtoolbox.php

% Code written by Kelly L. Whiteford
% Last modified on 8-13-19

%% Clean and format data for each site
% This section only needs to be run onced, then it can be commented out.

run clean_da_BU.m
run clean_da_CMU.m
run clean_da_PU.m
run clean_da_UMN.m
run clean_da_UR.m
run clean_da_UWO.m

%% INFORMATION THAT NEEDS TO BE EDITED TO RUN ON YOUR COMPUTER
folderName = '/labs/apclab/Lab_Files/Neuroimaging/Kelly/EEG/Within_Subj_Pilot/Within_Subj_Data/11)EEG_da'; % This should be the name of the folder with the subfolders of pilot data.
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
run preprocess_da

%% Plot within-subject, between-site data
siteNames = {'BU','CMU','PU','UMN','UR','UWO'};

% Plot time waveform averaged across epochs
figure('units','inch','position',[2,1,7.2,5]);
for uni = 1:size(siteNames,2)
    
    cd(['../../Within_Subj_Data/11)EEG_da/' siteNames{uni} '/da_Preprocessed_Cz/']) % Go to site folder with preprocessed data
    
    fileName = strcat('da_klw_', lower(siteNames{uni}), '_Cz.mat'); % Name of file for within-subject pilot
    
    load(fileName); % load preprocessed data

    subplot(3,2,uni)
    plotTime(Cz.SumAvg,Cz.Fs,'/da/',siteNames{uni})
    hold on
    cd '../../' % Go back to Data/11)EEG_da folder
    clear Cz % remove Cz structure from workspace
end

% Plot FFT of steady-state response
figure('units','inch','position',[2,1,7.2,5]);
for uni = 1:size(siteNames,2)
    cd(['./' siteNames{uni} '/da_Preprocessed_Cz/']) % Go to site folder with preprocessed data
    
    fileName = strcat('da_klw_', lower(siteNames{uni}), '_Cz.mat'); % Name of file for within-subject pilot
    
    load(fileName); % load preprocessed data
   
    subplot(3,2,uni)
    dataFFT(Cz.SumAvg,Cz.Fs,siteNames{uni});
    hold on
    cd '../../'
    clear Cz % remove Cz structure from workspace
end

%% Plot within-site, within-subject data
siteNames = {'UMN','UMN2'};

% Plot time waveform averaged across epochs
figure
for uni = 1:size(siteNames,2)
    
    cd('./UMN/da_Preprocessed_Cz/') % Go to site folder with preprocessed data
    
    switch siteNames{uni}
        case 'UMN'
            fileName = 'da_klw_umn_Cz.mat'; % Name of file for first UMN recording
        case 'UMN2'
            fileName = 'da_klw2_umn_Cz.mat'; % Name of file for second UMN recording
    end
    
    load(fileName); % load preprocessed data
  
    subplot(2,1,uni)
    plotTime(Cz.SumAvg,Cz.Fs,'/da/',siteNames{uni})
    hold on
    cd '../../' 
    clear Cz % remove Cz structure from workspace
end

% Plot FFT of steady-state response
figure
for uni = 1:size(siteNames,2)
    cd('./UMN/da_Preprocessed_Cz/') % Go to site folder with preprocessed data
    
    switch siteNames{uni}
        case 'UMN'
            fileName = 'da_klw_umn_Cz.mat'; % Name of file for within-subject pilot klw
        case 'UMN2'
            fileName = 'da_klw2_umn_Cz.mat'; % Name of file for second UMN recording
    end
    load(fileName); % load klw's preprocessed data
  
    subplot(2,1,uni)
    dataFFT(Cz.SumAvg,Cz.Fs,siteNames{uni});
    hold on
    cd '../../' 
    clear Cz % remove Cz structure from workspace
end

%% Calculate response-to-response correlations 
siteNames = {'BU','CMU','PU','UMN','UMN2','UR','UWO'};

% Load preprocessed data and place into dataCz structure
for uni = 1:size(siteNames,2)
    
    switch siteNames{uni}
        case {'UMN','UMN2'}
            cd('./UMN/da_Preprocessed_Cz/') % Go to site folder with preprocessed data
            
            if strcmp(siteNames{uni},'UMN')
                fileName = 'da_klw_umn_Cz.mat'; % Name of file for  first UMN recording
            else
                fileName = 'da_klw2_umn_Cz.mat'; % Name of file for second UMN recording
            end
            
        case {'BU','CMU','PU','UR','UWO'}
            cd(['./' siteNames{uni} '/da_Preprocessed_Cz/']) % Go to site folder with preprocessed data
            fileName = strcat('da_klw_', lower(siteNames{uni}), '_Cz.mat'); % Name of file for between-subject pilot
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