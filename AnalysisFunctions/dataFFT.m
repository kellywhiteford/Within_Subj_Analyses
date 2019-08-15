% Plots FFT of steady-state EEG response (60-180 ms) to /da/ in babble

function [data, freq] = dataFFT(avgDat,Fs,site) 
% Input
% avgDat   : row vector with EEG data averaged across epochs
% Fs       : sampling rate 
% site     : string of the university site location

% Output
% data    : FFT response to /da/ in microvolts
% freq    : The frequency values used for plotting the x-axis of figure


% For manuscript
fSize = 7; % Font size
Lw = 1; % Line width

% For posters
% f = 14; % Font size
% Lw = 2; % Line width

minTime = 60; % Time where steady-state portion begins (ms)
maxTime = 180; % Time where steady-state portion ends (ms)
minSamp = round(minTime * Fs/1000); % convert ms to samples
maxSamp = round(maxTime * Fs/1000); % convert ms to samples
steadyState = avgDat(1,minSamp:maxSamp); % just the steady-state response to /da/

L = length(steadyState);  % Length (in samples) of the steady-state portion of the /da/ response

x = 2; 
NFFT = 2^(nextpow2(L)+x); % Lots of zero-padding to smoothen fft plot

freq = Fs/2*linspace(0,1,NFFT/2+1);  % frequency values for plotting; length needs to be the same as data for plot
data = fft(steadyState,NFFT)/L;  % Because NFFT is greater than the length of steady-state, steady-state will be padded with zeros
data = 2*abs(data(1:NFFT/2+1)); % Just keep the positive values, and multiply them by 2 to account for that we're taking half the fft data

% Plot the data
h = plot(freq,data,'r','LineWidth',Lw);
set(gca,'linewidth',Lw)
h.LineWidth = Lw;
xlim([0 1100]) % x-axis limits
ylim([0,.55]) % Hard-coded- change this to change y-axis limits
title(site,'FontSize',fSize)
ylabel('Amplitude (\muV)','FontSize',fSize)
xlabel('Frequency (Hz)','FontSize',fSize)
ax = ancestor(h, 'axes');
yrule = ax.YAxis;
xrule = ax.XAxis;
yrule.FontSize = fSize;
xrule.FontSize = fSize;

