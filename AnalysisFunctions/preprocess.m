% Epochs, artifact rejects, and baselines raw data according to the
% parameters defined in the global variables. Preprocessing is for all
% channels. 

function [D, Cz] = preprocess(DATA,makePlot)
% Input
% DATA    : Structure of filtered EEG data.
% makePlot: Set to 'yes' to plot the results.

% Output
% D  : Structure of preprocessed EEG data.
% Cz : Structure of preprocessed EEG data for Cz only.


%% Define some parameters
Fs = DATA.Fs;
baseline_start_in_ms = DATA.EventTimingParams(1);
start_in_ms = DATA.EventTimingParams(2);
stop_in_ms = DATA.EventTimingParams(3);
cutOff = DATA.ArtifactThreshold;

if isempty(find(strcmp(DATA.Labels,'A32'),1))
    Cz_ind = find(strcmp(DATA.Labels,'Cz')); % index for electrode Cz with 1- or 16-channel cap
else
    Cz_ind = find(strcmp(DATA.Labels,'A32')); % index for electrode Cz with 32-channel cap
end

extraTrigs = setdiff(unique(DATA.Triggers),DATA.TriggerNums); % Triggers we don't need

CzEventCount = 0; % counts trials where Cz is artifact free
MasterEventCount = 0; % counts artifact-free trials for all-electrode analyses
badCount = 0; % counts trials with artifacts during the epoch
badCzCount = 0; % counts trials with artifacts during the epoch for electrode Cz only
transCount = 0; % counts trials that might have a transient from filtfilt
noDataTrial = 0; % counts trials where the EEG recording was stopped before the entire stimulus was presented

Cz_eventCount_t1 = 0; % counts usable Cz trials for first trigger number
Cz_eventCount_t2 = 0; % counts usable Cz trials for second trigger number
eventCount_t1 = 0; % counts usable trials for first trigger number
eventCount_t2 = 0; % counts usable trials for second trigger number

n_trig1 = length(find(DATA.Triggers==DATA.TriggerNums(1))); % number of trials for first trigger number
n_trig2 = length(find(DATA.Triggers==DATA.TriggerNums(2))); % number of trials for second trigger number

%% Preprocess
for a = 1:length(DATA.Triggers) % For each trigger event
    trig = DATA.Triggers(a); % Trigger number for this event
    
    if ~ismember(trig, extraTrigs) % Only keep events where stimulus was presented (i.e., ignore start/stop triggers)
        baseline_start_time = DATA.Latency(a)+round(Fs*baseline_start_in_ms/1000); % baseline for trial (in samples)
        start_time = DATA.Latency(a)+round(Fs*start_in_ms/1000); % stimulus start time for trial (in samples)
        stop_time =  DATA.Latency(a)+round(Fs*stop_in_ms/1000); % end of epoch for trial (in samples)
        
        if stop_time < length(DATA.Record) % Only keep trials where EEG data was still being recorded during epoch
            
            if baseline_start_time > 400 && (length(DATA.Record) - stop_time) > 400 % Throws out first/last trials if there's not enough padding (i.e., due to transients from filtEEG)
                
                if max(abs(DATA.Record(Cz_ind,baseline_start_time:stop_time))) < cutOff % Only keep data events where Cz is below artifact threshold (necessary for single-electrode analyses)
                    CzEventCount = CzEventCount + 1; % Number of  trials where Cz is artifact free
                    
                    switch trig
                        case DATA.TriggerNums(1)
                            Cz_eventCount_t1 = Cz_eventCount_t1 + 1; % Number of Cz artifact-free trials for first trigger number
                        case DATA.TriggerNums(2)
                            Cz_eventCount_t2 = Cz_eventCount_t2 + 1; % Number of Cz artifact-free trials for second trigger number
                    end
                    
                    % NOTE: EEG lab already referenced data, so now we're just
                    % basleining relative to activity in the prestimulus period
                    baseline_Cz = DATA.Record(Cz_ind,baseline_start_time:DATA.Latency(a)-1); % Activity during baseline
                    
                    % Epoch for Cz only
                    Cz.Epoched(1,:,CzEventCount) = DATA.Record(Cz_ind,start_time:stop_time) - mean(baseline_Cz);   %Activity at active Cz during stimulus minus average Cz activity during baseline
                    Cz.Baseline(1,:,CzEventCount) = baseline_Cz - mean(baseline_Cz); % Store baseline activity for each event
                    Cz.Triggers(1,CzEventCount) = trig; % Store trigger for each event
                    
                    % Check for artifacts across all electrodes
                    if max(abs(DATA.Record(:,baseline_start_time:stop_time))) < cutOff % Only keep data events where all electrodes are below artifact threshold
                        MasterEventCount = MasterEventCount + 1; % Number of artifact-free trials
                        
                        switch trig
                            case DATA.TriggerNums(1)
                                eventCount_t1 = eventCount_t1 + 1; % Number of artifact-free trials for first trigger number
                            case DATA.TriggerNums(2)
                                eventCount_t2 = eventCount_t2 + 1; % Number of artifact-free trials for second trigger number
                        end
                        
                        % NOTE: EEG lab already referenced data, so now we're just
                        % basleining relative to activity in the prestimulus period
                        baseline = DATA.Record(:,baseline_start_time:DATA.Latency(a)-1); % Activity during baseline
                        
                        % Epoch for all electrodes
                        D.Epoched(:,:,MasterEventCount) = DATA.Record(:,start_time:stop_time) - mean(baseline,2);  %Activity at active electrodes during stimulus minus average activity during baseline
                        D.Baseline(:,:,MasterEventCount) = baseline - mean(baseline,2); % Store baseline activity for each event
                        D.Triggers(1,MasterEventCount) = trig; % Store trigger for each event
                    else
                        badSweep = max(max(abs(DATA.Record(:,baseline_start_time:stop_time)))); % the absolute value of the worst artifact in microvolts
                        disp(['Trial #' num2str(a) ' of trigger ' num2str(trig) ' has artifact of +- ' num2str(badSweep) ' \muVs.']) % print bad trial info to command window
                        badCount = badCount + 1; % count the bad trial
                    end
                    
                else
                    badCz = max(abs(DATA.Record(Cz_ind,baseline_start_time:stop_time)));
                    disp(['Cz Trial #' num2str(a) ' of trigger ' num2str(trig) ' has artifact of +- ' num2str(badCz) ' \muVs.']) % print bad trial info to command window
                    badCzCount = badCzCount + 1;   
                end
                
            else
                % Transient removed
                disp(['Trial #' num2str(a) ' of trigger ' num2str(trig) ' was removed due to transient from filtering.']) % First/last epochs are removed if there's not enough padding before/after.
                transCount = transCount + 1;
            end
        else
            disp(['Trial #' num2str(a) ' of trigger ' num2str(trig) ' did not have any EEG data recorded.']) % This can happen if recording is paused right after the last trigger is presented.
            noDataTrial = noDataTrial + 1; % count the trial with missing EEG data
        end
    end
end

%% Store info and display in command window
% Info for single-electrode analyses
Cz.UsableEvents = CzEventCount; % total number of usable events for Cz
Cz.NumEvents = n_trig1 + n_trig2; % total number of trials presented to the subject
Cz.UsablePercentage = Cz.UsableEvents/Cz.NumEvents * 100; % Percentage of artifact-free trials for single-electrode analysis
Cz.Fs = DATA.Fs; % samplerate
Cz.FixedDelay_ms = DATA.FixedDelay_ms; % Fixed delay between the onset of the trigger and the arrival of the stimulus as the insert ear probe.
Cz

% Info for all-electrode analyses
D.UsableEvents = MasterEventCount; % total number of usable events for full-electrode analyses
D.NumEvents = n_trig1 + n_trig2; % total number of trials presented to the subject
D.UsablePercentage = D.UsableEvents/D.NumEvents * 100; % Percentage of artifact-free trials for full-electrode analysis
D.Fs = DATA.Fs; % samplerate
D

NumberBadCzTrails = badCzCount
NumberBadTrials = badCount
NumberMissingDataTrials = noDataTrial
NumberTransientsRemoved = transCount

if MasterEventCount == 0
    disp('   ');
    disp('   ');
    disp(' *** There were no usable events.  Please check all analysis parameters. ***');
    disp('   ');
    disp(' Suggestions for troubleshooting: ');
    disp('  Check that the electrode numbers and trigger numbers are correct.');
    disp('  Check filtering parameters and/or artifact removal threshold.');
    disp('  Check DATA.Triggers to see if triggers are actually present in the file.');
    disp('   ');
    error(' *** Empty dataset after processing. ***');
end


%% Single-electrode analysis
% Takes the average across all events for each stimulus polarity. The sum 
% of these averages is taken across the two polarities to remove artifacts. 

t1_ind = find(Cz.Triggers == DATA.TriggerNums(1)); % indices of trigger 1 events
t2_ind = find(Cz.Triggers == DATA.TriggerNums(2)); % indices of trigger 2 events

% Avg activity during stimulus presentation for each trigger
avgT1 = mean(Cz.Epoched(:,:,t1_ind),3); % Trigger 1: Average across events
avgT2 = mean(Cz.Epoched(:,:,t2_ind),3); % Trigger 2: Average across events

% Avg activity during baseline presentation for each trigger
b_avgT1 = mean(Cz.Baseline(:,:,t1_ind),3); % Trigger 1: Average across events
b_avgT2 = mean(Cz.Baseline(:,:,t2_ind),3); % Trigger 2: Average across events

Cz.SumAvg = avgT1 + avgT2; % Summed response across the two polarities for Cz
Cz.SumAvg_Baseline = b_avgT1 + b_avgT2; % Summed response across the two polarities for baseline Cz

%% Plot Cz if makePlot is set to 'yes'
if strcmp(makePlot,'yes')
    f = 7; % Small font size
    L = 1; % Thin line width
    
    X_Axis = 1000*((1:(size(avgT1,2)))/Fs);
    
    figure
    h = plot(X_Axis,avgT1,'b','LineWidth',L);
    hold on
    plot(X_Axis,avgT2,'r','LineWidth',L);
    title(DATA.Subj,'FontSize',f,'Interpreter','none')
    xlabel('Time (ms)','FontSize',f)
    ylabel('Amplitude (\muV)','FontSize',f)
    legend(['Trig. ' num2str(DATA.TriggerNums(1))], ['Trig. ' num2str(DATA.TriggerNums(2))],'Location','Best')
    set(gca,'linewidth',L)
    h.LineWidth = L;
    ax = ancestor(h, 'axes');
    yrule = ax.YAxis;
    xrule = ax.XAxis;
    yrule.FontSize = f;
    xrule.FontSize = f;
end

