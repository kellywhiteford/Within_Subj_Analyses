function [f0Max, f0amp_avg, allFFT_mag] = slidingFFT_mi3(dat,baseline,Fs,delay, isStim)
% Performs the sliding window FFT analysis described in Wong et al. (2007,
% Supplementary Methods).
% dat      : A row vector of either EEG data from Cz or the original stimulus.
% baseline : A row vector of either averaged EEG baseline data or zeros.
%            Zeros should be used if dat is the stimulus.
% Fs       : Samplerate of data in dat
% delay    : Fixed delay accounting for the difference between the trigger
%            onset time and the arrival time of the stimulus at the ear 
%            canal.
% isStim   : String indicating 'yes' if dat is the stimulus and 'no' if dat
%            is the EEG response.

% OUTPUT
% f0Max      : A row vector of frequencies that have the maximum F0 magnitudes in each FFT bin.
% f0amp_avg  : The F0 magnitude for each frequency in f0Max.
% allFFT_mag : Matrix with all frequency amplitudes for all FFT bins (bin x frequency).

f = 7; % Small font size
L = 1; % Thin line width

% f = 14; % Large font size
% L = 2; % Thick line width

%% Set parameters
width_ms = 40; % Width of FFT bins (in ms)
numBins = 238; % Number of bins we want
width_samp = round(width_ms * Fs/1000); % Width of FFT window (in samples)

if delay == 0
    start_samp = 1; % For no delay, start the first bin for FFT at the first sample.
else
    start_samp = round(delay * Fs/1000); % When the first bin begins for FFT (in samples)
end
end_samp = start_samp+width_samp-1; % When the first bin ends for FFT (in samples)

%% Calculate the spectral noise floor
base_win = baseline.*hanning(length(baseline))'; % Hanning window is the length of the baseline and applied before zero padding
NFFT = Fs; % Zero-padding should be out to 1 s, according to Wong et al. (2007)
dfft_noise = fft(base_win,NFFT)/NFFT; % Because the samplerate is greater than the length of the bin window, this will be padded with zeros out to 1 sec
noise_pos = 2*abs(dfft_noise(1:NFFT/2+1)); % Get the magnitude of the data; just keep the positive values.

%% Sliding FFT 
f0amp = zeros(numBins,1); % Maximum F0 amplitudes will be stored here
f0Max = zeros(numBins,1); % Frequency with the maximum F0 amplitudes will be stored here
allFFT_mag = zeros(numBins,length(noise_pos)); % All F0 amplitudes for all bins will be stored here. 
for b = 1:numBins
    
    bin = dat(start_samp:end_samp); % 40-ms bin of dat
    bin_win = bin.*hanning(length(bin))'; % Hanning window should be the length of the data and should be applied before zero padding.
    
    freq = Fs/2*linspace(0,1,NFFT/2+1);  % frequency values for plotting
    
    data = fft(bin_win,NFFT)/NFFT; % Because NFFT is greater than the length of the bin window, steady-state will be padded with zeros out to 1 sec
    data_pos = 2*abs(data(1:NFFT/2+1)); % Get the magnitude of the data; just keep the positive values.
    
    allFFT_mag(b,:) = data_pos; % magnitude of the fft response for each bin
    
    %% Exclude frequencies that are not above the noise floor
    check = data_pos - noise_pos; 
    inds_remove = check <= 0; % Returns 1 for any frequencies where magnitude of FFT is not above the noise floor.
    data_pos(inds_remove) = []; % Removes magnitudes that are not above the noise floor
    freq(inds_remove) = []; % Removes frequencies corresponding to magnitudes that are not above the noise floor
    
    %% Excludes frequencies that are outside the range of 1/2 octave above/below 100 Hz
    too_high = freq > 100*2^.5; % Returns 1 for any frequencies that are > 1/2 octave above 100 Hz
    data_pos(too_high) = []; % Removes magnitudes of freqs that are far away from the F0
    freq(too_high) = []; % Removes frequencies that are far away from the F0
    
    too_low = freq < 100*2^-.5; % Returns 1 for any frequencies that are < 40 Hz
    data_pos(too_low) = []; % Removes magnitudes of freqs that are far away from the F0
    freq(too_low) = [];  % Removes frequencies that are far away from the F0
    
    %% Get F0max
    [y, ii] = max(data_pos); % ii contains the index of frequency with greatest magnitude
    f0Max(b) = freq(ii); % Frequency with greatest FFT magnitude
    f0amp(b) = data_pos(ii); % Magnitude of the frequency with the greatest FFT magnitude 
    
    start_samp = start_samp + floor(1*Fs/1000); % Shift starting sample of next bin by 1 ms
    end_samp = end_samp + floor(1*Fs/1000); % Shift ending sample of next bin by 1 ms
end

%% Plot Sliding FFT Results
switch isStim
    case 'no'
        scatter(1:numBins,f0Max,'MarkerEdgeColor','m','MarkerFaceColor','w')
    case 'yes'
        h = plot(1:numBins,f0Max,'k','LineWidth',L);
        set(gca,'linewidth',L)
        h.LineWidth = L;
        ax = ancestor(h, 'axes');
        yrule = ax.YAxis;
        xrule = ax.XAxis;
        yrule.FontSize = f;
        xrule.FontSize = f;
end
ylabel('Frequency (Hz)','FontSize',f)
xlabel('Time (bin)','FontSize',f)
ylim([50 150])
xlim([0 250])

f0amp_avg = mean(f0amp); % Average f0 amplitude is the mean magnitude across the bins.
f0Max = f0Max';


  