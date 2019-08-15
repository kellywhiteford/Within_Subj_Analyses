%% Script for formatting and error-checking BU within-subjects pilot data
% Formats data into one .mat file in a manner consistent with other sites.
% Quality-checks data. 

% Created using Matlab 2016b and the EEG Lab toolbox (version 4.1.2b). 
% Download EEG Lab here: https://sccn.ucsd.edu/eeglab/downloadtoolbox.php
% Script has not been tested on older or newer versions of Matlab.

%% Subject file information
% Assumes bdf filename has the form "da_sID_uniID_b#.bdf"
subj = {'klw_bu'}; % subject and university ID -- Can include multiple subjects here
block = {}; % Not used -- BU has one large file for each subject
site = 'BU';

%% Site-specific information
TriggerNums = [32613, 32614]; % Site-specific trigger numbers 
OtherTrigs = 32512; % Other triggers indicating start/stop of blocks

% Fixed delay between the onset of the trigger and the arrival of the
% stimulus as the insert ear probe.
FixedDelay_ms = 1; % Delay for ER3-C earphones at BU

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

%% Load data with EEG Lab and qualty check
for s = 1:size(subj,2) % for each subject
    fileName = strcat('da_',subj{s},'.bdf'); % File name of raw data 
    
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
    
    % Qualtiy-control check for BU data
    if sum(~ismember(AllTrigs,[TriggerNums,OtherTrigs])) >= 1  % Checks if there are any unexpected triggers.
        disp(['Triggers can be any of the following: ' num2str([TriggerNums,OtherTrigs]) '. But this file has: ' num2str(AllTrigs)])
        %error(['Triggers can be any of the following: ' num2str([TriggerNums,OtherTrigs]) '. But this file has: ' num2str(AllTrigs)])  % REMOVED THIS LINE FOR NOW -- Extra trigger issue has been resolved after within-subjects pilot.
    elseif Fs ~= 16384 % Sampleing rate should be 16384
        error(['Samplerate = ' num2str(Fs) '! Sample rate should be 16384.'])
    elseif length(find(triggers==TriggerNums(1))) ~= 3000 || length(find(triggers==TriggerNums(2))) ~= 3000 % There should be 3000 trials per stimulus polarity.
        disp(['Trigger #' num2str(TriggerNums(1)) ': ' num2str(length(find(triggers==TriggerNums(1)))) ' trials'])
        disp(['Trigger #' num2str(TriggerNums(2)) ': ' num2str(length(find(triggers==TriggerNums(2)))) ' trials'])
        %error('There are not the correct number of triggers in this data file!') % Some triggers were overwritten by spurioius triggers leading to slightly smaller number of usable trials.
    end
    
    %% FOR BU WITHIN-SUBJECT PILOT ONLY!
    % This code is needed to remove extra trials that were administered 
    % when the earprobe became loose. This code only keeps the first and 
    % last set of 1500 trials for each stimulus polarity.
    
    [all_t1, i_t1] = find(triggers == TriggerNums(1)); % all trigger 32613 trials and their indices
    [all_t2, i_t2] = find(triggers == TriggerNums(2)); % all trigger 32614 trials and their indices
    
    i_t1_bad = i_t1(1501:end-1500); % indices of unwanted trigger 32613 trials
    i_t2_bad = i_t2(1501:end-1500); % indices of unwanted trigger 32614 trials
    
    triggers([i_t1_bad,i_t2_bad]) = []; % remove extra triggers between blocks 1 and 2
    latency([i_t1_bad,i_t2_bad]) = []; % adjust timing of trigger onsets so that the columns corresponding to extra triggers between blocks 1 and 2 are removed
    %% Store data and save
    
    % Store useful information in a structure
    data.Subj = subj{s}; % subject_uniID info
    data.Record = ALLEEG.data; % eeg data
    data.Triggers = triggers; % vector of triggers
    data.Latency = latency; % timing of trigger onset in samples
    data.FixedDelay_ms = FixedDelay_ms; % Fixed delay between the onset of the trigger and the arrival of sound at the insert ear probe.
    data.Fs = Fs; %  store sampling rate
    data.Labels = {ALLEEG.chanlocs.labels}'; % Label(s) for active electrode(s)
    data.SiteName = site;
    data.TotalDur_min = size(data.Record,2)/Fs/60; % Total duration of recording (min)
    data.TriggerNums = TriggerNums; % stores the trigger numbers we want to use for preprocessing
    
    % Additional quality check
    inds_1 = find(data.Triggers == TriggerNums(1)); % indices of first trigger number
    inds_2 = find(data.Triggers == TriggerNums(2)); % indices of second trigger number
    inds = sort([inds_1,inds_2]);
    trig_dif_ms = diff(data.Latency(inds)/(data.Fs/1000)); % difference in onset times between connsecutive trigger trials (in ms)
    
    if true % Set to true for plotting; inter-trigger-intervals should be around 253 ms (170 + 83)
        figure
        hist(trig_dif_ms,1:400) % plot histogram of inter-trigger-intervals; one large inter-trigger-interval will appear between blocks
        title(site)
        xlabel('Time between Consecutive Triggers (ms)')
        ylabel('Number of Triggers')
    end
    
    rawAllFileName = [folderName, '/', site, '/da_RawReferenced/', strcat('da_',subj{s},'_rawAll.mat')]; % Location for saving raw data after referencing to earlobes in EEG lab
    % Saves the concatinated referenced data to a .mat file.
    disp('   Saving full referenced dataset to a MAT file...');
    save(rawAllFileName,'data', '-v7.3');
    disp(['      Referenced data saved as:  ' rawAllFileName]);
    
    clearvars -except s subj folderName block site original_path TriggerNums OtherTrigs FixedDelay_ms
end