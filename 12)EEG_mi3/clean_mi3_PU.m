%% Script for formatting and error-checking PU within-subjects pilot data
% Formats data into one .mat file in a manner consistent with other sites.
% Quality-checks data. 

% Created using Matlab 2016b and the EEG Lab toolbox (version 4.1.2b). 
% Download EEG Lab here: https://sccn.ucsd.edu/eeglab/downloadtoolbox.php
% Script has not been tested on older or newer versions of Matlab.

%% Subject file information
% Assumes bdf filename has the form "mi3_sID_uniID_b#.bdf"
subj = {'klw_pu'}; % subject and university ID -- Can include multiple subjects here
block = {'','+001','+002','+003'}; % block -- PU system chunks data into bdf files < 1.05 GB 
site = 'PU';

%% Site-specific information
TriggerNums = [65281, 65282]; % Site-specific trigger numbers 
OtherTrigs = [65533,65280]; % Other triggers indicating start/stop of blocks -- 65533 indicates the start of recording; 65280 indicates either (1) end of a block or (2) start of a new recording in the middle of a block

% Fixed delay between the onset of the trigger and the arrival of the
% stimulus as the insert ear probe.
FixedDelay_ms = 1.6; % PU delay

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

%% Load data with EEG Lab, qualty check, and concatinate into one matrix
for s = 1:size(subj,2) % for each subject
    for b = 1:size(block,2) % for each block
        
        fileName = strcat('mi3_',subj{s},block{b},'.bdf'); % File name of raw data
        
        % Load and reference data using EEG Lab.
        ALLEEG = eeglab;
        EEG = pop_biosig(strcat(folderName,'/',site,'/RawData/',fileName), 'ref',[33 34] ,'refoptions',{'keepref' 'on'}); % read in bdf data for all channels; reference to EXG1 and EXG2
        [ALLEEG, EEG] = pop_newset(ALLEEG, EEG, 0,'setname','raw','gui','off');
        EEG = eeg_checkset( EEG );
        EEG = pop_select( EEG,'nochannel',{'EXG1','EXG2','EXG3' 'EXG4' 'EXG5' 'EXG6' 'EXG7' 'EXG8'}); % Remove references and unused channels
        [ALLEEG, EEG] = pop_newset(ALLEEG, EEG, 1,'gui','off');
        close % Close the EEG Lab window- we don't need it.
        
        % Remove full raw dataset since we don't need it now
        ALLEEG(1) = [];
        
        % Some parameter info from EEG data
        triggers=cell2mat({ALLEEG.event.type}); % Make triggers a matrix
        AllTrigs = unique(triggers); % The trigger numbers present in the file
        latency = cell2mat({ALLEEG.event.latency}); % timing of trigger onset in samples
        Fs = ALLEEG.srate; % samplerate
        
        % Quality-control check for PU data
        if sum(~ismember(AllTrigs,[TriggerNums,OtherTrigs])) >= 1  % Checks if there are any unexpected triggers.
            error(['Triggers can be any of the following: ' num2str([TriggerNums,OtherTrigs]) '. But this file has: ' num2str(AllTrigs)])
        elseif Fs ~= 16384 % Sampleing rate should be 16384
            error(['Samplerate = ' num2str(Fs) '! Sample rate should be 16384.'])
        end
        
        % Concatinate data
        if b == 1
            data.Subj = subj{s}; % subject_uniID info
            data.Record = ALLEEG.data; % eeg data 
            data.Triggers = triggers; % vector of triggers
            data.Latency = latency; % timing of trigger onset in samples
        else
            update_samples = size(data.Record,2); % trigger timings need to be updated by this many samples, since we are concatinating datasets
            data.Record = [data.Record, ALLEEG.data]; % concatinate most recent data onto earlier data
            data.Triggers = [data.Triggers, triggers]; % concatinate most recent block onto earlier block
            latency_new = update_samples + latency; % shift trigger onsets (in samples) by the length of the previous concatinated data
            data.Latency = [data.Latency, latency_new]; % concatinate timing of trigger onsets
        end
        
        if b == size(block,2) % If it is the last loop
            % Store useful information in a structure
            data.FixedDelay_ms = FixedDelay_ms; % Fixed delay between the onset of the trigger and the arrival of sound at the insert ear probe.
            data.Fs = Fs; %  Sampling rate
            data.Labels = {ALLEEG.chanlocs.labels}'; % Label(s) for active electrode(s)
            data.SiteName = site;
            data.TotalDur_min = size(data.Record,2)/Fs/60; % Total duration of recording (min)
            data.TriggerNums = TriggerNums; % stores the trigger numbers we want to use for preprocessing
        end
        
        clear ALLEEG EEG CURRENTSET CURRENTSTUDY LASTCOM triggers AllTrigs latency Fs update_samples latency_new
    end
    
    
    % Additional quality checks
    inds_1 = find(data.Triggers == TriggerNums(1)); % indices of first trigger number
    inds_2 = find(data.Triggers == TriggerNums(2)); % indices of second trigger number
    inds = sort([inds_1,inds_2]);
    trig_dif_ms = diff(data.Latency(inds)/(data.Fs/1000)); % difference in onset times between connsecutive trigger trials (in ms)
    
    if true % Set to true for plotting; inter-trigger-intervals should be around 361.5 ms (278.5 + 83)
        figure
        hist(trig_dif_ms,1:400) % plot histogram of inter-trigger-intervals; one large inter-trigger-interval will appear between blocks
        title(site)
        xlabel('Time between Consecutive Triggers (ms)')
        ylabel('Number of Triggers')
    end
    
    if(length(find(data.Triggers==data.TriggerNums(1))) ~= 2400) || (length(find(data.Triggers==data.TriggerNums(2))) ~= 2400) % There should be 2400 trials per stimulus polarity.
        disp(['Trigger #' num2str(data.TriggerNums(1)) ': ' num2str(length(find(data.Triggers==data.TriggerNums(1)))) ' trials'])
        disp(['Trigger #' num2str(data.TriggerNums(2)) ': ' num2str(length(find(data.Triggers==data.TriggerNums(2)))) ' trials'])
        error('There are not the correct number of triggers in this data file!')
    end
    
    rawAllFileName = [folderName, '/', site, '/mi3_RawReferenced/', strcat('mi3_',subj{s},'_rawAll.mat')]; % Location for saving raw data after referencing to earlobes in EEG lab
    % Saves the concatinated referenced data to a .mat file.
    disp('   Saving full referenced dataset to a MAT file...');
    save(rawAllFileName,'data', '-v7.3');
    disp(['      Referenced data saved as:  ' rawAllFileName]);
    
    clearvars -except s b subj folderName block site original_path TriggerNums OtherTrigs FixedDelay_ms
end

%% Restore original path
path(original_path) % Now your path is back where you started.

%clear all