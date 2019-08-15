%% Script for formatting and error-checking UWO between-subjects pilot data
% Formats data into one .mat file in a manner consistent with other sites.
% Quality-checks data. 

% Created using Matlab 2016b and the EEG Lab toolbox (version 4.1.2b). 
% Download EEG Lab here: https://sccn.ucsd.edu/eeglab/downloadtoolbox.php
% Script has not been tested on older or newer versions of Matlab.

%% Subject file information
% Assumes bdf filename has the form "mi3_sID_uniID_b#.bdf"
subj = {'klw_uwo'}; % subject and university ID -- Can include multiple subjects here
block = {'b1_triggers','b2_triggers'}; % block -- UWO has one large file for each subject, but the trigger polarities are stored in separate files for each block
site = 'UWO';

%% Site-specific information
TriggerNums = [1 2]; % Site-specific trigger numbers 
OtherTrigs = []; % Other triggers indicating start/stop of blocks 
TriggerNums_bdf = 16; % Trigger numbers we want to get from the bdf file; NOTE that actual trigger polarities are stored in trigFile.

% Fixed delay between the onset of the trigger and the arrival of the
% stimulus as the insert ear probe.
FixedDelay_ms = 1.5; % UWO: Tube latency of insert earphones

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

%% Load data with EEG Lab, load trigger log file, and qualty check
for s = 1:size(subj,2) % for each subject
    fileName = strcat('mi3_',subj{s},'.bdf'); % File name of raw data
    
    % Load and reference data using EEG Lab.
    ALLEEG = eeglab;
    EEG = pop_biosig(strcat(folderName,'/',site,'/RawData/',fileName), 'ref',[17 18] ,'refoptions',{'keepref' 'on'}); % read in bdf data for all channels; reference to EXG1 and EXG2
    [ALLEEG, EEG] = pop_newset(ALLEEG, EEG, 0,'setname','raw','gui','off');
    EEG = eeg_checkset( EEG );
    EEG = pop_select( EEG,'nochannel',{'EXG1' 'EXG2' 'EXG3' 'EXG4' 'EXG5' 'EXG6' 'EXG7' 'EXG8'}); % Remove references and unused channels
    [ALLEEG, EEG] = pop_newset(ALLEEG, EEG, 1,'gui','off');
    close % Close the EEG Lab window- we don't need it.
    
    % Remove full raw dataset since we don't need it now
    ALLEEG(1) = [];
    
    % Some parameter info from EEG data
    triggers_bdf=cell2mat({ALLEEG.event.type}); % Make triggers a matrix. NOTE: Actual trigger polarities are located in trigFile for this site!
    latency = cell2mat({ALLEEG.event.latency}); % timing of trigger onset in samples
    Fs = ALLEEG.srate; % samplerate
    
    trig_16_inds = find(triggers_bdf == TriggerNums_bdf); % indices of events with trigger of 16
    
    % Quality check number of triggers in bdf.
    if trig_16_inds ~= 4800
        error([fileName ': This bdf has ' num2str(trig_16_inds) ' triggers but there should be 6000 triggers.'])
    end
    
    triggers = zeros(1,4800); % Real triggers will be stored here.
    
    %% Load triggers from log file
    for b = 1:size(block,2) % for each block
        trigFile = strcat(folderName,'/',site,'/RawData/Logs/mi3_',subj{s},'_',block{b},'.mat'); % File name of raw data
        
        load(trigFile); % load trigger polarities
        if b == 1
            triggers = polarity'; % store trigger polarities in triggers, consistent with other sites
        else
            triggers = [triggers, polarity']; % concatinate triggers into one vector
        end
    end
    
    AllTrigs = unique(triggers); % The trigger numbers present in the file
    
    % Quality-control check for UWO data
    if sum(~ismember(AllTrigs,[TriggerNums,OtherTrigs])) >= 1  % Checks if there are any unexpected triggers.
        error(['Triggers can be any of the following: ' num2str([TriggerNums,OtherTrigs]) '. But this file has: ' num2str(AllTrigs)])
    elseif Fs ~= 16384 % Sampleing rate should be 16384
        error(['Samplerate = ' num2str(Fs) '! Sample rate should be 16384.'])
    elseif length(find(triggers==TriggerNums(1))) ~= 2400 || length(find(triggers==TriggerNums(2))) ~= 2400 % There should be 2400 trials per stimulus polarity.
        disp(['Trigger #' num2str(TriggerNums(1)) ': ' num2str(length(find(triggers==TriggerNums(1)))) ' trials'])
        disp(['Trigger #' num2str(TriggerNums(2)) ': ' num2str(length(find(triggers==TriggerNums(2)))) ' trials'])
        error('There are not the correct number of triggers in this data file!')
    end
    
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
    
    rawAllFileName = [folderName, '/', site, '/mi3_RawReferenced/', strcat('mi3_',subj{s},'_rawAll.mat')]; % Location for saving raw data after referencing to earlobes in EEG lab
    % Saves the concatinated referenced data to a .mat file.
    disp('   Saving full referenced dataset to a MAT file...');
    save(rawAllFileName,'data', '-v7.3');
    disp(['      Referenced data saved as:  ' rawAllFileName]);
    
    clearvars -except s b subj folderName block site original_path TriggerNums OtherTrigs FixedDelay_ms
end

%% Restore original path
path(original_path) % Now your path is back where you started.
