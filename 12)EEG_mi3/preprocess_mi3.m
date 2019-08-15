%% Script for preprocessing within-subjects pilot data 
% All preprocessing matches Wong et al. (2007, Nature Neuro.). 

%% University file information
siteNames = {'BU','CMU','PU','UMN','UR','UWO'};

%% Parameters for preprocessing -- These are the same for each site.
%Filter parameters
N = 2; % Filter order; 2 corresponds to 12 dB/Oct
Fc1 = 80; % Lower-frequency cutoff (Hz)
Fc2 = 1000; % Higher-frequency cutoff (Hz)

% Artifact removal parameters
cutOff = 35; % Absolute value threshold for removing /da/ trials with artifacts (microvolts)

% Epoch parameters
baseline_start_in_ms = -45; % Where baseline epoch starts (ms)
start_in_ms = 0; % Time of stimulus onset in epoch (ms)
stop_in_ms = 295; % End time of epoch (ms)

%% Preprocess all subjects at each university 
for uni = 1:length(siteNames)
    
    cd(['../../Within_Subj_Data/12)EEG_mi3/',siteNames{uni},'/mi3_RawReferenced'])
    Files=dir('*.*'); % Lists all data file names
    
    % Preallocate string arrays with no characters
    subj_file = strings([1,length(Files)-2]);
    subj = strings([1,length(Files)-2]);
    
    for k=3:length(Files)
        subj_file{k-2} = Files(k).name; % subject-specific file name
        subj(k-2) = extractBefore(extractAfter(subj_file{k-2},'mi3_'),'_rawAll.mat'); % subj_uni ID
    end

    for s = 1:size(subj,2)
        
        load(subj_file{s});
        output_file = strcat('../mi3_Preprocessed/mi3_',subj{s},'_all.mat');
        output_file_Cz = strcat('../mi3_Preprocessed_Cz/mi3_',subj{s},'_Cz.mat');
        
        data.EventTimingParams = [baseline_start_in_ms start_in_ms stop_in_ms];
        data.FilterParams = [N Fc1 Fc2];
        data.ArtifactThreshold = cutOff;
        
        %% Filter raw EEG data
        % Setting the last input of filtEEG to 'yes' will plot the filters 
        % and their impulse response.
        data.Record = filtEEG(data.Record,Fc1,Fc2,N,data.Fs,'no'); % Performs bandpass butterworth filtering with zero-phase shift.
        
        %% Epoch, artifact reject, and baseline EEG data
        % Setting the last variable to 'yes' in preprocess will plot the
        % preprocessed average data for each trigger.
        [Data, Cz] = preprocess(data,'yes');
        
        %% Save preprocessed data
        % Save analyzed data for Cz:
        disp('   Saving analyzed data to a MAT file...');
        save(output_file_Cz,'Cz');
        disp('      Analyzed data saved as:  ');
        disp(['         ', output_file_Cz]);
        
        % Save analyzed data for all electrodes: UNCOMMENT this section to
        % save Data, the full set of preprocessed electrodes. This is not 
        % currently used for anything.
        % disp('   Saving analyzed data to a MAT file...');
        % save(output_file,'Data','-v7.3');
        % disp('      Analyzed data saved as:  ');
        % disp(['         ', output_file, '.mat']);
        
        %% Clear all variables except a few that we need
        clearvars -except uni s N Fc1 Fc2 cutOff baseline_start_in_ms start_in_ms stop_in_ms folderName original_path siteNames subj_file subj
    end
    
    %% Go back to correct Analyses folder
    cd ../../../../Within_Subj_Analyses/12)EEG_mi3
end
clearvars -except folderName original_path siteNames


