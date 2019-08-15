function output = filtEEG(rawData,Fc1,Fc2,N,Fs,makePlot)
% Bandpass butterworth filters EEG data using the specified cutoff
% frequencies and filter order with zero-phase shift. rawData should be a
% matrix of EEG data, where the rows correspond to electrodes and the
% columns correspond to time (in samples).
% INPUT
% rawData : Matrix of raw EEG data (after referencing)
% Fc1     : Low-frequency cutoff
% Fc2     : High-frequency cutoff
% N       : Filter order; 2 is 12 dB/Octave.
% Fs      : Sampling rate
% makePlot: 'yes' or 'no', where 'yes' will plot the filter and the
% impulse response.

% OUTPUT
% output  : Matrix of filtered EEG data (electrodes x time).

%% Note.
% Filtering can contaminate a small chunk of data in the beggining and the
% end of the recording. Impulse responses show ringing for our filter only
% affects about the first/last 200 samples of the recording. Transients are
% removed in the preprocess.m function.

%% Convert array to double- needed for filtfilt
rawData = double(rawData);

%% Filter data
% Set makePlot to yes to view the filter and impulse responses.

ElectrodesUsed = 1:size(rawData,1); % indices of electrodes 

if N > 0
    disp('   ');
    
    % Filter info
    Wn = [Fc1 Fc2]/(Fs/2); % Window for filtering
    [B_low,A_low] = butter(N/2,Wn(2),'low'); % This is a first-order lowpass filter when N=2
    [B_high,A_high] = butter(N/2,Wn(1),'high'); % This is a first-order highpass filter when N=2
    
    switch makePlot
        case 'yes' % Plot filter info if case is 'yes'.
        figure
        freqz(B_low,A_low) % view lowpass filter
        hold on
        figure
        impz(B_low,A_low) % view impulse response of lowpass filter
        
        figure
        freqz(B_high,A_high) % view highpass filter
        hold on 
        figure
        impz(B_high,A_high) % view impulse response of highpass filter
    end
    
    for a = 1:size(rawData,1) % Filter raw data (each electrode independently)
        disp(['      Filtering electrode: ', num2str(ElectrodesUsed(a))]);
        % Filtering
        rawData(a,:) = filtfilt(B_low,A_low,rawData(a,:)); % low-pass rawData with zero-phase shift; this will double the order of the LOW frequency side of the filter
        rawData(a,:) = filtfilt(B_high,A_high,rawData(a,:)); % high-pass the low-passed data with zero-phase shift; this will double the order of the HIGH frequency side of the filter
    end
end


%% Store filtered data in output variable
output = rawData; % output of function is the raw data after filtering
end