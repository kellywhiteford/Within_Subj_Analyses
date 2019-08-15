% Plots time waveform of EEG data

function plotTime(avgDat,SR,condition,site)
% avgDat   : row vector with EEG data averaged across epochs
% SR       : sampling rate 
% condition: string indicating "/da/" or "/mi3/"
% site     : string of the university site location


% For manuscript
f = 7; % Small font size
L = 1; % Thin line width

% For posters
% f = 14; % Large font size
% L = 2; % Thick line width

X_Axis = 1000*((1:(size(avgDat,2)))/SR);
h = plot(X_Axis,avgDat,'k','LineWidth',L);
title(site,'FontSize',f)
xlabel('Time (ms)','FontSize',f)
ylabel('Amplitude (\muV)','FontSize',f)
set(gca,'linewidth',L)
h.LineWidth = L;
ax = ancestor(h, 'axes');
yrule = ax.YAxis;
xrule = ax.XAxis;
yrule.FontSize = f;
xrule.FontSize = f;


switch condition
    case '/da/'
        ylim([-.8 1.4])
        xlim([0 250])
     
    case '/mi3/'
        ylim([-.6 1])
end


end
