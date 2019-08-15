%% Script for formatting and error-checking UR within-subjects pilot data
% Formats data into one .mat file in a manner consistent with other sites.
% Quality-checks data. 

% Created using Matlab 2016b and the EEG Lab toolbox (version 4.1.2b). 
% Download EEG Lab here: https://sccn.ucsd.edu/eeglab/downloadtoolbox.php
% Script has not been tested on older or newer versions of Matlab.

%% Subject file information
% Assumes bdf filename has the form "da_sID_uniID_b#.bdf"
subj = {'klw_ur'}; % subject and university ID -- Can include multiple subjects here
block = {'run1','run2'}; % block -- Each subject must have 2 blocks, labeled "b1" and "b2"
site = 'UR';

%% Site-specific information
TriggerNums = [1, 2]; % Site-specific trigger numbers 
OtherTrigs = []; 

% Fixed delay between the onset of the trigger and the arrival of the
% stimulus as the insert ear probe.
FixedDelay_ms = 0; % Delay time at UR is already compensated for in the triggers.

%% INFORMATION THAT NEEDS TO BE EDITED TO RUN ON YOUR COMPUTER
folderName = '/labs/apclab/Lab_Files/Neuroimaging/Kelly/EEG/Within_Subj_Pilot/Within_Subj_Data/11)EEG_da'; % This should be the name of the folder with the subfolders of pilot data.

%% Store orignal path
% Running this script will change the path, so we want to save the name of 
% the original path in order to restore it when the script is finished 
% running.
original_path = path; % This is your current path

%% Load .mat data, qualty check, and concatinate into one matrix
for s = 1:size(subj,2) % for each subject
    for b = 1:size(block,2) % for each block
        
        fileName = strcat('da_',subj{s},'_',block{b},'.mat'); % File name of raw data
        
        load(strcat(folderName,'/',site,'/RawData/',fileName)); % load raw data
        % The first row of raw is Cz referenced to the left
        % auricular, while the second row is Cz referenced to the right
        % auricular.
    
        % Some parameter info from EEG data
        triggers = double(events(:,2)'); % format triggers to be consistent with other sites
        AllTrigs = unique(triggers); % The trigger numbers present in the file
        latency = double(events(:,1)'); % timing of trigger onset in samples; convert to double to match other sites
        Fs_UR = fs; % samplerate -- note this is higher than other sites
        
        % Quality-control check for UR data
        if sum(~ismember(AllTrigs,[TriggerNums,OtherTrigs])) >= 1  % Checks if there are any unexpected triggers.
            error(['Triggers can be any of the following: ' num2str([TriggerNums,OtherTrigs]) '. But this file has: ' num2str(AllTrigs)])
        elseif Fs_UR ~= 25000 % Sampleing rate at UR should be 25 kHz
            error(['Samplerate = ' num2str(Fs_UR) '! Sample rate should be 25000.'])
        elseif length(find(triggers==TriggerNums(1))) ~= 1500 || length(find(triggers==TriggerNums(2))) ~= 1500 % There should be 1500 trials per stimulus polarity.
            disp(['Trigger #' num2str(TriggerNums(1)) ': ' num2str(length(find(triggers==TriggerNums(1)))) ' trials'])
            disp(['Trigger #' num2str(TriggerNums(2)) ': ' num2str(length(find(triggers==TriggerNums(2)))) ' trials'])
            error('There are not the correct number of triggers in this data file!')
        end
        
        % Concatinate data
        if b == 1
            data.Subj = subj{s}; % subject_uniID info
            data.Record =  mean(raw).*1000000; % To get a linked earlobe reference, average the two channels; multiply by 1,000,000 to transform Volts to Microvolts.
            data.Triggers = triggers; % vector of triggers
            data.Latency = latency; % timing of trigger onset in samples
        else
            update_samples = size(data.Record,2); % trigger timings need to be updated by this many samples, since we are concatinating datasets
            data.Record = [data.Record, mean(raw).*1000000]; % concatinate most recent data onto earlier data
            data.Triggers = [data.Triggers, triggers]; % concatinate most recent block onto earlier block
            latency_new = update_samples + latency; % shift trigger onsets (in samples) by the length of the previous concatinated data
            data.Latency = [data.Latency, latency_new]; % concatinate timing of trigger onsets
        end
        
        if b == size(block,2) % If it is the last loop
            % Store useful information in a structure
            data.FixedDelay_ms = FixedDelay_ms; % Fixed delay between the onset of the trigger and the arrival of sound at the insert ear probe.
            data.Fs = Fs_UR; %  Sampling rate
            data.Labels = 'Cz'; % Label for active electrode
            data.SiteName = site;
            data.TotalDur_min = size(data.Record,2)/Fs_UR/60; % Total duration of recording (min)
            data.TriggerNums = TriggerNums; % stores the trigger numbers we want to use for preprocessing
        end
        
        clear raw triggers AllTrigs latency Fs_UR fs update_samples latency_new
    end
    
    %% Downsample data to match other sites
    
    fs_UR = data.Fs; % Origignal samplring rate at UR
    fs_All = 16384; % Sampling rate used at all other sites -- this is the maximum sampling rate for BioSemi.
    
    data.Record = resample(data.Record,fs_All,fs_UR); % Resampled data has a sampling rate of fs_All (16384)
    
    data.Fs = fs_All; % Store new sampling rate
    
    % IMPORTANT: Updates trigger onset times (in samples) to match new
    % sampling rate!!
    ratio = fs_All/fs_UR; % Ratio of the two sampling rates
    orig_Latency = data.Latency; % Original trigger onset times (in samples)
    data.Latency = floor(orig_Latency.*ratio); % Updated trigger onset times (in samples)
   
    resamp_dur_min = size(data.Record,2)/fs_All/60; % Total duration of resampled recording in seconds
    
    % Error check -- Ensures resampled UR data is the same duration as
    % original UR data.
    if round(resamp_dur_min,4) ~= round(data.TotalDur_min,4) % Checks if the resampled UR data is the same duration as original UR data.
        disp(['Original UR data duration: ' num2str(data.TotalDur_min) ' min'])
        disp(['Resampled UR data duration: ' num2str(resamp_dur_min) ' min'])
        error('Durations of original UR and resampled UR data do not match!')
    elseif round(data.Latency./fs_All,4) ~= round(orig_Latency./fs_UR,4)
        error('Trigger onset times of original and resampled UR data do not match!') % Throws an error if the trigger onset times (in seconds) of the original and resampled data do not match.
    end
    
    %% Additional quality checks
    inds_1 = find(data.Triggers == TriggerNums(1)); % indices of first trigger number
    inds_2 = find(data.Triggers == TriggerNums(2)); % indices of second trigger number
    inds = sort([inds_1,inds_2]);
    trig_dif_ms = diff(data.Latency(inds)/(data.Fs/1000)); % difference in onset times between connsecutive trigger trials (in ms)
    
    if true % Set to true for plotting; inter-trigger-intervals should be around 253 ms (170 + 83)
        figure
        hist(trig_dif_ms,1:400) % plot histogram of inter-trigger-intervals
        title(site)
        xlabel('Time between Consecutive Triggers (ms)')
        ylabel('Number of Triggers')
    end
    
    if(length(find(data.Triggers==data.TriggerNums(1))) ~= 3000) || (length(find(data.Triggers==data.TriggerNums(2))) ~= 3000) % There should be 3000 trials per stimulus polarity.
        disp(['Trigger #' num2str(data.TriggerNums(1)) ': ' num2str(length(find(data.Triggers==data.TriggerNums(1)))) ' trials'])
        disp(['Trigger #' num2str(data.TriggerNums(2)) ': ' num2str(length(find(data.Triggers==data.TriggerNums(2)))) ' trials'])
        error('There are not the correct number of triggers in this data file!')
    elseif data.Fs ~= 16384 % Sampleing rate should be 16384 -- Checks this again just in case resampling step was skipped by mistake.
        error(['Samplerate = ' num2str(Fs) '! Sample rate should be 16384.'])
    end
    
    %% Save referenced and resampled data
    rawAllFileName = [folderName, '/', site, '/da_RawReferenced/', strcat('da_',subj{s},'_rawAll.mat')]; % Location for saving raw data after referencing to earlobes in EEG lab
    % Saves the concatinated referenced data to a .mat file.
    disp('   Saving full referenced dataset to a MAT file...');
    save(rawAllFileName,'data', '-v7.3');
    disp(['      Referenced data saved as:  ' rawAllFileName]);
    
    clearvars -except s b subj folderName block site original_path TriggerNums OtherTrigs FixedDelay_ms
end

%% Restore original path
path(original_path) % Now your path is back where you started.
