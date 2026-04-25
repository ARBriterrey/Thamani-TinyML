% Important changes on 10 Sep2025_v2 as compared to 20Aug2025
% (1)while sectioning plateaus, 1/4 to 3/4 of the plateau is taken for cell0mean - line number ~ 164
% (2) In Oscpoint M2 and M4, when the size is 2, if there are only 2 sets % of peaks, and they differe by more than 15, one of them is taken as MAP rather than average
% (3) If Oscpoint M4 is empty, MAP is taken from MAP1 instead of MAP newCompare
% (4) A new DiamatrureArray_late is added to correct dia after MAP is determined
% (5) The corrected dia appears in Pressure selection
% (6) Equal weightage is given to Sys and Dia in line numbers ~14061, ~14178.

% From sep12 code, many clauses where dimension of 'size' was not mentioned
% has been corrected. Though the code worked in our computers in the dept,
% it did not work with the latest Matlab that Vishnu had, and therefore the
% correction. 

% Difference from 15Sep2025:
%Lakshmidata Harinath 24110101 - there is inversion of PPG in cuffed arm
%even at 90 mmHg. Many of these pulses are missed because of width
%probably.

%If cuff PPG was inverted and the inversion was corrected, a negative
%amplitude will be obtained. Take the amplitude and add to peak amplitude
%for correction

%more corrections in oscpointM2 ==2:
%change from 19 Sep: If the highest feature of min and max in PTOMMM is the same, then there is only one oscillation peak there.  

% MAP selection for size ==1 has been simplified as min and max.
%DMA_late has been corrected to have P dia May2025 as well

tic
% clear % Removed for programmatic execution
% close all % Removed for programmatic execution
%set(0, 'DefaultFigureVisible', 'off'); % Hide figures

% My colour palette:
DarkRed = [0.5,0,0];
WhatRed = [0.9,0.3,0.05];
Orange = [1, 0.5, 0];

DarkGreen = [0, 0.5, 0.5];
MediumGreen = [0.4660 0.6740 0.1880];
MediumGreen_1 = [0.46 0.67 0.18];

DarkBlue =  [0 0.4470 0.7410] ;
CyanBlue =  [0 0.5 1] ;

if exist('auto_input_file', 'var')
    file = auto_input_file;
else
    file = uigetfile('*.txt');
end
data = dlmread(file);
[~, fname, ~] = fileparts(file);
if length(fname) >= 8
    expt_id = fname(1:8);
else
    expt_id = fname;
end
data0 = data(:, :);
time = data0(:,1);

addpath('D:\Project\NIBP_algorithm\Functions');

% Sometimes, due to a recording error, time starts at negative. Set it
% to zero as follows:

if time (1,1)<0
    time (:,1) = time(:,1)+ abs(time (1,1));
end

% Sometimes, due to a recording error, time starts at more than zero. Set it
% to zero as follows:

if time (1,1)> 0
    time (:,1) = time(:,1)- abs(time (1,1));
end

data0(:,1)= time;  % This is time corrected data. Use it in figures
cuff_pressure = data0(:,2);
PPGref = data0(:,3);
PPGcuff = data0(:,4);

%%
data1 = cat(2, time, cuff_pressure, PPGref, PPGcuff);

%Thresh_minPeakProm_PPG = 0.001; % Change threshold as required
Thresh_minPeakProm_PPG = 0.0005;
%%
%Take care
%Define fs carefully:

SamplingInterval = (time(2,1)-time(1,1))*1000;% in milliseconds
fs = 1000/SamplingInterval;% Sampling frequency (samples per second)

%% Use only if necessary: (This is necessary currently as the filter setting for PPG aquisition has been changed to 8 from 4.

%for removing noise in PPG signal in columns 3 and 4 of data

cutoff_freq = 4; % to low pass signals

% Normalize the cutoff frequency with respect to the Nyquist frequency
normalized_cutoff = cutoff_freq / (0.5 * fs);

% Design a 4th-order lowpass Butterworth filter
[b, a] = butter(4, normalized_cutoff);

columns_to_filter = [3, 4];

% Apply the lowpass filter to the selected columns of data using filtfilt
for col = columns_to_filter
    data1(:, col) = filtfilt(b, a, data1(:, col));
end

%%
CPPZ0a = data1;
%CPPZ0a(:,2) = 1000.*CPPZ0a(:,2); %Commented becoz done earlier
% Becoz the values for pressure are
% in kmmHg. Multiply by 1000

B = diff(CPPZ0a(:,2)); % differential is high when the pressure rises and drops. We want only plateaus.
C = abs (B);

forD(1,1) = max(C)/2;
forD(1,2) = mean(nonzeros(C));
%forD(1,3)= 10*forD(1,2);
%forD(1,3)= 5*forD(1,2);
forD(1,3)= 3*forD(1,2);


%Take care 3/5
D = C > forD(1,3); % Keep checking if this works

CPPZ0a (D,:)= [];
E=CPPZ0a(:,2)<25;
CPPZ0a (E,:)= [];

CPPZ0 = CPPZ0a;

CPPZ = CPPZ0;
F=abs(diff(CPPZ(:,2)));% differentiate cuff pressure ?
F1=F>5;
G=abs(diff(CPPZ(:,1))); % differentiate time ?
G1=G>2;

AB = (length (CPPZ)-1);
N_oneless = (CPPZ(1:AB, :));
AC = [N_oneless(:,:) F F1 G1];
%%
x = 1;
[m,n] = size(AC);
col5 = AC(:,6);
col6 = AC(:,7);
vec1 = col5 == 0 & col6 == 0;
vec2 = col5 == 1 | col6==1 ;   % Note that vec2 has been changed from col5==1 in Vish's original code
pos1 = find(vec1); pos2 = find(vec2);
posn_mat1 = [];
start_posn = pos1(1);

while x == 1
    next1 = pos2 > start_posn;
    temp1 = pos2(next1);
    end_posn = temp1(1);
    posn_mat1 = [posn_mat1 ; [start_posn end_posn]];
    next2 = pos1 > end_posn;
    temp2 = pos1(next2);
    start_posn = temp2(1);
    if start_posn > pos2(end)
        x = 0;
    end
end

% For some reason, if we say E=CPPZ0a(:,2)<10; instead of <25, in the previous section, the above code does not run.

posn_mat1 = [posn_mat1 ; [start_posn m]];
no_rows = posn_mat1(:,2) - posn_mat1(:,1) + 1;
no_rowsvec = no_rows >=1100;
posn_mat = posn_mat1(no_rowsvec,:);
cell0b = cell(length(posn_mat),4);

for i = 1:length(posn_mat)
    cell0b{i,1} = AC(posn_mat(i,1):posn_mat(i,2),:);
    temp3 = cell0b{i,1};
    cell0b{i,2} = mean(temp3(:,2)); % There is a problem here.
    %when mean cuff pressure is taken before ensuring that the rising phase is deleted, mean becomes less
    %Leave it as is here. But later, after plateaus are ensured, replace the second column with new mean
    % cell0b{i,3} = mean(temp3(:,3));
    cell0b{i,3} = posn_mat(i,:);
end

% In the above, cell {i,1} is a repeat of AC in that segment, with
% eight columns. Only the first five columns matter now
%cell {i, 2} is mean of cuff pressure in that segment
%cell {i, 3} is meaningless? dont worry

%%
for i = 1:size(cell0b,1)
    cell0aMeanPressure{i,1} = round(mean(cell0b{i,1}(end/5:4*(end/5),2))); %mean cuff Pressurec in the middle portion 
    cell0aMeanPressure{i,2} = std(cell0b{i,1}(end/5:4*(end/5),2));
end

for i = 1:size(cell0b,1)
    currentData = cell0b{i,1};
    for j = 1:size(currentData,1)
        
        %if round(currentData(j,2)) == round(cell0aMeanPressure{i,1}- cell0aMeanPressure{i,2})%mean - SD
        if round(currentData(j,2)) == round(cell0aMeanPressure{i,1}- cell0aMeanPressure{i,2}) || round(currentData(j,2)) == round(cell0aMeanPressure{i,1}+ cell0aMeanPressure{i,2})%mean +- SD
            newData=currentData(j:end,:);
            break;
        end
    end
    cell0a4{i,1}=newData;
    cell0a4{i,2} = round(mean(newData(:,2)));
end

for i = 1:size(cell0a4,1)
    currentData = cell0a4{i,1};
    for j = size(currentData,1):-1:1
        %if round(currentData(j,2)) == round(cell0aMeanPressure{i,1}+ cell0aMeanPressure{i,2}) %mean + SD
         if round(currentData(j,2)) == round(cell0aMeanPressure{i,1}- cell0aMeanPressure{i,2}) || round(currentData(j,2)) == round(cell0aMeanPressure{i,1}+ cell0aMeanPressure{i,2})%mean +- SD
            newData=currentData(j:end,:);
            newData=currentData(1:j,:);
            break;
        end
    end
    cell0a3{i,1}=newData;
    cell0a3{i,2} = round(mean(newData(:,2)));
end

% for i = 1:size(cell0a3,1) %Repeat with new mean
%     cell0aMeanPressure1 {i,1} = round(mean(cell0a3{i,1}(end/2:end,2))); %mean cuff Pressurec in the second half
% end

for i = 1:size(cell0a3,1)%Repeat with new mean
    cell0aMeanPressure1{i,1} = round(mean(cell0a3{i,1}(end/5:4*(end/5),2))); %mean cuff Pressurec in the middle portion 
    cell0aMeanPressure{i,2} = std(cell0b{i,1}(end/5:4*(end/5),2));
end


for i = 1:size(cell0a3,1)
    currentData = cell0a3{i,1};
    for j = 1:size(currentData,1)
        
       % if round(currentData(j,2)) == round(cell0aMeanPressure{i,1}-cell0aMeanPressure{i,2})%mean - SD
         if round(currentData(j,2)) == round(cell0aMeanPressure{i,1}- cell0aMeanPressure{i,2}) || round(currentData(j,2)) == round(cell0aMeanPressure{i,1}+ cell0aMeanPressure{i,2})%mean +- SD
            newData=currentData(j:end,:);
            break;
        end
    end
    cell0a2{i,1}=newData;
    cell0a2{i,2} = round(mean(newData(:,2)));
end

for i = 1:size(cell0a2,1)
    currentData = cell0a2{i,1};
    for j = size(currentData,1):-1:1
        %if round(currentData(j,2)) == round(cell0aMeanPressure{i,1}+ cell0aMeanPressure{i,2})
         if round(currentData(j,2)) == round(cell0aMeanPressure{i,1}- cell0aMeanPressure{i,2}) || round(currentData(j,2)) == round(cell0aMeanPressure{i,1}+ cell0aMeanPressure{i,2})%mean +- SD
            newData=currentData(1:j,:);
            break;
        end
    end
    cell0a{i,1}=newData;
    cell0a{i,2} = round(mean(newData(:,2)));
end

%%
%figure (2)
%hold on
for i= 1:size(cell0b,1)
%    yyaxis left
%    yticks ([0: 10: 300])
%    plot (cell0b{i,1} (:,1), cell0b{i,1} (:,2),'Marker', 'none','color', 'k', 'LineStyle', '--');% cuff pressure
%    plot (cell0a{i,1} (:,1), cell0a{i,1} (:,2),'Marker', 'none','color', 'r', 'LineStyle', '-');% cuff pressure
    
%    xlabel ('time in seconds');
%    xticks([0: 40: 1000])
%    set(gca,'XMinorTick','on','YMinorTick','on')
%    grid on
end

%saveas(gcf,[expt_id 'fig2.fig']);
%%
cell0 = cell0a;%
%With the following code, one does not have to worry about step up or step down.
cell1 = sortrows(cell0,-2); % 2 stands for second column, -2 stands for descending order. This line is to correct the order for step up protocol as further code treats first cell as highest cuff pressure

% To correct any reversed PPG channels
% checkPPG1 = rms(cell1{1,1}(:,3));
% checkPPG2 = rms(cell1{1,1}(:,4));

checkPPG1 = rms(cell1{1,1}(end/2:end,3)); % There are instances where test PPG amp is larger than ref and even at hcp, the large initial wave leads to higher test rms
checkPPG2 = rms(cell1{1,1}(end/2:end,4));

if checkPPG1< checkPPG2
    PPGref = data0(:,4);
    PPGcuff = data0(:,3);
    
    for i = 1:size(cell1,1)
        cell1{i,1}(:,8)= cell1{i,1}(:,3);
        cell1{i,1}(:,3)= cell1{i,1}(:,4);
        cell1{i,1}(:,4)= cell1{i,1}(:,8);
    end
    
    for i = 1:size(cell1,1)
        cell1{i,1}(:,8)= [];
    end
end

% Redo data1
data1 = cat(2, time, cuff_pressure, PPGref, PPGcuff);

%%
%High pass filtering can cause havoc by introducing unnecessary dicrotic pulses
%For high pass filtering specific cells. Only the simplest filter works best.
for i = 1:4
    cell1 {i,1}(:,4) = highpass(cell1 {i,1}(:,4), 1, fs); % highpass filters of 0.8 and 1.5 dont work. Only 1 is good
end

%%
cell = cell1;
hcp =cell{1,2};
lcp = cell{end, 2};

for i = 1: size(cell,1)
Stepsize(i,1)= cell{i,2};
end

for i = 1:size(Stepsize,1)-1
    Stepsize(i,2)= Stepsize(i,1)- Stepsize(i+1,1);
end

AvgStepSize = mean(nonzeros(Stepsize(:,2)));
SDStepSize = std(nonzeros(Stepsize(:,2)));
MeanPlus2SD_StepSize = ceil(AvgStepSize + 2*(SDStepSize));    

%%
%RMS value for each plateau:
for i=1: length (cell)
    rmscell{i,1} = cell{i,2};% cuff pressure
    rmscell{i,2}= rms(cell{i,1}(:,3));%reference PPG voltage ?
    rmscell{i,3} = rms(cell{i,1}(:,4)); %test PPG voltage in the whole plateau can be taken as the data is filtered
    rmscell {i,4} =  rmscell{i,3}/ rmscell{i,2};%test/reference
    rmscell{i,5}= (rmscell{i,2} + rmscell{i,3});%total rms (ref+test)
    rmscell {i,6} = rmscell{i,3}/rmscell{i,5};% test/total
    rmscell{i,7}= (rmscell{i,2} - rmscell{i,3});
    rmscell{i,8}= round(rms(cell{i,1}(:,2)));%rms of cuff pressure Is this column necessary? It is the same as col 1
end
%%
rmsmat1 = cell2mat(rmscell);
rmscellmat1 = rmsmat1;

%figure(401)
%plot (rmsmat1(:,1), rmsmat1(:,4));

%%
max_rmsRatio = max(nonzeros(rmsmat1(:,4)));
min_rmsRatio = min(nonzeros(rmsmat1(:,4)));
rms_halfAmp = (max_rmsRatio - min_rmsRatio)/2;
rms_quarterAmp = (max_rmsRatio - min_rmsRatio)/4;
rms_eighthAmp = (max_rmsRatio - min_rmsRatio)/8;

rms_Sys_for(:,1) = rmsmat1(rmsmat1(:,4)<rms_halfAmp,1);
rms_Sys_for(:,2) = rmsmat1(rmsmat1(:,4)<rms_halfAmp,4);

rms_Sys_for_max = max(rms_Sys_for(:,2));
rms_Sys_for_min = min(rms_Sys_for(:,2));

rms_Sys_for_amp = max(rms_Sys_for(:,2))- min(rms_Sys_for(:,2));
rms_Sys_for_mean = mean(rms_Sys_for(:,2));

rms_Sys_for_SD = std(rms_Sys_for(:,2));

if rms_Sys_for_SD > 0.05
    if any(any(rms_Sys_for(:,2))) < rms_Sys_for_amp/2
        rms_Sys_for_1 = rms_Sys_for(rms_Sys_for(:,2)< rms_Sys_for_amp/2, :);
        rms_Sys_for_1(end+1, :) = rms_Sys_for(size(rms_Sys_for_1,1)+1, :);
    else
        rms_Sys_for_1 = rms_Sys_for;
    end
else
    rms_Sys_for_1 = rms_Sys_for;
end

if size(rms_Sys_for,1) - size(rms_Sys_for_1,1)<4
    rms_Sys_for =[];
    rms_Sys_for_1 = [];
    rms_Sys_for(:,1) = rmsmat1(rmsmat1(:,4)<rms_quarterAmp,1);
    rms_Sys_for(:,2) = rmsmat1(rmsmat1(:,4)<rms_quarterAmp,4);
    
    if isempty(rms_Sys_for)
        rms_Sys_for =[];
        rms_Sys_for_1 = [];
        rms_Sys_for(:,1) = rmsmat1(rmsmat1(:,4)<rms_halfAmp,1);
        rms_Sys_for(:,2) = rmsmat1(rmsmat1(:,4)<rms_halfAmp,4);
        if rms_Sys_for_SD > 0.05
            if any(any(rms_Sys_for(:,2))) < rms_Sys_for_amp/2
                rms_Sys_for_1 = rms_Sys_for(rms_Sys_for(:,2)< rms_Sys_for_amp/2, :);
                rms_Sys_for_1(end+1, :) = rms_Sys_for(size(rms_Sys_for_1,1)+1, :);
            else
                rms_Sys_for_1 = rms_Sys_for;
            end
        else
            rms_Sys_for_1 = rms_Sys_for;
        end
    else
        rms_Sys_for_max = max(rms_Sys_for(:,2));
        rms_Sys_for_min = min(rms_Sys_for(:,2));
        rms_Sys_for_amp = max(rms_Sys_for(:,2))- min(rms_Sys_for(:,2));
        rms_Sys_for_mean = mean(rms_Sys_for(:,2));
        rms_Sys_for_SD = std(rms_Sys_for(:,2));
        
        if rms_Sys_for_SD > 0.03
            rms_Sys_for_1 = rms_Sys_for(rms_Sys_for(:,2)< rms_Sys_for_amp/2, :);
            rms_Sys_for_1(end+1, :) = rms_Sys_for(size(rms_Sys_for_1,1)+1, :);
        else
            rms_Sys_for_1 = rms_Sys_for;
        end
        
        if size(rms_Sys_for,1) - size(rms_Sys_for_1,1)<4
            rms_Sys_for =[];
            rms_Sys_for_1 = [];
            rms_Sys_for(:,1) = rmsmat1(rmsmat1(:,4)<rms_eighthAmp,1);
            rms_Sys_for(:,2) = rmsmat1(rmsmat1(:,4)<rms_eighthAmp,4);
            
            if isempty(rms_Sys_for)
                rms_Sys_for =[];
                rms_Sys_for_1 = [];
                rms_Sys_for(:,1) = rmsmat1(rmsmat1(:,4)<rms_halfAmp,1);
                rms_Sys_for(:,2) = rmsmat1(rmsmat1(:,4)<rms_halfAmp,4);
            else
                rms_Sys_for_max = max(rms_Sys_for(:,2));
                rms_Sys_for_min = min(rms_Sys_for(:,2));
                rms_Sys_for_amp = max(rms_Sys_for(:,2))- min(rms_Sys_for(:,2));
                rms_Sys_for_mean = mean(rms_Sys_for(:,2));
                rms_Sys_for_SD = std(rms_Sys_for(:,2));
                
                if rms_Sys_for_SD > 0.02
                    rms_Sys_for_1 = rms_Sys_for(rms_Sys_for(:,2)< rms_Sys_for_amp/2, :);
                    rms_Sys_for_1(end+1, :) = rms_Sys_for(size(rms_Sys_for_1,1)+1, :);
                else
                    rms_Sys_for_1 = rms_Sys_for;
                end
            end
        end
    end
end

if isempty(rms_Sys_for_1)
    rms_Sys_for_1 = rms_Sys_for;
end
%%
rms_Sys_for_1(1:end-1, 3)= diff(rms_Sys_for_1(:,2));

if size(rms_Sys_for_1,1)==1
    rms_sysvalue = rms_Sys_for_1(1,1);
elseif size(rms_Sys_for_1,1)==2
    for j = 1:2
        if rms_Sys_for_1(j,2)< rms_Sys_for_mean
            rms_sysvalue = rms_Sys_for_1(j,1);
            break
        end
    end
end

if size(rms_Sys_for_1,1)>2
    for i = size(rms_Sys_for_1,1)-1:-1:2
        if rms_Sys_for_SD > 0.05
            if rms_Sys_for_1(i,3)~=0 && rms_Sys_for_1(i-1, 3)< rms_Sys_for_1(i,3)/8
                rms_sysvalue = rms_Sys_for_1(i,1);
                break
            end
            if ~exist('rms_sysvalue', 'var')
                rms_sysvalue = NaN;
            end
        else
            for j = size(rms_Sys_for_1,1):-1:1
                if rms_Sys_for_mean >0
                    if rms_Sys_for_1(j,2)<= rms_Sys_for_mean
                        rms_sysvalue = rms_Sys_for_1(j,1);
                        break
                    end
                else
                    if rms_Sys_for_1(j,2)<= rms_Sys_for_mean
                        rms_sysvalue = rms_Sys_for_1(j,1);
                        break
                    end
                end
            end
        end
    end
end

%%
%Fit data to a third degree polynomial'.
% Set up fittype and options.
fitrmspoly = fittype('a*x^3 + b*x^2 + c*x + d', 'independent', 'x', 'dependent', 'y');
opts_rmspoly = fitoptions( 'Method', 'NonlinearLeastSquares' );
optsrmspoly.Algorithm = 'Levenberg-Marquardt';
poly.Display = 'Off';
optsrmspoly.Robust = 'Bisquare';
optsrmspoly.StartPoint = [10 1 1 1];% changed

% Fit model to data.
[fitresult{58}, gof(58)] = fit(rmsmat1(:,1), rmsmat1(:,4), fitrmspoly, opts_rmspoly);
coefficients_rmspoly= coeffvalues(fitresult{58});
%
fitx_polyrms = (lcp:1:hcp+20);
fitx_polyrms = fitx_polyrms';
fity_polyrms = fitresult{58}(lcp:1:hcp+20);
fit_polyrms = [fitx_polyrms,fity_polyrms]; % fit polymin from lowest cuff pressure to highest cuff pressure + 30

fit_polyrms(:,3)= fit_polyrms(:,2)- rms_halfAmp;

[pk_fitpolyrms, loc_pk_fitpolyrms]   = findpeaks (fit_polyrms (:,2), fit_polyrms (:,1));
[trf_fitpolyrms, loc_trf_fitpolyrms] = findpeaks (-fit_polyrms (:,2), fit_polyrms (:,1));
trf_fitpolyrms = -trf_fitpolyrms; %n troughs falling after midpoint

if ~exist('loc_pk_fitpolyrms', 'var') | loc_pk_fitpolyrms > loc_trf_fitpolyrms
    loc_pk_fitpolyrms = [];
end

for i = 1:size(fit_polyrms ,1)-1
    if  fit_polyrms(i+1,2)<0 && fit_polyrms (i,2)>0 || fit_polyrms (i,2) ==0 % find first zero crossing
        X_intercept_poly_rms = fit_polyrms(i+1,1);
        break; %report first zero crossing
        % if there is no zero crossing, report trough
    elseif ~isempty(trf_fitpolyrms)
        X_intercept_poly_rms = loc_trf_fitpolyrms;
    end
end

% tangent to poly trough
if ~isempty (trf_fitpolyrms)
    x_lowerHoriz_rmspoly = (X_intercept_poly_rms - 50:1: X_intercept_poly_rms+20);
    x_lowerHoriz_rmspoly=transpose(x_lowerHoriz_rmspoly);
    y_lowerHoriz_rmspoly(1:size(x_lowerHoriz_rmspoly,1)) = trf_fitpolyrms;
end

%%
% Set up fittype and options.
ft_rmsratio = fittype( 'smoothingspline' );
opts_rmsratio = fitoptions( 'Method', 'SmoothingSpline' );
opts_rmsratio.SmoothingParam = 0.999999023293969;

% Fit model to data.
[fitresult{79}, gof(79)] = fit( rmsmat1(:,1), rmsmat1(:,4), ft_rmsratio, opts_rmsratio);

coefficients_rmsratio= coeffvalues(fitresult{79});

fitx_rmsratio = (lcp:1:hcp+20);
fitx_rmsratio = fitx_rmsratio';
fity_rmsratio = fitresult{79}(lcp:1:hcp+20);
fit_rmsratio = [fitx_rmsratio,fity_rmsratio]; % fit polymin from lowest cuff pressure to highest cuff pressure + 30

[pk_fitrmsratio, loc_pk_fitrmsratio]   = findpeaks (fit_rmsratio (:,2), fit_rmsratio (:,1));
[trf_fitrmsratio, loc_trf_fitrmsratio] = findpeaks (-fit_rmsratio (:,2), fit_rmsratio (:,1));
trf_fitrmsratio = -trf_fitrmsratio;
trf_rmsratio = [loc_trf_fitrmsratio, trf_fitrmsratio];

% added on 5th May

[~, rISysrms_equivalent] = min(rmsmat1(:,4));
Sysrms_equivalent = rmsmat1(rISysrms_equivalent,1);

if ~isempty(rms_Sys_for_1)
    trf_rmsratio(trf_rmsratio(:,1)< rms_Sys_for_1(size(rms_Sys_for_1,1),1),:)=[];
else
    trf_rmsratio(trf_rmsratio(:,1)< Sysrms_equivalent, :) = [];
end

[max_rms_pk, rImax_rms] = max(pk_fitrmsratio);
Dia_max_rms_pk_CP = loc_pk_fitrmsratio(rImax_rms);

if ~isempty(trf_rmsratio)
    Sys_rms_from_trf = trf_rmsratio(1,1);
else
    Sys_rms_from_trf=NaN;
end

%Intersection of tangent to poly and smsp_rmsratio

if ~isempty(trf_fitpolyrms)
    for i = 1: size(fit_rmsratio,1)
        fit_rmsratio(i,3)= fit_rmsratio(i,2)- trf_fitpolyrms;
    end
    
    for i = 2: size(fit_rmsratio,1)-1
        if fit_rmsratio(i+1,3)<0 && fit_rmsratio(i-1,3)>0
            X_eqCrossing_rmsratio = fit_rmsratio(i,1);
            break
        end
    end
end

if ~exist ('X_eqCrossing_rmsratio', 'var')
    X_eqCrossing_rmsratio = NaN;
end

if exist('X_intercept_poly_rms', 'var')
    %Intersection of poly and smsp_rmsratio % May not be essential
    fitx_rmsRatioAndPoly = (X_intercept_poly_rms-30: 0.1: X_intercept_poly_rms+20);
    fitx_rmsRatioAndPoly = fitx_rmsRatioAndPoly';
    
    fity_rmsRatio2 = fitresult{79}(X_intercept_poly_rms-30: 0.1: X_intercept_poly_rms+20);
    fity_rmsPoly2 =  fitresult{58}(X_intercept_poly_rms-30: 0.1: X_intercept_poly_rms+20);
else
    fitx_rmsRatioAndPoly = (Sysrms_equivalent-30: 0.1: Sysrms_equivalent+20);
    fitx_rmsRatioAndPoly = fitx_rmsRatioAndPoly';
    
    fity_rmsRatio2 = fitresult{79}(Sysrms_equivalent-30: 0.1: Sysrms_equivalent+20);
    fity_rmsPoly2 =  fitresult{58}(Sysrms_equivalent-30: 0.1: Sysrms_equivalent+20);
end

fity_rmsRatioAndPoly(:,1)= fitx_rmsRatioAndPoly;
fity_rmsRatioAndPoly(:,2)= fity_rmsRatio2;
fity_rmsRatioAndPoly(:,3)= fity_rmsPoly2;
fity_rmsRatioAndPoly(:,4)= abs(fity_rmsRatioAndPoly(:,2) - fity_rmsRatioAndPoly(:,3));

[~, rIminrmsRatio_Polydiff]= min(fity_rmsRatioAndPoly(:,4));
X_equalIntsect_rms_PolyAndsmsp = round(fitx_rmsRatioAndPoly(rIminrmsRatio_Polydiff));

%%
% Plot fit with data.
%figure (400) ;
%hold on
%h_rmsratio = plot( fitresult{79}, rmsmat1(:,1), rmsmat1(:,4));
%plot (fitx_polyrms,fity_polyrms)
if ~isempty(trf_fitpolyrms)
%    plot(x_lowerHoriz_rmspoly, y_lowerHoriz_rmspoly);
end

%xlabel cuffPressure
%ylabel rmsratio
%grid on

%legend ('rms smsp fit');
%title (expt_id);

%saveas(gcf,[expt_id 'fig400.fig']);
%%
if ~exist('rms_sysvalue', 'var')
    rms_sysvalue = NaN;
end

if ~exist('X_intercept_poly_rms', 'var')
    X_intercept_poly_rms = NaN;
end

Sys_rms_Cand = [Sys_rms_from_trf; Sysrms_equivalent; rms_sysvalue; X_eqCrossing_rmsratio; X_equalIntsect_rms_PolyAndsmsp; X_intercept_poly_rms];

if isnan(rms_sysvalue)
    if ~isempty(rms_Sys_for_1) && rms_Sys_for_1(end-1, 1)> min(Sys_rms_Cand)
        rms_sysvalue = rms_Sys_for_1(end-1, 1); % Taking end-1 because, the last value was added so as to obtain diff
        Sys_rms_Cand (1,1)= rms_sysvalue;
    else
        rms_sysvalue = Sysrms_equivalent; % Taking end-1 because, the last value was added so as to obtain diff
        Sys_rms_Cand (1,1)= rms_sysvalue;
    end
end

for i = 1:size(fit_rmsratio,1)
    for j = 1:5
        if Sys_rms_Cand(j,1)== fit_rmsratio(i,1)
            Sys_rms_Cand(j,2) = fit_rmsratio(i,2);
        end
    end
end

if ~isnan(X_intercept_poly_rms)
    Sys_rms_Cand1 = Sys_rms_Cand(Sys_rms_Cand(:,1)<= X_intercept_poly_rms, :);
else
    Sys_rms_Cand1 = Sys_rms_Cand;
end

Sys_rms = max(Sys_rms_Cand1(:,1));
    
if ~exist('Sys_rms', 'var')|| isempty(Sys_rms)
    Sys_rms = Sysrms_equivalent;
end

%%

% To remove very low values in cuff oscillation, try to get peaks in reference PPG even as early as here 
[mcell, ncell] = size (cell);
for j=1:mcell
    [pk_d,locpk_d,w_pkd,p_pkd]=findpeaks(cell{j,1}(:,4),cell{j,1}(:,1),'minPeakProminence', Thresh_minPeakProm_PPG);
    ptest0{j,1}=[pk_d,locpk_d,w_pkd,p_pkd];
    
    [trf_d,loctrf_d,w_trf_dd,p_trf_d]=findpeaks(-cell{j,1}(:,4),cell{j,1}(:,1),'minPeakProminence', Thresh_minPeakProm_PPG);
    trftest0{j,1}=[-trf_d,loctrf_d,w_trf_dd,p_trf_d];
    
    [pk_r,locpk_r,w_pk_r,p_pk_r]=findpeaks(cell{j,1}(:,3),cell{j,1}(:,1),'minPeakProminence', Thresh_minPeakProm_PPG);
    pref0{j,1}=[pk_r,locpk_r,w_pk_r,p_pk_r];
    
    [trf_r,loctrf_r,w_trf_r,p_trf_r]=findpeaks(-cell{j,1}(:,3),cell{j,1}(:,1),'minPeakProminence',Thresh_minPeakProm_PPG);
    trfref0{j,1}=[-trf_r,loctrf_r,w_trf_r,p_trf_r];
end

ylim1_forFig = -(max(max(trf_d), max(trf_r)));
ylim2_forFig = max(max(pk_d), max(pk_r));

%%
%figure (3)
%hold on
%yyaxis left
%yticks ([0: 10: 300])
%ylabel ('pressure in mmHg, intra arterial (Orange) or cuff pressure (black)');
%plot(data1(:,1), data1(:,2), 'color', 'k', 'LineStyle', '-');% cuff pressure, is in KmmHg. Therefore multiply by 1000

%yyaxis right

%ylim ([1.5*ylim1_forFig 1.5*ylim2_forFig]);
%ylabel ('PPG cuff (green)');
%yticks([-0.2: 0.1: 10]);

MyDarkGreen= [0, 0.5, 0.5];

%plot(data1(:,1), data1(:,3),'color', CyanBlue,'LineStyle', '-');% PPG ref
%plot(data1(:,1), data1(:,4),'color', DarkGreen,'LineStyle', '-');% PPG cuff

%xlabel ('time in seconds');
%xticks([0: 20: size(time,1)])
%set(gca,'XMinorTick','on','YMinorTick','on')

%grid on

%title (expt_id);
%legend ('Cuff pressure, PPGref and PPGcuff');
%hold off
%saveas(gcf,[expt_id 'fig3.fig']);

%%
for i = 1: size(cell,1)
    cuffoscillation{i,1}(:,1)= cell{i,1}(:,1); %time
    cuffoscillation{i,1}(:,2) =cell{i,1}(:,2);%oscillations
    cuffoscillation{i,2}= cell{i,2}; % mean cuff pressure
end

%%
%Take care about threshold
for i = 1: size(cuffoscillation,1)
    [pk_Osc, loc_pk_Osc, w_pk_Osc, p_pk_Osc]= findpeaks(cuffoscillation{i,1}(:,2),cuffoscillation{i,1}(:,1),'MinPeakProminence', 0.1, 'MinPeakWidth', 0.1);
    p_Osc_1{i,1}=[pk_Osc,loc_pk_Osc,w_pk_Osc,p_pk_Osc];
end
% Interestingly, prominence of peaks graph looks like PPG ratio roughly

for i = 1: size(p_Osc_1,1)
    p_Osc_1{i,2} = mean(p_Osc_1{i,1}(:,3));% mean width
    p_Osc_1 {i,3}= mean(p_Osc_1{i,1}(:,4));% mean prominence
end

%%
%Take care about threshold
for i = 1: size(cuffoscillation,1)
    [trf_Osc, loc_trf_Osc, w_trf_Osc, p_trf_Osc]= findpeaks(-cuffoscillation{i,1}(:,2),cuffoscillation{i,1}(:,1),'MinPeakProminence', 0.1, 'MinPeakWidth', 0.1);
    t_Osc_1{i,1}=[-trf_Osc,loc_trf_Osc,w_trf_Osc,p_trf_Osc];
end
% Interestingly, prominence of peaks graph looks like PPG ratio roughly

for i = 1: size(t_Osc_1,1)
    t_Osc_1{i,2} = mean(t_Osc_1{i,1}(:,3));% mean width
    t_Osc_1 {i,3}= mean(t_Osc_1{i,1}(:,4));% mean prominence
end
%%
%   To equal the number of peaks and troughs in every cuff pressure
%   plateau in the cuffed arm

[ mp_Osc, ~] = size(p_Osc_1);

for i=1:mp_Osc
    pktrf_Osc_count{i,1}= size(p_Osc_1{i,1});
    pktrf_Osc_count{i,2}= size(t_Osc_1{i,1});
    pktrf_Osc_count{i,3}=abs((pktrf_Osc_count{i,1} - pktrf_Osc_count {i,2}));
end

% If more peaks than troughs, add zeros to troughs

[mpktrf_Osc, ~] = size (pktrf_Osc_count);
for i = 1: mpktrf_Osc
    if pktrf_Osc_count{i,1}(:,1) > pktrf_Osc_count {i,2}(:,1)
        t_Osc_1{i,1}(end+pktrf_Osc_count{i,3}(:,1),:)=0;
    end
    
    % If more troughs than peaks, add zeros to peaks
    
    if pktrf_Osc_count{i,1}(:,1) < pktrf_Osc_count{i,2}(:,1)
        p_Osc_1{i,1} (end+pktrf_Osc_count{i,3}(:,1), :)=0;
    end
end

% Check if peak and trough numbers in every plateau is same for cuffed
% arm. The last column in pktrfafter should be 0,0.
for i=1:mp_Osc
    
    pktrf_Osc_countafter{i,1}= size(p_Osc_1{i,1});
    pktrf_Osc_countafter{i,2}= size(t_Osc_1{i,1});
    pktrf_Osc_countafter{i,3}= abs ((pktrf_Osc_countafter{i,1} - pktrf_Osc_countafter{i,2}));
end

% Now that peaks and troughs are the same in every cell, we can
% concatenate peaks and troughs

for j = 1: mp_Osc
    pktrf_Osc{j,1} = cat (2, p_Osc_1 {j,1} (:,:), t_Osc_1{j,1} (:,:));
end

for j = 1:size(pktrf_Osc, 1)
    if isempty(pktrf_Osc{j, 1})
        pktrf_Osc{j, 1} = zeros(1,8); % Assign a row of zeros in 8 columns
    end
end

%%
pktrf_Osc_a = pktrf_Osc;

for i =1:size(pktrf_Osc_a,1)
    [m1_Osc, n1_Osc]= size (pktrf_Osc_a{i,1});
    for k=1:m1_Osc-1
        if pktrf_Osc_a{i,1}(k,2) < pktrf_Osc_a{i,1}(k,6)
            addrowtest(1:8) = zeros; %This is done so that the last ref data in 5:8 does not get deleted
            pktrf_Osc_a{i,1} = [pktrf_Osc_a{i,1}; addrowtest];
            pktrf_Osc_a{i,1}(k+1:end,5:8)= pktrf_Osc_a{i,1}(k:end-1,5:8);
            pktrf_Osc_a{i,1}(k,5:8)= 0;% In 6May code, 1:4 was rendered to 0. That is incorrect.
            %Actually there is a peak, but no preceding trough here.
        end
    end
end

%Remove zero entries from pktrf_Osc_a:
for j = 1:size(pktrf_Osc_a,1)
    temp_Osc = pktrf_Osc_a{j,1};
    idx_Osc = ~any(temp_Osc==0, 2); % Find the rows without zero entries using logical indexing
    temp_Osc = temp_Osc(idx_Osc,:); % Select the rows without zero entries using logical indexing
    pktrf_Osc_a{j,1} = temp_Osc; % Assign the modified array back to the j-th cell of pktrf_Osc_a
end

%%
% Get absolute amplitudes of oscillations

for i = 1:size(pktrf_Osc_a, 1)
    [mi, ni] = size(pktrf_Osc_a{i, 1});
    for k = 1:mi
        pktrf_Osc_a{i, 1}(k,9) = pktrf_Osc_a{i, 1}(k,1)- pktrf_Osc_a{i, 1}(k,5); % amplitude of oscillation
    end
end

for i = 1:size(pktrf_Osc_a, 1)
    if size(pktrf_Osc_a{i,1})>3
        [mi, ni] = size(pktrf_Osc_a{i, 1});
        %pktrf_Osc_a{i, 1}(1,:) = 0; %Remove first row
        pktrf_Osc_a{i, 1}(end,:) = 0; %Remove last row
    end
end

for i = 1:size(pktrf_Osc, 1)
    pktrf_Osc_a{i, 2}= cuffoscillation{i,2}; % cuff pressure?
end

%Remove rows with zeros
for j = 1:size(pktrf_Osc_a,1)
    temp_Osc = pktrf_Osc_a{j,1};
    idx_Osc = ~any(temp_Osc==0, 2); % Find the rows without zero entries using logical indexing
    temp_Osc = temp_Osc(idx_Osc,:); % Select the rows without zero entries using logical indexing
    pktrf_Osc_a{j,1} = temp_Osc; % Assign the modified array back to the j-th cell of pktrf_Osc_a
end

EmptyRows_pktrf_osc_a = any(cellfun(@isempty, pktrf_Osc_a), 2);
pktrf_Osc_b = pktrf_Osc_a(~EmptyRows_pktrf_osc_a, :);

for i = 1:size(pktrf_Osc_b, 1) % This is repeated again later. But required here to get the mean
    pktrf_Osc_b{i,3}= mean(pktrf_Osc_b{i, 1}(:,9)); % mean oscillation amplitude
    pktrf_Osc_b{i,4}= min(pktrf_Osc_b{i, 1}(:,9)); % min oscillation amplitude
end

%Take care: sometimes a very tiny peak is picked and the next one is
%deleted. Avoid this:

for    i = 1:size(pktrf_Osc_b, 1)
    for  j = 1:size(pktrf_Osc_b{i, 1},1)
        if pktrf_Osc_b{i,1}(j,9)< 0.25* pktrf_Osc_b{i,3}
            pktrf_Osc_b{i, 1}(j,1:8) = 0; % Remove peaks which are less than one fourth the mean value for that plateau.
        end
    end
end

%Remove rows with zeros
for j = 1:size(pktrf_Osc_b,1)
    temp_Oscb = pktrf_Osc_b{j,1};
    idx_Oscb = ~any(temp_Oscb==0, 2); % Find the rows without zero entries using logical indexing
    temp_Oscb = temp_Oscb(idx_Oscb,:); % Select the rows without zero entries using logical indexing
    pktrf_Osc_b{j,1} = temp_Oscb; % Assign the modified array back to the j-th cell of pktrf_Osc_a
end

for i = 1:size(pktrf_Osc_b, 1)
    pktrf_Osc_b{i,3}= mean(pktrf_Osc_b{i, 1}(:,9)); % mean oscillation amplitude
    pktrf_Osc_b{i,4}= min(pktrf_Osc_b{i, 1}(:,9)); % min oscillation amplitude
    pktrf_Osc_b{i,5}= max( pktrf_Osc_b{i, 1}(:,9)); % max oscillation amplitude
end

%copying into another matrix
for i=1:size( pktrf_Osc_b,1)
    for_pktrf_Osc_b_mat{i,1}= pktrf_Osc_b{i,2}; % cuff pressure
    for_pktrf_Osc_b_mat{i,2}= pktrf_Osc_b{i,3}; % mean osc amp
    for_pktrf_Osc_b_mat{i,3}= pktrf_Osc_b{i,4}; % min osc amp
    for_pktrf_Osc_b_mat{i,4}= pktrf_Osc_b{i,5}; % max osc amp
end

%Remove empty rows

EmptyRows_pktrf_osc_b = any(cellfun(@isempty, for_pktrf_Osc_b_mat), 2);
for_pktrf_Osc_b_mat1 = for_pktrf_Osc_b_mat(~EmptyRows_pktrf_osc_b, :);

pktrf_Osc_b_mat = cell2mat(for_pktrf_Osc_b_mat1);

%%
%figure (17)
%hold on

for i= 1:size(pktrf_Osc_b,1)
%    plot (cell{i,1} (:,1), cell{i,1} (:,2),'color', MediumGreen_1);
    
%    scatter (pktrf_Osc_b{i,1}(:,2),pktrf_Osc_b{i,1}(:,1));
%    scatter (pktrf_Osc_b{i,1}(:,6), pktrf_Osc_b{i,1}(:,5));
end
%hold off

%xlabel ('time in seconds');
%grid on
%legend 'pktrf_Osc_a';
%title (expt_id);

%saveas(gcf,[expt_id 'fig17.fig']);

%% %%
%figure (100)
%hold on
for i = 1: size (pktrf_Osc_b,1)
    for j = 1:size(pktrf_Osc_b{i,1},1)
%        plot(pktrf_Osc_b{i,1}(j,1), pktrf_Osc_b{i,1}(j,9), 'o', 'MarkerSize', 4, 'color', 'k' );
    end
end
%hold off

%saveas(gcf,[expt_id 'fig100.fig']);

%%
% 
%Fit Oscillation amplitude vs cuff pressure with smoothing spline
cuffPresOsc = pktrf_Osc_b_mat(:,1);
meanOsc = pktrf_Osc_b_mat(:,2);
minOsc = pktrf_Osc_b_mat(:,3);
maxOsc = pktrf_Osc_b_mat(:,4);

if hcp - Sys_rms >20 % condition added on 21 May2025
    minOsc_Value_for00(:,1) = cuffPresOsc(cuffPresOsc < Sys_rms) ; % sometimes there are very high oscillations above sys. Remove those
    minOsc_Value_for00(:,2) = minOsc(cuffPresOsc < Sys_rms);
else
    minOsc_Value_for00(:,1) = cuffPresOsc(cuffPresOsc < hcp-15) ; % sometimes there are very high oscillations above sys. Remove those
    minOsc_Value_for00(:,2) = minOsc(cuffPresOsc < hcp-15);
end

if exist('loc_pk_fitpolyrms', 'var') && ~isempty(loc_pk_fitpolyrms)
    if loc_pk_fitpolyrms > 40
        minOsc_Value_for0 = minOsc_Value_for00(minOsc_Value_for00(:,1)> loc_pk_fitpolyrms+10, :);
    else
        minOsc_Value_for0 = minOsc_Value_for00(minOsc_Value_for00(:,1)> loc_pk_fitpolyrms+15, :);
    end
    
elseif exist('max_rms_pk_CP', 'var') && ~isempty (Dia_max_rms_pk_CP)
    if Dia_max_rms_pk_CP > 60
        minOsc_Value_for0 = minOsc_Value_for00(minOsc_Value_for00(:,1)> (Dia_max_rms_pk_CP-30), :);
    elseif  Dia_max_rms_pk_CP > 50
        minOsc_Value_for0 = minOsc_Value_for00(minOsc_Value_for00(:,1)> Dia_max_rms_pk_CP-20, :);
    else
        minOsc_Value_for0 = minOsc_Value_for00(minOsc_Value_for00(:,1)> Dia_max_rms_pk_CP, :);
    end
else
    minOsc_Value_for0= minOsc_Value_for00;
end

minOscvalueDiff = diff(minOsc_Value_for0(:,2));
minOsc_Value_for1 = minOsc_Value_for0;

for i = 1:size(minOsc_Value_for1,1)
    if minOsc_Value_for1(i,1)<35
        minOsc_Value_for1(i,:)=NaN;
    end
end

minOsc_Value_for2 = minOsc_Value_for0;

for i = 1:size(minOsc_Value_for2,1)
    if minOsc_Value_for2(i,1)<30
        minOsc_Value_for2(i,:)=NaN;
    end
end

cuffPresOscmin1 = minOsc_Value_for1(:,1);
minOsc1 = minOsc_Value_for1(:,2);

minOsc_highestValue = max(nonzeros(minOsc_Value_for1(:,2)));
minOsc_lowestValue = min(nonzeros(minOsc_Value_for2(:,2)));
minOsc_highest_amp = minOsc_highestValue - minOsc_lowestValue;

minOsc_highthreshold1 = minOsc_lowestValue + minOsc_highest_amp*0.65;
minOsc_highthreshold2 = minOsc_lowestValue + minOsc_highest_amp*0.8;

minOsc_lowthreshold1 = minOsc_lowestValue + minOsc_highest_amp*0.4;
minOsc_lowthreshold2 = minOsc_lowestValue + minOsc_highest_amp*0.3;

%For MAP consideration:
minOsc_MAPlogical_1 = minOsc_Value_for1(:,2) > minOsc_highthreshold1;
minOsc_MAPlogical_2 = minOsc_Value_for1(:,2) > minOsc_highthreshold2;

minOscMAPcandidates_1(:,1) =cuffPresOscmin1(minOsc_MAPlogical_1);
minOscMAPcandidates_1(:,2) = minOsc1(minOsc_MAPlogical_1);

minOscMAPcandidates_2(:,1) =cuffPresOscmin1(minOsc_MAPlogical_2);
minOscMAPcandidates_2(:,2) = minOsc1(minOsc_MAPlogical_2);
%%
if hcp - Sys_rms >20 % condition added on 21 May2025
    maxOsc_Value_for00(:,1) = cuffPresOsc(cuffPresOsc < Sys_rms); % sometimes there are very high oscillations beyond sys. Remove those Sysrms may be incorrect
    maxOsc_Value_for00(:,2) = maxOsc(cuffPresOsc < Sys_rms);
else
    maxOsc_Value_for00(:,1) = cuffPresOsc(cuffPresOsc < hcp-15) ; % sometimes there are very high oscillations below dia. Remove those
    maxOsc_Value_for00(:,2) = maxOsc(cuffPresOsc < hcp-15);
end

if exist('loc_pk_fitpolyrms', 'var') && ~isempty(loc_pk_fitpolyrms)
    if loc_pk_fitpolyrms > 40
        maxOsc_Value_for0 = maxOsc_Value_for00(maxOsc_Value_for00(:,1)> loc_pk_fitpolyrms+10, :);
    else
        maxOsc_Value_for0 = maxOsc_Value_for00(maxOsc_Value_for00(:,1)> loc_pk_fitpolyrms+15, :);
    end
    
elseif exist('max_rms_pk_CP', 'var') && ~isempty (Dia_max_rms_pk_CP)
    if Dia_max_rms_pk_CP > 60
        maxOsc_Value_for0 = maxOsc_Value_for00(maxOsc_Value_for00(:,1)> (Dia_max_rms_pk_CP-30), :);
    elseif  Dia_max_rms_pk_CP > 50
        maxOsc_Value_for0 = maxOsc_Value_for00(maxOsc_Value_for00(:,1)> Dia_max_rms_pk_CP-20, :);
    else
        maxOsc_Value_for0 = maxOsc_Value_for00(maxOsc_Value_for00(:,1)> Dia_max_rms_pk_CP, :);
    end
else
    maxOsc_Value_for0= maxOsc_Value_for00;
end

maxOsc_Value_for1 = maxOsc_Value_for0;

for i = 1:size(maxOsc_Value_for1,1)
    if maxOsc_Value_for1(i,1)<35
        maxOsc_Value_for1(i,:)=NaN;
    end
end

maxOsc_Value_for2 = maxOsc_Value_for0;

for i = 1:size(maxOsc_Value_for2,1)
    if maxOsc_Value_for2(i,1)<30
        maxOsc_Value_for2(i,:)=NaN;
    end
end

cuffPresOscmax1 = maxOsc_Value_for1(:,1);
maxOsc1 = maxOsc_Value_for1(:,2);

maxOsc_highestValue = max(nonzeros(maxOsc_Value_for1(:,2)));
maxOsc_lowestValue = min(nonzeros(maxOsc_Value_for2(:,2)));
maxOsc_highest_amp = maxOsc_highestValue - maxOsc_lowestValue;

maxOsc_highthreshold1 = maxOsc_lowestValue + maxOsc_highest_amp*0.65;
maxOsc_highthreshold2 = maxOsc_lowestValue + maxOsc_highest_amp*0.8;

maxOsc_lowthreshold1 = maxOsc_lowestValue + maxOsc_highest_amp*0.4;
maxOsc_lowthreshold2 = maxOsc_lowestValue + maxOsc_highest_amp*0.25;%changed only for max in view of ibp1101

maxOsc_MAPlogical_1 = maxOsc_Value_for1(:,2) > maxOsc_highthreshold1;
maxOsc_MAPlogical_2 = maxOsc_Value_for1(:,2) > maxOsc_highthreshold2;

maxOscMAPcandidates_1(:,1) =cuffPresOscmax1(maxOsc_MAPlogical_1);
maxOscMAPcandidates_1(:,2) = maxOsc1(maxOsc_MAPlogical_1);

maxOscMAPcandidates_2(:,1) =cuffPresOscmax1(maxOsc_MAPlogical_2);
maxOscMAPcandidates_2(:,2) =  maxOsc1(maxOsc_MAPlogical_2);
%%
if hcp - Sys_rms >20 % condition added on 21 May2025
    meanOsc_Value_for00(:,1) = cuffPresOsc(cuffPresOsc < Sys_rms); % sometimes there are very high oscillations beyond sys. Remove those
    meanOsc_Value_for00(:,2) = meanOsc(cuffPresOsc < Sys_rms);
else
    meanOsc_Value_for00(:,1) = cuffPresOsc(cuffPresOsc < hcp-15) ; % sometimes there are very high oscillations below dia. Remove those
    meanOsc_Value_for00(:,2) = meanOsc(cuffPresOsc < hcp-15);
end

if exist('loc_pk_fitpolyrms', 'var') && ~isempty(loc_pk_fitpolyrms)
    if loc_pk_fitpolyrms > 40
        meanOsc_Value_for0 = meanOsc_Value_for00(meanOsc_Value_for00(:,1)> loc_pk_fitpolyrms+10, :);
    else
        meanOsc_Value_for0 = meanOsc_Value_for00(meanOsc_Value_for00(:,1)> loc_pk_fitpolyrms+15, :);
    end
    
elseif exist('max_rms_pk_CP', 'var') && ~isempty (Dia_max_rms_pk_CP)
    if Dia_max_rms_pk_CP > 60
        meanOsc_Value_for0 = meanOsc_Value_for00(meanOsc_Value_for00(:,1)> (Dia_max_rms_pk_CP-30), :);
    elseif  Dia_max_rms_pk_CP > 50
        meanOsc_Value_for0 = meanOsc_Value_for00(meanOsc_Value_for00(:,1)> Dia_max_rms_pk_CP-20, :);
    else
        meanOsc_Value_for0 = meanOsc_Value_for00(meanOsc_Value_for00(:,1)> Dia_max_rms_pk_CP, :);
    end
else
    meanOsc_Value_for0= meanOsc_Value_for00;
end

meanOsc_Value_for1 = meanOsc_Value_for0;

for i = 1:size(meanOsc_Value_for1,1)
    if meanOsc_Value_for1(i,1)<35
        meanOsc_Value_for1(i,:)=NaN;
    end
end

meanOsc_Value_for2 = meanOsc_Value_for0;

for i = 1:size(meanOsc_Value_for2,1)
    if meanOsc_Value_for2(i,1)<30
        meanOsc_Value_for2(i,:)=NaN;
    end
end

cuffPresOscmean1 = meanOsc_Value_for1(:,1);
meanOsc1 = meanOsc_Value_for1(:,2);

meanOsc_highestValue = max(nonzeros(meanOsc_Value_for1(:,2)));
meanOsc_lowestValue = min(nonzeros(meanOsc_Value_for2(:,2)));
meanOsc_highest_amp = meanOsc_highestValue - meanOsc_lowestValue;

meanOsc_highthreshold1 = meanOsc_lowestValue + meanOsc_highest_amp*0.65;
meanOsc_highthreshold2 = meanOsc_lowestValue + meanOsc_highest_amp*0.8;

meanOsc_lowthreshold1 = meanOsc_lowestValue + meanOsc_highest_amp*0.4;
meanOsc_lowthreshold2 = meanOsc_lowestValue + meanOsc_highest_amp*0.3;

meanOsc_MAPlogical_1 =  meanOsc_Value_for1(:,2) > meanOsc_highthreshold1;
meanOsc_MAPlogical_2 = meanOsc_Value_for1(:,2) > meanOsc_highthreshold2;

meanOscMAPcandidates_1(:,1) =cuffPresOscmean1(meanOsc_MAPlogical_1);
meanOscMAPcandidates_1(:,2) = meanOsc1(meanOsc_MAPlogical_1);

meanOscMAPcandidates_2(:,1) =cuffPresOscmean1(meanOsc_MAPlogical_2);
meanOscMAPcandidates_2(:,2) = meanOsc1(meanOsc_MAPlogical_2);

%%
% Find the maximum length of the columns
maxLength_MAPcandiates = max([length(minOscMAPcandidates_1), length(meanOscMAPcandidates_1), length(maxOscMAPcandidates_1)]);

% Pad the columns with NaN (or 0) to match the maximum length
col1_paddedMAP = [minOscMAPcandidates_1(:,1); NaN(maxLength_MAPcandiates - size(minOscMAPcandidates_1,1), 1)];
col2_paddedMAP = [meanOscMAPcandidates_1(:,1); NaN(maxLength_MAPcandiates - size(meanOscMAPcandidates_1,1), 1)];
col3_paddedMAP = [maxOscMAPcandidates_1(:,1); NaN(maxLength_MAPcandiates - size(maxOscMAPcandidates_1,1), 1)];
col4_paddedMAP = [minOscMAPcandidates_2(:,1); NaN(maxLength_MAPcandiates - size(minOscMAPcandidates_2,1), 1)];
col5_paddedMAP = [meanOscMAPcandidates_2(:,1); NaN(maxLength_MAPcandiates - size(meanOscMAPcandidates_2,1), 1)];
col6_paddedMAP = [maxOscMAPcandidates_2(:,1); NaN(maxLength_MAPcandiates - size(maxOscMAPcandidates_2,1), 1)];
%%
% Combine the padded columns into a matrix
minMeanMaxMAPcandidates = [col1_paddedMAP, col2_paddedMAP, col3_paddedMAP, col4_paddedMAP, col5_paddedMAP, col6_paddedMAP];

for i = 1:size(minMeanMaxMAPcandidates,1)
    for j = 1:6
        if minMeanMaxMAPcandidates(i,j)< 55 || minMeanMaxMAPcandidates(i,j)>=Sys_rms
            minMeanMaxMAPcandidates(i,j)=NaN;
        end
    end
end

%Removing all NANs
for i = 1: size(minMeanMaxMAPcandidates,1)
    MAPcandidatesNaNlogical(i,1)= all(all(isnan(minMeanMaxMAPcandidates(i, :))));
end

minMeanMaxMAPcandidates = minMeanMaxMAPcandidates(~MAPcandidatesNaNlogical, :);

%%
%if there is any NaN in top row, shift cells up
if size(minMeanMaxMAPcandidates,1)>2
    for i = 2:size(minMeanMaxMAPcandidates,1)-1
        for j = 1:6
            if ~isnan(minMeanMaxMAPcandidates(i,j))
                if all(isnan(minMeanMaxMAPcandidates(1:i-1, j)))
                    minMeanMaxMAPcandidates(1:end-i+1,j)= minMeanMaxMAPcandidates(i:end,j);
                    minMeanMaxMAPcandidates(end-1:end,j)= NaN;
                end
            end
        end
    end
elseif size(minMeanMaxMAPcandidates,1)==2
    for j = 1:6
        if isnan(minMeanMaxMAPcandidates(1,j))&& ~isnan(minMeanMaxMAPcandidates(2,j))
            minMeanMaxMAPcandidates(1,j) = minMeanMaxMAPcandidates(2,j);
            minMeanMaxMAPcandidates(2,j) = NaN;
        end
    end
end

%sometimes there are more than 1 plateau at same cuff pressure; Make these
%unique
addrowsMMMMAPC = [];
addrowsMMMMAPC(1:2, 1:6)=NaN;
minMeanMaxMAPcandidates = [minMeanMaxMAPcandidates; addrowsMMMMAPC];

for i = 1:size(minMeanMaxMAPcandidates,1)-2
    for j = 1:6
        if minMeanMaxMAPcandidates(i,j)-minMeanMaxMAPcandidates(i+2, j)<3
            minMeanMaxMAPcandidates(i:end-2,j)= minMeanMaxMAPcandidates(i+2:end,j);
            minMeanMaxMAPcandidates(end-1:end,j)= NaN;
        elseif minMeanMaxMAPcandidates(i,j)-minMeanMaxMAPcandidates(i+1, j)<3
            minMeanMaxMAPcandidates(i:end-1,j)= minMeanMaxMAPcandidates(i+1:end,j);
            minMeanMaxMAPcandidates(end,j)= NaN;
        end
    end
end

% To keep numbers in a row equal
for i = 1:size(minMeanMaxMAPcandidates,1)-1
    for j = 1:6
        if ~isnan (minMeanMaxMAPcandidates(i,j))
            if minMeanMaxMAPcandidates(i,j)< max(minMeanMaxMAPcandidates(i,:))
                minMeanMaxMAPcandidates(i+1:end,j)= minMeanMaxMAPcandidates(i:end-1,j);
                minMeanMaxMAPcandidates(i,j)= NaN;
            end
        end
    end
end

for i = 1:size(minMeanMaxMAPcandidates,1)-1
    for j = 1:6
        if minMeanMaxMAPcandidates(i,j)== max(minMeanMaxMAPcandidates(i+1,:))
            minMeanMaxMAPcandidates(i,j)= NaN;
        end
    end
end

for i = 1:size(minMeanMaxMAPcandidates,1)-2
    for j = 1:6
        if minMeanMaxMAPcandidates(i,j)-minMeanMaxMAPcandidates(i+2, j)<3
            minMeanMaxMAPcandidates(i:end-2,j)= minMeanMaxMAPcandidates(i+2:end,j);
            minMeanMaxMAPcandidates(end-1:end,j)= NaN;
        elseif minMeanMaxMAPcandidates(i,j)-minMeanMaxMAPcandidates(i+1, j)<3
            minMeanMaxMAPcandidates(i:end-1,j)= minMeanMaxMAPcandidates(i+1:end,j);
            minMeanMaxMAPcandidates(end,j)= NaN;
        end
    end
end

%Removing all NANs
for i = 1: size(minMeanMaxMAPcandidates,1)
    MAPcandidatesNaNlogical_1 (i,1)= all(isnan(minMeanMaxMAPcandidates(i, :)));
end

minMeanMaxMAPcandidates = minMeanMaxMAPcandidates(~MAPcandidatesNaNlogical_1, :);

sort_minMeanMaxMAPcandidates = [minMeanMaxMAPcandidates(:,1); minMeanMaxMAPcandidates(:,2); minMeanMaxMAPcandidates(:,3); minMeanMaxMAPcandidates(:,4); minMeanMaxMAPcandidates(:,5); minMeanMaxMAPcandidates(:,6)];
sort_minMeanMaxMAPcandidates = sort(sort_minMeanMaxMAPcandidates);

% Step 2: Find unique values excluding NaN values
unique_minMeanMaxMAPcandidates  = unique(sort_minMeanMaxMAPcandidates(~isnan(sort_minMeanMaxMAPcandidates)));
unique_minMeanMaxMAPcandidates  = sort(unique_minMeanMaxMAPcandidates, 'descend');

addrowsMMMMAPC = nan((size(unique_minMeanMaxMAPcandidates,1)-size(minMeanMaxMAPcandidates,1))*2, 6);
addrowsuniqueMAP = nan((size(unique_minMeanMaxMAPcandidates,1)-size(minMeanMaxMAPcandidates,1)), 1); % adding rows for rearrangement
% adding rows for rearrangement
minMeanMaxMAPcandidates = [minMeanMaxMAPcandidates; addrowsMMMMAPC];
unique_minMeanMaxMAPcandidates = [unique_minMeanMaxMAPcandidates; addrowsuniqueMAP];

if size(minMeanMaxMAPcandidates,2)>6
    minMeanMaxMAPcandidates(:,7:end)=[];
end % Is this loop analogous to rendering empty in case of repeats?

minMeanMaxMAPcandidates = [minMeanMaxMAPcandidates, unique_minMeanMaxMAPcandidates];

%Removing all NANs
for i = 1: size(minMeanMaxMAPcandidates,1)
    MAPcandidatesNaNlogical_2 (i,1)= all(isnan(minMeanMaxMAPcandidates(i, :)));
end

minMeanMaxMAPcandidates = minMeanMaxMAPcandidates(~MAPcandidatesNaNlogical_2, :);

%%
minOsc_SDlogical_1 = minOsc < minOsc_lowthreshold1;
minOscSDcandidates(:,1) = cuffPresOsc(minOsc_SDlogical_1);
minOscSDcandidates(:,2) = minOsc(minOsc_SDlogical_1);

minOsc_SDlogical_1 = minOsc < minOsc_lowthreshold1;
minOsc_SDlogical_2 = minOsc < minOsc_lowthreshold2;

minOscSDcandidates_1(:,1) =cuffPresOsc(minOsc_SDlogical_1);
minOscSDcandidates_1(:,2) = minOsc(minOsc_SDlogical_1);

minOscSDcandidates_2(:,1) =cuffPresOsc(minOsc_SDlogical_2);
minOscSDcandidates_2(:,2) = minOsc(minOsc_SDlogical_2);

maxOsc_SDlogical_1 = maxOsc < maxOsc_lowthreshold1;
maxOsc_SDlogical_2 = maxOsc < maxOsc_lowthreshold2;

maxOscSDcandidates_1(:,1) =cuffPresOsc(maxOsc_SDlogical_1);
maxOscSDcandidates_1(:,2) = maxOsc(maxOsc_SDlogical_1);

maxOscSDcandidates_2(:,1) =cuffPresOsc(maxOsc_SDlogical_2);
maxOscSDcandidates_2(:,2) = maxOsc(maxOsc_SDlogical_2);

meanOsc_SDlogical_1 = meanOsc < meanOsc_lowthreshold1;
meanOsc_SDlogical_2 = meanOsc < meanOsc_lowthreshold2;

meanOscSDcandidates_1(:,1) =cuffPresOsc(meanOsc_SDlogical_1);
meanOscSDcandidates_1(:,2) = meanOsc(meanOsc_SDlogical_1);

meanOscSDcandidates_2(:,1) =cuffPresOsc(meanOsc_SDlogical_2);
meanOscSDcandidates_2(:,2) = meanOsc(meanOsc_SDlogical_2);

% Find the maximum length of the columns
maxLength_SDcandiates = max([length(minOscSDcandidates_1), length(meanOscSDcandidates_1), length(maxOscSDcandidates_1)]);

% Pad the columns with NaN (or 0) to match the maximum length
col1_paddedSD = [minOscSDcandidates_1(:,1); NaN(maxLength_SDcandiates - size(minOscSDcandidates_1,1), 1)];
col2_paddedSD = [meanOscSDcandidates_1(:,1); NaN(maxLength_SDcandiates - size(meanOscSDcandidates_1,1), 1)];
col3_paddedSD = [maxOscSDcandidates_1(:,1); NaN(maxLength_SDcandiates - size(maxOscSDcandidates_1,1), 1)];
col4_paddedSD = [minOscSDcandidates_2(:,1); NaN(maxLength_SDcandiates - size(minOscSDcandidates_2,1), 1)];
col5_paddedSD = [meanOscSDcandidates_2(:,1); NaN(maxLength_SDcandiates - size(meanOscSDcandidates_2,1), 1)];
col6_paddedSD = [maxOscSDcandidates_2(:,1); NaN(maxLength_SDcandiates - size(maxOscSDcandidates_2,1), 1)];

% Combine the padded columns into a matrix
minMeanMaxSDcandidates = [col1_paddedSD, col2_paddedSD, col3_paddedSD, col4_paddedSD, col5_paddedSD, col6_paddedSD];

%sometimes there are more than 1 plateau at same cuff pressure; Make these
%unique

%It is necessary to add some rows to allow operations
addrowsMMMSDC(1:2, 1:6)=NaN;
minMeanMaxSDcandidates = [minMeanMaxSDcandidates; addrowsMMMSDC];

for i = 1:size(minMeanMaxSDcandidates,1)-2
    for j = 1:6
        if minMeanMaxSDcandidates(i,j)-minMeanMaxSDcandidates(i+2, j)<3
            minMeanMaxSDcandidates(i:end-2,j)= minMeanMaxSDcandidates(i+2:end,j);
            minMeanMaxSDcandidates(end-1:end,j)= NaN;
        elseif minMeanMaxSDcandidates(i,j)-minMeanMaxSDcandidates(i+1, j)<3
            minMeanMaxSDcandidates(i:end-1,j)= minMeanMaxSDcandidates(i+1:end,j);
            minMeanMaxSDcandidates(end,j)= NaN;
        end
    end
end

%Removing NaNs at the top rows to reduce size

for i = 2:size(minMeanMaxSDcandidates,1)-1
    for j = 1:6
        if ~isnan(minMeanMaxSDcandidates(i,j)) && all(isnan(minMeanMaxSDcandidates(1:i-1,j)))
            minMeanMaxSDcandidates(1:end-i+1,j)= minMeanMaxSDcandidates(i:end,j);
            minMeanMaxSDcandidates(end-i-1:end, j)=NaN;
        end
    end
end

% To keep numbers in a row equal
for i = 1:size(minMeanMaxSDcandidates,1)-1
    for j = 1:6
        if minMeanMaxSDcandidates(i,j)< max(minMeanMaxSDcandidates(i,:))
            minMeanMaxSDcandidates(i+1:end,j)= minMeanMaxSDcandidates(i:end-1,j);
            minMeanMaxSDcandidates(i,j)= NaN;
        end
    end
end

%Removing all NANs
for i = 1: size(minMeanMaxSDcandidates,1)
    if any(isnan(minMeanMaxSDcandidates(:,1)))
        SDcandidatesNaNlogical (i,1)= all(isnan(minMeanMaxSDcandidates(i, :)));
    else
        SDcandidatesNaNlogical (i,1)= all(all(isnan(minMeanMaxSDcandidates(i, 2:6))));
    end
end

minMeanMaxSDcandidates = minMeanMaxSDcandidates(~SDcandidatesNaNlogical, :);

%%
sort_minMeanMaxSDcandidates = [minMeanMaxSDcandidates(:,1); minMeanMaxSDcandidates(:,2); minMeanMaxSDcandidates(:,3); minMeanMaxSDcandidates(:,4); minMeanMaxSDcandidates(:,5); minMeanMaxSDcandidates(:,6)];
sort_minMeanMaxSDcandidates = sort(sort_minMeanMaxSDcandidates);
%%
% Step 2: Find unique values excluding NaN values
unique_minMeanMaxSDcandidates  = unique(sort_minMeanMaxSDcandidates(~isnan(sort_minMeanMaxSDcandidates)));
unique_minMeanMaxSDcandidates  = sort(unique_minMeanMaxSDcandidates, 'descend');

addrowsMMMSDC = nan((size(unique_minMeanMaxSDcandidates,1)-size(minMeanMaxSDcandidates,1))*2, 6);
addrowsunique = nan((size(unique_minMeanMaxSDcandidates,1)-size(minMeanMaxSDcandidates,1)), 1); % adding rows for rearrangement
% adding rows for rearrangement
minMeanMaxSDcandidates = [minMeanMaxSDcandidates; addrowsMMMSDC];
unique_minMeanMaxSDcandidates = [unique_minMeanMaxSDcandidates; addrowsunique];

minMeanMaxSDcandidates = [minMeanMaxSDcandidates, unique_minMeanMaxSDcandidates];

minMeanMaxSDcandidates(1:end-1,8)= -diff(minMeanMaxSDcandidates(:,7)); 

%%
%sometimes there are tiny oscillations in all plateaus, that may confuse
%the picture. If there are no NaNs in column 7, then do not use the
%minoscillations. Checking mean and max as well..If there are no sufficient
%rows with NaNs,(Nans are pressures near MAP). 

%Do this exercise ONLY after confirming that there is no big gap in the
%pressure values

if all(minMeanMaxSDcandidates(:,8)<15)
    for i = 1:size(minMeanMaxSDcandidates,1)
        for j = 1:size(minMeanMaxSDcandidates,2)
            NaNs_minMeanMaxSDcandidates (i,j) = isnan(minMeanMaxSDcandidates(i,j));
        end
    end
    
    for j = 1:size(minMeanMaxSDcandidates,2)
        NaN_numberMMMSD(1,j) = sum(NaNs_minMeanMaxSDcandidates(2:end-1,j)); %usig 2 to end-1 because we dont expect naNs in extreme ends
    end
    
    if any(NaN_numberMMMSD <2)
        minMeanMaxSDcandidates_original = minMeanMaxSDcandidates;%saving a copy of original
        for j = 1:6
            if NaN_numberMMMSD(1,j)<2
                minMeanMaxSDcandidates(:,j)=NaN;
            end
        end
    end
    
    %Removing all NANs
    for i = 1: size(minMeanMaxSDcandidates,1)
        if any(isnan(minMeanMaxSDcandidates(:,1)))
            SDcandidatesNaNlogical_1(i,1)= all(isnan(minMeanMaxSDcandidates(i, :)));
        else
            SDcandidatesNaNlogical_1(i,1)= all(all(isnan(minMeanMaxSDcandidates(i, 2:6))));
        end
    end
    
    minMeanMaxSDcandidates = minMeanMaxSDcandidates(~SDcandidatesNaNlogical_1, :);
end

%%
forCat_SDandMAP = max(size(minMeanMaxSDcandidates,1), size(minMeanMaxMAPcandidates,1));

col1_paddedSDandMAP = [minMeanMaxSDcandidates(:,7); NaN(forCat_SDandMAP - size(minMeanMaxSDcandidates,1), 1)];
col2_paddedSDandMAP = [minMeanMaxMAPcandidates(:,7); NaN(forCat_SDandMAP - size(minMeanMaxMAPcandidates,1), 1)];

MMMSDandMAP = [col1_paddedSDandMAP, col2_paddedSDandMAP];

addrows_MMMSDandMAP = NaN(forCat_SDandMAP,2);
MMMSDandMAP = [MMMSDandMAP; addrows_MMMSDandMAP];

% To keep numbers in a row equal
for i = 1:size(MMMSDandMAP,1)-1
    for j = 1:2
        if MMMSDandMAP(i,j)< max(MMMSDandMAP(i,:))
            MMMSDandMAP(i+1:end,j)= MMMSDandMAP(i:end-1,j);
            MMMSDandMAP(i,j)= NaN;
        end
    end
end

%MMMSDandMAP_Sysguess:
for i = 1:size(MMMSDandMAP,1)-1
    if MMMSDandMAP(i,1) < Sys_rms+10
        if ~isnan(MMMSDandMAP(i,1)) && isnan(MMMSDandMAP(i+1,1))
            Sysguess_MMMSDandMAP_Tr1 = MMMSDandMAP(i,1);
            break
        end
    end
end

if hcp<200 && Sysguess_MMMSDandMAP_Tr1 > hcp-15 % the method makes hcp 30 mmHg above guess value from ramp
    %Sysguess_MMMSDandMAP is wrong. Change it.
    for i = 1:size(MMMSDandMAP,1)/2
        if MMMSDandMAP(i,1)== Sysguess_MMMSDandMAP_Tr1
            MMMSDandMAP(i,:)= NaN;
        end
    end
end

%Find sysguess again
for i = 1:size(MMMSDandMAP,1)-1
    if MMMSDandMAP(i,1) < Sys_rms+10
        if ~isnan(MMMSDandMAP(i,1)) && isnan(MMMSDandMAP(i+1,1))
            Sysguess_MMMSDandMAP_Tr1 = MMMSDandMAP(i,1);
            break
        end
    end
end

for i = size(MMMSDandMAP,1)-1:-1:2
    if ~isnan(MMMSDandMAP(i,1)) && isnan(MMMSDandMAP(i-1,1))
        Diaguess_MMMSDandMAP_1Tr1 = MMMSDandMAP(i,1);
        break
    end
end

if  ~exist('Diaguess_MMMSDandMAP_1Tr1', 'var')% This is a repeat of above loop including last row. Above loop may be redundant. But scared to remove
    for i = size(MMMSDandMAP,1):-1:2
        if ~isnan(MMMSDandMAP(i,1)) && isnan(MMMSDandMAP(i-1,1))
            Diaguess_MMMSDandMAP_1Tr1 = MMMSDandMAP(i,1);
            break
        end
    end
end

if ~exist('Diaguess_MMMSDandMAP_1Tr1', 'var')|| Diaguess_MMMSDandMAP_1Tr1 >= Sysguess_MMMSDandMAP_Tr1 % try different strategy to get dia
    for i = size(MMMSDandMAP,1)-1:-1:2
        if (isnan(MMMSDandMAP(i,2)) && ~isnan(MMMSDandMAP(i-1,2))) && ~isnan(MMMSDandMAP(i,1))
            Diaguess_MMMSDandMAP_1Tr1 = MMMSDandMAP(i,1);
            break
        end
    end
end

if Diaguess_MMMSDandMAP_1Tr1 >= Sysguess_MMMSDandMAP_Tr1 % still, dia > systry different strategy to get sys
    MMMSDandMAP_forSysguess1 = MMMSDandMAP(~(MMMSDandMAP(:,1)<=Diaguess_MMMSDandMAP_1Tr1), :);
    for i = 1: size(MMMSDandMAP_forSysguess1,1)
        MMMSDandMAP_forsysLogical(i,1) = isnan(MMMSDandMAP_forSysguess1(i,2))&& ~isnan(MMMSDandMAP_forSysguess1(i,1));
    end
    MMMSDandMAP_forsys1 = MMMSDandMAP_forSysguess1(MMMSDandMAP_forsysLogical);
    
    for i = 1: size(MMMSDandMAP_forsys1,1)
        if abs(Sys_rms - MMMSDandMAP_forsys1(i,1))<20 || MMMSDandMAP_forsys1(i,1)- Diaguess_MMMSDandMAP_1Tr1 >20
            Sysguess_MMMSDandMAP_Tr1 = MMMSDandMAP_forsys1(i,1);
            break
        end
    end
end
%%
MMMSDandMAP_forSysguess = MMMSDandMAP(~isnan(MMMSDandMAP(:,1)),:);
MMMSDandMAP_forSysguess = MMMSDandMAP_forSysguess(~(~isnan(MMMSDandMAP_forSysguess(:,2))),:);
MMMSDandMAP_forSysguess (1:end-1,2)= diff(MMMSDandMAP_forSysguess(:,1));

[~, rmaxSysguess] = max(abs(MMMSDandMAP_forSysguess(:,2))); 
Sysguess_MMMSDandMAP_Tr2 = MMMSDandMAP_forSysguess(rmaxSysguess, 1);
Diaguess_MMMSDandMAP_1Tr2 = MMMSDandMAP_forSysguess(rmaxSysguess+1, 1);

if Diaguess_MMMSDandMAP_1Tr2 > max(minMeanMaxMAPcandidates(:,end)) && Dia_max_rms_pk_CP < max(minMeanMaxMAPcandidates(:,end))
    Diaguess_MMMSDandMAP_1Tr2 = Dia_max_rms_pk_CP;
else
    Diaguess_MMMSDandMAP_1Tr2 = Diaguess_MMMSDandMAP_1Tr1;
end

SysDiaMMMSD_array = [Sysguess_MMMSDandMAP_Tr1, Diaguess_MMMSDandMAP_1Tr1;
    Sysguess_MMMSDandMAP_Tr2 , Diaguess_MMMSDandMAP_1Tr2];

SysDiaMMMSD_array (:,3) = SysDiaMMMSD_array(:,1)- Sys_rms;
SysDiaMMMSD_array (:,4) = SysDiaMMMSD_array(:,2)- Sys_rms;

if SysDiaMMMSD_array(1,1)== SysDiaMMMSD_array(2,1)
    Sysguess_MMMSDandMAP = SysDiaMMMSD_array(1,1);
else
    for i = 1:2
        if abs(SysDiaMMMSD_array(i,3))== min(abs(SysDiaMMMSD_array(:,3)))
            Sysguess_MMMSDandMAP = SysDiaMMMSD_array(i,1);
        end
    end
end

if SysDiaMMMSD_array(1,2)== SysDiaMMMSD_array(2,2)
    Diaguess_MMMSDandMAP_1 = SysDiaMMMSD_array(1,2);
else
    SysDiaMMMSD_array(:,5)= Sysguess_MMMSDandMAP - SysDiaMMMSD_array(:,2);
    for i = 1:2
        if abs(SysDiaMMMSD_array(i,5))== min(abs(SysDiaMMMSD_array(:,5)))
            Diaguess_MMMSDandMAP_1 = SysDiaMMMSD_array(i,2);
        end
    end
end

%%
if ~exist('Diaguess_MMMSDandMAP_1', 'var')
    for i = size(MMMSDandMAP,1)-1:-1:2
        if (~isnan(MMMSDandMAP(i,1)) && isnan(MMMSDandMAP(i-1,1))) || (~isnan(MMMSDandMAP(i-1,1)) && ~isnan(MMMSDandMAP(i-1,2)))
            Diaguess_MMMSDandMAP_1 = MMMSDandMAP(i,1);
            break
        end
    end
end
%%
%Added on 16May2025
if ~exist('Diaguess_MMMSDandMAP_1', 'var') && ~isnan(MMMSDandMAP(end,1))
    Diaguess_MMMSDandMAP_1 = MMMSDandMAP(end,1);
end

%%
MMMSDandMAP_trimmed = MMMSDandMAP(MMMSDandMAP(:,1)<=Diaguess_MMMSDandMAP_1, :);

for i = 1: size(MMMSDandMAP_trimmed,1)
    if ~isnan(MMMSDandMAP_trimmed(i,1)) && isnan(MMMSDandMAP_trimmed(i,2))
        Diaguess_MMMSDandMAP_2 = MMMSDandMAP_trimmed(i,1);
        break
    elseif ~isnan(MMMSDandMAP_trimmed(i,1)) && ~isnan(MMMSDandMAP_trimmed(i,2))
        Diaguess_MMMSDandMAP_2 = Diaguess_MMMSDandMAP_1;
    end
end

if Diaguess_MMMSDandMAP_1 == Diaguess_MMMSDandMAP_2
    Diaguess_MMMSDandMAP_2 = Diaguess_MMMSDandMAP_1 - 4;
end

%%
MMMSDandMAP_1 = MMMSDandMAP;

for i = 2:size(MMMSDandMAP_1, 1)
    if MMMSDandMAP_1(i,2)< Sysguess_MMMSDandMAP
        if isnan(MMMSDandMAP_1(i-1,2)) || MMMSDandMAP_1(i-1,2)>= Sysguess_MMMSDandMAP-5
            MMMSDandMAP_1 (1:i-1, :)=NaN;
            break
        end
    end
end

for i = size(MMMSDandMAP_1, 1)-1:-1:1
    if MMMSDandMAP_1(i,2)>= min([Diaguess_MMMSDandMAP_1, Diaguess_MMMSDandMAP_2])
        MMMSDandMAP_1 (i+1:end, :)=NaN;
        break
    end
end

% Find rows where all elements are NaN
for i = 1:size(MMMSDandMAP_1,1)
    rTD_MMMSDandMAP_1 (i, 1)= all(all(isnan(MMMSDandMAP_1 (i,1:2))));
end

% Remove rows with zeros
MMMSDandMAP_1(rTD_MMMSDandMAP_1, :) = []; % column 1 here is low values and column2 peak values

MAP_calc_MMMSD(1,1) = round(Diaguess_MMMSDandMAP_2 + 0.4*((Sysguess_MMMSDandMAP-3)-Diaguess_MMMSDandMAP_2));
MAP_calc_MMMSD(1,2) = round(Diaguess_MMMSDandMAP_1 + 0.33*(Sysguess_MMMSDandMAP-Diaguess_MMMSDandMAP_1));

MMMSDandMAP_1(:,3) = MMMSDandMAP_1(:,2)-MAP_calc_MMMSD(:,1);
MMMSDandMAP_1(:,4) = MMMSDandMAP_1(:,2)-MAP_calc_MMMSD(:,2);

%[~, rI_MMMSDandMAP_1high] = min(abs(MMMSDandMAP_1(:,3))); % Dont say nonzeros here - 
[~, rI_MMMSDandMAP_1high] = min(abs(MMMSDandMAP_1(:,4)));%Bug detected on 19Aug2025. Col 4 is for high MAP
MAP_calc_MMMSD_match_high = MMMSDandMAP_1(rI_MMMSDandMAP_1high, 2);

for i = 1:size(MMMSDandMAP_1,1)
    if MMMSDandMAP_1(i,2) == MAP_calc_MMMSD_match_high
        if i ~= 1 && i~= size(MMMSDandMAP_1,1)
            if ~isnan(MMMSDandMAP_1(i-1,2))
                MAP_higherlimitOscDatapoints_a = MMMSDandMAP_1(i-1, 2);
            else
                MAP_higherlimitOscDatapoints_a = MMMSDandMAP_1(i, 2)+5;
            end
            
        elseif i == 1 && size(MMMSDandMAP_1,1)==1
            MAP_higherlimitOscDatapoints_a = MMMSDandMAP_1(i,2)+3;
        elseif i == 1 && size(MMMSDandMAP_1,1)>1
            MAP_higherlimitOscDatapoints_a = MMMSDandMAP_1(i,2);
            if ~isnan(MMMSDandMAP_1(i+1,2))
            end
        elseif i == size(MMMSDandMAP_1,1) && size(MMMSDandMAP_1,1)==2
            if  ~isnan(MMMSDandMAP_1(i-1,2))
                MAP_higherlimitOscDatapoints_a = MMMSDandMAP_1(i-1,2);
            else
                MAP_higherlimitOscDatapoints_a = MMMSDandMAP_1(i,2)+ 5;
            end
        elseif i == size(MMMSDandMAP_1,1) && size(MMMSDandMAP_1,1)> 2
            if  ~isnan(MMMSDandMAP_1(i-1,2))
                MAP_higherlimitOscDatapoints_a = MMMSDandMAP_1(i-2,2);
            else
                MAP_higherlimitOscDatapoints_a = MMMSDandMAP_1(i,2)+ 5;
            end
        end
    end
end

%[~, rI_MMMSDandMAP_1low] = min(abs(MMMSDandMAP_1(:,4))); % Dont say nonzeros here
[~, rI_MMMSDandMAP_1low] = min(abs(MMMSDandMAP_1(:,3)));%col3 is for low MAP
MAP_calc_MMMSD_match_low = MMMSDandMAP_1(rI_MMMSDandMAP_1low, 2);

for i = 1:size(MMMSDandMAP_1,1)
    if MMMSDandMAP_1(i,2) == MAP_calc_MMMSD_match_low
        if i ~= 1 && i~= size(MMMSDandMAP_1,1)
            if ~isnan(MMMSDandMAP_1(i+1,2))
                MAP_lowerlimitOscDatapoints_a = MMMSDandMAP_1(i+1, 2);
            else
                MAP_lowerlimitOscDatapoints_a = MMMSDandMAP_1(i, 2)-5;
            end
        elseif i == 1 && size(MMMSDandMAP_1,1)==1
            MAP_lowerlimitOscDatapoints_a = MMMSDandMAP_1(i,2)-3;
            
        elseif i == 1 && size(MMMSDandMAP_1,1)>1
            if ~isnan(MMMSDandMAP_1(i+1,2))
                MAP_lowerlimitOscDatapoints_a = MMMSDandMAP_1(i+1,2);
            else
                MAP_lowerlimitOscDatapoints_a = MMMSDandMAP_1(i,2)-5;
            end
        elseif i == size(MMMSDandMAP_1,1) && size(MMMSDandMAP_1,1)==2
            MAP_lowerlimitOscDatapoints_a = MMMSDandMAP_1(i,2);
            
        elseif i == size(MMMSDandMAP_1,1) && size(MMMSDandMAP_1,1)> 2
            MAP_lowerlimitOscDatapoints_a = MMMSDandMAP_1(i,2);
        end
    end
end

%%
for i=1:size(minMeanMaxSDcandidates,1)-1
    diffSD (i,2)= minMeanMaxSDcandidates(i,7)- minMeanMaxSDcandidates(i+1,7);
    diffSD (i,1)= minMeanMaxSDcandidates(i,7);
end

%case of 18091102 where there is a below threshold value at end
for i=1:size(diffSD,1)-1
    if diffSD (i,1)>  Sysguess_MMMSDandMAP +20 % It was 20 here, changed to 30 on 24Mar2025; changed to +20 as Sysrms has been replaced
        diffSD (i,:)= NaN;
    end
end

if max(diffSD(:,2))>20
    [maxdiffSD, rImaxdiffSD] = max(diffSD(2:end-1,2));
    if size(minMeanMaxSDcandidates,1)-(rImaxdiffSD+1) > size(minMeanMaxSDcandidates,1)/3 % if the max diff is in dia region, it is artifactual
        rImaxdiffSD = rImaxdiffSD;
    else
        [maxdiffSD, rImaxdiffSD] = max(diffSD(2:rImaxdiffSD,2));
    end
    minMeanMaxSysCand = minMeanMaxSDcandidates(1:rImaxdiffSD+1, :); % This has been changed to r+1 on 24 Mar2025 because we are starting with row 2
    minMeanMaxDiaCand = minMeanMaxSDcandidates(rImaxdiffSD+2:end, :);
else
    minMeanMaxDiaCand = minMeanMaxSDcandidates(minMeanMaxSDcandidates(:,1)<=Diaguess_MMMSDandMAP_1 + 5, :);
    minMeanMaxSysCand = minMeanMaxSDcandidates(minMeanMaxSDcandidates(:,1)> Diaguess_MMMSDandMAP_1 +15, :);
end
%%
if isempty(minMeanMaxDiaCand)|| isempty(minMeanMaxSysCand)
    minMeanMaxSDcandidates_tight = minMeanMaxSDcandidates(:,4:6);
    %Removing all NANs
    for i = 1: size(minMeanMaxSDcandidates_tight,1)
        if any(isnan(minMeanMaxSDcandidates_tight(:,1)))
            SDcandidatesNaNlogical_tight(i,1)= all(isnan(minMeanMaxSDcandidates_tight(i, :)));
        else
            SDcandidatesNaNlogical_tight(i,1)= all(all(isnan(minMeanMaxSDcandidates_tight(i, 2:6))));
        end
    end
    
    minMeanMaxSDcandidates_tight = minMeanMaxSDcandidates_tight(~SDcandidatesNaNlogical_tight, :);
    
    for i = 1:size(minMeanMaxSDcandidates_tight,1)
        for j = 1:3
            if ~isnan(minMeanMaxSDcandidates_tight(i, j))
                minMeanMaxSDcandidates_tight(i,4)= minMeanMaxSDcandidates_tight(i,j);
            end
        end
    end
    
    for i=1:size(minMeanMaxSDcandidates_tight,1)-1
        diffSD_tight (i,2)= minMeanMaxSDcandidates_tight(i, 4)- minMeanMaxSDcandidates_tight(i+1,4);
        diffSD_tight (i,1)= minMeanMaxSDcandidates_tight(i,4);
    end
    
    if max(diffSD_tight(:,2))>20
        [maxdiffSD_tight, rImaxdiffSD_tight] = max(diffSD_tight(2:end-1,2));
        if size(minMeanMaxSDcandidates_tight,1)-(rImaxdiffSD_tight+1) > size(minMeanMaxSDcandidates_tight,1)/3 % if the max diff is in dia region, it is artifactual
            rImaxdiffSD_tight = rImaxdiffSD_tight;
        else
            [maxdiffSD_tight, rImaxdiffSD_tight] = max(diffSD_tight(2:rImaxdiffSD_tight,2));
        end
        minMeanMaxSysCand_tight = minMeanMaxSDcandidates_tight(1:rImaxdiffSD_tight+1, :); % This has been changed to r+1 on 24 Mar2025 because we are starting with row 2
        minMeanMaxDiaCand_tight = minMeanMaxSDcandidates_tight(rImaxdiffSD_tight+2:end, :);
    else
        minMeanMaxDiaCand_tight = minMeanMaxSDcandidates_tight(minMeanMaxSDcandidates_tight(:,1)<=Diaguess_MMMSDandMAP_1 + 5, :);
        minMeanMaxSysCand_tight = minMeanMaxSDcandidates_tight(minMeanMaxSDcandidates_tight(:,1)> Diaguess_MMMSDandMAP_1 +15, :);
    end
end

%if minMeanMaxDiaCand and minMeanMaxSysCand are obtained from tight
%thresholds, then the column numbers will be different. To avoid confusion,
%maintain column numbers by replicating the three columns

if exist('minMeanMaxSysCand_tight', 'var')
    minMeanMaxSysCand_tight(:,5:7)=zeros;
    minMeanMaxSysCand_tight(:,7)= minMeanMaxSysCand_tight(:,4);
    minMeanMaxSysCand_tight(:,4:6)=minMeanMaxSysCand_tight(:,1:3);
    minMeanMaxSysCand = minMeanMaxSysCand_tight;
end

if exist('minMeanMaxDiaCand_tight', 'var')
    minMeanMaxDiaCand_tight(:,5:7)=zeros;
    minMeanMaxDiaCand_tight(:,7)= minMeanMaxDiaCand_tight(:,4);
    minMeanMaxDiaCand_tight(:,4:6)=minMeanMaxDiaCand_tight(:,1:3);
    minMeanMaxDiaCand = minMeanMaxDiaCand_tight;
end
%%
%Trim dia again
for i = 1: size(minMeanMaxDiaCand,1)
    for j = 1:6
        if minMeanMaxDiaCand(i,j)>= MAP_higherlimitOscDatapoints_a
            minMeanMaxDiaCand(i,j) = NaN;
        end
    end
end

for i = 1: size(minMeanMaxDiaCand,1)
    minMMMMDia_logical (i,1)= all(isnan(minMeanMaxDiaCand(i, 1:6)));
end

minMeanMaxDiaCand = minMeanMaxDiaCand(~minMMMMDia_logical, :);

%%
for i = 1:size(minMeanMaxSysCand,1)
    for j = 1:7
        if minMeanMaxSysCand(i,j)<= MAP_higherlimitOscDatapoints_a + 5% There is the possibility of adding a +5 here
            minMeanMaxSysCand(i,j) = NaN;
        end
    end
end

rTDminMeanMaxSysCand =  zeros(size(minMeanMaxSysCand,1), 1);

for i = 1:size(minMeanMaxSysCand,1)
    rTDminMeanMaxSysCand(i,1) = all(isnan(minMeanMaxSysCand(i,1:6)));
end

if sum(isnan(minMeanMaxSysCand(end, 1:6))) == 5 %Adding a caveat here: If there is only one entry in the last row, dont %consider unless the entry is in mean 16May2025
    rTDminMeanMaxSysCand(end,1)=1;
end

minMeanMaxSysCand = minMeanMaxSysCand(~rTDminMeanMaxSysCand, :);

for i = size(minMeanMaxSysCand,1):-1:1
    if ~isnan(minMeanMaxSysCand(i,7))
        PSyslowMay2025 = minMeanMaxSysCand(i,7);
        break
    elseif ~isnan(minMeanMaxSysCand(i,2))
        PSyslowMay2025 = minMeanMaxSysCand(i,2);
        break
    end
end

PSyshighMay2025For = minMeanMaxSysCand;
for i = 1:size(PSyshighMay2025For,1)
    if any(any(PSyshighMay2025For(i,:)== PSyslowMay2025))
        PSyshighMay2025For(i,:)= NaN;
    end
    
    if all(isnan(PSyshighMay2025For(i,1:7)))
        PSyshighMay2025For(i,8)= NaN;
    end
end

if any(any(~isnan(PSyshighMay2025For(:,:))))
    if any(any(~isnan(PSyshighMay2025For(:,[2,4]))))
        for i = size(PSyshighMay2025For,1):-1:1
            if ~isnan(PSyshighMay2025For(i,4))
                PSyshighMay2025Candidate1 = PSyshighMay2025For(i,4);
                break
            elseif ~isnan(PSyshighMay2025For(i,2))
                PSyshighMay2025Candidate1 = PSyshighMay2025For(i,2);
                break
            end
        end
    end
    
    if ~isempty(PSyshighMay2025For) & any(any(~isnan(PSyshighMay2025For(:,[1,3]))))
        for i = size(PSyshighMay2025For,1):-1:1
            if ~isnan(PSyshighMay2025For(i,3))
                PSyshighMay2025Candidate2 = PSyshighMay2025For(i,3);
                break
            elseif ~isnan(PSyshighMay2025For(i,1))
                PSyshighMay2025Candidate2 = PSyshighMay2025For(i,1);
                break
            end
        end
    end
    
else % if there are no entries in mean and max, choose from min
    
    PSyshighMay2025For = minMeanMaxSysCand(1:end-1, :);
    
    for i = size(PSyshighMay2025For,1):-1:1
        if ~isnan(PSyshighMay2025For(i,4))
            PSyshighMay2025Candidate1 = PSyshighMay2025For(i,4);
            break
        end
        if ~isnan(PSyshighMay2025For(i,1))
            PSyshighMay2025Candidate2 = PSyshighMay2025For(i,1);
            break
        end
    end
end

if ~exist('PSyshighMay2025Candidate1', 'var') && exist('PSyshighMay2025Candidate2', 'var')
    PSyshighMay2025Candidate1 = PSyshighMay2025Candidate2;
elseif ~exist('PSyshighMay2025Candidate2', 'var')&& exist('PSyshighMay2025Candidate1', 'var')
    PSyshighMay2025Candidate2 = PSyshighMay2025Candidate1;
end

if exist('PSyshighMay2025Candidate1', 'var') && exist('PSyshighMay2025Candidate2', 'var')
    PSyshighMay2025Candidates = [PSyshighMay2025Candidate1,PSyshighMay2025Candidate2];
    
    if Sys_rms - PSyslowMay2025 <= 30
        if Sys_rms >= max(PSyshighMay2025Candidates)
            PSyshighMay2025 = max(PSyshighMay2025Candidates);
        elseif Sys_rms <= min(PSyshighMay2025Candidates)
            PSyshighMay2025 = min(PSyshighMay2025Candidates);
        elseif Sys_rms < max(PSyshighMay2025Candidates) && Sys_rms > min(PSyshighMay2025Candidates)
            PSyshighMay2025 = Sys_rms;
        end
    elseif min(PSyshighMay2025Candidates)- PSyslowMay2025 >= 10
        PSyshighMay2025 = min(PSyshighMay2025Candidates);
    elseif max(PSyshighMay2025Candidates)- PSyslowMay2025 <=30
        PSyshighMay2025 = max(PSyshighMay2025Candidates);
    else
        PSyshighMay2025 = mean(PSyshighMay2025Candidates);
    end
end

if ~exist('PSyshighMay2025','var')
    PSyshighMay2025 = PSyslowMay2025;
end
%%
minMeanMaxDia = max(minMeanMaxDiaCand(:,1:3)); % gives the first value b below threshold in each of min mean and max

Pdialow_fromMMMDia = min(minMeanMaxDia);
Pdiahigh_fromMMMDia = max(minMeanMaxDia);

if Pdiahigh_fromMMMDia == Pdialow_fromMMMDia
    Pdialow_fromMMMDia = Pdiahigh_fromMMMDia - 4;
end

PDialowCalcMay2025_1 = round((MAP_calc_MMMSD(1,1) - 0.45*PSyslowMay2025)/0.55);
PDialowCalcMay2025_2 = round((MAP_calc_MMMSD(1,1) - 0.4*PSyslowMay2025)/0.6);
PDialowCalcMay2025_3 = round((MAP_calc_MMMSD(1,1) - 0.36*PSyslowMay2025)/0.64);

PDiahighCalcMay2025_1 = round((MAP_calc_MMMSD(1,2) - 0.36*PSyshighMay2025)/0.64);
PDiahighCalcMay2025_2 = round((MAP_calc_MMMSD(1,2) - 0.33*PSyshighMay2025)/0.67);
PDiahighCalcMay2025_3 = round((MAP_calc_MMMSD(1,2) - 0.27*PSyshighMay2025)/0.73);

PDiaCheck = zeros(7,5);
PDiaCheck(1, :) = [NaN, Diaguess_MMMSDandMAP_2, Pdialow_fromMMMDia, Diaguess_MMMSDandMAP_1, Pdiahigh_fromMMMDia];
PDiaCheck(2:7,1) =[PDialowCalcMay2025_1, PDialowCalcMay2025_2, PDialowCalcMay2025_3, PDiahighCalcMay2025_1, PDiahighCalcMay2025_2, PDiahighCalcMay2025_3];

PDiaCheck(2:4,2) = PDiaCheck(2:4,1)- PDiaCheck(1,2);
PDiaCheck(2:4,3) = PDiaCheck(2:4,1)- PDiaCheck(1,3);
PDiaCheck(5:7,4) = PDiaCheck(5:7,1)- PDiaCheck(1,4);
PDiaCheck(5:7,5) = PDiaCheck(5:7,1)- PDiaCheck(1,5);

for i = 2:4
    for j = 2:3
        if abs(PDiaCheck(i,j))== min(min(abs(PDiaCheck(2:4, 2:3))))
            PDialowMay2025 = PDiaCheck(1,j);
        end
    end
end

for i = 5:7
    for j = 4:5
        if abs(PDiaCheck(i,j))== min(min(abs(PDiaCheck(5:7, 4:5))))
            PDiahighMay2025 = PDiaCheck(1,j);
        end
    end
end

%%
PSysDiaMay2025 =[PSyslowMay2025, PSyshighMay2025, PDialowMay2025, PDiahighMay2025];%The dia values here are the values from actual oscillation amplitudes falling below thereshold that match calculated dia from MAP and sys

PSysDiaMay2025(1,5) = PSysDiaMay2025(1,3)+ 0.4*(PSysDiaMay2025(1,1)- PSysDiaMay2025(1,3));
PSysDiaMay2025(1,6) = PSysDiaMay2025(1,4)+ 0.33*(PSysDiaMay2025(1,2)- PSysDiaMay2025(1,4));

PSysDiaMay2025(1,7) = MAP_calc_MMMSD(1,1);
PSysDiaMay2025(1,8) = MAP_calc_MMMSD(1,2);

PSysDiaMay2025 = round(PSysDiaMay2025);
disp (PSysDiaMay2025);

% Reconsider Dia_max_rms_pk_CP

Dia_max_rms_pk_CP_1 = max(loc_pk_fitrmsratio(loc_pk_fitrmsratio< max(PSysDiaMay2025(1, 5:8))));

%%
%To enable sigmoid fits, correct any y2 data above sys value that is more
%than minimum, set it to the minimum

[x2Data, y2Data] = prepareCurveData(rmsmat1(:,1), rmsmat1(:,4));

for i = 1:size(y2Data,1) % To correct any rms value beyond high systolic
    if x2Data(i,1)> PSysDiaMay2025(1,2)
        y2Data(i,1)= min(y2Data);
    end
end

for  i = 2:size(y2Data,1) % To correct any rms value beyond low systolic
    if x2Data(i,1)> PSysDiaMay2025(1,1)
        if y2Data(i,1)> 2*(y2Data(i-1,1))
            y2Data(i,1)= y2Data(i-1,1);
        end
    end
end

%To correct any rms value at low cuff pressures (to enable better sigmoid fits)
if y2Data(end,1)>(y2Data(end-1,1))
    y2Data(end,1)= y2Data(end-1,1);
end

% Set up fittype and options.
ftrms13 = fittype( 'a./(1+(x./c).^b)', 'independent', 'x', 'dependent', 'y' );
optsrms13 = fitoptions( 'Method', 'NonlinearLeastSquares' );
optsrms13.Algorithm = 'Levenberg-Marquardt';
optsrms13.Display = 'Off';
optsrms13.Robust = 'Bisquare';
optsrms13.StartPoint = [0.5 5 50];% changed
%optsrms13.StartPoint = [0.5 5 5];% changed

% Fit model to data.
[fitresult{18}, gof(18)] = fit( x2Data, y2Data, ftrms13, optsrms13 );
coefficientsrms13= coeffvalues(fitresult{18});
halfrms13 = coefficientsrms13 (:,3);
ymax_rms13 = coefficientsrms13 (:,1);

% plot (x2Data, y2Data);
%%
%tangents to 3PL fit
% Generate upper horizontal in 3PL
yuhrms13= (fitresult{18}(1:1:30));
xuhrms1t3 = (1:1:30);
xuhrms13=transpose(xuhrms1t3);

% Fit upper horizontal line to 3PL  ratios
[xuhrms13, yuhrms13] = prepareCurveData( xuhrms13, yuhrms13 );
fituhrms13 = fittype( 'm*x+c', 'independent', 'x', 'dependent', 'y' );
optsuhrms13 = fitoptions( 'Method', 'NonlinearLeastSquares' );
optsuhrms13.Algorithm = 'Levenberg-Marquardt';
optsuhrms13.Display = 'Off';
optsuhrms13.Robust = 'Bisquare';
optsuhrms13.StartPoint = [ ymax_rms13 0.01];

[fitresult{20}, gof(20)] = fit( xuhrms13, yuhrms13, fituhrms13, optsuhrms13 );

coefficients_uhrms1_3= coeffvalues(fitresult{20});
fitxuhrms13 = ((20:1:120));
fityuhrms13 = (fitresult{20} (20:1:120));

%%
% Generate midtangent in 3PL
a_rms13=coefficientsrms13(1,1);
b_rms13=coefficientsrms13(1,2);
c_rms13=coefficientsrms13(1,3);
%
y_rms13a = yuhrms13 (1,1)* (7/8);
y_rms13b = yuhrms13 (1,1)* (3/4);
y_rms13new = yuhrms13 (1,1)/2;
y_rms13_1=yuhrms13 (1,1)/4;
y_rms13_2 = yuhrms13 (1,1)/8;

y_rms13b_3new = (y_rms13b+y_rms13new)/2;
y_rms13new_3_1 = (y_rms13new+y_rms13_1)/2;
%
x_rms13a = c_rms13 * (((a_rms13/y_rms13a)-1)^(1/b_rms13));
x_rms13b = c_rms13 * (((a_rms13/y_rms13b)-1)^(1/b_rms13));
x_rms13new = c_rms13 * (((a_rms13/y_rms13new)-1)^(1/b_rms13));
x_rms13_1 = c_rms13 *(((a_rms13./y_rms13_1)-1).^(1/b_rms13));
x_rms13_2 = c_rms13 *(((a_rms13./y_rms13_2)-1).^(1/b_rms13));

x_rms13b_3new = c_rms13 * (((a_rms13/ y_rms13b_3new)-1)^(1/b_rms13));
x_rms13new_3_1  = c_rms13 *(((a_rms13./ y_rms13new_3_1 )-1).^(1/b_rms13));

xrms1_3matrix =  [x_rms13a  x_rms13b  x_rms13new  x_rms13_1  x_rms13_2]';
ymid_rms13newup= (fitresult {18}(x_rms13a:0.05: x_rms13b));
%%
xmid_rms1t_3newup = ( x_rms13a:0.05: x_rms13b);
xmid_rms1_3newup=transpose(xmid_rms1t_3newup);
[xmid_rms1_3newup, ymid_rms13newup] = prepareCurveData( xmid_rms1_3newup, ymid_rms13newup );

fitmid_rms13newup = fittype( 'm*x+c', 'independent', 'x', 'dependent', 'y' );
optsmid_rms13newup = fitoptions( 'Method', 'NonlinearLeastSquares' );
optsmid_rms13newup.Algorithm = 'Levenberg-Marquardt';
optsmid_rms13newup.Display = 'Off';
optsmid_rms13newup.Robust = 'Bisquare';
optsmid_rms13newup.StartPoint = [10 10];

[fitresult{43}, gof(43)] = fit( xmid_rms1_3newup, ymid_rms13newup, fitmid_rms13newup, optsmid_rms13newup );

coefficients_mid_rms13newup= coeffvalues(fitresult{43});
fitxmid_rms13newup = ((30:1:hcp));
fitymid_rms13newup = (fitresult{43} (30:1:hcp));

ymid_rms13new= (fitresult {18}(x_rms13new-5:0.05: x_rms13new+5));
xmid_rms1t_3new = ( x_rms13new-5:0.05: x_rms13new+5);
xmid_rms1_3new=transpose(xmid_rms1t_3new);
[xmid_rms1_3new, ymid_rms13new] = prepareCurveData( xmid_rms1_3new, ymid_rms13new );

fitmid_rms13new = fittype( 'm*x+c', 'independent', 'x', 'dependent', 'y' );
optsmid_rms13new = fitoptions( 'Method', 'NonlinearLeastSquares' );
optsmid_rms13new.Algorithm = 'Levenberg-Marquardt';
optsmid_rms13new.Display = 'Off';
optsmid_rms13new.Robust = 'Bisquare';
optsmid_rms13new.StartPoint = [10 10];

[fitresult{22}, gof(22)] = fit( xmid_rms1_3new, ymid_rms13new, fitmid_rms13new, optsmid_rms13new );

coefficients_mid_rms13new= coeffvalues(fitresult{22});
fitxmid_rms13new = ((30:1:hcp));
fitymid_rms13new = (fitresult{22} (30:1:hcp));

ymid_rms13newdown= (fitresult {18}(x_rms13_1:0.05: x_rms13_2));
xmid_rms1t3newdown =             (x_rms13_1:0.05: x_rms13_2);

xmid_rms13newdown=transpose(xmid_rms1t3newdown);

[xmid_rms13newdown, ymid_rms13newdown] = prepareCurveData( xmid_rms13newdown, ymid_rms13newdown );

fitmid_rms13newdown = fittype( 'm*x+c', 'independent', 'x', 'dependent', 'y' );
optsmid_rms13newdown = fitoptions( 'Method', 'NonlinearLeastSquares' );
optsmid_rms13newdown.Algorithm = 'Levenberg-Marquardt';
optsmid_rms13newdown.Display = 'Off';
optsmid_rms13newdown.Robust = 'Bisquare';
optsmid_rms13newdown.StartPoint = [10 10];

[fitresult{44}, gof(44)] = fit( xmid_rms13newdown, ymid_rms13newdown, fitmid_rms13newdown, optsmid_rms13newdown );

coefficients_mid_rms13newdown= coeffvalues(fitresult{44});
fitxmid_rms13newdown = ((30:1:hcp));
fitymid_rms13newdown = (fitresult{44} (30:1:hcp));

%%
% sigmoid fits to rms1
%Fit: '5'.
% Set up fittype and options.
ftrms15 = fittype('d + (a - d) / (1 + (x / c)^b)^e', 'independent', 'x', 'dependent', 'y');
optsrms15 = fitoptions( 'Method', 'NonlinearLeastSquares' );
optsrms15.Algorithm = 'Levenberg-Marquardt';
optsrms15.Display = 'Off';
optsrms15.Robust = 'Bisquare';
%optsrms15.StartPoint = [0.5 0.5 50 0.5 0.5];% changed coeff 2
optsrms15.StartPoint = [5 0.5 50 0.5 0.5];% changed coeff 2

% Fit model to data.
[fitresult{19}, gof(19)] = fit( x2Data, y2Data, ftrms15, optsrms15 );

coefficientsrms15= coeffvalues(fitresult{19});
ymax_rms15 = coefficientsrms15 (:,1);
fitx_rms15 = (30:0.1:hcp);
fitx_rms15 =   fitx_rms15';
fity_rms15 = (fitresult{19}(30:0.1:hcp));
fit_rms15 = [fitx_rms15, fity_rms15];

%%
%tangents to 5PL fit
% Generate upper horizontal in 5PL
yuhrms15= (fitresult {19}(0:1:50));
xuhrms1t5 = (0:1:50);
xuhrms15=transpose(xuhrms1t5);
%
% Fit upper horizontal line to 5PL  ratios
[xuhrms15, yuhrms15] = prepareCurveData( xuhrms15, yuhrms15 );
fituhrms15 = fittype( 'm*x+c', 'independent', 'x', 'dependent', 'y' );
optsuhrms15 = fitoptions( 'Method', 'NonlinearLeastSquares' );
optsuhrms15.Algorithm = 'Levenberg-Marquardt';
optsuhrms15.Display = 'Off';
optsuhrms15.Robust = 'Bisquare';
optsuhrms15.StartPoint = [ ymax_rms15  0.01];

[fitresult{23}, gof(23)] = fit( xuhrms15, yuhrms15, fituhrms15, optsuhrms15 );

coefficients_uhrms1_5= coeffvalues(fitresult{23});
fitxuhrms15 = ((20:1:120));
fityuhrms15 = (fitresult{23} (20:1:120));

a_rms15=coefficientsrms15(1,1);
b_rms15=coefficientsrms15(1,2);
c_rms15=coefficientsrms15(1,3);
d_rms15=coefficientsrms15(1,4);
e_rms15=coefficientsrms15(1,5);
%
y_rms15a = yuhrms15 (1,1)* (7/8);
y_rms15b = yuhrms15 (1,1)* (3/4);
y_rms15_new = yuhrms15 (1,1)/2;
y_rms15_1=yuhrms15 (1,1)/4;
y_rms15_2 = yuhrms15 (1,1)/8;

y_rms15b_5new = (y_rms15b+y_rms15_new)/2;
y_rms15new_5_1 = (y_rms15_new+y_rms15_1)/2;

yrmsmatrix =  [y_rms15a  y_rms15b  y_rms15_new  y_rms15_1  y_rms15_2]';
%
% Trying another approach
fit_rms15a = fit_rms15; %Getting the data points of the fitted sigmoid
fit_rms15b = fit_rms15;
fit_rms15_new = fit_rms15;
fit_rms15_1 = fit_rms15;
fit_rms15_2 = fit_rms15;

fit_rms15a(:,3) =  abs (fit_rms15 (:,2)- y_rms15a);%  get the difference between yvalue in the curve and the y level required
fit_rms15b(:,3) =  abs (fit_rms15 (:,2)- y_rms15b);
fit_rms15_new(:,3) =  abs (fit_rms15(:,2)- y_rms15_new);
fit_rms15_1(:,3) =  abs (fit_rms15 (:,2)- y_rms15_1);
fit_rms15_2(:,3) =    abs (fit_rms15 (:,2)- y_rms15_2);

% Find the minimum value in the third column
[mindiff_rms15a, minindex_rms15a] = min(fit_rms15a(:,3));
[mindiff_rms15b, minindex_rms15b] = min(fit_rms15b(:,3));
[mindiff_rms15_new, minindex_rms15_new] = min(fit_rms15_new(:,3));
%The problem in the following 2 is that, if the curve has flattened
%much above 0, then the mindiff will be the last value.
[mindiff_rms15_1, minindex_rms15_1] = min(fit_rms15_1(:,3));
[mindiff_rms15_2, minindex_rms15_2] = min(fit_rms15_2(:,3));

% Get the corresponding value in the first column
x_rms15a =  fit_rms15a(minindex_rms15a, 1);
x_rms15b =  fit_rms15a(minindex_rms15b, 1);
x_rms15new =  fit_rms15a(minindex_rms15_new, 1);
x_rms15_1 =  fit_rms15a(minindex_rms15_1, 1);
x_rms15_2 =  fit_rms15a(minindex_rms15_2, 1);

xrms1_5matrix =  [x_rms15a  x_rms15b  x_rms15new  x_rms15_1  x_rms15_2]';

ymid_rms15new_up= (fitresult {19}(x_rms15a:0.2: x_rms15b+1));
xmid_rms1t_5new_up =             (x_rms15a:0.2: x_rms15b+1);

xmid_rms1_5new_up=transpose(xmid_rms1t_5new_up);
[xmid_rms1_5new_up, ymid_rms15new_up] = prepareCurveData( xmid_rms1_5new_up, ymid_rms15new_up );

fitmid_rms15new_up = fittype( 'm*x+c', 'independent', 'x', 'dependent', 'y' );
optsmid_rms15new_up = fitoptions( 'Method', 'NonlinearLeastSquares' );
optsmid_rms15new_up.Algorithm = 'Levenberg-Marquardt';
optsmid_rms15new_up.Display = 'Off';
optsmid_rms15new_up.Robust = 'Bisquare';
optsmid_rms15new_up.StartPoint = [10 10];

[fitresult{25}, gof(25)] = fit( xmid_rms1_5new_up, ymid_rms15new_up, fitmid_rms15new_up, optsmid_rms15new_up );

coefficients_mid_rms15new_up= coeffvalues(fitresult{25});
fitxmid_rms15new_up = ((50:1:hcp));
fitymid_rms15new_up = (fitresult{25} (50:1:hcp));
%-------------------------------------------------------------------------
ymid_rms15new   = (fitresult {19}(x_rms15new-2:0.2: x_rms15new+3));
xmid_rms1t_5new =                (x_rms15new-2:0.2: x_rms15new+3);
xmid_rms1_5new  = transpose(xmid_rms1t_5new);
[xmid_rms1_5new, ymid_rms15new] = prepareCurveData(xmid_rms1_5new, ymid_rms15new );

fitmid_rms15new = fittype( 'm*x+c', 'independent', 'x', 'dependent', 'y' );
optsmid_rms15new = fitoptions( 'Method', 'NonlinearLeastSquares' );
optsmid_rms15new.Algorithm = 'Levenberg-Marquardt';
optsmid_rms15new.Display = 'Off';
optsmid_rms15new.Robust = 'Bisquare';
optsmid_rms15new.StartPoint = [10 10];

[fitresult{26}, gof(26)] = fit( xmid_rms1_5new, ymid_rms15new, fitmid_rms15new, optsmid_rms15new );

coefficients_mid_rms15new= coeffvalues(fitresult{26});
fitxmid_rms15new = ((50:1:hcp));
fitymid_rms15new = (fitresult{26} (50:1:hcp));

ymid_rms15new_down= (fitresult {19}(x_rms15new+6:0.2: x_rms15new+15));%Use as required
xmid_rms1t_5new_down =             (x_rms15new+6:0.2: x_rms15new+15);

xmid_rms1_5new_down=transpose(xmid_rms1t_5new_down);
[xmid_rms1_5new_down, ymid_rms15new_down] = prepareCurveData( xmid_rms1_5new_down, ymid_rms15new_down );

fitmid_rms15new_down = fittype( 'm*x+c', 'independent', 'x', 'dependent', 'y' );
optsmid_rms15new_down = fitoptions( 'Method', 'NonlinearLeastSquares' );
optsmid_rms15new_down.Algorithm = 'Levenberg-Marquardt';
optsmid_rms15new_down.Display = 'Off';
optsmid_rms15new_down.Robust = 'Bisquare';
optsmid_rms15new_down.StartPoint = [10 10];

[fitresult{24}, gof(24)] = fit( xmid_rms1_5new_down, ymid_rms15new_down, fitmid_rms15new_down, optsmid_rms15new_down );

coefficients_mid_rms15new_down= coeffvalues(fitresult{24});
fitxmid_rms15new_down = ((50:1:hcp));
fitymid_rms15new_down = (fitresult{24} (50:1:hcp));

%%
%figure (6)
%hold on
%scatter (  x_rms15a ,   y_rms15a );
%scatter (  x_rms15b ,  y_rms15b );
%scatter (  x_rms15new ,  y_rms15_new );
%scatter (  x_rms15_1 ,  y_rms15_1 );
%scatter (  x_rms15_2 ,  y_rms15_2 );
%hrms15 = plot(fitresult{19});

%set (hrms15, 'color', 'r','LineStyle', '-');
%hold off
%saveas(gcf,[expt_id 'fig6.fig']);

%%
% Plotting the rms data and the fitted sigmoid
%figure (7)
%plot(x2Data, y2Data, 'o', 'MarkerSize', 4); % Original data points

%hold on

%hrms13 = plot(fitresult{18});
%set (hrms13, 'color', 'b');

%hrms15 = plot(fitresult{19});
%set (hrms15, 'color', 'r','LineStyle', '-');

%huhrms13 = plot (fitresult {20});
%set (huhrms13, 'color', 'b');

%h3rms1new = plot (fitresult {22});
%set (h3rms1new, 'color', 'b', 'LineStyle', ':');

%h3rms1newup = plot (fitresult {43});
%set (h3rms1newup, 'color', 'b', 'LineStyle', '-.');

%h3rms1newdown = plot (fitresult {44});
%set (h3rms1newdown, 'color', 'b', 'LineStyle', '--');

%huhrms15 = plot (fitresult {23});
%set (huhrms15, 'color', 'r', 'LineStyle', '--');

%h5rms1new_up = plot (fitresult {25});
%set (h5rms1new_up, 'color', 'r', 'LineStyle', '-.');

%h5rms1new = plot (fitresult {26});
%set (h5rms1new, 'color', 'r', 'LineStyle', ':');

%h5rms1new_down = plot (fitresult {24});
%set (h5rms1new_down, 'color', 'r', 'LineStyle', '--');

%xticks([0: 10: 1000])
%set(gca,'XMinorTick','on','YMinorTick','on')
%grid on

%line([20, hcp], [min(y2Data), min(y2Data)], 'Color', 'k', 'LineStyle', '-'); % Line of lowest rms
%ylim ([0 max(y2Data)+0.05]);

%xlabel('cuff pressure');
%ylabel('rms ratio');
%hold off
txt=['rms'];
%legend(txt);
%set(legend,'FontSize',10);
%title (expt_id);

%saveas(gcf,[expt_id 'fig7.fig']);

%%
uhintercept_rms1_3new  = round((coefficients_mid_rms13new (1,1) - coefficients_uhrms1_3 (1,1))/( coefficients_uhrms1_3 (1,2)- coefficients_mid_rms13new (1,2)));
uhintercept_rms1_3newup  = round((coefficients_mid_rms13newup (1,1) - coefficients_uhrms1_3 (1,1))/( coefficients_uhrms1_3 (1,2)- coefficients_mid_rms13newup (1,2)));
uhintercept_rms1_3newdown  = round((coefficients_mid_rms13newdown (1,1) - coefficients_uhrms1_3 (1,1))/( coefficients_uhrms1_3 (1,2)- coefficients_mid_rms13newdown (1,2)));
uhintercept_rms1_5new  = round((coefficients_mid_rms15new(1,1) - coefficients_uhrms1_5(1,1))/(coefficients_uhrms1_5(1,2)- coefficients_mid_rms15new (1,2)));
uhintercept_rms1_5new_up  = round((coefficients_mid_rms15new_up (1,1) - coefficients_uhrms1_5 (1,1))/( coefficients_uhrms1_5 (1,2)- coefficients_mid_rms15new_up (1,2)));
uhintercept_rms1_5new_down  = round((coefficients_mid_rms15new_down (1,1) - coefficients_uhrms1_5 (1,1))/( coefficients_uhrms1_5 (1,2)- coefficients_mid_rms15new_down (1,2)));

%It is better to get the intercepts with a lower horizontal drawn at the
%level of the minimum y value rather than X intercept

Xequal_intercept_rms1_3new      = round((coefficients_mid_rms13new     (1,1) - min(y2Data))/ - coefficients_mid_rms13new (1,2));
Xequal_intercept_rms1_3newup    = round((coefficients_mid_rms13newup   (1,1) - min(y2Data))/ - coefficients_mid_rms13newup (1,2));
Xequal_intercept_rms1_3newdown  = round((coefficients_mid_rms13newdown (1,1) - min(y2Data))/ - coefficients_mid_rms13newdown (1,2));
Xequal_intercept_rms1_5new      = round((coefficients_mid_rms15new     (1,1) - min(y2Data))/ - coefficients_mid_rms15new (1,2));
Xequal_intercept_rms1_5new_up   = round((coefficients_mid_rms15new_up  (1,1) - min(y2Data))/ - coefficients_mid_rms15new_up (1,2));
Xequal_intercept_rms1_5new_down = round((coefficients_mid_rms15new_down(1,1) - min(y2Data))/ - coefficients_mid_rms15new_down (1,2));

%%
%Getting UH intercept of 3PL UH and poly (fit result 4 is used for this)
yforpoly_rmslow3(:,1) = fity_polyrms;
yforpoly_rmslow3 (:,2) = yuhrms13(1,1);
yforpoly_rmslow3 (:,3) = yforpoly_rmslow3(:,1)- yforpoly_rmslow3(:,2);

yforpoly_rmslow5 (:,1) = fity_polyrms;
yforpoly_rmslow5 (:,2) = yuhrms15(1,1);
yforpoly_rmslow5 (:,3) =  yforpoly_rmslow5 (:,1)- yforpoly_rmslow5 (:,2);

% Set up fittype and options.
fit_type_polyrmslow = fittype('a*x^3 + b*x^2 + c*x + d', 'independent', 'x', 'dependent', 'y');
optspoly_rmslow = fitoptions( 'Method', 'NonlinearLeastSquares' );
optspoly_rmslow.Algorithm = 'Levenberg-Marquardt';
poly.Display = 'Off';
optspoly_rmslow.Robust = 'Bisquare';
optspoly_rmslow.StartPoint = [10 1 1 1];% changed

% Fit model to data.
[fitresult{4}, gof(4)] = fit( fitx_polyrms, yforpoly_rmslow3(:,3), fit_type_polyrmslow, optspoly_rmslow );
coefficientspoly_rms3low= coeffvalues(fitresult{4});

fitx_poly_rmslow = [lcp:1:hcp];
fitx_poly_rmslow =fitx_poly_rmslow';
fity_poly_rmslow3 = fitresult{4}(lcp:1:hcp);
fit_poly_rmslow3 = [fitx_poly_rmslow, fity_poly_rmslow3];

[pk_fitpoly_rmslow3, loc_pk_fitpoly_rmslow3] =   findpeaks (fit_poly_rmslow3 (:,2), fit_poly_rmslow3 (:,1));
[trf_fitpoly_rmslow3, loc_trf_fitpoly_rmslow3] = findpeaks (-fit_poly_rmslow3 (:,2), fit_poly_rmslow3 (:,1));

if ~exist('loc_pk_fitpoly_rmslow3', 'var') | loc_pk_fitpoly_rmslow3 > loc_trf_fitpoly_rmslow3
    loc_pk_fitpoly_rmslow3 = [];
end

for i = 1:size(fit_poly_rmslow3 ,1)-1
    if  fit_poly_rmslow3(i+1,2)<0 && fit_poly_rmslow3 (i,2)>0 || fit_poly_rmslow3 (i,2) ==0 % find first zero crossing
        UH_intercept_poly_rms3= fit_poly_rmslow3(i+1,1);
        
        break; %report first zero crossing
        % if there is no zero crossing, report trough
    else
        UH_intercept_poly_rms3 = loc_pk_fitpoly_rmslow3;
    end
end

%Getting UH intercept of 5PL UH and poly (fit result 6 is used for this)

[fitresult{6}, gof(6)] = fit( fitx_polyrms,   yforpoly_rmslow5(:,3), fit_type_polyrmslow, optspoly_rmslow );
coefficientspoly_rms5low= coeffvalues(fitresult{6});

fitx_poly_rmslow = [lcp:1:hcp];
fitx_poly_rmslow =fitx_poly_rmslow';
fity_poly_rmslow5 = fitresult{6}(lcp:1:hcp);
fit_poly_rmslow5 = [fitx_poly_rmslow, fity_poly_rmslow5];

[pk_fitpoly_rmslow5, loc_pk_fitpoly_rmslow5] =   findpeaks (fit_poly_rmslow5 (:,2), fit_poly_rmslow5 (:,1));
[trf_fitpoly_rmslow5, loc_trf_fitpoly_rmslow5] = findpeaks (-fit_poly_rmslow5 (:,2), fit_poly_rmslow5 (:,1));

if ~exist('loc_pk_fitpoly_rmslow5', 'var') | loc_pk_fitpoly_rmslow5 > loc_trf_fitpoly_rmslow5
    loc_pk_fitpoly_rmslow5 = [];
end

for i = 1:size(fit_poly_rmslow5 ,1)-1
    if  fit_poly_rmslow5(i+1,2)<0 && fit_poly_rmslow5 (i,2)>0 || fit_poly_rmslow5 (i,2) ==0 % find first zero crossing
        UH_intercept_poly_rms5= fit_poly_rmslow5(i+1,1);
        
        break; %report first zero crossing
        % if there is no zero crossing, report trough
    else
        UH_intercept_poly_rms5 = loc_pk_fitpoly_rmslow5;
    end
end

DiaPolyrms = round(mean([UH_intercept_poly_rms3, UH_intercept_poly_rms5]));

if all(isnan(DiaPolyrms))
    DiaPolyrms=[];
end

%%
forHrms(:,1) = rmsmat1 (:,1);
forHrms(:,2) = rmsmat1 (:,4);

fHrms(:,1) = forHrms (1:end-1,1);
fHrms (:,2)= diff(forHrms(:,2));

for i = 1: size (forHrms,1)-1
    if forHrms (i+1,2)==0  % if pulse amplitude is 0
        fHrms(i,3)=0; %assign 0
    else  fHrms(i,3)= 1; % If there is no zero pulse, in that cuff pressure, assign 1
    end
end

fHrms(:,4) = fHrms (:,2)<0; % if differential is negative, logical 1
fHrms(:,5)= diff(forHrms(:,1));

fHrmsCandidates = fHrms((fHrms(:, 3) == 1) & (fHrms(:, 4) == 1), :); % Choose rows where there is no zero pulse, but the differential is negative

fHrmsCandidates1 = fHrmsCandidates;

if ~isnan(PSysDiaMay2025 (1,8))% added on 12 May2025
    rowsToDeletefHrms = fHrmsCandidates1(:,1)> PSysDiaMay2025(1,8)-5;% Changed on 26Mar2025; -10 added on 1 May2025. Changed to -5 on 16May
else
    rowsToDeletefHrms = fHrmsCandidates1(:,1)> max(PSysDiaMay2025(1,[5,7]));% changed on 16May2025
end

fHrmsCandidates1(rowsToDeletefHrms, :)= [];

if ~isempty(fHrmsCandidates1) %ref: 18092502 which is empty
    Hpointrms = round(max(fHrmsCandidates1(:,1)));
else
    Hpointrms = NaN;
    Hpointrms_equiv = PSysDiaMay2025(1,4);
end

if ~exist('Hpointrms_equiv', 'var')
    Hpointrms_equiv = NaN;
end
%%
forLrms(:,1) = rmsmat1 (:,1);
forLrms(:,2) = rmsmat1 (:,4); %ratios

fLrms(:,1) = forLrms (2:end,1);
fLrms (:,2)= diff (forLrms(:,2));

for i = 1: size (forLrms,1)-1
    if forLrms (i+1,2)==0  % if pulse amplitude is 0
        fLrms(i,3)=0; %assign 0
    else  fLrms(i,3)= 1; % If there is no zero pulse, in that cuff pressure, assign 1
    end
end

fLrms(:,4) = fLrms (:,2)<0; % if differential is negative, logical 1

fLrms(:,5)= diff (forLrms(:,1));
fLrmsCandidates = fLrms((fLrms(:, 3) == 1) & (fLrms(:, 4) == 1), :); % Choose rows where there is no zero pulse, but the differential is negative
fLrmsCandidates1 =fLrmsCandidates;

% Remove rows where cuff pressure is more than a limit
rowsToDeletefLrms = fLrmsCandidates1 (:,1)> PSysDiaMay2025(1,7)- 5;
fLrmsCandidates1(rowsToDeletefLrms, :)= [];

%If the cuff pressures in fLPmincandidates are successive, then choose the lower value
%Otherwise, chose the higher value for Lpointmin

if ~isempty(fLrmsCandidates1)
    if   size(fLrmsCandidates1,1)==1
        Lpointrms = round(fLrmsCandidates1(1,1));
        %If the cuff pressures in fLPmincandidates are successive, then choose the lower value
        %Otherwise, chose the higher value for Lpointmin
        
    elseif size(fLrmsCandidates1,1)==2
        if fLrmsCandidates1(1,1)< Hpointrms+3
            Lpointrms = fLrmsCandidates1(1,1);
        elseif fLrmsCandidates1(2,1)< Hpointrms+3
            Lpointrms = fLrmsCandidates1(2,1);
        else
            Lpointrms = NaN;
        end
        
    elseif size(fLrmsCandidates1,1)>2
        i=1;
        while i < size(fLrmsCandidates1,1)
            if  abs(fLrmsCandidates1(i,1)- fLrmsCandidates1(i+1,1))>= abs(fLrmsCandidates1(i+1,5)) && fLrmsCandidates1(i,1)< (Hpointrms+3)  %The difference between 2 steps is in column 5, lower row
                %So, if the difference between pressures (i and i+1, column 1)  is more than that listed in i+1 col 5,
                Lpointrms = round(fLrmsCandidates1(i,1));
                break;
            else
                i=i+1;
            end
        end
    end
else
    Lpointrms = NaN;
    Lpointrms_equiv = PSysDiaMay2025(1, 3);
end
if ~exist('Lpointrms_equiv', 'var')
    Lpointrms_equiv = NaN;
end

%%
fitx_ratio_env_rms = (20:1: max(Xequal_intercept_rms1_3newdown, Xequal_intercept_rms1_5new_down)); % Changed on 13 Feb, zeroing was not done properly for high cuff pressures in 18092702
fitx_ratio_env_rms =  fitx_ratio_env_rms';
fity_ratio_env_rms = (fitresult{79}(20:1: max(Xequal_intercept_rms1_3newdown, Xequal_intercept_rms1_5new_down)));
fit_ratio_env_rms = [fitx_ratio_env_rms, fity_ratio_env_rms];

if exist('fity_ratio_env_rms', 'var')
    [pk_ratio_env_rms, locpk_ratio_env_rms] = findpeaks(fity_ratio_env_rms, fitx_ratio_env_rms);
    Hpoint_env_rms = locpk_ratio_env_rms;
    %Hpointrms_diff = abs(x_rms13new - Hpoint_env_rms);
    
    Hpoint_env_rms(Hpoint_env_rms>PSysDiaMay2025(1,8)-10)=[]; %-10 added on 1 May2025
    
    Hpointrms_diff = abs(PSysDiaMay2025(1,8) - Hpoint_env_rms);%Changed on 26 Mar2025
    [~, Hpoint_env_rms_index]= min(Hpointrms_diff);
    Hpoint_env_rms1 = Hpoint_env_rms(Hpoint_env_rms_index);
end

fitx_ratio_env_rms1 = (20:1: hcp); % Changed on 13 Feb, zeroing was not done properly for high cuff pressures in 18092702
fitx_ratio_env_rms1 =  fitx_ratio_env_rms1';
fity_ratio_env_rms1 = (fitresult{79}(20:1: hcp));
fit_ratio_env_rms1 = [fitx_ratio_env_rms1, fity_ratio_env_rms1];
[pk_ratio_env_rms1, locpk_ratio_env_rms1] = findpeaks(fity_ratio_env_rms1, fitx_ratio_env_rms1);
[trf_ratio_env_rms1, loctrf_ratio_env_rms1] = findpeaks(-fity_ratio_env_rms1, fitx_ratio_env_rms1);

if ~exist ('Hpoint_env_rms1', 'var')&& ~isnan (Hpointrms)
    Hpoint_env_rms1 = Hpointrms;
elseif ~exist ('Hpoint_env_rms1', 'var')|| isempty(Hpoint_env_rms1)
    Hpoint_env_rms1 = NaN;
end
%%
if exist('fity_ratio_env_rms', 'var')
    [trf_ratio_env_rms, loctrf_ratio_env_rms] = findpeaks (-fity_ratio_env_rms, fitx_ratio_env_rms);
    Lpoint_env_rms = loctrf_ratio_env_rms;
    
    Lpoint_env_rms(Lpoint_env_rms>PSysDiaMay2025(1,7)-5)=[];    %-5 added on 1 May2025
    
    if isnan(Hpoint_env_rms1) && ~isempty(Lpoint_env_rms)
        Lpointrms_diff = abs(Hpoint_env_rms1 - Lpoint_env_rms);
        [~, Lpoint_env_rms_index]= min(Lpointrms_diff);
        Lpoint_env_rms1 = Lpoint_env_rms(Lpoint_env_rms_index);
        
    elseif ~isempty(Lpoint_env_rms)
        Lpointrms_diff = abs(PSysDiaMay2025(1,8) - Lpoint_env_rms);
        [~, Lpoint_env_rms_index]= min(Lpointrms_diff);
        Lpoint_env_rms1 = Lpoint_env_rms(Lpoint_env_rms_index);
    end
end

if ~exist ('Lpoint_env_rms1', 'var')|| isempty(Lpoint_env_rms1)
    Lpoint_env_rms1 = NaN;
end
%%
if exist ('trf_ratio_env_rms','var')&& max(x_rms13new, x_rms15new)> Hpoint_env_rms1
    for_rmsSysPoint = [-trf_ratio_env_rms, loctrf_ratio_env_rms];
    rmsSysPoint_candidates = for_rmsSysPoint(for_rmsSysPoint(:,2)> max(x_rms13new, x_rms15new),:);
    [~, row_with_rmsMinimum]= min(abs(rmsSysPoint_candidates(:,1)));
    rms_SysGuess_smsp = rmsSysPoint_candidates(row_with_rmsMinimum, 2);
    
elseif  max(x_rms13new, x_rms15new)< Hpoint_env_rms1
    for_rmsSysPoint1 = [-trf_ratio_env_rms1, loctrf_ratio_env_rms1];
    rmsSysPoint_candidates1 = for_rmsSysPoint1(for_rmsSysPoint1(:,2)> Hpoint_env_rms1+10, :);
    [~, row_with_rmsMinimum1]= min(abs(rmsSysPoint_candidates1(:,1)));
    rms_SysGuess_smsp = rmsSysPoint_candidates1(row_with_rmsMinimum1, 2)+20;
end
%Use this value for zeroing amplitudes at higher cuff pressures

%%
Lpointrms_array = [Lpointrms, Lpoint_env_rms1, Lpointrms_equiv];
Hpointrms_array = [Hpointrms, Hpoint_env_rms1, Hpointrms_equiv];

%%
% Added on 21 May

falselow_for = []; %initializing
falselow_for(1, :) = Lpointrms_array(1,:);
falselow_for = falselow_for';
falselow_for(isnan(falselow_for))=[];

for i = 1:size(rmsmat1,1)
    for j = 1:size(falselow_for,1)
        if rmsmat1(i,1)== falselow_for(j,1)|| abs(falselow_for(j,1) - rmsmat1(i,1))<=5
            falselow_for(j,2)= rmsmat1(i,4);
        end
    end
end

falselow_for(:, 3) = falselow_for(:, 1)- Diaguess_MMMSDandMAP_1;
falselow_for(:, 4) = falselow_for(:, 1)- Diaguess_MMMSDandMAP_2;

for j = 1:size(falselow_for,1)
    if ~isempty(Dia_max_rms_pk_CP_1)
        falselow_for(j,5)= falselow_for(j, 1)- Dia_max_rms_pk_CP_1;
    end
    if ~isempty(DiaPolyrms)
        falselow_for(j,6)= falselow_for(j, 1)- DiaPolyrms;
    else
        falselow_for(j,6)= 0;
    end
    if ~isempty(loc_pk_fitpolyrms)
        falselow_for(j,7)= falselow_for(j, 1)- loc_pk_fitpolyrms;
    end
end

for i = 1: size(falselow_for,1)
    falselow_for_score(i,1) = falselow_for(i,1);% pressure
    falselow_for_score(i,2) = falselow_for(i,1) >= PSysDiaMay2025(1,3);% which point is higher
end

for i = 1: size(falselow_for,1) % Lrms value can be higher than Diaguess values, as Diaguess_MMMSDandMAP_1 represents peripheral
    if all(falselow_for(:, 3)>0) || all(falselow_for(:, 3)<0)    % if both are more than or both are less than Diaguess_MMMSDandMAP_1
        falselow_for_score(i,3)= abs(falselow_for(i,3)) == min(abs(falselow_for(:,3)));
    elseif falselow_for (i,3)==0 || abs(falselow_for(i,3))< 3% if the value is same as or very close to Diaguess_MMMSDandMAP_1
        falselow_for_score(i,3)= 1;
    else % if they are too far on either side of Diaguess_MMMSDandMAP_1
        falselow_for_score(i,3)= 0;
    end
end

for i = 1: size(falselow_for,1)
    falselow_for_score(i,4)= falselow_for(i,4) >= 0;  % Lrms  value cannot be lower than Diaguess_MMMSDandMAP_2
    falselow_for_score(i,5)= falselow_for(i,5) < 0; % Lrms  value cannot be higher than Dia_max_rms_pk_CP_1
    falselow_for_score(i,6)= falselow_for(i,6) >= 0; % Lrms  value cannot be lower than DiaPolyrms
    if size(falselow_for,2)>6
        falselow_for_score(i,7)= falselow_for(i,7) > 0; % Lrms  value cannot be lower than loc_pk_fitpolyrms
    else
        falselow_for_score(i,7)=0;
    end
end

for i = 1: size(falselow_for_score,1)
    falselow_for_score(i,8)= sum(falselow_for_score(i,2:7));
end

[~, row_LrmsTrue] = max(falselow_for_score(:, 8));
if range(falselow_for_score(:,8))~=0
    LrmsTrue = falselow_for_score(row_LrmsTrue, 1);
else
    LrmsTrue = 'Wait';
    LrmsTrue1 = NaN;
end

LHrmstrue(1,:)= falselow_for(row_LrmsTrue, :);
%%
% Added on 21 May
falsehigh_for = [];
falsehigh_for(1, :) = Hpointrms_array(1,:);
falsehigh_for = falsehigh_for';
falsehigh_for(isnan(falsehigh_for))=[];

for i = 1:size(rmsmat1,1)
    for j = 1:size(falsehigh_for,1)
        if rmsmat1(i,1)== falsehigh_for(j,1)|| abs(falsehigh_for(j,1) - rmsmat1(i,1))<=5
            falsehigh_for(j,2)= rmsmat1(i,4);
        end
    end
end

falsehigh_for(:, 3) = falsehigh_for(:, 1)- Diaguess_MMMSDandMAP_1;
falsehigh_for(:, 4) = falsehigh_for(:, 1)- Diaguess_MMMSDandMAP_2;

for j = 1:size(falsehigh_for,1)
    if ~isempty(Dia_max_rms_pk_CP_1)
        falsehigh_for(j,5)= falsehigh_for(j, 1)- Dia_max_rms_pk_CP_1;
    end
    if ~isempty(DiaPolyrms)
        falsehigh_for(j,6)= falsehigh_for(j, 1)- DiaPolyrms;
    else
        falsehigh_for(j,6)= 0;
    end
    if ~isempty(loc_pk_fitpolyrms)
        falsehigh_for(j,7)= falsehigh_for(j, 1)- loc_pk_fitpolyrms;
    end
end

for i = 1: size(falsehigh_for,1)
    falsehigh_for_score(i,1) = falsehigh_for(i,1);% pressure
    falsehigh_for_score(i,2) = falsehigh_for(i,2)>= PSysDiaMay2025(1,4);
    if all(falsehigh_for(:, 3)>0) || all(falsehigh_for(:, 3)<0)    % if both are more than or both are less than Diaguess_MMMSDandMAP_1
        falsehigh_for_score(i,3)= abs(falsehigh_for(i,3)) == min(abs(falsehigh_for(:,3)));
    elseif falsehigh_for (i,3)==0 || abs(falsehigh_for(i,3))< 3% if the value is same as or very close to Diaguess_MMMSDandMAP_1
        falsehigh_for_score(i,3)= 1;
    else % if they are too far on either side of Diaguess_MMMSDandMAP_1
        falsehigh_for_score(i,3)= 0;
    end
end

for i = 1: size(falsehigh_for,1)
    falsehigh_for_score(i,4)= falsehigh_for(i,4) >= 0;  % Hrms  value cannot be lower than Diaguess_MMMSDandMAP_2
    falsehigh_for_score(i,5)= abs(falsehigh_for(i,5)) == min(abs(falsehigh_for(:,5)));% value closest to Dia_max_rms_pk_CP_1
    falsehigh_for_score(i,6)= falsehigh_for(i,6) >= 0; % Hrms  value cannot be lower than DiaPolyrms
    if size(falsehigh_for,2)>6
        falsehigh_for_score(i,7)= falsehigh_for(i,7) > 0; % Hrms  value cannot be lower than loc_pk_fitpolyrms
    else
        falsehigh_for_score(i,7)=0;
    end
    if ~exist('LrmsTrue1', 'var') % it would exist if there is a 'Wait' string for LrmsTrue
        falsehigh_for_score(i,8)= falsehigh_for_score(i,1)> LrmsTrue;
    else
        falsehigh_for_score(i,8)= 0;
    end
end

for i = 1: size(falsehigh_for_score,1)
    falsehigh_for_score(i,9)= sum(falsehigh_for_score(i,2:8));
end

[~, row_HrmsTrue] = max(falsehigh_for_score(:, 9));
if range(falsehigh_for_score(:,9))~=0
    HrmsTrue = falsehigh_for_score(row_HrmsTrue, 1);
else
    HrmsTrue = mean(falsehigh_for(:,1));
end

LHrmstrue(2,:)= falsehigh_for(row_HrmsTrue, :);
for i = 1:2
    LHrmstrue(i,7)= sum(LHrmstrue(i,3:6));
end

%%
if exist('LrmsTrue1', 'var') || LrmsTrue > HrmsTrue % Rescoring for Lrms
    for i = 1: size(falselow_for_score,1)
        falselow_for_score(i,8) = falselow_for_score(i,1)< HrmsTrue;
        falselow_for_score(i,9) = sum(falselow_for_score(i,2:8));
    end
    if range(falselow_for_score(:,9))~=0
        [~, row_LrmsTrue] = max(falselow_for_score(:, 9));
        LrmsTrue = falselow_for_score(row_LrmsTrue, 1);
    else
        LrmsTrue = mean(falselow_for(:,1));
    end
end

if LrmsTrue > HrmsTrue
    if any(LrmsTrue==falselow_for(:,1)) && any(HrmsTrue==falsehigh_for(:,1))% changed on 29 Jun2025
        for i = 1:2
            if LHrmstrue(1,7)< LHrmstrue(2,7)
                HrmsTrue = LrmsTrue;
            else
                LrmsTrue = HrmsTrue;
            end
        end
    elseif any(LrmsTrue==falselow_for(1:2,1))
        HrmsTrue = LrmsTrue;
    elseif any(HrmsTrue==falsehigh_for(1:2,1))
        LrmsTrue = HrmsTrue;
    else
        meanLHrms = mean([LrmsTrue, HrmsTrue]);
        LrmsTrue = meanLHrms;
        HrmsTrue = meanLHrms;
    end
end

%%
DiaEarlyArray = zeros(4,2);
if ~isempty (loc_pk_fitpolyrms) && ~isempty (DiaPolyrms)
    DiaEarlyArray(1,1:2) = [loc_pk_fitpolyrms, DiaPolyrms];
elseif ~isempty (DiaPolyrms)
    DiaEarlyArray(1,1:2) = [NaN, DiaPolyrms];
else
    DiaEarlyArray(1,1:2) = [NaN, NaN];
end

UH_intercept_rmsArray = NaN(3,4);
UH_intercept_rmsArray(2:3, 1:2) = [uhintercept_rms1_3newup, uhintercept_rms1_3new; uhintercept_rms1_5new_up, uhintercept_rms1_5new ];
UH_intercept_rmsArray(1,3:4)= [LrmsTrue, HrmsTrue];
UH_intercept_rmsArray(2:3, 3) = UH_intercept_rmsArray(2:3, 1) - LrmsTrue;
UH_intercept_rmsArray(2:3, 4) = UH_intercept_rmsArray(2:3, 2) - HrmsTrue;

for i = 2:3
    for j = 1:2
        if any(abs(UH_intercept_rmsArray(:, j+2))<10)
            if abs(UH_intercept_rmsArray(i, j+2))>15
                UH_intercept_rmsArray(i,j)= 0;
            end
        end
    end
end

UH_intercept_up_MeanSigmoid_rms =  round(mean(nonzeros(UH_intercept_rmsArray(2:3, 1))));
UH_intercept_new_MeanSigmoid_rms = round(mean(nonzeros(UH_intercept_rmsArray(2:3, 2))));

DiaEarlyArray(2:4, 1:2) = [LrmsTrue, HrmsTrue; UH_intercept_up_MeanSigmoid_rms, UH_intercept_new_MeanSigmoid_rms; Diaguess_MMMSDandMAP_2, Diaguess_MMMSDandMAP_1];

X_intercept_new_MeanSigmoid_rms = round(mean(nonzeros([Xequal_intercept_rms1_3new, Xequal_intercept_rms1_5new])));
X_intercept_down_MeanSigmoid_rms = round(mean(nonzeros([Xequal_intercept_rms1_3newdown, Xequal_intercept_rms1_5new_down])));

SysEarlyArray = [Sys_rms, Sysrms_equivalent, Sys_rms_from_trf;  X_intercept_new_MeanSigmoid_rms, X_intercept_down_MeanSigmoid_rms, X_intercept_poly_rms;
    PSysDiaMay2025(1,1:2), Sysguess_MMMSDandMAP];

%%
disp('DiaEarlyArray');
disp(DiaEarlyArray);

disp('SysEarlyArray');
disp(SysEarlyArray);
%%
[mcell, ncell] = size (cell);
for j=1:mcell
    [pk_d,locpk_d,w_pkd,p_pkd]=findpeaks(cell{j,1}(:,4),cell{j,1}(:,1),'minPeakProminence', Thresh_minPeakProm_PPG);
    ptest0{j,1}=[pk_d,locpk_d,w_pkd,p_pkd];
    
    [trf_d,loctrf_d,w_trf_dd,p_trf_d]=findpeaks(-cell{j,1}(:,4),cell{j,1}(:,1),'minPeakProminence', Thresh_minPeakProm_PPG);
    trftest0{j,1}=[-trf_d,loctrf_d,w_trf_dd,p_trf_d];
    
    [pk_r,locpk_r,w_pk_r,p_pk_r]=findpeaks(cell{j,1}(:,3),cell{j,1}(:,1),'minPeakProminence', Thresh_minPeakProm_PPG);
    pref0{j,1}=[pk_r,locpk_r,w_pk_r,p_pk_r];
    
    [trf_r,loctrf_r,w_trf_r,p_trf_r]=findpeaks(-cell{j,1}(:,3),cell{j,1}(:,1),'minPeakProminence',Thresh_minPeakProm_PPG);
    trfref0{j,1}=[-trf_r,loctrf_r,w_trf_r,p_trf_r];
end

ylim1_forFig = -(max(max(trf_d), max(trf_r)));
ylim2_forFig = max(max(pk_d), max(pk_r));

%%
%figure (3)
%hold on
%yyaxis left
%yticks ([0: 10: 300])
%ylabel ('pressure in mmHg, intra arterial (Orange) or cuff pressure (black)');
%plot(data1(:,1), data1(:,2), 'color', 'k', 'LineStyle', '-');% cuff pressure, is in KmmHg. Therefore multiply by 1000

%yyaxis right

%ylim ([1.5*ylim1_forFig 1.5*ylim2_forFig]);
%ylabel ('PPG cuff (green)');
%yticks([-0.2: 0.1: 10]);

MyDarkGreen= [0, 0.5, 0.5];

%plot(data1(:,1), data1(:,3),'color', CyanBlue,'LineStyle', '-');% PPG ref
%plot(data1(:,1), data1(:,4),'color', DarkGreen,'LineStyle', '-');% PPG cuff

%xlabel ('time in seconds');
%xticks([0: 20: size(time,1)])
%set(gca,'XMinorTick','on','YMinorTick','on')

%grid on

%title (expt_id);
%legend ('Cuff pressure, PPGref and PPGcuff');
%hold off
%saveas(gcf,[expt_id 'fig3.fig']);

%%
%figure (4)
%hold on

for i= 1:size(cell,1)
%    yyaxis left
%    yticks ([0: 10: 300])
%    ylabel ('cuff pressure (mmHg)');
%    plot (cell{i,1} (:,1), cell{i,1} (:,2),'Marker', 'none','color', 'k', 'LineStyle', '-');% cuff pressure
%    yyaxis right
%    ylabel ('rms of PPG ratio (black circles');
    
%    plot (mean(cell{i,1}(:,1)), rmscell{i,4},'o','color', 'k');% rms of PPG ratio
    
%    xlabel ('time in seconds');
%    xticks([0: 40: 1000])
%    set(gca,'XMinorTick','on','YMinorTick','on')
%    grid on
    
end

%hold off
%legend ('rms PPGratio (black circles)', 'Location', 'North');
%title(expt_id);

%saveas(gcf,[expt_id 'fig4.fig']);

%%
%   To equal the number of peaks and troughs in every cuff pressure plateau in the cuffed arm

[mptest0, nptest0] = size(ptest0);

for i=1:mptest0
    pktrfcount{i,1}= size(ptest0{i,1});
    pktrfcount{i,2}= size(trftest0{i,1});
    pktrfcount{i,3}=abs((pktrfcount{i,1} - pktrfcount {i,2}));
end

% If more peaks than troughs, add zeros to troughs

[mpktrf, npktrf] = size (pktrfcount);
for i = 1: mpktrf
    if pktrfcount{i,1}(:,1) > pktrfcount {i,2}(:,1)
        trftest0{i,1}(end+pktrfcount{i,3}(:,1),:)=0;
    end
    % If more troughs than peaks, add zeros to peaks
    if pktrfcount{i,1}(:,1) < pktrfcount{i,2}(:,1)
        ptest0{i,1} (end+pktrfcount{i,3}(:,1), :)=0;
    end
end

%%

% Check if peak and trough numbers in every plateau is same for cuffed
% arm. The last column in pktrfafter should be 0,0.
for i=1:mptest0
    pktrfcountafter{i,1}= size(ptest0{i,1});
    pktrfcountafter{i,2}= size(trftest0{i,1});
    pktrfcountafter{i,3}= abs ((pktrfcountafter{i,1} - pktrfcountafter{i,2}));
end

% Now that peaks and troughs are the same in every cell, we can
% concatenate peaks and troughs

for j = 1: mptest0
    pktrf0a{j,1} = cat (2, ptest0 {j,1} (:,:), trftest0 {j,1} (:,:));
end

for j = 1:size(pktrf0a, 1)
    if isempty(pktrf0a{j, 1})
        pktrf0a{j, 1} = zeros(1,8); % Assign a row of zeros in 8 columns
    end
end

%%    %   To equal the number of peaks and troughs in every cuff pressure
%   plateau in the reference arm

[ mpref0, npref0] = size(pref0);
for i=1:mpref0
    pktrfcountref{i,1}= size(pref0{i,1});
    pktrfcountref{i,2}= size(trfref0{i,1});
    pktrfcountref{i,3}=abs((pktrfcountref{i,1} - pktrfcountref {i,2}));
end

% If more peaks than troughs, add zeros to troughs

[mpktrfref, npktrfref] = size (pktrfcountref);
for i = 1: mpktrfref
    if pktrfcountref{i,1}(:,1) > pktrfcountref {i,2}(:,1)
        trfref0{i,1}(end+pktrfcountref{i,3}(:,1),:)=0;
    end
    % If more troughs than peaks, add zeros to peaks
    if pktrfcountref{i,1}(:,1) < pktrfcountref{i,2}(:,1)
        pref0{i,1} (end+pktrfcountref{i,3}(:,1), :)=0;
    end
end

% Check if peak and trough numbers in every plateau is same for cuffed
% arm. The last column in pktrfafter should be 0,0.
for i=1:mptest0
    pktrfcountrefafter{i,1}= size(pref0{i,1});
    pktrfcountrefafter{i,2}= size(trfref0{i,1});
    pktrfcountrefafter{i,3}= abs ((pktrfcountrefafter{i,1} - pktrfcountrefafter{i,2}));
end

% Now that peaks and troughs are the same in every cell, we can
% concatenate peaks and troughs

for j = 1: mpref0
    pktrfref0a{j,1} = cat (2, pref0 {j,:} (:,:), trfref0 {j,1} (:,:));
end
%%
% To ensure each peak comes after a trough in ref
pktrfref0c = pktrfref0a;

for i =1:size(pktrfref0c,1)
    [m1c, n1c]= size(pktrfref0c{i,1});
    for k=1:m1c-1
        if pktrfref0c{i,1}(k,2) < pktrfref0c{i,1}(k,6)
            addrowref(1:8) = zeros; %This is done so that the last ref data in 5:8 does not get deleted
            pktrfref0c{i,1} = [pktrfref0c{i,1}; addrowref];
            pktrfref0c{i,1}(k+1:end,5:8)= pktrfref0c{i,1}(k:end-1,5:8);
            pktrfref0c{i,1}(k,5:8)= 0;% This line was 1:4 = 0 earlier. That is incorrect.
        end
    end
end

%%
%To consider false peaks (defined as amplitude < 1/10 of mean amplitude of nonzero entries in that cell) in ref:

pktrfref0b = pktrfref0c;

% calculate amplitude of peaks
for j = 1: size(pktrfref0b,1)
    for i = 1:size(pktrfref0b{j,1},1)
        pktrfref0b {j,1}(:,9) = pktrfref0b{j,1}(:,1)- pktrfref0b{j,1}(:,5); %actual amplitude of peaks
    end
    
end

%Take mean of amplitudes and enter in second column of the cell array
for j = 1: size(pktrfref0b,1)
    pktrfref0b {j,2}= mean(nonzeros(pktrfref0b{j,1}(:,9)));
end

% Identify amplitudes less than one tenth the mean in each cell
for j = 1: size (pktrfref0b,1)
    pktrfref0b{j,1}(:,10)= pktrfref0b{j,1}(:,9) < (pktrfref0b{j,2})/10;% col 10 is logical array
end

%The above strategy alone may not work. The wave after dicrotic notch
%can cause havoc. See 220303AP for example.

for j = 1: size(pktrfref0b,1)
    if size(pktrfref0b{j,1},1)>1
        for i = 2:size (pktrfref0b{j,1},1) % Problem occurs when there is only one row of data
            pktrfref0b{j,1}(i,11)= pktrfref0b{j,1}(i,9) < (pktrfref0b{j,1}(i-1,9))/4;
            %If a peak amplitude is less than one fourth the peak amplitude
            %of the previous row, logical 1.
        end
    end
end

% If there is an anacrotic notch after a dicrotic notch,
%that does not get flagged with the previous code. 220303AP is again the example here.
%Compare against next pulse

for j = 1: size(pktrfref0b,1)
    for i = 1:(size(pktrfref0b{j,1},1)-1)% Problem if there is only one row of data
        pktrfref0b{j,1}(i,12)= pktrfref0b{j,1}(i,9) < (pktrfref0b{j,1}(i+1,9))/4;
        %If a peak amplitude is less than one fourth the peak amplitude
        %of the succeeding row, logical 1.
    end
end

% the following lines delete rows with logical 1 in columns 10, 11 and 12.
% The following create problems in 220624DP, probably  because of the loop
% before the previous. It starts from row 2. Changing it to include row 1
% did not work.

pktrfref0d = pktrfref0b;

for j = 1: size(pktrfref0d,1)
    for i = 1:size(pktrfref0d{j,1},1)
        if pktrfref0b{j,1}(i,10)== 1
            pktrfref0d{j,1}(i,1:8)= 0;
        end
    end
end

for j = 1: size(pktrfref0d,1)
    for i = 1:size(pktrfref0d{j,1},1)
        if pktrfref0b{j,1}(i,11)== 1
            pktrfref0d{j,1}(i,1:8)= 0;
        end
    end
end

for j = 1: size(pktrfref0d,1)
    for i = 1:size(pktrfref0d{j,1},1)
        if pktrfref0b{j,1}(i,12)== 1
            pktrfref0d{j,1}(i,1:8)= 0;
        end
    end
end

%To match the code that follows,the 9th, 10th and 11th columns are removed from
%pktrfref0d. The new array is named pktrfref0.

for j = 1: size(pktrfref0d,1)
    for i = 1:size(pktrfref0d{j,1})
        pktrfref0{j,1}(i,1:8)= pktrfref0d {j,1}(i,1:8);
    end
end

%Remove zero entries from pktrfref0:
for j = 1:size(pktrfref0,1)
    temp = pktrfref0{j,1};
    idx = ~all(temp==0, 2); % Find the rows without zero entries using logical indexing
    temp = temp(idx,:); % Select the rows without zero entries using logical indexing
    pktrfref0{j,1} = temp; % Assign the modified array back to the j-th cell of pktrfref0
end

% The above strategy takes care of dicrotic and anacrotic notches
%   The above strategy misses the dicrotic notch if it occurs in the first
%   row (again 12th segment in 220303AP)(especially if an anacrotic notch
%   follows the dicrotic in the initial data)Delete it as follows:
%

for j = 1: size(pktrfref0,1)    
    if pktrfref0{j,1}(1,1)- pktrfref0{j,1}(1,5) < (pktrfref0{j,1}(2,1)- pktrfref0{j,1}(2,5))/4
        pktrfref0{j,1}(1,1:8)=0;
    end
end
%
%Repeat removal of zeros
for j = 1:size(pktrfref0,1)
    temp = pktrfref0{j,1};
    idx = ~all(temp==0, 2); % Find the rows without zero entries using logical indexing
    temp = temp(idx,:); % Select the rows without zero entries using logical indexing
    pktrfref0{j,1} = temp; % Assign the modified array back to the j-th cell of pktrfref0
end

%Calculate average cycle duration for every cell of ref
for j = 1:size(pktrfref0,1)
    for i = 1:size(pktrfref0{j,1},1)-2
        pktrfref0{j,2}= mean(pktrfref0{j,1}(i+1,2)- pktrfref0 {j,1}(i,2));
    end
end

%%
%Now it is possible to calculate heart rate
pulseinterval = pktrfref0;

for j = 1: size(pktrfref0,1)
    for i = 1:(size(pktrfref0{j,1},1)-1)
        if pktrfref0 {j,1}(i+1,2)>0 || pktrfref0 {j,1}(i+1,2)<0  % this is just to say if it is a nonzero entry
            pulseinterval{j,1}(i,9)= pktrfref0 {j,1}(i+1,2)- pktrfref0 {j,1}(i,2);
        end
    end
end

for j = 1: size(pulseinterval,1)
    pulseinterval{j,2}= mean(nonzeros(pulseinterval{j,1}(:,9)));
    pulseinterval {j,3} = 60/pulseinterval{j,2};
end

for j = 1: size(pulseinterval,1)
    pulseintervalmat (j,1) = pulseinterval{j,2};
    pulseintervalmat (j,2) = pulseinterval{j,3};
end

% pulseinterval = (pulseintervalmat(:, 1));
maxpulseinterval = max(pulseintervalmat(:, 1));
HR = (pulseintervalmat(:, 2));
maxHR = max(pulseintervalmat(:, 2));

%%
% To ensure each peak comes after a trough in test
pktrf0c = pktrf0a;

for i =1:size(pktrf0c,1)
    [m1c, n1c]= size(pktrf0c{i,1});
    for k=1:m1c-1
        if pktrf0c{i,1}(k,2) < pktrf0c{i,1}(k,6)
            addrowtest(1:8) = zeros; %This is done so that the last ref data in 5:8 does not get deleted
            pktrf0c{i,1} = [pktrf0c{i,1}; addrowtest];
            pktrf0c{i,1}(k+1:end,5:8)= pktrf0c{i,1}(k:end-1,5:8);
            pktrf0c{i,1}(k,5:8)= 0;% In 6May code, 1:4 was rendered to 0. That is incorrect.
            %Actually there is a peak, but no preceding trough here.
        end
    end    
end

%%
% added on 17Sep2025 to take care of cuffPPG inversion at high cuff pressures 
% if width of peak is > width of trough, there is inversion. Switch peaiks
% and troughs. Save the original as a copy.
% 
pktrf0c_copy = pktrf0c;
for i = 1:size(pktrf0c,1)
    for j = 1:size(pktrf0c{i,1},1)
        pktrf0c_hold{i,1}(j,1:8)= zeros;
    end
end

for i =1:size(pktrf0c,1)
    for j = 1:size(pktrf0c{i,1},1)
        if pktrf0c{i,1}(j,3) > pktrf0c{i,1}(j,7)% if peak width is 1.3 times more than trough width
            pktrf0c_hold{i,1}(j, 1:8)=  pktrf0c{i,1}(j,1:8);% save peak data on hold            
            pktrf0c{i,1}(j,1:4) = pktrf0c{i,1}(j,5:8); % switch peak and trough
            pktrf0c{i,1}(j,5:8)= pktrf0c_hold{i,1}(j, 1:4);
            % Now it is important to change the peak amplitude in column 1.
            % Take the difference of peak and trough in the original, and
            % add that to switched peak
            pktrf0c_hold{i,1}(j, 9)=  pktrf0c_hold{i,1}(j,1)- pktrf0c_hold{i,1}(j,5);%get the amplitude
            pktrf0c_hold{i,1}(j, 10)=  pktrf0c_hold{i,1}(j,1)+ pktrf0c_hold{i,1}(j,9);% Add to trough to get peak amplitude after inversion
            pktrf0c{i,1}(j, 1)=  pktrf0c_hold{i,1}(j,10);
        end
    end
end
%%
% %Dangerous to remove lone peaks and lone troughs in test at this stage. Keep the lone trough
% %till merging with reference data. The peak after that might have been cut
% %while sectioning. But it will appear as a zero after merging.
%
%% To consider false peaks in pktrf0:
pktrf0b = pktrf0c;
% calculate amplitude of peaks
for j = 1: size(pktrf0b,1)
    for i = 1:size(pktrf0b{j,1},1)
        
        if abs(pktrf0b{j,1}(i,1))>0
            pktrf0b {j,1}(i,9) = pktrf0b{j,1}(i,1)- (pktrf0b{j,1}(i,5)); %actual amplitude of peaks
        end
    end
end

%%
rmsmat = rmsmat1;

meanrmstest =  mean(rmsmat(1:3,3));%mean of test amplitude?
meanrmsratio = mean(rmsmat(:,4));%mean ratio (test/ref)
meanrmsratio_tot = mean(rmsmat(:,6));%mean ratio of test/total

%   %% % Set different thresholds for test peaks in different plateaus using rms value.
%This strategy causes serious trouble in 220525CP. Due to large swings

for j = 1: size(pktrf0b,1)
    for i = 1:size (pktrf0b{j,1},1)
        if rmsmat(j,1) > max(Xequal_intercept_rms1_3newdown, Xequal_intercept_rms1_5new_down)
            if abs(pktrf0b{j,1}(i,1)) > 0 && pktrf0b{j,1}(i,9)< 3*meanrmstest
                pktrf0b{j,1}(i,1:8)= 0;
            end
        else
            if abs(pktrf0b{j,1}(i,1))> 0 && pktrf0b{j,1}(i,9) < 0.3*(rmsmat(j,3))
                %what is meant by > 0, is that there is an entry.
                %Taking modulus is important for negative entries.
                pktrf0b{j,1}(i,1:8)= 0;
            end
        end
    end
end

%%
pktrf0d = pktrf0b;
%To match the code that follows,the 9th and 10th column are removed from pktrf0d
for j = 1: size(pktrf0d,1)
    for i = 1:size (pktrf0d{j,1},1)
        pktrf0{j,1}(i,1:8)= pktrf0d {j,1}(i,1:8);
    end
end
%%
%Remove zero entries from pktrf0:
for j = 1:size(pktrf0,1)
    temp = pktrf0{j,1};
    idxFZ = ~all(temp==0, 2); % Find the rows without zero entries using logical indexing
    temp = temp(idxFZ,:); % Select the rows without zero entries using logical indexing
    pktrf0{j,1} = temp; % Assign the modified array back to the j-th cell of pktrf0
end


%%  To equal the number of rows in pktrf0 and pktrfref0
[ mpktrf0, npktrf0] = size(pktrf0);
for i=1:mpktrf0
    pktrf0count{i,1}= size(pktrf0{i,1});
    pktrf0count{i,2}= size(pktrfref0{i,1});
    pktrf0count{i,3}=abs((pktrf0count{i,1} - pktrf0count {i,2}));
end


% If more rows in cuff than ref, add zeros to ref
[mpktrf0count, npktrf0count] = size(pktrf0count);
for i = 1: mpktrf0count
    if pktrf0count{i,1}(:,1) > pktrf0count {i,2}(:,1)
        pktrfref0{i,1}(end+pktrf0count{i,3}(:,1),:)=0;
    end
    % If more rows in ref than cuff, add zeros to cuff
    if pktrf0count{i,1}(:,1) < pktrf0count{i,2}(:,1)
        pktrf0{i,1} (end+pktrf0count{i,3}(:,1), :)=0;
    end
end

% Check if row numbers are same for cuffed and uncuffed arm. The last column in pktrfafter should be 0,0.
for i=1:mpktrf0
    pktrf0countafter{i,1}= size(pktrf0{i,1},1);
    pktrf0countafter{i,2}= size(pktrfref0{i,1},1);
    pktrf0countafter{i,3}= abs((pktrf0countafter{i,1} - pktrf0countafter{i,2}));
end

% Now that test and ref peaks and troughs are the same number of rows in every cell, we can
% concatenate test and ref
for j = 1: size (pktrf0,1)
    pktrfboth{j,1} = cat(2, pktrf0 {j,1}(:,:), pktrfref0 {j,1} (:,:));
end
%%

%To remove the initial wave (large trough and peak) that comes in test PPG at the start of a plateau
pktrfboth1 = pktrfboth;

% If the interval between test trough and
%test peak in a row is more than two-thirds
% of maximum peak to peak interval of reference peaks delete the test data. Do this for first row only.
for i =1:size(pktrfboth1,1)
    
    for k = 1
        if pktrfboth1{i,1}(k,5:8)~= 0
            if (pktrfboth1{i,1}(k,2) - pktrfboth1{i,1}(k,6))> (2*maxpulseinterval)/3
                pktrfboth1{i,1}(k, 1:8) = 0;
            end
        end
    end
end

% For removing peaks during a staggered upswing in test PPG (say of the initial wide wave or any where else). If successive trough is higher in amplitude than previous peak,
% delete it
for i =1:size(pktrfboth1,1)
    for k = 1:(size(pktrfboth1{i,1},1)-1)
        if (pktrfboth1{i,1}(k,1) < pktrfboth1{i,1}(k+1,5)) && all(pktrfboth1{i,1}(k,1:4)~= 0)
            pktrfboth1{i,1}(k,1:8)= 0;
        end
    end
end

%Some peaks in the upswing of test PPG still remain undeleted if not too wide. If the
%difference in voltage between peak and successive trough is less than one fifth of
%the difference between a peak and its preceding trough
%_______________________________________________________
%I commented this on sep 12, as the high pass filtering early on will remove the initial wide wave at high sys pressures in cuff PPG
%High pass filtering causes havoc in ibp/nibp study. So using the following
%here.
for i =1:size(pktrfboth1,1)
    %         [mi, ni]= size (pktrfboth1{i,1});
    if size(pktrfboth1{i,1},1)>2 % This condition was added on 20 Mar2025
        for k=1:2 %Note this is for first 3 rows only
            if abs(pktrfboth1{i,1}(k,1)- pktrfboth1{i,1}(k+1,5)) < abs((pktrfboth1{i,1}(k,1)- pktrfboth1{i,1}(k,5)))/5
                pktrfboth1{i,1}(k,1:8)=0;% OMG, the original code here said delete 1:16. Only delete test.
            end
        end
    end
end
%_______________________________________________________

% %For deletion of  any test pulse if wide (more than 2/3 of max pulse
% %interval)

for i =1:size(pktrfboth1,1)
    for k = 1: size(pktrfboth1{i,1},1)
        if (pktrfboth1{i,1}(k,2) - pktrfboth1{i,1}(k,6))>(2*maxpulseinterval)/3 && all (pktrfboth1{i,1}(k,1:8)~= 0)
            pktrfboth1{i,1}(k,1:8)= 0;
        end
    end
end   % This one causes trouble in 220304AP. Many test pulses are deleted

%The above strategy to remove wide pulses does not work in some cases eg
%test pulse at 55 seconds in 220405BP. Do the following:

% If the duration between a test trough and peak is more than 2.5 times the
% duration of the corresponding ref peak, delete the test row. Add an IF statement: becoz otherwise eg. 220405BP, deletion of test pulse at 206 sec
%Add an && statement, otherwise 2245BP cell 9 faces deletion of test pulse
for i =1:size(pktrfboth1,1)
    for k = 1: size(pktrfboth1{i,1},1)
        if all (pktrfboth1{i,1}(k,1:16)~=0)
            if (pktrfboth1{i,1}(k,2)- pktrfboth1{i,1}(k,6))> 3*(pktrfboth1{i,1}(k,10)- pktrfboth1{i,1}(k,14))
                pktrfboth1{i,1}(k,1:8)= 0;
            end
        end
    end
end

%%
% To ensure corresponding test peaks and ref peaks are aligned
pktrfboth2 = pktrfboth1;

for i =1:size(pktrfboth2,1)
    [mi, ni]= size(pktrfboth2{i,1});
    for k=1 % why is this done for first row only? Problem was observed in first peak only. This loop was added only in 19 april code
        if  abs(pktrfboth2{i,1}(k,2)- pktrfboth2{i,1}(k,10)) > abs(pktrfboth2{i,1}(k+1,2)- pktrfboth2{i,1}(k,10))
            pktrfboth2{i,1}(k, 1:8) =  0; % The first test peak is deleted as there is no reference for comparison
            appendrow (1,16) = zeros; %This is done so that the last reference peak does not get deleted
            pktrfboth2{i,1} = [pktrfboth2{i,1}; appendrow];
            pktrfboth2{i,1}(k+1:end, 9:16) =  pktrfboth2{i,1}(k:end-1, 9:16);
            pktrfboth2{i,1}(k, 1:16) = 0;
        end
    end
end

% If a test peak comes closer to the reference peak in the next row, push
% the test peaks down by a row

for i =1:size(pktrfboth2,1)
    [mi, ni]= size(pktrfboth2{i,1});
    for k=1:mi-1 % Doing this for all rows.
        if  abs(pktrfboth2{i,1}(k,2)- pktrfboth2{i,1}(k,10)) > abs(pktrfboth2{i,1}(k,2)- pktrfboth2{i,1}(k+1,10))
            appendrow (1,16) = zeros; %This is done so that the last test peak does not get deleted
            pktrfboth2{i,1} = [pktrfboth2{i,1}; appendrow];
            pktrfboth2{i,1}(k+1:end, 1:8) =  pktrfboth2{i,1}(k:end-1, 1:8);
            pktrfboth2{i,1}(k, 1:8) =  0;  % There is no test data here
        end
    end
end

%If x test peak come after x+1 ref peak, push test peaks and troughs down
%by a row and delete the test data in that row
for i =1:size(pktrfboth2,1)
    [mi, ni]= size(pktrfboth2{i,1});
    for k=1:mi-1
        if  pktrfboth2{i,1}(k,2) > pktrfboth2{i,1}(k+1,10)&& pktrfboth2{i,1}(k+1,10)>0
            pktrfboth2{i,1}(k+1:end, 1:8) =  pktrfboth2{i,1}(k:end-1, 1:8);
            pktrfboth2{i,1}(k, 1:8) = 0;% This line was copied from the next loop which seems unnecessary
        end
    end
end

%If a nonzero test peak in the first row comes earlier than the reference trough in that
%row, push the reference data one step down and delete the row
%zero while there is a reference peak.

for i =1:size(pktrfboth2,1)
    [mi, ni]= size(pktrfboth2{i,1});
    for k=1
        if  pktrfboth2{i,1}(k,2) < pktrfboth2{i,1}(k,14)&& pktrfboth2{i,1}(k,2)>0
            appendrow (1,16) = zeros; %This is done so that the last reference peak does not get deleted
            pktrfboth2{i,1} = [pktrfboth2{i,1}; appendrow];
            pktrfboth2{i,1}(k+1:end, 9:16) =  pktrfboth2{i,1}(k:end-1, 9:16);
            pktrfboth2{i,1}(k, 1:16) = 0;
        end
    end
end

% Repeating the above for second row onwards
for i =1:size(pktrfboth2,1)
    [mi, ni]= size(pktrfboth2{i,1});
    for k=2:mi
        if  pktrfboth2{i,1}(k,2) < pktrfboth2{i,1}(k,14)&& pktrfboth2{i,1}(k,2)>0
            appendrow (1,16) = zeros; %This is done so that the last reference peak does not get deleted
            pktrfboth2{i,1} = [pktrfboth2{i,1}; appendrow];
            pktrfboth2{i,1}(k+1:end, 9:16) =  pktrfboth2{i,1}(k:end-1, 9:16);
            pktrfboth2{i,1}(k, 9:16) =  pktrfboth2{i,1}(k-1, 9:16);
            
        end
    end
end

% If there are two test peaks against the same reference, copy the peak
% with higher amplitude into the other
for i = 1:size(pktrfboth2, 1)
    [mi, ni] = size(pktrfboth2{i, 1});
    k = 1;
    while k < mi
        if all(pktrfboth2{i, 1}(k, 9:16) == pktrfboth2{i, 1}(k+1, 9:16))
            if pktrfboth2{i, 1}(k, 1)- pktrfboth2{i, 1}(k, 5)> pktrfboth2{i, 1}(k+1, 1)- pktrfboth2{i, 1}(k+1, 5) && pktrfboth2{i, 1}(k+1, 1) ~= 0
                pktrfboth2{i, 1}(k+1, 1:8) = pktrfboth2{i, 1}(k, 1:8);
            else
                pktrfboth2{i, 1}(k, 1:8) = pktrfboth2{i, 1}(k+1, 1:8);
            end
        end
        k = k + 1;
    end
end

%Remove duplicate rows
for i =1:size(pktrfboth2,1)
    [mi, ni]= size(pktrfboth2{i,1});
    for k=1:mi-1
        if  pktrfboth2{i,1}(k,1:16)== pktrfboth2{i,1}(k+1,1:16)
            pktrfboth2{i,1}(k,1:16)= 0;
        end
    end
end

%Remove reference data when there is a lone reference peak
for i =1:size(pktrfboth2,1)
    [mi, ni]= size(pktrfboth2{i,1});
    for k=1:mi
        if  pktrfboth2{i,1}(k,13:16)==0
            pktrfboth2{i,1}(k,9:12)= 0;
        end
    end
end

%Remove reference data when there is a lone reference trough
for i =1:size(pktrfboth2,1)
    [mi, ni]= size(pktrfboth2{i,1});
    for k=1:mi
        if  pktrfboth2{i,1}(k,9:12)== 0
            pktrfboth2{i,1}(k,13:16)= 0;
        end
    end
end

% %If there is a lone test peak without preceding trough in test data in the first row, it may be because of sectioning of plateaus.
% %Remove both test and reference data. This is done only after alignment

for i =1:size(pktrfboth2,1)
    if all(pktrfboth2{i,1}(1,5:8) == 0) && all(pktrfboth2{i,1}(1,1:4)~= 0)
        pktrfboth2{i,1}(1,1:16)= 0;
    end
end

% %To remove a lone trough without a succeeding peak in test upto last but
% two rows. The following can cause trouble if test data is cut in the last pulse,
% while ref peak is identified. (eg. 220303AP)


for i =1:size(pktrfboth2,1)
    for k = 1:size(pktrfboth2{i,1},1)-1 % This is just up to last but one row? And the size is not specified?
        if (pktrfboth2{i,1}(k,1:4)) == 0
            pktrfboth2{i,1}(k,1:8)= 0;% considered and found right.
        end
    end
end

% For the last row, should you run the same loop and delete 1:16? (Entry
% made on 31 August

for i = 1:size(pktrfboth2,1)
    for k = size(pktrfboth2{i,1},1)
        if (pktrfboth2{i,1}(k,1:4)) == 0
            pktrfboth2{i,1}(k,1:16)= 0;
        end
    end
end

%% Remove rows that have all zeros from pktrfboth2

for j = 1:size(pktrfboth2,1)
    temp = pktrfboth2{j,1};
    idxFZ = ~all(temp==0, 2); % Find the rows without zero entries using logical indexing
    temp = temp(idxFZ,:); % Select the rows without zero entries using logical indexing
    pktrfboth2{j,1} = temp; % Assign the modified array back to the j-th cell of pktrfboth2
end


%%
%The issue now is that there are multiple test peaks within two ref troughs.
%Should select the larger one of the test peaks.
%The aim is to have same number of pulses in tests and troughs for taking ratios

%It is important to add rows with zeros to the array because pushing reference data down will cause loss of reference peaks in the end
%The zeros may be added in the loop
pktrfboth3 = pktrfboth2;

for i = 1:size(pktrfboth3, 1)
    [mi, ni] = size(pktrfboth3{i, 1});
    k = 1;
    while k < mi
        if all(pktrfboth3{i, 1}(k, 9:16) == pktrfboth3{i, 1}(k+1, 9:16))
            if pktrfboth3{i, 1}(k, 4) > pktrfboth3{i, 1}(k+1, 4)%&& pktrfboth3{i, 1}(k+1, 4)>0
                pktrfboth3{i, 1}(k+1, 1:8) = pktrfboth3{i, 1}(k, 1:8);%selecting the larger peak and copying into both rows
            else
                pktrfboth3{i, 1}(k, 1:8) = pktrfboth3{i, 1}(k+1, 1:8);
            end
        end
        k = k + 1;
    end
end

%Is not the following code a little problematic?
%it just removes the current row reference data without considering the test peak amplitude
% Looks like the same test data will be found in both rows, as updated from
% the previous loop.
for i = 1:size(pktrfboth3, 1)
    [mi, ni] = size(pktrfboth3{i, 1});
    for k = 1:mi-1
        if (pktrfboth3{i, 1}(k, 1:16) == (pktrfboth3{i, 1}(k+1, 1:16)))
            pktrfboth3{i, 1}(k, 1:16) = 0;
        end
    end
end

%If a test trough comes before the previous reference peak, delete it
%(This is the case with some initial swings that have duration between trough and peak less than 1).

for i = 1:size(pktrfboth3, 1)
    [mi, ni] = size(pktrfboth3{i, 1});
    for k = 2:mi
        if pktrfboth3{i, 1}(k, 6) < pktrfboth3{i, 1}(k-1, 10)&&pktrfboth3{i, 1}(k-1, 10)>0 % The && operator is not there in 17apr code
            pktrfboth3{i, 1}(k, 1:8) = 0;
        end
    end
end

% for too wide and false test wave as in 220405 cell3, which does not get
% deleted with any of above
for i = 1:size(pktrfboth3,1)
    [mi, ni] = size(pktrfboth3{i, 1});
    for k = 1:mi
        meanwidthtest (i,1) = mean(nonzeros(pktrfboth3 {i,1} (:,3)));
        meanwidthref (i,1) = mean(nonzeros(pktrfboth3 {i,1} (:,11)));
        maxmeanwidthref = max(meanwidthref);
        if pktrfboth3{i, 1}(k, 3) > 2*maxmeanwidthref
            pktrfboth3{i, 1}(k, 1:8) = 0;
        end
    end
end

%to delete false narrow peaks in test:

for i = 1:size(pktrfboth3,1)
    [mi, ni] = size(pktrfboth3{i, 1});
    for k = 1:mi
        if pktrfboth3{i, 1}(k, 3) < 0.2*maxmeanwidthref
            pktrfboth3{i, 1}(k, 1:8) = 0;
        end
    end
end

%After alignment for I row, if there is a lone test peak without trough, delete whole row, otherwise it will appear as a false zero.

% For the last row, in every cell, or atleast in cells which are below systolic range), remove the last ref pulse, if
% there is no test pulse.

for j = 1:size(pktrfboth3,1)
    for i = size (pktrfboth3{j,1},1)
        if  pktrfboth3{j,1}(i,1:8)==0
            pktrfboth3{j,1}(i,1:16)= 0;
        end
    end
end

%Deleting a lone peak in test

for j = 1: size(pktrfboth3,1)
    for i = 1
        if  pktrfboth3{j,1}(i,5:8)==0
            pktrfboth3{j,1}(i,1:4)= 0;
        end
    end
end

%Remove zero entries from pktrfboth3:
for j = 1:size(pktrfboth3,1)
    temp = pktrfboth3{j,1};
    idxFZ = ~all(temp==0, 2); % Find the rows without zero entries using logical indexing
    temp = temp(idxFZ,:); % Select the rows without zero entries using logical indexing
    pktrfboth3{j,1} = temp; % Assign the modified array back to the j-th cell of pktrf0
end

%%
%figure (8)
%hold on

for i= 1:size(cell,1)
%    plot (cell{i,1} (:,1), cell{i,1} (:,3),'color', MediumGreen_1);
%    plot (cell{i,1} (:,1), cell{i,1} (:,4), 'color', Orange);
    
%    scatter (pktrfboth3{i,1}(:,2), pktrfboth3{i,1}(:,1));
%    scatter (pktrfboth3{i,1}(:,6), pktrfboth3{i,1}(:,5));
%    scatter (pktrfboth3{i,1}(:,10), pktrfboth3{i,1}(:,9));
%    scatter (pktrfboth3{i,1}(:,14), pktrfboth3{i,1}(:,13));
end
%
for i= 1:size(cell,1)
%    yyaxis right
%    plot (cell{i,1} (:,1), cell{i,1} (:,2), 'color', 'k');
end
%hold off

%xlabel ('time in seconds');
%grid on
%title (expt_id);
%saveas(gcf,[expt_id 'fig8.fig']);

%%
% Get absolute amplitudes of test and ref pulses (col 17 and 18) and the
% ratio in col 19
% 
for i = 1:size(pktrfboth3, 1)
    [mi, ni] = size(pktrfboth3{i, 1});
    for k = 1:mi
        pktrfboth3{i, 1}(k,17) = pktrfboth3{i, 1}(k,1)- pktrfboth3{i, 1}(k,5); % amplitude of test PPG
        pktrfboth3{i, 1}(k,18) = pktrfboth3{i, 1}(k,9)- pktrfboth3{i, 1}(k,13); % amplitude of ref PPG
        pktrfboth3{i, 1}(k,19) = pktrfboth3{i, 1}(k,17)/ pktrfboth3{i, 1}(k,18); % ratio of test/ref
    end
end

%adding a column of cuff pressure to pktrfboth3
for j = 1: length(pktrfboth3)
    pktrfboth3{j,1}(:,20)=cell{j,2};
end

for i = 1:size(pktrfboth3,1)
    pktrfboth3{i,2} = mean(pktrfboth3{i,1}(:,20));%mean of cuff pressure
end

for i = 1:size(pktrfboth3, 1)
    for j = 1:size(pktrfboth3{i, 1},1)
        pktrfboth3{i, 1}(j, 21)= pktrfboth3{i, 1}(j, 3)+ pktrfboth3{i, 1}(j, 7);  % sum of widths of peak and trough of cuffed arm
        pktrfboth3{i, 1}(j, 22)= pktrfboth3{i, 1}(j, 21)==0; %(logical for zero pulses)
        pktrfboth3{i, 1}(j, 23)= pktrfboth3{i, 1}(j, 2)- pktrfboth3{i, 1}(j, 6);%time to peak from trough for test
        
        pktrfboth3{i, 1}(j, 24)= pktrfboth3{i, 1}(j, 11)+pktrfboth3{i, 1}(j, 15);%  sum of widths of peak and trough of ref arm
        pktrfboth3{i, 1}(j, 25)= pktrfboth3{i, 1}(j, 10)- pktrfboth3{i, 1}(j, 14);%time to peak from trough for ref
        
        pktrfboth3{i, 3} = sum(pktrfboth3{i, 1}(:, 22));%Number of zero pulses- repeat
        pktrfboth3{i, 4} = max(pktrfboth3{i, 1}(:, 21)); %max widthsum test
        
        pktrfboth3{i, 5} = min(nonzeros(pktrfboth3{i, 1}(:, 17)));%min test amplitude
        pktrfboth3{i, 6} = max(pktrfboth3{i, 1}(:, 17));%max  test amplitude
        pktrfboth3{i, 7} = mean(nonzeros(pktrfboth3{i, 1}(:, 17)));% mean test amplitude
        
        pktrfboth3{i, 8} = max(nonzeros(pktrfboth3{i, 1}(:, 24)));% max widthsum ref
        pktrfboth3{i, 9} = max(nonzeros(pktrfboth3{i, 1}(:, 19)));% max ratio
        
        pktrfboth3{i, 10} = (size(pktrfboth3{i,1},1)- pktrfboth3{i,3}); % pulse number
        pktrfboth3{i, 11} =  pktrfboth3{i, 1}(end, 10)- pktrfboth3{i, 1}(1, 10); %Time of last peak minus time of first peak gives duration of plateau
        averagePlateauPeriod = mean(cell2mat(pktrfboth3(:, 11)));
        pktrfboth3{i, 12} = round((((pktrfboth3{i, 10}/ pktrfboth3{i, 11}*10)))); %number of pulses per 10 seconds
        averageTestPulseNumber = round(mean(cell2mat(pktrfboth3(:, 12)))); %average Number of test pulses per 10 seconds
    end
end
%%
%Taking the risk of declaring all zeros below max(x_rms13new,
%x_rms15new) as false negative

for i = 1: size(pktrfboth3,1)
    for j = 1: size(pktrfboth3{i,1})
        if max(x_rms13new, x_rms15new)> max(Hpointrms_array)
            if  pktrfboth3{i,2} < max(x_rms13new, x_rms15new) %for cuff pressures below xrmsnew
                if pktrfboth3 {i,1}(j, 17)==0 %if there is a zero pulse
                    pktrfboth3 {i,1}(j, :)=0;% render col 22 to zero, which is actually a logical for zero pulses. Because it is a false zero, the logical becomes zero.
                    pktrfboth3{i, 3} = sum(pktrfboth3{i, 1}(:, 22));%Number of zero pulses- repeat
                end
            end
        else
            if  pktrfboth3{i,2} < max(Hpointrms_array)
                if pktrfboth3 {i,1}(j, 17)==0 %if there is a zero pulse
                    pktrfboth3 {i,1}(j, :)=0;% render col 22 to zero, which is actually a logical for zero pulses. Because it is a false zero, the logical becomes zero.
                    pktrfboth3{i, 3} = sum(pktrfboth3{i, 1}(:, 22));%Number of zero pulses- repeat
                end
            end
        end
    end
end

%All pulses above Sys_rms+5 are false positives

threshold_forCSys = Sys_rms(1,1) +5;

for i = 1: size(pktrfboth3,1)
    for j = 1: size(pktrfboth3{i,1},1)
        if  pktrfboth3{i,2} > threshold_forCSys %for cuff pressures above xrms1_2
            if pktrfboth3 {i,1}(j, 22)==0 %if there is a pulse, it is a false pulse
                pktrfboth3 {i,1}(j, 1:8)=0;% render col 22 to zero, which is actually a logical for zero pulses. Because it is a false zero, the logical becomes zero.
                pktrfboth3{i, 1}(j, 17:2:23)=0; %Render test amplitude, ratio and sum of widths to zero
                pktrfboth3 {i,1}(j, 22)=1;
                pktrfboth3{i, 3} = sum(pktrfboth3{i, 1}(:, 22));%Number of zero pulses- repeat
            end
        end
    end
end

%Case of 220318AP detected on 20May2025 - lone false high peak in 110 cuff
%pressure, higher than max of diastolic range. This sure is an artefact

for j = 1:size(pktrfboth3,1)
    tempPTB3 = pktrfboth3{j,1};
    idxPTB3 = ~all(tempPTB3==0, 2); % Find the rows without zero entries using logical indexing
    tempPTB3 = tempPTB3(idxPTB3,:); % Select the rows without zero entries using logical indexing
    pktrfboth3{j,1} = tempPTB3; % Assign the modified array back to the j-th cell of pktrfref0
end

%Repeat

for i = 1:size(pktrfboth3, 1)
    for j = 1:size(pktrfboth3{i, 1},1)
        pktrfboth3{i, 1}(j, 21)= pktrfboth3{i, 1}(j, 3)+ pktrfboth3{i, 1}(j, 7);  % sum of widths of peak and trough of cuffed arm
        pktrfboth3{i, 1}(j, 22)= pktrfboth3{i, 1}(j, 21)==0; %(logical for zero pulses)
        pktrfboth3{i, 1}(j, 23)= pktrfboth3{i, 1}(j, 2)- pktrfboth3{i, 1}(j, 6);%time to peak from trough for test
        
        pktrfboth3{i, 1}(j, 24)= pktrfboth3{i, 1}(j, 11)+pktrfboth3{i, 1}(j, 15);%  sum of widths of peak and trough of ref arm
        pktrfboth3{i, 1}(j, 25)= pktrfboth3{i, 1}(j, 10)- pktrfboth3{i, 1}(j, 14);%time to peak from trough for ref
        
        pktrfboth3{i, 3} = sum(pktrfboth3{i, 1}(:, 22));%Number of zero pulses- repeat
        pktrfboth3{i, 4} = max(pktrfboth3{i, 1}(:, 21)); %max widthsum test
        
        pktrfboth3{i, 5} = min(nonzeros(pktrfboth3{i, 1}(:, 17)));%min test amplitude
        pktrfboth3{i, 6} = max(pktrfboth3{i, 1}(:, 17));%max  test amplitude
        pktrfboth3{i, 7} = mean(nonzeros(pktrfboth3{i, 1}(:, 17)));% mean test amplitude
        
        pktrfboth3{i, 8} = max(nonzeros(pktrfboth3{i, 1}(:, 24)));% max widthsum ref
        pktrfboth3{i, 9} = max(nonzeros(pktrfboth3{i, 1}(:, 19)));% max ratio
        
        pktrfboth3{i, 10} = (size(pktrfboth3{i,1},1)- pktrfboth3{i,3}); % pulse number
        pktrfboth3{i, 11} =  pktrfboth3{i, 1}(end, 10)- pktrfboth3{i, 1}(1, 10); %Time of last peak minus time of first peak gives duration of plateau
        averagePlateauPeriod = mean(cell2mat(pktrfboth3(:, 11)));
        pktrfboth3{i, 12} = round((((pktrfboth3{i, 10}/ pktrfboth3{i, 11}*10)))); %number of pulses per 10 seconds
        averageTestPulseNumber = round(mean(cell2mat(pktrfboth3(:, 12)))); %average Number of test pulses per 10 seconds
    end
end

% Systolic pressures are in the range where both columns 3 amd 12 are more
% than zero

% In pressures below systolic (wehre there are no zero pulses, and
% therefore column 3 is ==0)take the mean and sd of amplitudes and if any
% amplitude is more than mean + 2SD of amplitude is likely to be an
% artifact and can be deleted

for i = 1:size(pktrfboth3, 1)
    for j = 1:size(pktrfboth3{i, 1},1)
        if   pktrfboth3{i, 3} ==0
            if pktrfboth3{i, 1}(j,17)> mean(pktrfboth3{i, 1}(j,17))+ 2*std(pktrfboth3{i, 1}(j,17))
                pktrfboth3{i, 1}(j,:)=0;
            end
        end
    end
end

for j = 1:size(pktrfboth3,1)
    tempPTB3 = pktrfboth3{j,1};
    idxPTB3 = ~all(tempPTB3==0, 2); % Find the rows without zero entries using logical indexing
    tempPTB3 = tempPTB3(idxPTB3,:); % Select the rows without zero entries using logical indexing
    pktrfboth3{j,1} = tempPTB3; % Assign the modified array back to the j-th cell of pktrfref0
end

for i = 1:size(pktrfboth3, 1)
    for j = 1:size(pktrfboth3{i, 1},1)
        pktrfboth3{i, 1}(j, 21)= pktrfboth3{i, 1}(j, 3)+ pktrfboth3{i, 1}(j, 7);  % sum of widths of peak and trough of cuffed arm
        pktrfboth3{i, 1}(j, 22)= pktrfboth3{i, 1}(j, 21)==0; %(logical for zero pulses)
        pktrfboth3{i, 1}(j, 23)= pktrfboth3{i, 1}(j, 2)- pktrfboth3{i, 1}(j, 6);%time to peak from trough for test
        
        pktrfboth3{i, 1}(j, 24)= pktrfboth3{i, 1}(j, 11)+pktrfboth3{i, 1}(j, 15);%  sum of widths of peak and trough of ref arm
        pktrfboth3{i, 1}(j, 25)= pktrfboth3{i, 1}(j, 10)- pktrfboth3{i, 1}(j, 14);%time to peak from trough for ref
        
        pktrfboth3{i, 3} = sum(pktrfboth3{i, 1}(:, 22));%Number of zero pulses- repeat
        pktrfboth3{i, 4} = max(pktrfboth3{i, 1}(:, 21)); %max widthsum test
        
        pktrfboth3{i, 5} = min(nonzeros(pktrfboth3{i, 1}(:, 17)));%min test amplitude
        pktrfboth3{i, 6} = max(pktrfboth3{i, 1}(:, 17));%max  test amplitude
        pktrfboth3{i, 7} = mean(nonzeros(pktrfboth3{i, 1}(:, 17)));% mean test amplitude
        
        pktrfboth3{i, 8} = max(nonzeros(pktrfboth3{i, 1}(:, 24)));% max widthsum ref
        pktrfboth3{i, 9} = max(nonzeros(pktrfboth3{i, 1}(:, 19)));% max ratio
        
        pktrfboth3{i, 10} = (size(pktrfboth3{i,1},1)- pktrfboth3{i,3}); % pulse number
        pktrfboth3{i, 11} =  pktrfboth3{i, 1}(end, 10)- pktrfboth3{i, 1}(1, 10); %Time of last peak minus time of first peak gives duration of plateau
        averagePlateauPeriod = mean(cell2mat(pktrfboth3(:, 11)));
        pktrfboth3{i, 12} = round((((pktrfboth3{i, 10}/ pktrfboth3{i, 11}*10)))); %number of pulses per 10 seconds
        averageTestPulseNumber = round(mean(cell2mat(pktrfboth3(:, 12)))); %average Number of test pulses per 10 seconds
    end
end

%%
% Collect the amplitudes and ratios_0 in an array called ratios_0
ratios_0a = [];

for i = 1:size(pktrfboth3, 1)
    for k = 1:size(pktrfboth3{i, 1},1)
        ratios_0a{i,1}(k,1:4) = pktrfboth3{i,1}(k,17:20);
    end
end

for i = 1: size(ratios_0a,1)
    ratios_0a_logical(i,1) = ~isempty(ratios_0a{i,1});
end

ratios_0 = ratios_0a(ratios_0a_logical, :);

% In ratios_0, if there is a 0 in ref amplitude (ie, column 2) then some
% values are turned out as infinity and this creates problems. Therefore
% delete rows with 0 in column 2

% Remove rows from ratios_0 where the second column is equal to 0
ratios_0 = cellfun(@(x) x(x(:,2)~=0,:), ratios_0, 'UniformOutput', false);

% @(x) x(x(:,2)~=0,:)
% is an anonymous function (lambda function) defined using @(x).
% This anonymous function takes a single input x, which is expected to be a matrix.
% It filters the rows of the input matrix x based on the condition x(:,2)~=0,
% which means it keeps only the rows where the second column (column 2) is not equal to zero.
%
% 'UniformOutput', false is an option passed to cellfun.
% It specifies that the output should not be coerced into a uniform data type.
% Since the result of the anonymous function is a matrix,
% setting 'UniformOutput', false ensures that the output remains a cell array,
% with each element corresponding to the result of applying the function to each element
% of the input cell array.

% Remove the first row in every cell

for i = 1:numel(ratios_0)
    if size(ratios_0{i},1)>2 % added on 20Mar2025
        ratios_0{i} = ratios_0{i}(2:end, :);
    end
end

%%
hcp =cell {1,2};

ratiomat_0 = cell2mat(ratios_0);
eachratiomat_01 = cat(1,ratios_0{:,1}); % Both eachratiomat_0 and ratiomat_0 are identical, and redundant
eachratiomat_0 = eachratiomat_01;

%figure (9)
%scatter (eachratiomat_0(:,4), eachratiomat_0(:,3));
%legend ('PPG ratios_0');
%xticks([0: 10: 1000])
%set(gca,'XMinorTick','on','YMinorTick','on')
%grid on

%xlabel ('cuff pressure mmHg');
%ylabel ('PPG ratio');
%title (expt_id);

%saveas(gcf,[expt_id 'fig9.fig']);

%%
%Get the mean of ratios_0 for each cuff pressure
for i = 1:size(ratios_0,1)
    meanratios_0{i,1} = mean(ratios_0{i}(:,4));%cuff pressure
    meanratios_0{i,2} = mean(ratios_0{i}(:,3));%ratios_0
end
meanratiomat_0 = cell2mat(meanratios_0);
%%
%figure (10)
%scatter (meanratiomat_0(:,1), meanratiomat_0(:,2));
%xlabel ('cuff pressure mmHg');
%ylabel ('mean PPG ratio');
%legend ('mean PPG ratio');
%title (expt_id);
%xticks([0: 10: 1000])
%set(gca,'XMinorTick','on','YMinorTick','on')
%grid on
%grid on

%saveas(gcf,[expt_id 'fig10.fig']);

%%
% for taking min and max ratio
for i = 1:size(ratios_0,1)
    ratios_0 {i,2} = mean(ratios_0{i,1}(:,4)); % cuff pressure
end

for j = 1:size(ratios_0,1)
    % To delete some rows, mention the others that you want to keepHere, enter the rows that you want kept. May want to delete the last row or last 2 rows
    %for j = 3:  size(ratios_0,1)
    % If some rows are deleted, perform removal of zeros:This code is not
    % yet written
    
    minratiomat_0(j,1) = ratios_0{j,2};%cuff pressure
    minratiomat_0(j,2) = min(ratios_0{j,1}(:,3));% minimum ratio
    maxratiomat_0(j,1) = ratios_0{j,2};%cuff pressure
    maxratiomat_0(j,2) = max(ratios_0{j,1}(:,3));%maximum ratio
end

for i=1:size(minratiomat_0, 1)
    minratiomat_0(i,3) = minratiomat_0(i,2)==0;
end

for i=2:size(minratiomat_0, 1)
    if minratiomat_0(i,3) ==0 %identifying the last minimum pulse
        for_falsezero = minratiomat_0(i-1,1);
        break
    end
end
%%
for i=1:size(ratios_0, 1)
    if ratios_0{i,2}< for_falsezero
        temp_ratios_0 = (ratios_0{i,1});
        for j = 1:size(temp_ratios_0, 1)
            idxFZ_ratios_0 = temp_ratios_0(j, 1)==0;
            temp_ratios_1 =  temp_ratios_0(~idxFZ_ratios_0, :);
            %ratios_0{i,1}= temp_ratios_0;
        end
    end
end

%%
[x1Data, y1Data] = prepareCurveData(meanratiomat_0(:,1), meanratiomat_0(:,2));
[x4Data, y4Data] = prepareCurveData(minratiomat_0(:,1), minratiomat_0(:,2));
[x5Data, y5Data] = prepareCurveData(maxratiomat_0(:,1), maxratiomat_0(:,2));
%%
%%Smoothing spline fits for getting envelopes of ratios_0
% Set up fittype and options.
ft_minratio = fittype( 'smoothingspline' );
opts_minratio = fitoptions( 'Method', 'SmoothingSpline' );
opts_minratio.SmoothingParam = 0.999999023293969;

% Fit model to data.
[fitresult{84}, gof(84)] = fit( minratiomat_0(:,1), minratiomat_0(:,2), ft_minratio, opts_minratio );

% Set up fittype and options.
ft_maxratio = fittype( 'smoothingspline' );
opts_maxratio = fitoptions( 'Method', 'SmoothingSpline' );
opts_maxratio.SmoothingParam = 0.9999999;

% Fit model to data.
[fitresult{85}, gof(85)] = fit( maxratiomat_0(:,1), maxratiomat_0(:,2), ft_maxratio, opts_maxratio );
% Set up fittype and options.
ft_meanratio = fittype( 'smoothingspline' );
opts_meanratio = fitoptions( 'Method', 'SmoothingSpline' );
opts_meanratio.SmoothingParam = 0.9999999;

% Fit model to data.
[fitresult{86}, gof(86)] = fit( meanratiomat_0(:,1), meanratiomat_0(:,2), ft_meanratio, opts_meanratio );

%%
ysmspFitMinAfterHpointrms_0 =(fitresult{84}(max(Hpointrms_array) : 1: hcp+20));%get the y values of smsp segment after H point upto Xcrossing
xtsmspFitMinAfterHpointrms_0 =  (max(Hpointrms_array) : 1:hcp+20);% x values of smsp segment after H point
xsmspFitMinAfterHpointrms_0 = xtsmspFitMinAfterHpointrms_0';%transpose the array
smspFitMinAfterHpointrms_0 = [xsmspFitMinAfterHpointrms_0, ysmspFitMinAfterHpointrms_0]; % collect x and y values in one array

ysmspFitMaxAfterHpointrms_0 =(fitresult{85}(max(Hpointrms_array): 1: hcp+20));%get the y values of smsp segment after H point upto Xcrossing
xtsmspFitMaxAfterHpointrms_0 =  (max(Hpointrms_array): 1:hcp+20);% x values of smsp segment after H point
xsmspFitMaxAfterHpointrms_0 = xtsmspFitMaxAfterHpointrms_0';%transpose the array
smspFitMaxAfterHpointrms_0 = [xsmspFitMaxAfterHpointrms_0, ysmspFitMaxAfterHpointrms_0]; % collect x and y values in one array

%%
%figure (700)
%hold on
%plot (xsmspFitMinAfterHpointrms_0, ysmspFitMinAfterHpointrms_0);
%plot (xsmspFitMaxAfterHpointrms_0, ysmspFitMaxAfterHpointrms_0);
%hold off

%%    %to get te X crossing of the smspfit of ratios_0
%Find first draft of Xrossingmin

if any(ysmspFitMinAfterHpointrms_0<0)
    
    for i = 2: size(smspFitMinAfterHpointrms_0,1)
        if smspFitMinAfterHpointrms_0(i-1, 2)>0 && smspFitMinAfterHpointrms_0(i, 2)<0
            XcrossingsmspMin00 = (smspFitMinAfterHpointrms_0(i,1));
            break;
        end
    end
    
else
    Xaxisrms_for = min(ysmspFitMinAfterHpointrms_0);
    smspFitMinAfterHpointrms_0(:,3) = smspFitMinAfterHpointrms_0(:,2)- Xaxisrms_for;
    [~, rI_smspminratios] = min(smspFitMinAfterHpointrms_0 (:,3));
    XcrossingsmspMin00 = smspFitMinAfterHpointrms_0(rI_smspminratios, 1);
end

%Find Xcrossingmax

if any(ysmspFitMaxAfterHpointrms_0<0)
    for i = 2: size(smspFitMaxAfterHpointrms_0,1)
        if smspFitMaxAfterHpointrms_0(i-1, 2)>0 && smspFitMaxAfterHpointrms_0(i, 2)<0
            XcrossingsmspMax00 = (smspFitMaxAfterHpointrms_0(i,1));
            break;
        end
    end
else
    Xaxisrms_for = min(ysmspFitMaxAfterHpointrms_0);
    smspFitMaxAfterHpointrms_0(:,3) = smspFitMaxAfterHpointrms_0(:,2)- Xaxisrms_for;
    [~, rI_smspminratios] = min(smspFitMaxAfterHpointrms_0 (:,3));
    XcrossingsmspMax00 = smspFitMaxAfterHpointrms_0(rI_smspminratios, 1);
end

%%
%If there is only one zero pulse in the cuff pressure near which the X
%crossing occurs, then take the average of that and the next higher cuff pressure
%Set Xcrossing to the higher value. This minimizes the errors in Csyslow

pktrfboth4 =  pktrfboth3;

for i = 1:size(ratios_0,1)
    pktrfboth4{i,13}= pktrfboth4 {i,2}- XcrossingsmspMin00; %Find the differences of cuff pressure from Xcrossing.
    pktrfboth4{i,14}= pktrfboth4 {i,2}- XcrossingsmspMax00; %Find the differences of cuff pressure from Xcrossing.
end

[~, rowIndexsysDiff] = min(abs(cell2mat((pktrfboth4(:,13)))));%Find the lowest difference

rowsToSelect_0 = pktrfboth4{rowIndexsysDiff,1}(:,:);%Select that row; find the zeros, and do a logical on column 5
% rowsToSelect_0(:,22) = rowsToSelect_0(:,17)==0;

if sum(rowsToSelect_0(:,22))<2 % If there are not even two absent pulses,
    Xcrossingsmspmin_0 = round((cell2mat(ratios_0(rowIndexsysDiff-1,2))+cell2mat(ratios_0(rowIndexsysDiff,2)))/2);
else %if there are 2 or more absent pulses
    Xcrossingsmspmin_0 = XcrossingsmspMin00;
end

[~, rowIndexsysDiffmax_0] = min(abs(cell2mat((pktrfboth4(:,14)))));%Find the lowest difference
Xcrossingsmspmax_0 = round(cell2mat(pktrfboth4(rowIndexsysDiffmax_0,2)));

%%
%More deletions?
for i = 1:size(pktrfboth4, 1)
    for j = 1:size(pktrfboth4{i, 1},1)
        pktrfboth4{i, 1}(j, 26)= 1.5*(pktrfboth4{i, 1}(j, 25))- pktrfboth4{i, 1}(j, 23); % Difference between 1.5 times time to peak of ref and time to peak of test
        pktrfboth4{i, 1}(j, 27)= pktrfboth4{i, 1}(j, 24)/pktrfboth4{i, 1}(j, 21); %ratio of sum of widths of ref to test (ref on numerator)
        pktrfboth4{i, 1}(j, 28)=1.1*(pktrfboth4{i, 1}(j, 24))- pktrfboth4{i, 1}(j, 21);%added by bowya
 
        pktrfboth4{i, 15}=mean(pktrfboth4{i, 1}(~isinf(pktrfboth4{i, 1}(:, 27)), 27) - 2 * std(pktrfboth4{i, 1}(~isinf(pktrfboth4{i, 1}(:, 27)), 27))); %added by bowya
        
        if pktrfboth4{i,3}>0
            if pktrfboth4{i, 1}(j, 27)< pktrfboth4{i, 15}% if tatio of sum of widths (ref/test) is less than mean - 2SD of ratio of sum of widths
                pktrfboth4{i, 1}(j, 1:8)=0; %Render test entries to zero
                pktrfboth4{i, 1}(j, 17:2:21)=0; %Render test amplitude, ratio and sum of widths to zero
                pktrfboth4{i, 1}(j, 22)= pktrfboth4{i, 1}(j, 21)==0; %repeat logical after zeroing false positives
                pktrfboth4{i, 1}(j, 23)=0;%Render pulse amplitude and   time to peak to zero
            end
        end
    end
end

%added by bowya
for i = 1:size(pktrfboth4, 1)
    for j = 1:size(pktrfboth4{i, 1},1)
        if pktrfboth4{i,2}> pktrfboth4{rowIndexsysDiff+1,2}
            if pktrfboth4{i, 1}(j, 28)< 0% if tatio of sum of widths (ref/test) is less than mean - 2SD of ratio of sum of widths
                pktrfboth4{i, 1}(j, 1:8)=0; %Render test entries to zero
                pktrfboth4{i, 1}(j, 17:2:21)=0; %Render test amplitude, ratio and sum of widths to zero
                pktrfboth4{i, 1}(j, 22)= pktrfboth4{i, 1}(j, 21)==0; %repeat logical after zeroing false positives
                pktrfboth4{i, 1}(j, 23)=0;%Render pulse amplitude and   time to peak to zero
            end
        end
    end
end
% Deleting false positives based on time to peak, and sum of widths

for i = 1:size(pktrfboth4, 1)
    for j = 1:size(pktrfboth4{i, 1},1)
        
        if pktrfboth4{i,3}>0 && pktrfboth4{i,12}>0 %If there are positives above minimum systolic
            
            if pktrfboth4{i, 1}(j, 26)< 0 % if test pulse is too wide
                pktrfboth4{i, 1}(j, 1:8)=0; %Render test entries to zero
                pktrfboth4{i, 1}(j, 17:2:21)=0; %Render test amplitude, ratio and sum of widths to zero
                pktrfboth4{i, 1}(j, 22)= pktrfboth4{i, 1}(j, 21)==0; %repeat logical after zeroing false positives
                pktrfboth4{i, 1}(j, 23)=0;%Render pulse amplitude and time to peak to zero
                
            end
            
            if pktrfboth4{i, 1}(j, 21)> pktrfboth4{rowIndexsysDiff, 4}% if sum of widths is more than max of lower cuff pressure
                pktrfboth4{i, 1}(j, 1:8)=0; %Render test entries to zero
                pktrfboth4{i, 1}(j, 17:2:21)=0; %Render test amplitude, ratio and sum of widths to zero
                pktrfboth4{i, 1}(j, 22)= pktrfboth4{i, 1}(j, 21)==0; %repeat logical after zeroing false positives
                pktrfboth4{i, 1}(j, 23)=0;%Render pulse amplitude and  time to peak to zero
            end
            
        end
    end
end

for i = 1:size(pktrfboth4, 1)
    for j = 1:size(pktrfboth4{i, 1},1)
        
        if pktrfboth4{i,3}>0 %If the logical is more than 0, there are zero pulses
            if pktrfboth4{i, 1}(j, 17)> 1.5*(pktrfboth4{rowIndexsysDiff, 6})% if pulse amplitude is more than max of lower cuff pressure
                pktrfboth4{i, 1}(j, 1:8)=0; %Render test entries to zero
                pktrfboth4{i, 1}(j, 17:2:21)=0; %Render test amplitude, ratio and sum of widths to zero
                pktrfboth4{i, 1}(j, 22)= pktrfboth4{i, 1}(j, 21)==0; %repeat logical after zeroing false positives
                pktrfboth4{i, 1}(j, 23)=0;%Render pulse amplitude and amp*width product to zero
            end
            
            if pktrfboth4{i, 1}(j, 23)< 0.25* (pktrfboth4{i, 1}(j, 25))% if time to peak is less than 1/4th of corresponding ref
                pktrfboth4{i, 1}(j, 1:8)=0; %Render the test entries to zero
                pktrfboth4{i, 1}(j, 17:2:21)=0; %Render test amplitude, ratio and sum of widths to zero
                pktrfboth4{i, 1}(j, 22)= pktrfboth4{i, 1}(j, 21)==0;%Repeating logical after zeroing
                pktrfboth4{i, 1}(j, 23)=0;%Render pulse amplitude and amp*width product to zero
            end
            
        end
    end
end
%
for i = 1:size(pktrfboth4, 1)
    for j = 1:size(pktrfboth4{i, 1},1)
        pktrfboth4{i, 1}(j, 21)= pktrfboth4{i, 1}(j, 3)+ pktrfboth4{i, 1}(j, 7);  % sum of widths of peak and trough of cuffed arm
        pktrfboth4{i, 1}(j, 22)= pktrfboth4{i, 1}(j, 21)==0; %(logical for zero pulses)
        pktrfboth4{i, 1}(j, 23)= pktrfboth4{i, 1}(j, 2)- pktrfboth4{i, 1}(j, 6);%time to peak from trough for test
        
        pktrfboth4{i, 1}(j, 24)= pktrfboth4{i, 1}(j, 11)+pktrfboth4{i, 1}(j, 15);%  sum of widths of peak and trough of ref arm
        pktrfboth4{i, 1}(j, 25)= pktrfboth4{i, 1}(j, 10)- pktrfboth4{i, 1}(j, 14);%time to peak from trough for ref
        pktrfboth4{i, 1}(j, 26)= 1.5*(pktrfboth4{i, 1}(j, 25))- pktrfboth4{i, 1}(j, 23); % Difference between 1.5 times time to peak of ref and time to peak of test
        
        pktrfboth4{i, 3} = sum(pktrfboth4{i, 1}(:, 22));%Number of zero pulses- repeat
        pktrfboth4{i, 4} = max(pktrfboth4{i, 1}(:, 21)); %max widthsum test
        
        pktrfboth4{i, 5} = min(nonzeros(pktrfboth4{i, 1}(:, 17)));%min test amplitude
        pktrfboth4{i, 6} = max(pktrfboth4{i, 1}(:, 17));%max  test amplitude
        pktrfboth4{i, 7} = mean(nonzeros(pktrfboth4{i, 1}(:, 17)));% mean test amplitude
        
        pktrfboth4{i, 8} = max(nonzeros(pktrfboth4{i, 1}(:, 24)));% max widthsum ref
        pktrfboth4{i, 9} = max(nonzeros(pktrfboth4{i, 1}(:, 19)));% max ratio
        
        pktrfboth4{i, 10} = (size(pktrfboth4{i,1},1)- pktrfboth4{i,3}); % pulse number
        pktrfboth4{i, 11} =  pktrfboth4{i, 1}(end, 10)- pktrfboth4{i, 1}(1, 10); %Time of last peak minus time of first peak gives duration of plateau
        averagePlateauPeriod = mean(cell2mat(pktrfboth4(:, 11)));
        pktrfboth4{i, 12} = round((((pktrfboth4{i, 10}/ pktrfboth4{i, 11}*10)))); %number of pulses per 10 seconds
        averageTestPulseNumber = round(mean(cell2mat(pktrfboth4(:, 12)))); %average Number of test pulses per 10 seconds
    end
end

%In the case of 18092103, there was a false zero at 133 cuff pressure in pktrfboth4 because of the above deletions,
%while it was not there in pktrfboth3. Trying to restore it as follows:

for i = 1: size(pktrfboth4,1)
    falseZeros(i,1) = pktrfboth4{i,2}; %cuff pressure
    falseZeros(i,2) = pktrfboth4{i,3}-pktrfboth3{i,3};%new zeros
end

for i = 1: size(falseZeros,1)
    for j=2:size(pktrfboth3,2)
        if falseZeros(i,2)>0 && falseZeros(i,1)<min(XcrossingsmspMin00, Xcrossingsmspmin_0)
            pktrfboth4{i,1}(:,1:25)= pktrfboth3{i,1}(:,1:25);
            pktrfboth4{i,j}= pktrfboth3{i,j};
        end
    end
end
%Redoing the following:

for i = 1:size(pktrfboth4, 1)
    for j = 1:size(pktrfboth4{i, 1},1)
        pktrfboth4{i, 1}(j, 26)= 1.5*(pktrfboth4{i, 1}(j, 25))- pktrfboth4{i, 1}(j, 23); % Difference between 1.5 times time to peak of ref and time to peak of test
        pktrfboth4{i, 1}(j, 27)= pktrfboth4{i, 1}(j, 24)/pktrfboth4{i, 1}(j, 21); %ratio of sum of widths of ref to test (ref on numerator)
        pktrfboth4{i, 1}(j, 28)=1.1*(pktrfboth4{i, 1}(j, 24))- pktrfboth4{i, 1}(j, 21);%added by bowya
        pktrfboth4{i, 15}=mean(pktrfboth4{i, 1}(~isinf(pktrfboth4{i, 1}(:, 27)), 27) - 2 * std(pktrfboth4{i, 1}(~isinf(pktrfboth4{i, 1}(:, 27)), 27))); %added by bowya
    end
end

for i = 1:size(ratios_0,1)
    pktrfboth4{i,13}= pktrfboth4 {i,2}- XcrossingsmspMin00; %Find the differences of cuff pressure from Xcrossing.
    pktrfboth4{i,14}= pktrfboth4 {i,2}- XcrossingsmspMax00; %Find the differences of cuff pressure from Xcrossing.
end

[~, rowIndexsysDiff] = min(abs(cell2mat((pktrfboth4(:,13)))));%Find the lowest difference

rowsToSelect_0 = pktrfboth4{rowIndexsysDiff,1}(:,:);%Select that row; find the zeros, and do a logical on column 5
% rowsToSelect_0(:,22) = rowsToSelect_0(:,17)==0;

if sum(rowsToSelect_0(:,22))<2 % If there are not even two absent pulses,
    Xcrossingsmspmin_0 = round((cell2mat(ratios_0(rowIndexsysDiff-1,2))+cell2mat(ratios_0(rowIndexsysDiff,2)))/2);
else %if there are 2 or more absent pulses
    Xcrossingsmspmin_0 = XcrossingsmspMin00;
end

[~, rowIndexsysDiffmax_0] = min(abs(cell2mat((pktrfboth4(:,14)))));%Find the lowest difference
Xcrossingsmspmax_0 = round(cell2mat(pktrfboth4(rowIndexsysDiffmax_0,2)));

pktrfboth5 = pktrfboth4;


% % Added on 21 May - To remove an artefact whose ratio is higher than the
% max ratio at Hpoint

for i = 1:size(pktrfboth5, 1)
    for j = 1:size(pktrfboth5{i, 1},1)
        if abs(pktrfboth5{i,2}- HrmsTrue)<5
            Ratio_Ceiling = max(pktrfboth5{i,1}(:, 19));
            break
        elseif abs(pktrfboth5{i,2}- HrmsTrue)< 7
            Ratio_Ceiling = max(pktrfboth5{i,1}(:, 19));
            break
        else % case where the lcp is less than Hrmstrue
            Ratio_Ceiling = max(pktrfboth5{end,1}(:, 19));
        end
    end
end

for i = 1:size(pktrfboth5, 1)
    for j = 1:size(pktrfboth5{i, 1},1)
        if pktrfboth5{i,2}> HrmsTrue + 10
            if pktrfboth5{i,1}(j,19) >  Ratio_Ceiling
                pktrfboth5{i,1}(j,:)=0;
            end
        end
    end
end

for j = 1:size(pktrfboth5,1)
    tempFH = pktrfboth5{j,1};
    idxFH = ~all(tempFH==0, 2); % Find the rows without zero entries using logical indexing
    tempFH = tempFH(idxFH,:); % Select the rows without zero entries using logical indexing
    pktrfboth5{j,1} = tempFH; % Assign the modified array back to the j-th cell of pktrfboth2
end

for i = 1:size(pktrfboth5, 1)
    for j = 1:size(pktrfboth5{i, 1},1)
        pktrfboth5{i, 1}(j, 21)= pktrfboth5{i, 1}(j, 3)+ pktrfboth5{i, 1}(j, 7);  % sum of widths of peak and trough of cuffed arm
        pktrfboth5{i, 1}(j, 22)= pktrfboth5{i, 1}(j, 21)==0; %(logical for zero pulses)
        pktrfboth5{i, 1}(j, 23)= pktrfboth5{i, 1}(j, 2)- pktrfboth5{i, 1}(j, 6);%time to peak from trough for test
        
        pktrfboth5{i, 1}(j, 24)= pktrfboth5{i, 1}(j, 11)+pktrfboth5{i, 1}(j, 15);%  sum of widths of peak and trough of ref arm
        pktrfboth5{i, 1}(j, 25)= pktrfboth5{i, 1}(j, 10)- pktrfboth5{i, 1}(j, 14);%time to peak from trough for ref
        pktrfboth5{i, 1}(j, 26)= 1.5*(pktrfboth5{i, 1}(j, 25))- pktrfboth5{i, 1}(j, 23); % Difference between 1.5 times time to peak of ref and time to peak of test
        
        pktrfboth5{i, 3} = sum(pktrfboth5{i, 1}(:, 22));%Number of zero pulses- repeat
        pktrfboth5{i, 4} = max(pktrfboth5{i, 1}(:, 21)); %max widthsum test
        
        pktrfboth5{i, 5} = min(nonzeros(pktrfboth5{i, 1}(:, 17)));%min test amplitude
        pktrfboth5{i, 6} = max(pktrfboth5{i, 1}(:, 17));%max  test amplitude
        pktrfboth5{i, 7} = mean(nonzeros(pktrfboth5{i, 1}(:, 17)));% mean test amplitude
        
        pktrfboth5{i, 8} = max(nonzeros(pktrfboth5{i, 1}(:, 24)));% max widthsum ref
        pktrfboth5{i, 9} = max(nonzeros(pktrfboth5{i, 1}(:, 19)));% max ratio
        
        pktrfboth5{i, 10} = (size(pktrfboth5{i,1},1)- pktrfboth5{i,3}); % pulse number
        pktrfboth5{i, 11} =  pktrfboth5{i, 1}(end, 10)- pktrfboth5{i, 1}(1, 10); %Time of last peak minus time of first peak gives duration of plateau
        averagePlateauPeriod = mean(cell2mat(pktrfboth5(:, 11)));
        pktrfboth5{i, 12} = round((((pktrfboth5{i, 10}/ pktrfboth5{i, 11}*10)))); %number of pulses per 10 seconds
        averageTestPulseNumber = round(mean(cell2mat(pktrfboth5(:, 12)))); %average Number of test pulses per 10 seconds
    end
end

for i = 1:size(pktrfboth5, 1)
    for j = 1:size(pktrfboth5{i, 1},1)
        pktrfboth5{i, 1}(j, 26)= 1.5*(pktrfboth5{i, 1}(j, 25))- pktrfboth5{i, 1}(j, 23); % Difference between 1.5 times time to peak of ref and time to peak of test
        pktrfboth5{i, 1}(j, 27)= pktrfboth5{i, 1}(j, 24)/pktrfboth5{i, 1}(j, 21); %ratio of sum of widths of ref to test (ref on numerator)
        pktrfboth5{i, 1}(j, 28)=1.1*(pktrfboth5{i, 1}(j, 24))- pktrfboth5{i, 1}(j, 21);%added by bowya
        pktrfboth5{i, 15}=mean(pktrfboth5{i, 1}(~isinf(pktrfboth5{i, 1}(:, 27)), 27) - 2 * std(pktrfboth5{i, 1}(~isinf(pktrfboth5{i, 1}(:, 27)), 27))); %added by bowya
    end
end

%%
% Collect the amplitudes and ratios in an array called ratios

ratios_a = [];

for i = 1:size(pktrfboth5, 1)
    for k = 1:size(pktrfboth5{i, 1},1)
        ratios_a{i,1}(k,1:4) = pktrfboth5{i,1}(k,17:20);
    end
end

for i = 1: size(ratios_a,1) % This loop was added on 20Mar2025 to handle the problem of empty cells in ratios
    ratios_a_logical(i,1) = ~isempty(ratios_a{i,1});
end
ratios = ratios_a(ratios_a_logical, :);

% In ratios, if there is a 0 in ref amplitude (ie, column 2) then some
% values are turned out as infinity and this creates problems. Therefore
% delete rows with 0 in column 2

% Remove rows from ratios where the second column is equal to 0
ratios = cellfun(@(x) x(x(:,2)~=0,:), ratios, 'UniformOutput', false);

% @(x) x(x(:,2)~=0,:)
% is an anonymous function (lambda function) defined using @(x).
% This anonymous function takes a single input x, which is expected to be a matrix.
% It filters the rows of the input matrix x based on the condition x(:,2)~=0,
% which means it keeps only the rows where the second column (column 2) is not equal to zero.
%
% 'UniformOutput', false is an option passed to cellfun.
% It specifies that the output should not be coerced into a uniform data type.
% Since the result of the anonymous function is a matrix,
% setting 'UniformOutput', false ensures that the output remains a cell array,
% with each element corresponding to the result of applying the function to each element
% of the input cell array.

% Remove the first row in every cell
for i = 1:numel(ratios)
    if size( ratios{i},1)>2 % condition added on 20Mar2025
        ratios{i} = ratios{i}(2:end, :);
    end
end

%%
hcp =cell {1,2};

ratiomat  = cell2mat(ratios);
eachratiomat1 = cat(1,ratios{:,1}); % Both eachratiomat and ratiomat are identical, and redundant
eachratiomat = eachratiomat1;

%figure (9)
%scatter (eachratiomat(:,4), eachratiomat(:,3));
%legend ('PPG ratios');
%xticks([0: 10: 1000])
%set(gca,'XMinorTick','on','YMinorTick','on')
%grid on

%xlabel ('cuff pressure mmHg');
%ylabel ('PPG ratio');
%title (expt_id);

%saveas(gcf,[expt_id 'fig9.fig']);

%%
%Get the mean of ratios for each cuff pressure
for i = 1:size(ratios,1)
    meanratios{i,1} = mean(ratios{i}(:,4));%cuff pressure
    meanratios{i,2} = mean(ratios{i}(:,3));%ratios
end

meanratiomat0 = cell2mat(meanratios);
meanratiomat = meanratiomat0;

% added on 12 Mar2025.
for i = 1:size(meanratiomat,1)
    if meanratiomat(i,1)>= HrmsTrue %&& meanratiomat(i,2)>0% 28April2025
        meanratiomat(i,3)=  meanratiomat(i,1)- HrmsTrue;
    else
        meanratiomat(i,3)=0;
    end
end

meanratiomat(:,4)= meanratiomat(:,2); %keeping column 2 intact in col4. Col2 will be corrected for the least cuff pressure, if the values keep rising
meanratiomat(2:end,5)= diff(meanratiomat(:,4));

meanratiomat(:,6)= meanratiomat(:,1)-HrmsTrue;  % Though we have decided on HrmsTrue in Jun 2025, this code considers max and min of Hrms array. Leave it. Dont change

[~, rI_meanratiomatcol6] = min(abs(meanratiomat(:,6)));

if meanratiomat(rI_meanratiomatcol6,2)>0
    ratiomean_atHrms = meanratiomat(rI_meanratiomatcol6,2);
    rImeanratiomat_1 = rI_meanratiomatcol6;
end

for i = 1: size(meanratiomat,1)
    meanratiomat_logical(i,1) = meanratiomat(i,1) < HrmsTrue;
    meanratiomat_logical(i,2) = meanratiomat(i,5)<0;
    meanratiomat_logical_1(i,1)= meanratiomat_logical(i,1)==1&& meanratiomat_logical(i,2)==1;
end

% check if the PPGs are all rising till lcp: Fit the PPG ampls below Hrms
% to a straight line and check the slope of the line

meanratiomat_x_belowHrms = meanratiomat(rImeanratiomat_1:end,1);
meanratiomat_y_belowHrms = meanratiomat(rImeanratiomat_1:end,4);

if size(meanratiomat_x_belowHrms,1)>2
    meanratiomat_x_belowHrms_1 = meanratiomat(rImeanratiomat_1:end-1,1);
    meanratiomat_y_belowHrms_1 = meanratiomat(rImeanratiomat_1:end-1,4);
else
    meanratiomat_x_belowHrms_1 = meanratiomat_x_belowHrms;
    meanratiomat_y_belowHrms_1 = meanratiomat_y_belowHrms;
end

[meanratiomat_x_belowHrms, meanratiomat_y_belowHrms] = prepareCurveData(meanratiomat_x_belowHrms, meanratiomat_y_belowHrms );

fit_meanratio_x_belowHrms = fittype( 'm*x+c', 'independent', 'x', 'dependent', 'y' );
opts_meanratiomat_x_belowHrms = fitoptions( 'Method', 'NonlinearLeastSquares' );
opts_meanratiomat_x_belowHrms.Algorithm = 'Levenberg-Marquardt';
opts_meanratiomat_x_belowHrms.Display = 'Off';
opts_meanratiomat_x_belowHrms.Robust = 'Bisquare';
opts_meanratiomat_x_belowHrms.StartPoint = [10 10];

try
    [fitresult{5}, gof(5)] = fit( meanratiomat_x_belowHrms, meanratiomat_y_belowHrms, fit_meanratio_x_belowHrms, opts_meanratiomat_x_belowHrms);
    coefficients_meanratiomat_x_belowHrms= coeffvalues(fitresult{5});
    fit_meanratiomat_x_belowHrms = meanratiomat(end, 1):1:meanratiomat(rImeanratiomat_1, 1);
    fit_meanratiomat_y_belowHrms = (fitresult{5}(meanratiomat(end, 1):1:meanratiomat(rImeanratiomat_1, 1)));
    
    CATCH ME
end

[meanratiomat_x_belowHrms_1, meanratiomat_y_belowHrms_1] = prepareCurveData(meanratiomat_x_belowHrms_1, meanratiomat_y_belowHrms_1);

fit_meanratio_x_belowHrms_1 = fittype( 'm*x+c', 'independent', 'x', 'dependent', 'y' );
opts_meanratiomat_x_belowHrms_1 = fitoptions( 'Method', 'NonlinearLeastSquares' );
opts_meanratiomat_x_belowHrms_1.Algorithm = 'Levenberg-Marquardt';
opts_meanratiomat_x_belowHrms_1.Display = 'Off';
opts_meanratiomat_x_belowHrms_1.Robust = 'Bisquare';
opts_meanratiomat_x_belowHrms_1.StartPoint = [10 10];

try
    [fitresult{11}, gof(11)] = fit(meanratiomat_x_belowHrms_1, meanratiomat_y_belowHrms_1, fit_meanratio_x_belowHrms_1, opts_meanratiomat_x_belowHrms_1);
    coefficients_meanratiomat_x_belowHrms_1 = coeffvalues(fitresult{11});
    fit_meanratiomat_x_belowHrms_1 = meanratiomat(end-1, 1):1:meanratiomat(rImeanratiomat_1, 1);
    fit_meanratiomat_y_belowHrms_1 = (fitresult{11}(meanratiomat(end-1, 1):1:meanratiomat(rImeanratiomat_1, 1)));
    CATCH ME
end

%figure (1001)
%plot (fit_meanratiomat_x_belowHrms, fit_meanratiomat_y_belowHrms);
%hold on
%plot (meanratiomat_x_belowHrms, meanratiomat_y_belowHrms);
%plot (fit_meanratiomat_x_belowHrms_1, fit_meanratiomat_y_belowHrms_1);
%plot (meanratiomat_x_belowHrms_1, meanratiomat_y_belowHrms_1);

% Only if there are no dips or if the slope of line fitted to PPGs is negative, and more negative than quarter of the PPG amp set the last PPG value to that of Hrms
if sum(meanratiomat_logical_1(:,1))< 1 || abs(coefficients_meanratiomat_x_belowHrms(1,2))> abs(coefficients_meanratiomat_x_belowHrms_1(1,2))
    if meanratiomat(end,4)> (ratiomean_atHrms +  meanratiomat(end,4))/2 && meanratiomat(end-1,4)> (ratiomean_atHrms +  meanratiomat(end,4))/2  %+(ratiomean_atHrms/3)%&& meanratiomat(end-1,2)> ratiomean_atHrms+(ratiomean_atHrms/3)% changing PPG amp only for last row
        meanratiomat(end,2)= (ratiomean_atHrms +  meanratiomat(end,4))/2;%+(ratiomean_atHrms/3);
    elseif meanratiomat(end,4)> (ratiomean_atHrms +  meanratiomat(end-1,4))/2 && meanratiomat(end-1,4)> (ratiomean_atHrms +  meanratiomat(end-1,4))/2
        meanratiomat(end,2)= (ratiomean_atHrms +  meanratiomat(end-1,4))/2;
    else
        meanratiomat(end,2)=ratiomean_atHrms;
    end
end

%%
%figure (10)
%scatter (meanratiomat(:,1), meanratiomat(:,2));
%xlabel ('cuff pressure mmHg');
%ylabel ('mean PPG ratio');
%legend ('mean PPG ratio');
%title (expt_id);
%xticks([0: 10: 1000])
%set(gca,'XMinorTick','on','YMinorTick','on')
%grid on
%grid on

%saveas(gcf,[expt_id 'fig10.fig']);

%% for taking min and max ratio
for i = 1:size(ratios,1)
    ratios {i,2} = mean(ratios{i,1}(:,4)); % cuff pressure
end

for j = 1:size(ratios,1)
    minratiomat0(j,1) = ratios{j,2};%cuff pressure
    minratiomat0(j,2) = min(ratios{j,1}(:,3));% minimum ratio
    maxratiomat0(j,1) = ratios{j,2};%cuff pressure
    maxratiomat0(j,2) = max(ratios{j,1}(:,3));%maximum ratio
end

%On 12 Mar2025
%Trying to correct very high PPG amplitudes at low cuff pressures - setting
%it to amplitudes at Hpoint. This is essential to improve fits

minratiomat = minratiomat0;
maxratiomat = maxratiomat0;

for i = 1:size(minratiomat,1)
    if minratiomat(i,1)>= HrmsTrue %&& minratiomat(i,2)>0% 28April2025
        minratiomat(i,3)=  minratiomat(i,1)- HrmsTrue;
    else
        minratiomat(i,3)=0;
    end
end

minratiomat(:,4)= minratiomat(:,2); %keeping column 2 intact in col4. Col2 will be corrected for the least cuff pressure, if the values keep rising
minratiomat(2:end,5)= diff(minratiomat(:,4));

minratiomat(:,6)= minratiomat(:,1)- HrmsTrue;

[~, rI_minratiomatcol6] = min(abs(minratiomat(:,6)));

if minratiomat(rI_minratiomatcol6,2)>0
    ratiomin_atHrms = minratiomat(rI_minratiomatcol6,2);
    rIminratiomat_1 = rI_minratiomatcol6;
else
    ratiomin_atHrms = minratiomat(rI_minratiomatcol6+1,2);
    rIminratiomat_1 = rI_minratiomatcol6+1;
end

for i = 1: size(minratiomat,1)
    minratiomat_logical(i,1) = minratiomat(i,1) < max(Hpointrms_array);
    minratiomat_logical(i,2) = minratiomat(i,5)<0;
    minratiomat_logical_1(i,1)= minratiomat_logical(i,1)==1&& minratiomat_logical(i,2)==1;
end

% check if the PPGs are all rising till lcp: Fit the PPG ampls below Hrms
% to a straight line and check the slope of the line

minratiomat_x_belowHrms = minratiomat(rIminratiomat_1:end,1);
minratiomat_y_belowHrms = minratiomat(rIminratiomat_1:end,4);

if size(minratiomat_x_belowHrms,1)>2
    minratiomat_x_belowHrms_1 = minratiomat(rIminratiomat_1:end-1,1);
    minratiomat_y_belowHrms_1 = minratiomat(rIminratiomat_1:end-1,4);
else
    minratiomat_x_belowHrms_1 = minratiomat_x_belowHrms;
    minratiomat_y_belowHrms_1 = minratiomat_y_belowHrms;
end

[minratiomat_x_belowHrms, minratiomat_y_belowHrms] = prepareCurveData(minratiomat_x_belowHrms, minratiomat_y_belowHrms );

fit_minratio_x_belowHrms = fittype( 'm*x+c', 'independent', 'x', 'dependent', 'y' );
opts_minratiomat_x_belowHrms = fitoptions( 'Method', 'NonlinearLeastSquares' );
opts_minratiomat_x_belowHrms.Algorithm = 'Levenberg-Marquardt';
opts_minratiomat_x_belowHrms.Display = 'Off';
opts_minratiomat_x_belowHrms.Robust = 'Bisquare';
opts_minratiomat_x_belowHrms.StartPoint = [10 10];

try
    [fitresult{5}, gof(5)] = fit( minratiomat_x_belowHrms, minratiomat_y_belowHrms, fit_minratio_x_belowHrms, opts_minratiomat_x_belowHrms);
    coefficients_minratiomat_x_belowHrms= coeffvalues(fitresult{5});
    fit_minratiomat_x_belowHrms = minratiomat(end, 1):1:minratiomat(rIminratiomat_1, 1);
    fit_minratiomat_y_belowHrms = (fitresult{5}(minratiomat(end, 1):1:minratiomat(rIminratiomat_1, 1)));
    
    CATCH ME
end

[minratiomat_x_belowHrms_1, minratiomat_y_belowHrms_1] = prepareCurveData(minratiomat_x_belowHrms_1, minratiomat_y_belowHrms_1);

fit_minratio_x_belowHrms_1 = fittype( 'm*x+c', 'independent', 'x', 'dependent', 'y' );
opts_minratiomat_x_belowHrms_1 = fitoptions( 'Method', 'NonlinearLeastSquares' );
opts_minratiomat_x_belowHrms_1.Algorithm = 'Levenberg-Marquardt';
opts_minratiomat_x_belowHrms_1.Display = 'Off';
opts_minratiomat_x_belowHrms_1.Robust = 'Bisquare';
opts_minratiomat_x_belowHrms_1.StartPoint = [10 10];

try
    [fitresult{11}, gof(11)] = fit(minratiomat_x_belowHrms_1, minratiomat_y_belowHrms_1, fit_minratio_x_belowHrms_1, opts_minratiomat_x_belowHrms_1);
    coefficients_minratiomat_x_belowHrms_1 = coeffvalues(fitresult{11});
    fit_minratiomat_x_belowHrms_1 = minratiomat(end-1, 1):1:minratiomat(rIminratiomat_1, 1);
    fit_minratiomat_y_belowHrms_1 = (fitresult{11}(minratiomat(end-1, 1):1:minratiomat(rIminratiomat_1, 1)));
    CATCH ME
end

%figure (1001)
%plot (fit_minratiomat_x_belowHrms, fit_minratiomat_y_belowHrms);
%hold on
%plot (minratiomat_x_belowHrms, minratiomat_y_belowHrms);
%plot (fit_minratiomat_x_belowHrms_1, fit_minratiomat_y_belowHrms_1);
%plot (minratiomat_x_belowHrms_1, minratiomat_y_belowHrms_1);

% Only if there are no dips or if the slope of line fitted to PPGs is negative, and more negative than quarter of the PPG amp set the last PPG value to that of Hrms
if sum(minratiomat_logical_1(:,1))< 1 || abs(coefficients_minratiomat_x_belowHrms(1,2))> abs(coefficients_minratiomat_x_belowHrms_1(1,2))
    if minratiomat(end,4)> (ratiomin_atHrms +  minratiomat(end,4))/2 && minratiomat(end-1,4)> (ratiomin_atHrms +  minratiomat(end,4))/2  %+(ratiomax_atHrms/3)%&& maxratiomat(end-1,2)> ratiomax_atHrms+(ratiomax_atHrms/3)% changing PPG amp only for last row
        minratiomat(end,2)= (ratiomin_atHrms +  minratiomat(end,4))/2;%+(ratiomax_atHrms/3);
    elseif minratiomat(end,4)> (ratiomin_atHrms +  minratiomat(end-1,4))/2 && minratiomat(end-1,4)> (ratiomin_atHrms +  minratiomat(end-1,4))/2
        minratiomat(end,2)= (ratiomin_atHrms +  minratiomat(end-1,4))/2;
    else
        minratiomat(end,2)=ratiomin_atHrms;
    end
end

%%
for i = 1:size(maxratiomat,1)
    if maxratiomat(i,1)>= max(Hpointrms_array) %&& maxratiomat(i,2)>0% 28April2025
        maxratiomat(i,3)=  maxratiomat(i,1)- max(Hpointrms_array);
    else
        maxratiomat(i,3)=0;
    end
end

maxratiomat(:,4)= maxratiomat(:,2); %keeping column 2 intact in col4. Col2 will be corrected for the least cuff pressure, if the values keep rising
maxratiomat(2:end,5)= diff(maxratiomat(:,4));

maxratiomat(:,6)= maxratiomat(:,1)- HrmsTrue;

[~, rI_maxratiomatcol6] = min(abs(maxratiomat(:,6)));

if maxratiomat(rI_maxratiomatcol6,2)>0
    ratiomax_atHrms = maxratiomat(rI_maxratiomatcol6,2);
    rImaxratiomat_1 = rI_maxratiomatcol6;
end

for i = 1: size(maxratiomat,1)
    maxratiomat_logical(i,1) = maxratiomat(i,1) < HrmsTrue;
    maxratiomat_logical(i,2) = maxratiomat(i,5)<0;
    maxratiomat_logical_1(i,1)= maxratiomat_logical(i,1)==1&& maxratiomat_logical(i,2)==1;
end

% check if the PPGs are all rising till lcp: Fit the PPG ampls below Hrms
% to a straight line and check the slope of the line

maxratiomat_x_belowHrms = maxratiomat(rImaxratiomat_1:end,1);
maxratiomat_y_belowHrms = maxratiomat(rImaxratiomat_1:end,4);

if size(maxratiomat_x_belowHrms,1)>2
    maxratiomat_x_belowHrms_1 = maxratiomat(rImaxratiomat_1:end-1,1);
    maxratiomat_y_belowHrms_1 = maxratiomat(rImaxratiomat_1:end-1,4);
else
    maxratiomat_x_belowHrms_1 = maxratiomat_x_belowHrms;
    maxratiomat_y_belowHrms_1 = maxratiomat_y_belowHrms;
end

[maxratiomat_x_belowHrms, maxratiomat_y_belowHrms] = prepareCurveData(maxratiomat_x_belowHrms, maxratiomat_y_belowHrms );

fit_maxratio_x_belowHrms = fittype( 'm*x+c', 'independent', 'x', 'dependent', 'y' );
opts_maxratiomat_x_belowHrms = fitoptions( 'Method', 'NonlinearLeastSquares' );
opts_maxratiomat_x_belowHrms.Algorithm = 'Levenberg-Marquardt';
opts_maxratiomat_x_belowHrms.Display = 'Off';
opts_maxratiomat_x_belowHrms.Robust = 'Bisquare';
opts_maxratiomat_x_belowHrms.StartPoint = [10 10];

try
    [fitresult{5}, gof(5)] = fit( maxratiomat_x_belowHrms, maxratiomat_y_belowHrms, fit_maxratio_x_belowHrms, opts_maxratiomat_x_belowHrms);
    coefficients_maxratiomat_x_belowHrms= coeffvalues(fitresult{5});
    fit_maxratiomat_x_belowHrms = maxratiomat(end, 1):1:maxratiomat(rImaxratiomat_1, 1);
    fit_maxratiomat_y_belowHrms = (fitresult{5}(maxratiomat(end, 1):1:maxratiomat(rImaxratiomat_1, 1)));
    CATCH ME
end

[maxratiomat_x_belowHrms_1, maxratiomat_y_belowHrms_1] = prepareCurveData(maxratiomat_x_belowHrms_1, maxratiomat_y_belowHrms_1);

fit_maxnratio_x_belowHrms_1 = fittype( 'm*x+c', 'independent', 'x', 'dependent', 'y' );
opts_maxratiomat_x_belowHrms_1 = fitoptions( 'Method', 'NonlinearLeastSquares' );
opts_maxratiomat_x_belowHrms_1.Algorithm = 'Levenberg-Marquardt';
opts_maxratiomat_x_belowHrms_1.Display = 'Off';
opts_maxratiomat_x_belowHrms_1.Robust = 'Bisquare';
opts_maxratiomat_x_belowHrms_1.StartPoint = [10 10];

try
    [fitresult{11}, gof(11)] = fit(maxratiomat_x_belowHrms_1, maxratiomat_y_belowHrms_1, fit_maxnratio_x_belowHrms_1, opts_maxratiomat_x_belowHrms_1);
    coefficients_maxratiomat_x_belowHrms_1 = coeffvalues(fitresult{11});
    fit_maxratiomat_x_belowHrms_1 = maxratiomat(end-1, 1):1:maxratiomat(rImaxratiomat_1, 1);
    fit_maxratiomat_y_belowHrms_1 = (fitresult{11}(maxratiomat(end-1, 1):1:maxratiomat(rImaxratiomat_1, 1)));
    CATCH ME
end

%figure (1001)
%plot (fit_maxratiomat_x_belowHrms, fit_maxratiomat_y_belowHrms);
%hold on
%plot (maxratiomat_x_belowHrms, maxratiomat_y_belowHrms);
%plot (fit_maxratiomat_x_belowHrms_1, fit_maxratiomat_y_belowHrms_1);
%plot (maxratiomat_x_belowHrms_1, maxratiomat_y_belowHrms_1);

% Only if there are no dips or if the slope of line fitted to PPGs is negative, and more negative than quarter of the PPG amp set the last PPG value to that of Hrms
if sum(maxratiomat_logical_1(:,1))< 1 || abs(coefficients_maxratiomat_x_belowHrms(1,2))> abs(coefficients_maxratiomat_x_belowHrms_1(1,2))
    if maxratiomat(end,4)> (ratiomax_atHrms +  maxratiomat(end,4))/2 && maxratiomat(end-1,4)> (ratiomax_atHrms +  maxratiomat(end,4))/2  %+(ratiomax_atHrms/3)%&& maxratiomat(end-1,2)> ratiomax_atHrms+(ratiomax_atHrms/3)% changing PPG amp only for last row
        maxratiomat(end,2)= (ratiomax_atHrms +  maxratiomat(end,4))/2;%+(ratiomax_atHrms/3);
    elseif maxratiomat(end,4)> (ratiomax_atHrms +  maxratiomat(end-1,4))/2 && maxratiomat(end-1,4)> (ratiomax_atHrms +  maxratiomat(end-1,4))/2
        maxratiomat(end,2)= (ratiomax_atHrms +  maxratiomat(end-1,4))/2;
    else
        maxratiomat(end,2)=ratiomax_atHrms;
    end
end

%%
minmaxratiomat = cat (2, minratiomat, maxratiomat);

%%
% For getting lower and higher systolic pressures from min and max ratios

minratiomat(:,3)= minratiomat (:,2)==0;  %find all rows where the column 2 entry is zero
select_lowsys = minratiomat(:,3)==1; %
select_lowsys1 = minratiomat(select_lowsys, :);

LSP1 = round (min((select_lowsys1(:,1))));
select_lowsys2 = minratiomat(size(select_lowsys1,1)+1:end, :);

%LSP2 = round(select_lowsys2(1,1)); %In 18091101, there are three plateaus
%at the same pressure. LSP2 turns out to be higher than LSP1 Therefore do
%the following

for i = 1: size(select_lowsys2,1)
    if select_lowsys2(i,1)< LSP1
        LSP2 = select_lowsys2(i,1);
        break
    end
end

LSP = round((LSP1+LSP2)/2);

maxratiomat(:,3)= maxratiomat(:,2)==0;%find all rows where the column 2 entry is zero
%A false positive may create problems with HSP here. Be careful

for i = 1:size(maxratiomat,1)-1
    maxratiomat (end, 4)= NaN;
    maxratiomat (i,4)= maxratiomat(i+1,2)>0;
end
select_highsysLogical = maxratiomat(:,3)==1 & maxratiomat(:,4)==1; % Find rows with 0 pulses, but where the next row has pulses

select_highsysLogical_2 = maxratiomat(select_highsysLogical, :);
HSP1 = round (max(select_highsysLogical_2 (:,1)));

for i = 2:size(maxratiomat,1)
    maxratiomat(1, 5)= NaN;
    maxratiomat(i,5)= maxratiomat(i,3)- maxratiomat(i-1, 3)<0; % Find the rows with pulses, but above which there is no pulse
end

select_highsysLogical_2 = maxratiomat(:,5)==1;

select_highsys_2 = maxratiomat(select_highsysLogical_2, :);
HSP2 = round (max(select_highsys_2 (:,1)));
HSP = round((HSP1+HSP2)/2);

%%
[x1Data, y1Data] = prepareCurveData(meanratiomat(:,1), meanratiomat(:,2)); %Redoing these
[x4Data, y4Data] = prepareCurveData(minratiomat(:,1), minratiomat(:,2));
[x5Data, y5Data] = prepareCurveData(maxratiomat(:,1), maxratiomat(:,2));

%%
%%Smoothing spline fits for getting envelopes of ratios
% Set up fittype and options.
ft_minratio = fittype( 'smoothingspline' );
opts_minratio = fitoptions( 'Method', 'SmoothingSpline' );
opts_minratio.SmoothingParam = 0.999999023293969;

% Fit model to data.
[fitresult{73}, gof(73)] = fit( minratiomat(:,1), minratiomat(:,2), ft_minratio, opts_minratio );

% Set up fittype and options.
ft_maxratio = fittype( 'smoothingspline' );
opts_maxratio = fitoptions( 'Method', 'SmoothingSpline' );
opts_maxratio.SmoothingParam = 0.9999999;

% Fit model to data.
[fitresult{74}, gof(74)] = fit( maxratiomat(:,1), maxratiomat(:,2), ft_maxratio, opts_maxratio );

% Set up fittype and options.
ft_meanratio = fittype( 'smoothingspline' );
opts_meanratio = fitoptions( 'Method', 'SmoothingSpline' );
opts_meanratio.SmoothingParam = 0.9999999;

% Fit model to data.
[fitresult{75}, gof(75)] = fit( meanratiomat(:,1), meanratiomat(:,2), ft_meanratio, opts_meanratio );

%%
ysmspFitMinAfterHpointrms =(fitresult{73}(HrmsTrue:1:hcp+20));%get the y values of smsp segment after H point upto Xcrossing
xtsmspFitMinAfterHpointrms =  (HrmsTrue : 1:hcp+20);% x values of smsp segment after H point
xsmspFitMinAfterHpointrms = xtsmspFitMinAfterHpointrms';%transpose the array
smspFitMinAfterHpointrms = [xsmspFitMinAfterHpointrms, ysmspFitMinAfterHpointrms]; % collect x and y values in one array

ysmspFitMaxAfterHpointrms =(fitresult{74}(HrmsTrue : 1: hcp+20));%get the y values of smsp segment after H point upto Xcrossing
xtsmspFitMaxAfterHpointrms =  (HrmsTrue : 1:hcp+20);% x values of smsp segment after H point
xsmspFitMaxAfterHpointrms = xtsmspFitMaxAfterHpointrms';%transpose the array
smspFitMaxAfterHpointrms = [xsmspFitMaxAfterHpointrms, ysmspFitMaxAfterHpointrms]; % collect x and y values in one array

ysmspFitMeanAfterHpointrms =(fitresult{75}(HrmsTrue : 1: hcp+20));%get the y values of smsp segment after H point upto Xcrossing
xtsmspFitMeanAfterHpointrms =  (HrmsTrue : 1:hcp+20);% x values of smsp segment after H point
xsmspFitMeanAfterHpointrms = xtsmspFitMeanAfterHpointrms';%transpose the array
smspFitMeanAfterHpointrms = [xsmspFitMeanAfterHpointrms, ysmspFitMeanAfterHpointrms]; % collect x and y values in one array

%%    %to get te X crossing of the smspfit of ratios
%Find row index of cuff pressure closest to Xcrossingmin
if any(ysmspFitMinAfterHpointrms<0)
    
    for i = 2: size(smspFitMinAfterHpointrms,1)
        if smspFitMinAfterHpointrms(i-1, 2)>0 && smspFitMinAfterHpointrms(i, 2)<0
            Xcrossingsmspmin_0 = (smspFitMinAfterHpointrms(i,1));
            break;
        end
    end
    
else
    Xaxisrms_for = min(ysmspFitMinAfterHpointrms);
    smspFitMinAfterHpointrms(:,3) = smspFitMinAfterHpointrms(:,2)- Xaxisrms_for;
    [~, rI_smspminratios_1] = min(smspFitMinAfterHpointrms (:,3));
    Xcrossingsmspmin_0 = smspFitMinAfterHpointrms(rI_smspminratios_1, 1);
end

%Find row index of cuff pressure closest to Xcrossingmax
if any(ysmspFitMaxAfterHpointrms<0)
    
    for i = 2: size(smspFitMaxAfterHpointrms,1)
        if smspFitMaxAfterHpointrms(i-1, 2)>0 && smspFitMaxAfterHpointrms(i, 2)<0
            Xcrossingsmspmax_0 = (smspFitMaxAfterHpointrms(i,1));
            break;
        end
    end
    
else
    Xaxisrms_for = min(ysmspFitMaxAfterHpointrms);
    smspFitMaxAfterHpointrms(:,3) = smspFitMaxAfterHpointrms(:,2)- Xaxisrms_for;
    [~, rI_smspmaxratios_1] = min(smspFitMaxAfterHpointrms (:,3));
    Xcrossingsmspmax_0 = smspFitMaxAfterHpointrms(rI_smspmaxratios_1, 1);
end

if any(ysmspFitMeanAfterHpointrms<0)
    
    for i = 2: size(smspFitMeanAfterHpointrms,1)
        if smspFitMeanAfterHpointrms(i-1, 2)>0 && smspFitMeanAfterHpointrms(i, 2)<0
            Xcrossingsmspmean_0 = (smspFitMeanAfterHpointrms(i,1));
            break;
        end
    end
    
else
    Xaxisrms_for = min(ysmspFitMeanAfterHpointrms);
    smspFitMeanAfterHpointrms(:,3) = smspFitMeanAfterHpointrms(:,2)- Xaxisrms_for;
    [~, rI_smspmeanratios_1] = min(smspFitMeanAfterHpointrms (:,3));
    Xcrossingsmspmean_0 = smspFitMeanAfterHpointrms(rI_smspmeanratios_1, 1);
end

% Xcrossingsmspmean_0 was introduced on 17July to consider the possibility
% of a trough in smsp fit, close to zero, but not crossing zero, and
% therefore omitted. This can come up due to false positives or high noise
XcrossingsmspArray = [Xcrossingsmspmin_0, Xcrossingsmspmean_0, Xcrossingsmspmax_0];
XcrossingsmspArray(2,1)= XcrossingsmspArray(1,2)-XcrossingsmspArray(1,1);
XcrossingsmspArray(2,3)= XcrossingsmspArray(1,3)-XcrossingsmspArray(1,2);
XcrossingsmspArray (2,2)= XcrossingsmspArray(1,2)-  mean([XcrossingsmspArray(1,1), XcrossingsmspArray(1,3)]);
XcrossingsmspArray (3,1)= PSysDiaMay2025(1,1);
XcrossingsmspArray (3,2)= NaN;
XcrossingsmspArray (3,3)= PSysDiaMay2025(1,2);
XcrossingsmspArray (4,1)= XcrossingsmspArray(3,1)- XcrossingsmspArray(1,1);
XcrossingsmspArray (4,2)= NaN;
XcrossingsmspArray (4,3)= XcrossingsmspArray(3,3)- XcrossingsmspArray(1,3);

%pointers to false positives in high cuff pressures

XcrossingsmspArrayLogical(1,1)= XcrossingsmspArray(1,3)- XcrossingsmspArray(1,1)>30;
XcrossingsmspArrayLogical(1,2)=XcrossingsmspArray(2,2) < -10;
XcrossingsmspArrayLogical(1,3)= XcrossingsmspArray(4,1)>=0 && XcrossingsmspArray(4,3)< -5;
XcrossingsmspArrayLogical(1,4)= XcrossingsmspArray(1,3)- XcrossingsmspArray(1,1)> 1.5*(PSysDiaMay2025(1,2)- PSysDiaMay2025(1,1));

if sum(XcrossingsmspArrayLogical(1, :))>2 || sum(XcrossingsmspArrayLogical(1, 3:4))==2
    % correct Xcrossingsmspmax_0
    Xcrossingsmspmax_0 = XcrossingsmspArray(3,3)- XcrossingsmspArray (4,1);
end
%If there is only one zero pulse in the cuff pressure near which the X
%crossing occurs, then take the average of that and the next higher cuff pressure
%Set Xcrossing to the higher value. This minimizes the errors in Csyslow

for i = 1:size(ratios,1)
    pktrfboth4{i,13}= pktrfboth4 {i,2}- Xcrossingsmspmin_0; %Find the differences of cuff pressure from Xcrossing.
    pktrfboth4{i,14}= pktrfboth4 {i,2}- Xcrossingsmspmax_0; %Find the differences of cuff pressure from Xcrossing.
end

[~, rowIndexsysDiffmin] = min(abs(cell2mat((pktrfboth4(:,13)))));%Find the lowest difference
[~, rowIndexsysDiffmax] = min(abs(cell2mat((pktrfboth4(:,14)))));%Find the lowest difference


rowsToSelect_min = pktrfboth4{rowIndexsysDiffmin,1}(:,:);%Select that row; find the zeros, and do a logical on column 5
rowsToSelect_max = pktrfboth4{rowIndexsysDiffmax,1}(:,:);%Select that row; find the zeros, and do a logical on column 5

if sum(rowsToSelect_min(:,22))<2 % If there are not even two absent pulses,
    Xcrossingsmspmin = round((cell2mat(ratios(rowIndexsysDiffmin-1,2))+cell2mat(ratios(rowIndexsysDiffmin,2)))/2);
else %if there are 2 or more absent pulses
    Xcrossingsmspmin = Xcrossingsmspmin_0;
end

Xcrossingsmspmax = cell2mat(ratios(rowIndexsysDiffmax,2));

%%
XcrossingMinArray = [Xcrossingsmspmin, Xcrossingsmspmin_0, XcrossingsmspMin00, LSP1];
XcrossingMaxArray = [Xcrossingsmspmax, Xcrossingsmspmax_0, XcrossingsmspMax00, HSP1];

%%
%figure (600)
%hold on

%plot(x2Data, y2Data, 'o', 'MarkerSize', 3, 'color', 'c', 'LineStyle', ':'); %rms
%plot(x5Data, y5Data, 'o', 'MarkerSize', 4, 'color', 'r', 'LineStyle', ':'); % maxratios
%plot(x4Data, y4Data, 'o', 'MarkerSize', 3, 'color', 'b', 'LineStyle', ':'); %minratios
%plot (x1Data,y1Data,'o', 'MarkerSize', 4, 'color', 'k','LineStyle', ':');  % meanratios
%grid on
%hold off

%xlabel('cuff pressure');
%ylabel('PPG rms ratios or amplitude ratios');

%title (expt_id);

%xticks([0: 10: 1000])
%set(gca,'XMinorTick','on','YMinorTick','on')
%grid on

%legend ('rms, min, max and mean ratios');
%saveas(gcf,[expt_id 'fig11.fig']);

%% %%
% sigmoid fits to mean ratios
%Fit: '3'.
% Set up fittype and options.
ft3 = fittype( 'a./(1+(x./c).^b)', 'independent', 'x', 'dependent', 'y' );
opts3 = fitoptions( 'Method', 'NonlinearLeastSquares' );
opts3.Algorithm = 'Levenberg-Marquardt';
opts3.Display = 'Off';
opts3.Robust = 'Bisquare';
opts3.StartPoint = [0.5 5 50];% changed

% Fit model to data.
[fitresult{1}, gof(1)] = fit( x1Data, y1Data, ft3, opts3);

coefficients3= coeffvalues(fitresult{1});
half3 = coefficients3 (:,3);
ymax_3 = coefficients3 (:,1);

%% Fit: '5PL'.
% Set up fittype and options.
ft5 = fittype( 'd + (a - d) / (1 + (x / c)^b)^e', 'independent', 'x', 'dependent', 'y' );
opts5 = fitoptions( 'Method', 'NonlinearLeastSquares' );
opts5.Algorithm = 'Levenberg-Marquardt';
opts5.Display = 'Off';
opts5.Robust = 'Bisquare';
opts5.StartPoint = [0.5 0.5 50 0.5 0.5]; % if zc data is included, first coeff must be 5. after zc data, Second coeff was changed to 0.5 instead of 5

% Fit model to data.
[fitresult{2}, gof(2)] = fit( x1Data, y1Data, ft5, opts5 );

coefficients5= coeffvalues(fitresult{2});
ymax5 = coefficients5(:,1);

fitx5 = (30:0.1:hcp);
fitx5 =   fitx5';
fity5 = (fitresult{2}(30:0.1:hcp));
fit5 = [fitx5, fity5];

%%
%tangents to 3PL fit
% Generate upper horizontal in 3PL
yuh3= (fitresult {1}(0:1:30));
xuht3 = (0:1:30);
xuh3=transpose(xuht3);
%
% Fit upper horizontal line to 3PL  ratios
[xuh3, yuh3] = prepareCurveData( xuh3, yuh3 );
fituh3 = fittype( 'm*x+c', 'independent', 'x', 'dependent', 'y' );
optsuh3 = fitoptions( 'Method', 'NonlinearLeastSquares' );
optsuh3.Algorithm = 'Levenberg-Marquardt';
optsuh3.Display = 'Off';
optsuh3.Robust = 'Bisquare';
optsuh3.StartPoint = [ymax_3 0.01];

[fitresult{3}, gof(3)] = fit( xuh3, yuh3, fituh3, optsuh3 );

coefficients_uh_3= coeffvalues(fitresult{3});
fitxuh3 = ((20:1:120));
fityuh3 = (fitresult{3} (20:1:120));

% Generate midtangent in 3PL
a3=coefficients3(1,1);
b3=coefficients3(1,2);
c3=coefficients3(1,3);
%
y3a = yuh3 (1,1)*(7/8);
y3b = yuh3 (1,1)* (3/4);
y3new = yuh3 (1,1)/2;
y3_1=yuh3 (1,1)/4;
y3_2= yuh3 (1,1)/8;

y3b_3new = (y3b+y3new)/2;
y3new_3_1 = (y3new+y3_1)/2;
%
x3a = c3 * (((a3/y3a)-1)^(1/b3));
x3b = c3 * (((a3/y3b)-1)^(1/b3));
x3new = c3 * (((a3/y3new)-1)^(1/b3));
x3_1 = c3 *(((a3./y3_1)-1).^(1/b3));
x3_2 = c3 * (((a3/y3_2)-1)^(1/b3));

x3b_3new = c3 * (((a3/ y3b_3new)-1)^(1/b3));
x3new_3_1  = c3 *(((a3./ y3new_3_1 )-1).^(1/b3));

ymid_3new= (fitresult {1}(x3b_3new:0.2: x3new_3_1));
xmidt_3new = ( x3b_3new:0.2: x3new_3_1);
xmid_3new=transpose(xmidt_3new);
[xmid_3new, ymid_3new] = prepareCurveData( xmid_3new, ymid_3new );

fitmid_3new = fittype( 'm*x+c', 'independent', 'x', 'dependent', 'y' );
optsmid_3new = fitoptions( 'Method', 'NonlinearLeastSquares' );
optsmid_3new.Algorithm = 'Levenberg-Marquardt';
optsmid_3new.Display = 'Off';
optsmid_3new.Robust = 'Bisquare';
optsmid_3new.StartPoint = [10 10];

[fitresult{7}, gof(7)] = fit( xmid_3new, ymid_3new, fitmid_3new, optsmid_3new );

coefficients_mid_3new= coeffvalues(fitresult{7});
fitxmid_3new = ((30:1:hcp));
fitymid_3new = (fitresult{7} (30:1:hcp));

%%%%%
ymid_3newup= (fitresult {1}(x3a:0.2: x3b));
xmidt_3newup = ( x3a:0.2: x3b);
xmid_3newup=transpose(xmidt_3newup);
[xmid_3newup, ymid_3newup] = prepareCurveData( xmid_3newup, ymid_3newup );

fitmid_3newup = fittype( 'm*x+c', 'independent', 'x', 'dependent', 'y' );
optsmid_3newup = fitoptions( 'Method', 'NonlinearLeastSquares' );
optsmid_3newup.Algorithm = 'Levenberg-Marquardt';
optsmid_3newup.Display = 'Off';
optsmid_3newup.Robust = 'Bisquare';
optsmid_3newup.StartPoint = [10 10];

[fitresult{8}, gof(8)] = fit( xmid_3newup, ymid_3newup, fitmid_3newup, optsmid_3newup );

coefficients_mid_3newup= coeffvalues(fitresult{8});
fitxmid_3newup = ((30:1:hcp));
fitymid_3newup = (fitresult{8} (30:1:hcp));

%%%%%
ymid_3newdown= (fitresult {1}(x3_1:0.2: x3_2));
xmidt_3newdown = ( x3_1:0.2: x3_2);
xmid_3newdown=transpose(xmidt_3newdown);
[xmid_3newdown, ymid_3newdown] = prepareCurveData( xmid_3newdown, ymid_3newdown );

fitmid_3newdown = fittype( 'm*x+c', 'independent', 'x', 'dependent', 'y' );
optsmid_3newdown = fitoptions( 'Method', 'NonlinearLeastSquares' );
optsmid_3newdown.Algorithm = 'Levenberg-Marquardt';
optsmid_3newdown.Display = 'Off';
optsmid_3newdown.Robust = 'Bisquare';
optsmid_3newdown.StartPoint = [10 10];

[fitresult{9}, gof(9)] = fit( xmid_3newdown, ymid_3newdown, fitmid_3newdown, optsmid_3newdown );

coefficients_mid_3newdown= coeffvalues(fitresult{9});
fitxmid_3newdown = ((30:1:hcp));
fitymid_3newdown = (fitresult{9} (30:1:hcp));

%% tangents to 5PL fit

% Generate upper horizontal in 5PL  ratios
yuh5 =(fitresult {2}(0:1:50));
xuht5 = (0:1:50);
xuh5=transpose(xuht5);

% Fit upper horizontal line to 5PL  ratios
[xuh5, yuh5] = prepareCurveData( xuh5, yuh5 );
fituh5 = fittype( 'm*x+c', 'independent', 'x', 'dependent', 'y' );
optsuh5 = fitoptions( 'Method', 'NonlinearLeastSquares' );
optsuh5.Algorithm = 'Levenberg-Marquardt';
optsuh5.Display = 'Off';
optsuh5.Robust = 'Bisquare';
optsuh5.StartPoint = [ymax5 0.1];

[fitresult{10}, gof(10)] = fit( xuh5, yuh5, fituh5, optsuh5 );

coefficients_uh_5= coeffvalues(fitresult{10});
fitxuh5 = ((0:1:120));
fityuh5 = (fitresult{10} (0:1:120));

y5a = yuh5 (1,1)* (7/8);
y5b = yuh5 (1,1)* (3/4);
y5new = yuh5 (1,1)/2;
y5_1=yuh5 (1,1)/4;
y5_2 = yuh5 (1,1)/8;

y5b_5new = (y5b+y5new)/2;
y5new_5_1 = (y5new+y5_1)/2;
%
% Trying another approach
fit5a = fit5; %Getting the data points of the fitted sigmoid
fit5b = fit5;
fit5new = fit5;
fit5_1 = fit5;
fit5_2 = fit5;

fit5a(:,3) =  abs (fit5 (:,2)- y5a);%  get the difference between yvalue in the curve and the y level required
fit5b(:,3) =  abs (fit5 (:,2)- y5b);
fit5new(:,3) =  abs (fit5 (:,2)- y5new);
fit5_1(:,3) =  abs (fit5 (:,2)- y5_1);
fit5_2(:,3) =    abs (fit5 (:,2)- y5_2);

% Find the minimum value in the third column
[mindiff5a, minindex5a] = min(fit5a(:,3));
[mindiff5b, minindex5b] = min(fit5b(:,3));
[mindiff5_new, minindex5_new] = min(fit5new(:,3));
[mindiff5_1, minindex5_1] = min(fit5_1(:,3));
[mindiff5_2, minindex5_2] = min(fit5_2(:,3));

% Get the corresponding value in the first column
x5a =  fit5a(minindex5a, 1);
x5b =  fit5b(minindex5b, 1); % please see if there is a bug here. Should this be fit5b?
x5_new =  fit5new(minindex5_new, 1);
x5_1 =  fit5_1(minindex5_1, 1);
x5_2 =  fit5_2(minindex5_2, 1);

% Generate midtangent 'up' and 'down' in 5PL

ymid_5newup= (fitresult{2}(x5a:0.2: x5b+1));
xmidt_5newup = (x5a :0.2: x5b+1);
xmid_5newup=transpose(xmidt_5newup);
[xmid_5newup, ymid_5newup] = prepareCurveData( xmid_5newup, ymid_5newup );

% Fit mid tangentnew to 5PL  ratios.
[xmid_5newup, ymid_5newup] = prepareCurveData(xmid_5newup, ymid_5newup );

fitmid_5newup = fittype( 'm*x+c', 'independent', 'x', 'dependent', 'y' );
optsmid_5newup = fitoptions( 'Method', 'NonlinearLeastSquares' );
optsmid_5newup.Algorithm = 'Levenberg-Marquardt';
optsmid_5newup.Display = 'Off';
optsmid_5newup.Robust = 'Bisquare';
optsmid_5newup.StartPoint = [10 10];

[fitresult{14}, gof(14)] = fit( xmid_5newup, ymid_5newup, fitmid_5newup, optsmid_5newup);

coefficients_mid_5newup= coeffvalues(fitresult{14});
fitxmid_5newup = ((30:1:hcp));
fitymid_5newup = (fitresult{14} (30:1:hcp));
%%
ymid_5new= (fitresult{2}(x5_new-2:0.2: x5_new+3));
xmidt_5new = (x5_new-2 :0.2: x5_new+3);
xmid_5new=transpose(xmidt_5new);
[xmid_5new, ymid_5new] = prepareCurveData( xmid_5new, ymid_5new );

% Fit mid tangentnew to 5PL  ratios.
[xmid_5new, ymid_5new] = prepareCurveData(xmid_5new, ymid_5new );

fitmid_5new = fittype( 'm*x+c', 'independent', 'x', 'dependent', 'y' );
optsmid_5new = fitoptions( 'Method', 'NonlinearLeastSquares' );
optsmid_5new.Algorithm = 'Levenberg-Marquardt';
optsmid_5new.Display = 'Off';
optsmid_5new.Robust = 'Bisquare';
optsmid_5new.StartPoint = [10 10];

[fitresult{13}, gof(13)] = fit( xmid_5new, ymid_5new, fitmid_5new, optsmid_5new);

coefficients_mid_5new= coeffvalues(fitresult{13});
fitxmid_5new = ((30:1:hcp));
fitymid_5new = (fitresult{13} (30:1:hcp));

%%
ymid_5newdown= (fitresult{2}(x5_1:0.2: x5_2)); % As the above equations are not working properly, resorted to using x values calculated with 3 PL fit
xmidt_5newdown = (x5_1 :0.2: x5_2);
xmid_5newdown=transpose(xmidt_5newdown);
[xmid_5newdown, ymid_5newdown] = prepareCurveData( xmid_5newdown, ymid_5newdown );

% Fit mid tangentnew to 5PL  ratios.
[xmid_5newdown, ymid_5newdown] = prepareCurveData(xmid_5newdown, ymid_5newdown );

fitmid_5newdown = fittype( 'm*x+c', 'independent', 'x', 'dependent', 'y' );
optsmid_5newdown = fitoptions( 'Method', 'NonlinearLeastSquares' );
optsmid_5newdown.Algorithm = 'Levenberg-Marquardt';
optsmid_5newdown.Display = 'Off';
optsmid_5newdown.Robust = 'Bisquare';
optsmid_5newdown.StartPoint = [10 10];

try
    [fitresult{12}, gof(12)] = fit( xmid_5newdown, ymid_5newdown, fitmid_5newdown, optsmid_5newdown);
    coefficients_mid_5newdown= coeffvalues(fitresult{12});
    fitxmid_5newdown = ((30:1:hcp));
    fitymid_5newdown = (fitresult{12} (30:1:hcp));
    CATCH ME
end

%%
uhintercept_3new  = round((coefficients_mid_3new(1,1) - coefficients_uh_3 (1,1))/(coefficients_uh_3(1,2)- coefficients_mid_3new(1,2)));
uhintercept_3newup  = round((coefficients_mid_3newup(1,1) - coefficients_uh_3 (1,1))/(coefficients_uh_3(1,2)- coefficients_mid_3newup(1,2)));
uhintercept_3newdown  = round((coefficients_mid_3newdown(1,1) - coefficients_uh_3 (1,1))/(coefficients_uh_3(1,2)- coefficients_mid_3newdown(1,2)));

uhintercept_5new  = round((coefficients_mid_5new(1,1) - coefficients_uh_5 (1,1))/(coefficients_uh_5(1,2)- coefficients_mid_5new(1,2)));
uhintercept_5newup  = round((coefficients_mid_5newup(1,1) - coefficients_uh_5 (1,1))/(coefficients_uh_5(1,2)- coefficients_mid_5newup(1,2)));
uhintercept_5newdown = round((coefficients_mid_5newdown(1,1) - coefficients_uh_5 (1,1))/(coefficients_uh_5(1,2)- coefficients_mid_5newdown(1,2)));

X_intercept_3new = round(fzero(fitresult{7}, [x3new, hcp+100])); %LSP 3sig
X_intercept_3newup = round(fzero(fitresult{8}, [x3new, hcp+100])); %LSP 3sig
X_intercept_3newdown = round(fzero(fitresult{9}, [x3new, hcp+100])); %LSP 3sig

X_intercept_5new = round(fzero(fitresult{13}, [x5_new, hcp+100]));% LSP 5sig % note this has been set to x3new
X_intercept_5newdown = round(fzero(fitresult{12}, [x5_new, hcp+100]));% LSP 5sig % note this has been set to x3new
X_intercept_5newup = round(fzero(fitresult{14}, [x5_new, hcp+100]));% LSP 5sig % note this has been set to x3new

%%
Xmean_down = round((X_intercept_3newdown + X_intercept_5newdown)/2);
Xmean_new = round((X_intercept_3new+ X_intercept_5new)/2);

UHmean_up = round((uhintercept_3newup + uhintercept_5newup)/2);
UHmean_new = round((uhintercept_3new + uhintercept_5new)/2);

%%
%figure (13)
%hold on

%plot(x1Data, y1Data, 'o', 'MarkerSize', 3, 'color', 'k'); % all ratios data

%grid on
%h3 = plot(fitresult{1}); % 3PL sigmoid fit of all ratios
%set (h3, 'color', 'b');

%huh3 = plot (fitresult {3});%For upper horizontal to 3PL all ratios
%set (huh3, 'color', 'b');

%h3new = plot (fitresult {7}); % tangent of 3PL fit of all ratios
%set (h3new, 'color', 'b', 'LineStyle', ':');

%h3newup = plot (fitresult {8});
%set (h3newup, 'color', 'b','LineStyle', '-.');

%h3newdown = plot (fitresult {9});
%set (h3newdown, 'color', 'b','LineStyle', '--');

%h5 = plot(fitresult{2}); % 5PL sigmoid fit of all ratios
%set (h5, 'color', 'm');

%huh5 = plot (fitresult {10});  %For upper horizontal to 5PL fit of all ratios
%set (huh5, 'color', 'r');

%h5new = plot (fitresult {13}); % mid tangent of 5PL fit of all ratios
%set (h5new, 'color', 'r', 'LineStyle', ':');

%h5newup = plot (fitresult {14});  % tangent of 5PL fit of all ratios
%set (h5newup, 'color', 'r','LineStyle', '-.' );

%h5newdown = plot (fitresult {12});
%set (h5newdown, 'color', 'r','LineStyle', '--');

%grid on
%hold off

%xlabel('cuff pressure');
%ylabel('PPG amplitude min and max ratios');

%line([20, hcp], [min(y1Data), min(y1Data)], 'Color', 'k', 'LineStyle', '-'); % Line of lowest rms

%ylim ([0 max(y2Data)+0.1]);

%xlabel('cuff pressure');
%ylabel('PPG ratio');
%hold off
%legend('mean ratios');
%set(legend,'FontSize',10);
%title (expt_id);

%saveas(gcf,[expt_id 'fig13.fig']);

%%
% sigmoid fits to minratio
%Fit: 'min3PL'.
% Set up fittype and options.
ftmin3 = fittype( 'a./(1+(x./c).^b)', 'independent', 'x', 'dependent', 'y' );
optsmin3 = fitoptions( 'Method', 'NonlinearLeastSquares' );
optsmin3.Algorithm = 'Levenberg-Marquardt';
optsmin3.Display = 'Off';
optsmin3.Robust = 'Bisquare';
optsmin3.StartPoint = [0.5 5 50];
%optsmin3.StartPoint = [0.5 0.5 50];

% Fit model to data.
[fitresult{27}, gof(27)] = fit( x4Data, y4Data, ftmin3, optsmin3 );

coefficientsmin3= coeffvalues(fitresult{27});
halfmin3 = coefficientsmin3 (:,3);
ymax_min3 = coefficientsmin3 (:,1);

%% Fit: 'min5PL'.

% Set up fittype and options.
ftmin5 = fittype ('d + (a - d) / (1 + (x / c)^b)^e', 'independent', 'x', 'dependent', 'y' );
optsmin5 = fitoptions( 'Method', 'NonlinearLeastSquares' );
optsmin5.Algorithm = 'Levenberg-Marquardt';
optsmin5.Display = 'Off';
optsmin5.Robust = 'Bisquare';
optsmin5.StartPoint = [0.5 5 50 0.5 0.5]; % change coeff if required

% Fit model to data.
[fitresult{28}, gof(28)] = fit( x4Data, y4Data, ftmin5, optsmin5 );

coefficientsmin5= coeffvalues(fitresult{28});
ymax_min5 = coefficientsmin5 (:,1);

fitx_min5 = (30:0.1:hcp);
fitx_min5 =   fitx_min5';
fity_min5 = (fitresult{28}(30:0.1:hcp));
fit_min5 = [fitx_min5, fity_min5];

%% %%
% sigmoid fits to maxratio
%Fit: 'max3PL'.
% Set up fittype and options.
ftmax3 = fittype( 'a./(1+(x./c).^b)', 'independent', 'x', 'dependent', 'y' );
optsmax3 = fitoptions( 'Method', 'NonlinearLeastSquares' );
optsmax3.Algorithm = 'Levenberg-Marquardt';
optsmax3.Display = 'Off';
optsmax3.Robust = 'Bisquare';
optsmax3.StartPoint = [0.5 5 50];

% Fit model to data.
[fitresult{51}, gof(51)] = fit( x5Data, y5Data, ftmax3, optsmax3 );

coefficientsmax3= coeffvalues(fitresult{51});
halfmax3 = coefficientsmax3 (:,3);
ymax_max3 = coefficientsmax3 (:,1);

%% Fit: 'max5PL'.

% Set up fittype and options.
ftmax5 = fittype( 'd+(a-d)/(1+(x/c)^b)^e', 'independent', 'x', 'dependent', 'y' );
optsmax5 = fitoptions( 'Method', 'NonlinearLeastSquares' );
optsmax5.Algorithm = 'Levenberg-Marquardt';
optsmax5.Display = 'Off';
optsmax5.Robust = 'Bisquare';

optsmax5.StartPoint = [0.5 5 50 0.5 0.5]; %change coeff if required
%optsmax5.StartPoint = [0.5 50 50 0.5 0.5]; %change coeff if required

% Fit model to data.
[fitresult{52}, gof(52)] = fit( x5Data, y5Data, ftmax5, optsmax5 );

coefficientsmax5= coeffvalues(fitresult{52});
ymax_max5 = coefficientsmax5 (:,1);
fitx_max5 = (30:0.1:hcp);
fitx_max5 =   fitx_max5';
fity_max5 = (fitresult{52}(30:0.1:hcp));
fit_max5 = [fitx_max5, fity_max5];
%%
%Drawing 3 straight lines, Upper horizontal, Lower horizontal &
%midtangent to min ratios
%tangents to 3PL fit of minimum ratios
% Generate upper horizontal in 3PL min ratios
yuhmin3= (fitresult {27}(10:1:20));
xuhtmin3 = (10:1:20);
xuhmin3=transpose(xuhtmin3);
%
% Fit upper horizontal line to 3PL min ratios
[xuhmin3, yuhmin3] = prepareCurveData( xuhmin3, yuhmin3 );
fituhmin3 = fittype( 'm*x+c', 'independent', 'x', 'dependent', 'y' );
optsuhmin3 = fitoptions( 'Method', 'NonlinearLeastSquares' );
optsuhmin3.Algorithm = 'Levenberg-Marquardt';
optsuhmin3.Display = 'Off';
optsuhmin3.Robust = 'Bisquare';
optsuhmin3.StartPoint = [ymax_min3 0.1];

[fitresult{29}, gof(29)] = fit( xuhmin3, yuhmin3, fituhmin3, optsuhmin3 );

coefficients_uh_min3= coeffvalues(fitresult{29});
fitxuhmin3 = ((30:1:120));
fityuhmin3 = (fitresult{29} (30:1:120));

% Generate midtangent in 3PL min ratios
amin3=coefficientsmin3(1,1);
bmin3=coefficientsmin3(1,2);
cmin3=coefficientsmin3(1,3);
%
ymin3a =  yuhmin3 (1,1)*(7/8);
ymin3b =  yuhmin3 (1,1)*(3/4);
ymin3new= yuhmin3 (1,1)/2;
ymin3_1 = yuhmin3 (1,1)/4;
ymin3_2 = yuhmin3 (1,1)/8;

ymin3b_3new = (ymin3b+ymin3new)/2;
ymin3new_3_1 = (ymin3new+ymin3_1)/2;
%
xmin3a =    cmin3 * (((amin3/ymin3a)-1)  ^(1/bmin3));
xmin3b =    cmin3 * (((amin3/ymin3b)-1)  ^(1/bmin3));
xmin3new =  cmin3 * (((amin3/ymin3new)-1)^(1/bmin3));
xmin3_1 =   cmin3 * (((amin3/ymin3_1)-1) ^(1/bmin3));
xmin3_2 =   cmin3 * (((amin3/ymin3_2)-1) ^(1/bmin3));

xmin3b_3new =cmin3 * (((amin3/ ymin3b_3new)-1)^(1/bmin3));
xmin3new_3_1=cmin3 * (((amin3/ ymin3new_3_1)-1)^(1/bmin3));

yminmid_3new= (fitresult {27}(xmin3b_3new:0.2:xmin3new_3_1));
xminmidt_3new = ( xmin3b_3new:0.2: xmin3new_3_1);
xminmid_3new=transpose(xminmidt_3new);
[xminmid_3new, yminmid_3new] = prepareCurveData( xminmid_3new, yminmid_3new );

fit_min_mid_3new = fittype( 'm*x+c', 'independent', 'x', 'dependent', 'y' );
opts_min_mid_3new = fitoptions( 'Method', 'NonlinearLeastSquares' );
opts_min_mid_3new.Algorithm = 'Levenberg-Marquardt';
opts_min_mid_3new.Display = 'Off';
opts_min_mid_3new.Robust = 'Bisquare';
opts_min_mid_3new.StartPoint = [10 10];

[fitresult{30}, gof(30)] = fit(xminmid_3new, yminmid_3new, fit_min_mid_3new, opts_min_mid_3new );

coefficients_mid_min3new= coeffvalues(fitresult{30});
fitxminmid_3new = ((30:1:hcp));
fityminmid_3new = (fitresult{30} (30:1:hcp));

ymid_min3newup= (fitresult {27}(xmin3a: 0.2: xmin3b));
xmidt_min3newup = (xmin3a:0.2: xmin3b);
xmid_min3newup = transpose(xmidt_min3newup);
[xmid_min3newup, ymid_min3newup] = prepareCurveData( xmid_min3newup, ymid_min3newup );

fitmid_min3newup = fittype( 'm*x+c', 'independent', 'x', 'dependent', 'y' );
optsmid_min3newup = fitoptions( 'Method', 'NonlinearLeastSquares' );
optsmid_min3newup.Algorithm = 'Levenberg-Marquardt';
optsmid_min3newup.Display = 'Off';
optsmid_min3newup.Robust = 'Bisquare';
optsmid_min3newup.StartPoint = [10 10];

[fitresult{31}, gof(31)] = fit( xmid_min3newup, ymid_min3newup, fitmid_min3newup, optsmid_min3newup );

coefficients_mid_min3newup= coeffvalues(fitresult{31});
fitxmid_min3newup = ((30:1:hcp));
fitymid_min3newup = (fitresult{31} (30:1:hcp));

ymid_min3newdown= (fitresult {27}(xmin3_1:0.2: xmin3_2));
xmidt_min3newdown = ( xmin3_1:0.2: xmin3_2);
xmid_min3newdown=transpose(xmidt_min3newdown);
[xmid_min3newdown, ymid_min3newdown] = prepareCurveData( xmid_min3newdown, ymid_min3newdown );

fitmid_min3newdown = fittype( 'm*x+c', 'independent', 'x', 'dependent', 'y' );
optsmid_min3newdown = fitoptions( 'Method', 'NonlinearLeastSquares' );
optsmid_min3newdown.Algorithm = 'Levenberg-Marquardt';
optsmid_min3newdown.Display = 'Off';
optsmid_min3newdown.Robust = 'Bisquare';
optsmid_min3newdown.StartPoint = [10 10];

[fitresult{32}, gof(32)] = fit( xmid_min3newdown, ymid_min3newdown, fitmid_min3newdown, optsmid_min3newdown );

coefficients_mid_min3newdown = coeffvalues(fitresult{32});
fitxmid_min3newdown = ((30:1:hcp));
fitymid_min3newdown = (fitresult{32} (30:1:hcp));

%% tangents to 5PL fit of minimum ratios

% Generate upper horizontal in 5PL min ratios
yuhmin5= (fitresult {28}(10:1:20));
xuhtmin5 = (10:1:20);
xuhmin5=transpose(xuhtmin5);

% Fit upper horizontal line to 5PL min ratios
[xuhmin5, yuhmin5] = prepareCurveData( xuhmin5, yuhmin5 );
fituhmin5 = fittype( 'm*x+c', 'independent', 'x', 'dependent', 'y' );
optsuhmin5 = fitoptions( 'Method', 'NonlinearLeastSquares' );
optsuhmin5.Algorithm = 'Levenberg-Marquardt';
optsuhmin5.Display = 'Off';
optsuhmin5.Robust = 'Bisquare';
optsuhmin5.StartPoint = [ymax_min5 0.1];

[fitresult{45}, gof(45)] = fit( xuhmin5, yuhmin5, fituhmin5, optsuhmin5 );

coefficients_uh_min5= coeffvalues(fitresult{45});
fitxuhmin5 = ((0:1:120));
fityuhmin5 = (fitresult{45} (0:1:120));
%
%%
y_min5a = yuhmin5 (1,1)* (7/8);
y_min5b = yuhmin5 (1,1)* (3/4);
y_min5new = yuhmin5 (1,1)/2;
y_min5_1=yuhmin5 (1,1)/4;
y_min5_2 = yuhmin5 (1,1)/8;

y_min5b_5new = (y_min5b+y_min5new)/2;
y_min5new_5_1 = (y_min5new+y_min5_1)/2;
%
% Trying another approach
fit_min5a = fit_min5; %Getting the data points of the fitted sigmoid
fit_min5b = fit_min5;
fit_min5new = fit_min5;
fit_min5_1 = fit_min5;
fit_min5_2 = fit_min5;

fit_min5a(:,3) =  abs (fit_min5 (:,2)- y_min5a);%  get the difference between yvalue in the curve and the y level required
fit_min5b(:,3) =  abs (fit_min5 (:,2)- y_min5b);
fit_min5new(:,3) =  abs (fit_min5(:,2)- y_min5new);
fit_min5_1(:,3) =  abs (fit_min5 (:,2)- y_min5_1);
fit_min5_2(:,3) =    abs (fit_min5 (:,2)- y_min5_2);

% Find the minimum value in the third column
[mindiff_min5a, minindex_min5a] = min(fit_min5a(:,3));
[mindiff_min5b, minindex_min5b] = min(fit_min5b(:,3));
[mindiff_min5_new, minindex_min5_new] = min(fit_min5new(:,3));
[mindiff_min5_1, minindex_min5_1] = min(fit_min5_1(:,3));
[mindiff_min5_2, minindex_min5_2] = min(fit_min5_2(:,3));

% Get the corresponding value in the first column
x_min5a =  fit_min5a(minindex_min5a, 1);
x_min5b =  fit_min5b(minindex_min5b, 1);
x_min5new =  fit_min5new(minindex_min5_new, 1);
x_min5_1 =  fit_min5_1(minindex_min5_1, 1);
x_min5_2 =  fit_min5_2(minindex_min5_2, 1);

% Generate midtangent 'up' and 'down' in 5PL
ymid_min5newup= (fitresult{28}(x_min5a:0.2: x_min5b+1));
xmidt_min5newup =             (x_min5a :0.2: x_min5b+1); %The last term has plus 1 to avoid situations where 5a and 5b are equal

xmid_min5newup=transpose(xmidt_min5newup);
[xmid_min5newup, ymid_min5newup] = prepareCurveData( xmid_min5newup, ymid_min5newup );

% Fit mid tangentnew to 5PL  ratios.
[xmid_min5newup, ymid_min5newup] = prepareCurveData(xmid_min5newup, ymid_min5newup );

fitmid_min5newup = fittype( 'm*x+c', 'independent', 'x', 'dependent', 'y' );
optsmid_min5newup = fitoptions( 'Method', 'NonlinearLeastSquares' );
optsmid_min5newup.Algorithm = 'Levenberg-Marquardt';
optsmid_min5newup.Display = 'Off';
optsmid_min5newup.Robust = 'Bisquare';
optsmid_min5newup.StartPoint = [10 10];

[fitresult{46}, gof(46)] = fit( xmid_min5newup, ymid_min5newup, fitmid_min5newup, optsmid_min5newup);

coefficients_mid_min5newup= coeffvalues(fitresult{46});
fitxmid_min5newup = ((30:1:hcp));
fitymid_min5newup = (fitresult{46} (30:1:hcp));

%%
ymid_min5new= (fitresult{28}(x_min5new-2:0.2: x_min5new+3));
xmidt_min5new = (x_min5new-2 :0.2: x_min5new+3);
xmid_min5new=transpose(xmidt_min5new);
[xmid_min5new, ymid_min5new] = prepareCurveData( xmid_min5new, ymid_min5new );

% Fit mid tangentnew to 5PL  ratios.
fitmid_min5new = fittype( 'm*x+c', 'independent', 'x', 'dependent', 'y' );
optsmid_min5new = fitoptions( 'Method', 'NonlinearLeastSquares' );
optsmid_min5new.Algorithm = 'Levenberg-Marquardt';
optsmid_min5new.Display = 'Off';
optsmid_min5new.Robust = 'Bisquare';
optsmid_min5new.StartPoint = [10 10];

[fitresult{48}, gof(48)] = fit( xmid_min5new, ymid_min5new, fitmid_min5new, optsmid_min5new);

coefficients_mid_min5new= coeffvalues(fitresult{48});
fitxmid_min5new = ((30:1:hcp));
fitymid_min5new = (fitresult{48} (30:1:hcp));

%%
ymid_min5newdown  = (fitresult{28}(x_min5_1:0.2: x_min5_2));
xmidt_min5newdown =               (x_min5_1 :0.2: x_min5_2);

xmid_min5newdown=transpose(xmidt_min5newdown);
[xmid_min5newdown, ymid_min5newdown] = prepareCurveData( xmid_min5newdown, ymid_min5newdown );

% Fit mid tangentnew to 5PL  ratios.
[xmid_min5newdown, ymid_min5newdown] = prepareCurveData(xmid_min5newdown, ymid_min5newdown );

fitmid_min5newdown = fittype( 'm*x+c', 'independent', 'x', 'dependent', 'y' );
optsmid_min5newdown = fitoptions( 'Method', 'NonlinearLeastSquares' );
optsmid_min5newdown.Algorithm = 'Levenberg-Marquardt';
optsmid_min5newdown.Display = 'Off';
optsmid_min5newdown.Robust = 'Bisquare';
optsmid_min5newdown.StartPoint = [10 10];

[fitresult{47}, gof(47)] = fit( xmid_min5newdown, ymid_min5newdown, fitmid_min5newdown, optsmid_min5newdown);

coefficients_mid_min5newdown= coeffvalues(fitresult{47});
fitxmid_min5newdown = ((30:1:hcp));
fitymid_min5newdown = (fitresult{47} (30:1:hcp));

%%   %%
%Drawing 3 straight lines, Upper horizontal, Lower horizontal & midtangent
%tangents to 3PL fit of maximum ratios
% Generate upper horizontal in 3PL max ratios
yuhmax3= (fitresult {51}(10:1:20));
xuhtmax3 = (10:1:20);
xuhmax3=transpose(xuhtmax3);
%
% Fit upper horizontal line to 3PL max ratios
[xuhmax3, yuhmax3] = prepareCurveData( xuhmax3, yuhmax3 );
fituhmax3 = fittype( 'm*x+c', 'independent', 'x', 'dependent', 'y' );
optsuhmax3 = fitoptions( 'Method', 'NonlinearLeastSquares' );
optsuhmax3.Algorithm = 'Levenberg-Marquardt';
optsuhmax3.Display = 'Off';
optsuhmax3.Robust = 'Bisquare';
optsuhmax3.StartPoint = [ymax_max5 0.1];

[fitresult{53}, gof(53)] = fit( xuhmax3, yuhmax3, fituhmax3, optsuhmax3 );

coefficients_uh_max3= coeffvalues(fitresult{53});
fitxuhmax3 = ((30:1:120));
fityuhmax3 = (fitresult{53} (30:1:120));

% Generate midtangent in 3PL max ratios
amax3=coefficientsmax3(1,1);
bmax3=coefficientsmax3(1,2);
cmax3=coefficientsmax3(1,3);
%
ymax3a = yuhmax3 (1,1)*(7/8);
ymax3b = yuhmax3 (1,1)* (3/4);
ymax3new = yuhmax3(1,1)/2;
ymax3_1=yuhmax3(1,1)/4;
ymax3_2= yuhmax3 (1,1)/8;

ymax3b_3new = (ymax3b+ymax3new)/2;
ymax3new_3_1 = (ymax3new+ymax3_1)/2;
%
xmax3a =   cmax3 * (((amax3/ymax3a)-1)  ^(1/bmax3));
xmax3b =   cmax3 * (((amax3/ymax3b)-1)  ^(1/bmax3));
xmax3new = cmax3 * (((amax3/ymax3new)-1)^(1/bmax3));
xmax3_1 =  cmax3 * (((amax3/ymax3_1)-1) ^(1/bmax3));
xmax3_2 =  cmax3 * (((amax3/ymax3_2)-1) ^(1/bmax3));

xmax3b_3new = cmax3 * (((amax3/ ymax3b_3new)-1)  ^(1/bmax3));
xmax3new_3_1= cmax3 * (((amax3/ ymax3new_3_1 )-1)^(1/bmax3));

if xmax3new_3_1 - xmax3b_3new < 0.2
    xmax3b_3new = xmax3b_3new-0.5;
    xmax3new_3_1 = xmax3new_3_1+0.5;
end

ymaxmid_3new= (fitresult {51}(xmax3b_3new:0.2: xmax3new_3_1));
xmaxmidt_3new = ( xmax3b_3new:0.2: xmax3new_3_1);
xmaxmid_3new=transpose(xmaxmidt_3new);
[xmaxmid_3new, ymaxmid_3new] = prepareCurveData( xmaxmid_3new, ymaxmid_3new );

fit_max_mid_3new = fittype( 'm*x+c', 'independent', 'x', 'dependent', 'y' );
opts_max_mid_3new = fitoptions( 'Method', 'NonlinearLeastSquares' );
opts_max_mid_3new.Algorithm = 'Levenberg-Marquardt';
opts_max_mid_3new.Display = 'Off';
opts_max_mid_3new.Robust = 'Bisquare';
opts_max_mid_3new.StartPoint = [10 10];

[fitresult{54}, gof(54)] = fit( xmaxmid_3new, ymaxmid_3new, fit_max_mid_3new, opts_max_mid_3new );

coefficients_mid_max3new= coeffvalues(fitresult{54});
fitxmaxmid_max3new = ((30:1:hcp));
fitymaxmid_max3new = (fitresult{54} (30:1:hcp));

if xmax3b - xmax3a <0.2
    xmax3a = xmax3a-0.5;
    xmax3b = xmax3b+0.5;
end

ymid_max3newup= (fitresult {51}(xmax3a:0.2: xmax3b));
xmidt_max3newup = ( xmax3a:0.2: xmax3b);
xmid_max3newup=transpose(xmidt_max3newup);
[xmid_max3newup, ymid_max3newup] = prepareCurveData( xmid_max3newup, ymid_max3newup );

fitmid_max3newup = fittype( 'm*x+c', 'independent', 'x', 'dependent', 'y' );
optsmid_max3newup = fitoptions( 'Method', 'NonlinearLeastSquares' );
optsmid_max3newup.Algorithm = 'Levenberg-Marquardt';
optsmid_max3newup.Display = 'Off';
optsmid_max3newup.Robust = 'Bisquare';
optsmid_max3newup.StartPoint = [10 10];

[fitresult{55}, gof(55)] = fit( xmid_max3newup, ymid_max3newup, fitmid_max3newup, optsmid_max3newup );

coefficients_mid_max3newup= coeffvalues(fitresult{55});
fitxmid_max3newup = ((30:1:hcp));
fitymid_max3newup = (fitresult{55} (30:1:hcp));

if xmax3_2 - xmax3_1 < 0.2
    xmax3_1 = xmax3_1-0.5;
    xmax3_2 = xmax3_2+0.5;
end

ymid_max3newdown= (fitresult {51}(xmax3_1:0.2: xmax3_2));
xmidt_max3newdown = ( xmax3_1:0.2: xmax3_2);
xmid_max3newdown=transpose(xmidt_max3newdown);
[xmid_max3newdown, ymid_max3newdown] = prepareCurveData( xmid_max3newdown, ymid_max3newdown );

fitmid_max3newdown = fittype( 'm*x+c', 'independent', 'x', 'dependent', 'y' );
optsmid_max3newdown = fitoptions( 'Method', 'NonlinearLeastSquares' );
optsmid_max3newdown.Algorithm = 'Levenberg-Marquardt';
optsmid_max3newdown.Display = 'Off';
optsmid_max3newdown.Robust = 'Bisquare';
optsmid_max3newdown.StartPoint = [10 10];

[fitresult{56}, gof(56)] = fit( xmid_max3newdown, ymid_max3newdown, fitmid_max3newdown, optsmid_max3newdown );

coefficients_mid_max3newdown= coeffvalues(fitresult{56});
fitxmid_max3newdown = ((30:1:hcp));
fitymid_max3newdown = (fitresult{56} (30:1:hcp));

%% tangents to 5PL fit of maximum ratios
% Generate upper horizontal in 5PL max ratios
yuhmax5= (fitresult {52}(10:1:20));
xuhtmax5 = (10:1:20);
xuhmax5=transpose(xuhtmax5);

% Fit upper horizontal line to 5PL max ratios
[xuhmax5, yuhmax5] = prepareCurveData( xuhmax5, yuhmax5 );
fituhmax5 = fittype( 'm*x+c', 'independent', 'x', 'dependent', 'y' );
optsuhmax5 = fitoptions( 'Method', 'NonlinearLeastSquares' );
optsuhmax5.Algorithm = 'Levenberg-Marquardt';
optsuhmax5.Display = 'Off';
optsuhmax5.Robust = 'Bisquare';
optsuhmax5.StartPoint = [ymax_max5 0.1];

[fitresult{59}, gof(59)] = fit( xuhmax5, yuhmax5, fituhmax5, optsuhmax5 );

coefficients_uh_max5= coeffvalues(fitresult{59});
fitxuhmax5 = ((0:1:120));
fityuhmax5 = (fitresult{59} (0:1:120));

%%
y_max5a = yuhmax5 (1,1)* (7/8);
y_max5b = yuhmax5 (1,1)* (3/4);
y_max5new = yuhmax5 (1,1)/2;
y_max5_1=yuhmax5 (1,1)/4;
y_max5_2 = yuhmax5 (1,1)/8;

y_max5b_5new = (y_max5b+y_max5new)/2;
y_max5new_5_1 = (y_max5new+y_max5_1)/2;
%
% Trying another approach
fit_max5a = fit_max5; %Getting the data points of the fitted sigmoid
fit_max5b = fit_max5;
fit_max5new = fit_max5;
fit_max5_1 = fit_max5;
fit_max5_2 = fit_max5;

fit_max5a(:,3) =  abs (fit_max5 (:,2)- y_max5a);%  get the difference between yvalue in the curve and the y level required
fit_max5b(:,3) =  abs (fit_max5 (:,2)- y_max5b);
fit_max5new(:,3) =  abs (fit_max5 (:,2)- y_max5new);
fit_max5_1(:,3) =  abs (fit_max5 (:,2)- y_max5_1);
fit_max5_2(:,3) =    abs (fit_max5 (:,2)- y_max5_2);

% Find the minimum value in the third column
[mindiff_max5a, minindex_max5a] = min(fit_max5a(:,3));
[mindiff_max5b, minindex_max5b] = min(fit_max5b(:,3));
[mindiff_max5_new, minindex_max5_new] = min(fit_max5new(:,3));
[mindiff_max5_1, minindex_max5_1] = min(fit_max5_1(:,3));
[mindiff_max5_2, minindex_max5_2] = min(fit_max5_2(:,3));

% Get the corresponding value in the first column
x_max5a =  fit_max5a(minindex_max5a, 1);
x_max5b =  fit_max5b(minindex_max5b, 1);
x_max5new =  fit_max5new(minindex_max5_new, 1);
x_max5_1 =  fit_max5_1(minindex_max5_1, 1);
x_max5_2 =  fit_max5_2(minindex_max5_2, 1);
%%
% Generate midtangent 'up' in 5PL
ymid_max5newup= (fitresult{52}(x_max5a:0.2: x_max5b+5));
xmidt_max5newup = (x_max5a :0.2: x_max5b+5);
xmid_max5newup=transpose(xmidt_max5newup);
[xmid_max5newup, ymid_max5newup] = prepareCurveData( xmid_max5newup, ymid_max5newup );

% Fit mid tangentnew to 5PL  ratios.
[xmid_max5newup, ymid_max5newup] = prepareCurveData(xmid_max5newup, ymid_max5newup );

fitmid_max5newup = fittype( 'm*x+c', 'independent', 'x', 'dependent', 'y' );
optsmid_max5newup = fitoptions( 'Method', 'NonlinearLeastSquares' );
optsmid_max5newup.Algorithm = 'Levenberg-Marquardt';
optsmid_max5newup.Display = 'Off';
optsmid_max5newup.Robust = 'Bisquare';
optsmid_max5newup.StartPoint = [10 10];

[fitresult{60}, gof(60)] = fit( xmid_max5newup, ymid_max5newup, fitmid_max5newup, optsmid_max5newup);

coefficients_mid_max5newup= coeffvalues(fitresult{60});
fitxmid_max5newup = ((30:1:hcp));
fitymid_max5newup = (fitresult{60} (30:1:hcp));

%%
% Generate midtangent 'new' in 5PL
ymid_max5new = (fitresult{52}(x_max5new-2:0.2: x_max5new+3));
xmidt_max5new = (x_max5new-2 :0.2: x_max5new+3);
xmid_max5new=transpose(xmidt_max5new);
[xmid_max5new, ymid_max5new] = prepareCurveData( xmid_max5new, ymid_max5new );

% Fit mid tangentnew to 5PL  ratios.
fitmid_max5new = fittype( 'm*x+c', 'independent', 'x', 'dependent', 'y' );
optsmid_max5new = fitoptions( 'Method', 'NonlinearLeastSquares' );
optsmid_max5new.Algorithm = 'Levenberg-Marquardt';
optsmid_max5new.Display = 'Off';
optsmid_max5new.Robust = 'Bisquare';
optsmid_max5new.StartPoint = [10 10];

[fitresult{62}, gof(62)] = fit( xmid_max5new, ymid_max5new, fitmid_max5new, optsmid_max5new);

coefficients_mid_max5new= coeffvalues(fitresult{62});
fitxmid_max5new = ((30:1:hcp));
fitymid_max5new = (fitresult{62} (30:1:hcp));

%%
% Generate midtangent 'down' in 5PL
ymid_max5newdown  = (fitresult{52}(x_max5_1:0.2: x_max5_2+1)); %(The plus 1 in the second term is to avoid situations where  both 5_1 and 5_2 are equal)
xmidt_max5newdown =               (x_max5_1 :0.2: x_max5_2+1);

xmid_max5newdown=transpose(xmidt_max5newdown);
[xmid_max5newdown, ymid_max5newdown] = prepareCurveData( xmid_max5newdown, ymid_max5newdown );

% Fit mid tangentnew to 5PL  ratios.
[xmid_max5newdown, ymid_max5newdown] = prepareCurveData(xmid_max5newdown, ymid_max5newdown );

fitmid_max5newdown = fittype( 'm*x+c', 'independent', 'x', 'dependent', 'y' );
optsmid_max5newdown = fitoptions( 'Method', 'NonlinearLeastSquares' );
optsmid_max5newdown.Algorithm = 'Levenberg-Marquardt';
optsmid_max5newdown.Display = 'Off';
optsmid_max5newdown.Robust = 'Bisquare';
optsmid_max5newdown.StartPoint = [10 10];

[fitresult{61}, gof(61)] = fit( xmid_max5newdown, ymid_max5newdown, fitmid_max5newdown, optsmid_max5newdown);

coefficients_mid_max5newdown= coeffvalues(fitresult{61});
fitxmid_max5newdown = ((30:1:hcp));
fitymid_max5newdown = (fitresult{61} (30:1:hcp));

%%
%figure (14)
%hold on

%plot(x4Data, y4Data, 'o', 'MarkerSize', 3, 'color', 'b'); %minratios

%hmin3 = plot(fitresult{27}); % min3 sigmoid
%set (hmin3, 'color','b','LineStyle', '-');

%hmin3uh = plot (fitresult {29}); % min3uh
%set (hmin3uh, 'color','b','LineStyle', '-');

%hmin3new = plot(fitresult {30});%min3new
%set (hmin3new, 'color','b','LineStyle', ':');

%hmin3newup = plot(fitresult {31}); %min3newup
%set (hmin3newup, 'color','b','LineStyle', '-.');

%hmin3newdown = plot(fitresult {32}); %min3newdown
%set (hmin3newdown, 'color','b','LineStyle', '--');

%hmin5 = plot(fitresult{28}); % min5 sigmoid
%set (hmin5, 'color','m','LineStyle', '-');

%hmin5uh = plot (fitresult {45}); % min5uh
%set (hmin5uh, 'color','m','LineStyle', '-');

%hmin5newup = plot(fitresult {46}); %min5newup
%set (hmin5newup, 'color','m','LineStyle', '-.');

%hmin5new = plot(fitresult {48});%min5new
%set (hmin5new, 'color','m','LineStyle', ':');

%hmin5newdown = plot(fitresult {47}); %min5newdown
%set (hmin5newdown, 'color','m','LineStyle', '--');

%hold off

%xlabel('cuff pressure');
%ylabel('PPG min ratios');
%legend ('min ratios');
%title (expt_id);

%xticks(0: 10: 1000)
%set(gca,'XMinorTick','on','YMinorTick','on')
%grid on

%line([20, hcp], [min(y4Data), min(y4Data)], 'Color', 'k', 'LineStyle', '-'); % Line of lowest
%ylim ([0 max(y4Data)+0.1]);
%saveas(gcf,[expt_id 'fig14.fig']);

%%
%figure (15)
%hold on

%plot(x5Data, y5Data, 'o', 'MarkerSize', 4, 'color', 'r'); % maxratios

%hmax3 = plot(fitresult{51}); % max3 sigmoid
%set (hmax3, 'color','b','LineStyle', '-');

%hmax3uh = plot (fitresult {53}); % max3uh
%set (hmax3uh, 'color', 'b','LineStyle', '-');

%hmax3new = plot(fitresult {54});%max3new
%set (hmax3new, 'color','b','LineStyle', ':');

%hmax3newup = plot(fitresult {55}); %max3newup
%set (hmax3newup, 'color','b','LineStyle', '-.');

%hmax3newdown = plot(fitresult {56}); %max3newdown
%set (hmax3newdown, 'color','b','LineStyle', '--');

%hmax5 = plot(fitresult{52}); % max5 sigmoid
%set (hmax5, 'color','r','LineStyle', '-');

%hmax5uh = plot (fitresult {59}); % max5uh
%set (hmax5uh, 'color', 'r','LineStyle', '--');

%hmax5newup = plot(fitresult {60}); %max5newup
%set (hmax5newup, 'color','r','LineStyle', '-.');

%hmax5new = plot(fitresult {62});%max3new
%set (hmax5new, 'color','m','LineStyle', ':');

%hmax5newdown = plot(fitresult {61}); %max5newdown
%set (hmax5newdown, 'color','r','LineStyle', '--');

%hold off

%xlabel('cuff pressure');
%ylabel('PPG max ratios');
%legend ('max ratios');
%title (expt_id);

%xticks(0: 10: 1000)
%set(gca,'XMinorTick','on','YMinorTick','on')
%grid on

%line([20, hcp], [min(y5Data), min(y5Data)], 'Color', 'k', 'LineStyle', '-'); % Line of lowest
%ylim ([0 max(y5Data)+0.1]);
%saveas(gcf,[expt_id 'fig15.fig']);

%%
dx_max5down = diff(fitxmid_max5newdown);
dy_max5down  = diff(fitymid_max5newdown);
Slope_max5down_for = dy_max5down./dx_max5down;
Slope_max5down = Slope_max5down_for(1,1);

dx_min5down = diff(fitxmid_min5newdown);
dy_min5down  = diff(fitymid_min5newdown);
Slope_min5down_for = dy_min5down./dx_min5down;
Slope_min5down = Slope_min5down_for(1,1);

dx_min3down = diff(fitxmid_min3newdown);
dy_min3down  = diff(fitymid_min3newdown);
Slope_min3down_for = dy_min3down./dx_min3down;
Slope_min3down = Slope_min3down_for(1,1);

dx_max3down = diff(fitxmid_max3newdown);
dy_max3down  = diff(fitymid_max3newdown);
Slope_max3down_for = dy_max3down./dx_max3down;
Slope_max3down = Slope_max3down_for(1,1);

dx_max5up = diff(fitxmid_max5newup);
dy_max5up  = diff(fitymid_max5newup);
Slope_max5up_for = dy_max5up./dx_max5up;
Slope_max5up = Slope_max5up_for(1,1);

dx_min5up = diff(fitxmid_min5newup);
dy_min5up  = diff(fitymid_min5newup);
Slope_min5up_for = dy_min5up./dx_min5up;
Slope_min5up = Slope_min5up_for(1,1);

dx_min3up = diff(fitxmid_min3newup);
dy_min3up  = diff(fitymid_min3newup);
Slope_min3up_for = dy_min3up./dx_min3up;
Slope_min3up = Slope_min3up_for(1,1);

dx_max3up = diff(fitxmid_max3newup);
dy_max3up  = diff(fitymid_max3newup);
Slope_max3up_for = dy_max3up./dx_max3up;
Slope_max3up = Slope_max3up_for(1,1);

%%
uhintercept_min3up  = round((coefficients_mid_min3newup(1,1) - coefficients_uh_min3 (1,1))/(coefficients_uh_min3(1,2)- coefficients_mid_min3newup(1,2)));
uhintercept_min3new  = round((coefficients_mid_min3new(1,1) - coefficients_uh_min3 (1,1))/(coefficients_uh_min3(1,2)- coefficients_mid_min3new(1,2)));
uhintercept_min3down  = round((coefficients_mid_min3newdown(1,1) - coefficients_uh_min3 (1,1))/(coefficients_uh_min3(1,2)- coefficients_mid_min3newdown(1,2)));

uhintercept_min5up  = round((coefficients_mid_min5newup(1,1) - coefficients_uh_min5 (1,1))/(coefficients_uh_min5(1,2)- coefficients_mid_min5newup(1,2)));
uhintercept_min5new  = round((coefficients_mid_min5new(1,1) - coefficients_uh_min5 (1,1))/(coefficients_uh_min5(1,2)- coefficients_mid_min5new(1,2)));
uhintercept_min5down = round((coefficients_mid_min5newdown(1,1) - coefficients_uh_min5 (1,1))/(coefficients_uh_min5(1,2)- coefficients_mid_min5newdown(1,2)));

if abs(Slope_min3up) > 0.002
    X_intercept_min3up = round(fzero(fitresult{31}, [xmin3new, hcp+50]));
else
    X_intercept_min3up = NaN;
end

X_intercept_min3new = round(fzero(fitresult{30}, [xmin3new, hcp+50]));

if abs(Slope_min3down) > 0.002
    X_intercept_min3down = round(fzero(fitresult{32}, [xmin3new, hcp+50]));
else
    X_intercept_min3down = NaN;
end

if abs(Slope_min5up) > 0.002
    X_intercept_min5up = round(fzero(fitresult{46}, [x_min5new, hcp+50]));% note this has been set to x3new
else
    X_intercept_min5up = NaN;
end

X_intercept_min5new = round(fzero(fitresult{48}, [x_min5new, hcp+50]));

try
    if abs(Slope_min5down) > 0.002
        X_intercept_min5down = round(fzero(fitresult{47}, [xmin3new, hcp+50]));% note this has been set to x3new
    else
        X_intercept_min5down = NaN;
    end
catch ME
end

if ~exist('X_intercept_min5down','var')
    X_intercept_min5down=NaN;
end
%%
uhintercept_max3up    = round((coefficients_mid_max3newup(1,1)   - coefficients_uh_max3 (1,1)) /(coefficients_uh_max3(1,2)- coefficients_mid_max3newup(1,2)));
uhintercept_max3new   = round((coefficients_mid_max3new(1,1)     - coefficients_uh_max3 (1,1)) /(coefficients_uh_max3(1,2)- coefficients_mid_max3new(1,2)));
uhintercept_max3down  = round((coefficients_mid_max3newdown(1,1) - coefficients_uh_max3 (1,1)) /(coefficients_uh_max3(1,2)- coefficients_mid_max3newdown(1,2)));

uhintercept_max5up   = round((coefficients_mid_max5newup(1,1)  - coefficients_uh_max5 (1,1))/(coefficients_uh_max5(1,2)- coefficients_mid_max5newup(1,2)));
uhintercept_max5new  = round((coefficients_mid_max5new(1,1)    - coefficients_uh_max5 (1,1))/(coefficients_uh_max5(1,2)- coefficients_mid_max5new(1,2)));
uhintercept_max5down = round((coefficients_mid_max5newdown(1,1)- coefficients_uh_max5 (1,1))/(coefficients_uh_max5(1,2)- coefficients_mid_max5newdown(1,2)));

X_intercept_max3new = round(fzero(fitresult{54}, [xmax3new, hcp+50]));

if abs(Slope_max3down) > 0.002
    X_intercept_max3down = round(fzero(fitresult{56}, [xmax3new, hcp+50]));
else
    X_intercept_max3down=NaN;
end

X_intercept_max5new = round(fzero(fitresult{62}, [x_max5new, hcp+100]));

if abs(Slope_max5down) > 0.002
    X_intercept_max5down = round(fzero(fitresult{61}, [x_max5new-10, hcp+300])); % note this has been set to x3new
else
    X_intercept_max5down=NaN;
end

% Xintercepts of up tangents are not used anywhere. See if they can be
% sidelined.
try
    if abs(Slope_max3up) > 0.002
        X_intercept_max3up = round(fzero(fitresult{55}, [xmax3new-10, hcp+50]));
    else
        X_intercept_max3up = NaN;
    end
catch ME
end

try
    if abs(Slope_max5up) > 0.002
        X_intercept_max5up = round(fzero(fitresult{60}, [x_max5new, hcp+50]));% note this has been set to x3new
    else
        X_intercept_max5up=NaN;
    end
catch ME
end

if ~exist ('X_intercept_max3up', 'var')
    X_intercept_max3up= NaN;
end

if ~exist ('X_intercept_max5up', 'var')
    X_intercept_max5up= NaN;
end

X_interceptsMin3 = [X_intercept_min3up; X_intercept_min3new; X_intercept_min3down];
X_interceptsMax3 = [X_intercept_max3up; X_intercept_max3new; X_intercept_max3down];

X_interceptsMin5 = [X_intercept_min5up; X_intercept_min5new; X_intercept_min5down];
X_interceptsMax5 = [X_intercept_max5up; X_intercept_max5new; X_intercept_max5down];

X_interceptsMin = [ X_interceptsMin3,  X_interceptsMin5];

Table_Xintercepts_tangents = [X_interceptsMin3, X_interceptsMin5, X_interceptsMax3,X_interceptsMax5];
Table_Xintercepts_tangents1 =  Table_Xintercepts_tangents;

for i = 1:3
    if isnan(Table_Xintercepts_tangents1(i, 1))
        Table_Xintercepts_tangents1(i, 1)=Table_Xintercepts_tangents1(i, 2);
    end
    
    if isnan(Table_Xintercepts_tangents1(i, 2))
        Table_Xintercepts_tangents1(i, 2)=Table_Xintercepts_tangents1(i, 1);
    end
    
    if isnan(Table_Xintercepts_tangents1(i, 3))
        Table_Xintercepts_tangents1(i, 3)=Table_Xintercepts_tangents1(i, 4);
    end
    
    if isnan(Table_Xintercepts_tangents1(i, 4))
        Table_Xintercepts_tangents1(i, 4)=Table_Xintercepts_tangents1(i, 3);
    end
end

%%
% Collecting all results and reporting
Xmin_down = round((X_intercept_min3down + X_intercept_min5down)/2);
Xmax_down = round((X_intercept_max3down + X_intercept_max5down)/2);

Xmin_new = round((X_intercept_min3new+ X_intercept_min5new)/2);
Xmax_new = round((X_intercept_max3new+ X_intercept_max5new)/2);

Xmin_up = round ((X_intercept_min3up+X_intercept_min5up)/2);
Xmax_up = round ((X_intercept_max3up+X_intercept_max5up)/2);

UHmin_up = round((uhintercept_min3up + uhintercept_min5up)/2);
UHmax_up = round((uhintercept_max3up + uhintercept_max5up)/2);

UHmin_new = round((uhintercept_min3new + uhintercept_min5new)/2);
UHmax_new = round((uhintercept_max3new + uhintercept_max5new)/2);

UHmin_down = round((uhintercept_min3down + uhintercept_min5down)/2);
UHmax_down = round((uhintercept_max3down + uhintercept_max5down)/2);

%%
%Fit data to a third degree polynomial'.
% Set up fittype and options.
fitpolymin = fittype('a*x^3 + b*x^2 + c*x + d', 'independent', 'x', 'dependent', 'y');
optspolymin = fitoptions( 'Method', 'NonlinearLeastSquares' );
optspolymin.Algorithm = 'Levenberg-Marquardt';
poly.Display = 'Off';
optspolymin.Robust = 'Bisquare';
optspolymin.StartPoint = [10 1 1 1];% changed

% Fit model to data.
[fitresult{63}, gof(63)] = fit( x4Data, y4Data, fitpolymin, optspolymin );
coefficientspoly_min= coeffvalues(fitresult{63});
%
fitx_polymin = (lcp:1:hcp+30);
fitx_polymin = fitx_polymin';
fity_polymin = fitresult{63}(lcp:1:hcp+30);
fit_polymin = [fitx_polymin,fity_polymin]; % fit polymin from lowest cuff pressure to highest cuff pressure + 30

[pk_fitpolymin, loc_pk_fitpolymin]   = findpeaks ( fit_polymin (:,2), fit_polymin (:,1));
[trf_fitpolymin, loc_trf_fitpolymin] = findpeaks (-fit_polymin (:,2), fit_polymin (:,1));

if ~exist('loc_pk_fitpolymin', 'var') | loc_pk_fitpolymin > loc_trf_fitpolymin
    loc_pk_fitpolymin = [];
end

for i = 1:size(fit_polymin ,1)-1
    if  fit_polymin(i+1,2)<0 && fit_polymin (i,2)>0 || fit_polymin (i,2) ==0 % find first zero crossing
        X_intercept_poly_min = fit_polymin(i+1,1);
        break; %report first zero crossing
        % if there is no zero crossing, report trough
    else
        X_intercept_poly_min = loc_trf_fitpolymin;
    end
end

%%
%FInd the lower diastolic pressure by taking the UH intercept of the third degree polynomial. Can use UH of the 3PL sigmoid

% For this, it is necessary to make the UH as X axis. Or subtract the y intercept of the UH
yforpoly_min3low(:,1) = y4Data;
yforpoly_min3low (:,2) = yuhmin3(1,1);
yforpoly_min3low (:,3) = yforpoly_min3low(:,1)- yforpoly_min3low(:,2);

% Set up fittype and options.
fit_typepoly_min3low = fittype('a*x^3 + b*x^2 + c*x + d', 'independent', 'x', 'dependent', 'y');
optspoly_min3low = fitoptions( 'Method', 'NonlinearLeastSquares' );
optspoly_min3low.Algorithm = 'Levenberg-Marquardt';
poly.Display = 'Off';
optspoly_min3low.Robust = 'Bisquare';
optspoly_min3low.StartPoint = [10 1 1 1];% changed

% Fit model to data.
[fitresult{64}, gof(64)] = fit( x4Data, yforpoly_min3low(:,3), fit_typepoly_min3low, optspoly_min3low );

coefficientspoly_min3low= coeffvalues(fitresult{64});

fitx_poly_min3low = lcp:1:hcp;
fitx_poly_min3low =fitx_poly_min3low';
fity_poly_min3low = fitresult{64}(lcp:1:hcp);
fit_poly_min3low = [fitx_poly_min3low, fity_poly_min3low];

[pk_fitpoly_min3low, loc_pk_fitpoly_min3low] = findpeaks (fit_poly_min3low (:,2), fit_poly_min3low (:,1));
[trf_fitpoly_min3low, loc_trf_fitpoly_min3low] = findpeaks (-fit_poly_min3low (:,2), fit_poly_min3low (:,1));

if ~exist('loc_pk_fitpoly_min3low', 'var') | loc_pk_fitpoly_min3low > loc_trf_fitpoly_min3low
    loc_pk_fitpoly_min3low = [];
end

for i = 1:size(fit_poly_min3low ,1)-1
    if  fit_poly_min3low (i,2)>=0 && fit_poly_min3low(i+1,2)<0 %|| fit_poly_min3low (i,2) ==0 % find first zero crossing
        UH_intercept_poly_min3 = fit_poly_min3low(i,1);
        
        break % There will be 2 zero crossings for poly min3low. THe if condition already selects the second crossing
        
    else
        UH_intercept_poly_min3 = loc_pk_fitpoly_min3low;
    end
end

%%
% For this, it is necessary to make the UH as X axis. Or subtract the y
% intercept of the UH
yforpoly_min5low(:,1) = y4Data;
yforpoly_min5low (:,2) = yuhmin5(1,1);
yforpoly_min5low (:,3) = yforpoly_min5low(:,1)- yforpoly_min5low(:,2);

% Set up fittype and options.
fitpoly_min5low = fittype('a*x^3 + b*x^2 + c*x + d', 'independent', 'x', 'dependent', 'y');
optspoly_min5low = fitoptions( 'Method', 'NonlinearLeastSquares' );
optspoly_min5low.Algorithm = 'Levenberg-Marquardt';
poly.Display = 'Off';
optspoly_min5low.Robust = 'Bisquare';
optspoly_min5low.StartPoint = [10 1 1 1];% changed

% Fit model to data.
[fitresult{65}, gof(65)] = fit( x4Data, yforpoly_min5low(:,3), fitpoly_min5low, optspoly_min5low );

coefficientspoly_min5low= coeffvalues(fitresult{65});

fitx_poly_min5low = [lcp:1:hcp];
fitx_poly_min5low =fitx_poly_min5low';
fity_poly_min5low = fitresult{65}(lcp:1:hcp);
fit_poly_min5low = [fitx_poly_min5low, fity_poly_min5low];

[pk_fitpoly_min5low, loc_pk_fitpoly_min5low] = findpeaks (fit_poly_min5low (:,2), fit_poly_min5low (:,1));
[trf_fitpoly_min5low, loc_trf_fitpoly_min5low] = findpeaks (-fit_poly_min5low (:,2), fit_poly_min5low (:,1));

if ~exist('loc_pk_fitpoly_min5low', 'var') | loc_pk_fitpoly_min5low > loc_trf_fitpoly_min5low
    loc_pk_fitpoly_min5low = [];
end

for i = 1:size(fit_poly_min5low ,1)-1
    if   fit_poly_min5low (i,2)>= 0 && fit_poly_min5low(i+1,2)<0 %|| fit_poly_min5low (i,2) ==0 % find second zero crossing
        UH_intercept_poly_min5 = fit_poly_min5low(i,1); % for the if condition, this is already the second crossing
        break
    else
        UH_intercept_poly_min5 = loc_pk_fitpoly_min5low;
    end
end

%%
%Fit data to a third degree polynomial'.
% Set up fittype and options.
fitpolymax = fittype('a*x^3 + b*x^2 + c*x + d', 'independent', 'x', 'dependent', 'y');
optspolymax = fitoptions( 'Method', 'NonlinearLeastSquares' );
optspolymax.Algorithm = 'Levenberg-Marquardt';
poly.Display = 'Off';
optspolymax.Robust = 'Bisquare';
optspolymax.StartPoint = [10 1 1 1];% changed

% Fit model to data.
[fitresult{66}, gof(66)] = fit( x5Data, y5Data, fitpolymax, optspolymax );
coefficientspoly_max= coeffvalues(fitresult{66});

fitx_polymax = (lcp:1:hcp+30);
fitx_polymax = fitx_polymax';
fity_polymax = fitresult{66}(lcp:1:hcp+30);
fit_polymax = [fitx_polymax,fity_polymax];

[pk_fitpolymax, loc_pk_fitpolymax] = findpeaks (fit_polymax (:,2), fit_polymax (:,1));
[trf_fitpolymax, loc_trf_fitpolymax] = findpeaks (-fit_polymax (:,2), fit_polymax (:,1));

if ~exist('loc_pk_fitpolymax', 'var') | loc_pk_fitpolymax > loc_trf_fitpolymax
    loc_pk_fitpolymax = [];
end

for i = 1:size(fit_polymax,1)-1
    if  fit_polymax(i+1,2)<0 && fit_polymax (i,2)>0 || fit_polymax (i,2) ==0% find first zero crossing
        X_intercept_poly_max = fit_polymax (i+1);
        break; %report first zero crossing
        % if there is no zero crossing, report trough
    else
        X_intercept_poly_max = loc_trf_fitpolymax;
    end
end

if isempty(loc_pk_fitpolymin)% Just being sure, since sometimes it is empty. It is used a lot later
    loc_pk_fitpolymin = loc_pk_fitpolymax;
end

if isempty (loc_pk_fitpolymax)
    loc_pk_fitpolymax = loc_pk_fitpolymin;
end
%%
%FInd the lower diastolic pressure by taking the UH intercept of the third degree polynomial. Can use UH of the 3PL sigmoid

% For this, it is necessary to make the UH as X axis. Or subtract the y intercept of the UH

yforpoly_max3low(:,1) = y5Data;
yforpoly_max3low (:,2) = yuhmax3(1,1);
yforpoly_max3low (:,3) = yforpoly_max3low(:,1)- yforpoly_max3low(:,2);

% Set up fittype and options.
fitpoly_max3low = fittype('a*x^3 + b*x^2 + c*x + d', 'independent', 'x', 'dependent', 'y');
optspoly_max3low = fitoptions( 'Method', 'NonlinearLeastSquares' );
optspoly_max3low.Algorithm = 'Levenberg-Marquardt';
poly.Display = 'Off';
optspoly_max3low.Robust = 'Bisquare';
optspoly_max3low.StartPoint = [10 1 1 1];% changed

% Fit model to data.
[fitresult{67}, gof(67)] = fit( x5Data, yforpoly_max3low(:,3), fitpoly_max3low, optspoly_max3low );

coefficientspoly_max3low= coeffvalues(fitresult{67});

fitx_poly_max3low = [lcp:1:hcp];
fitx_poly_max3low =fitx_poly_max3low';
fity_poly_max3low = fitresult{67}(lcp:1:hcp);
fit_poly_max3low = [fitx_poly_max3low, fity_poly_max3low];

[pk_fitpoly_max3low, loc_pk_fitpoly_max3low] = findpeaks (fit_poly_max3low (:,2), fit_poly_max3low (:,1));
[trf_fitpoly_max3low, loc_trf_fitpoly_max3low] = findpeaks (-fit_poly_max3low (:,2), fit_poly_max3low (:,1));

if ~exist('loc_pk_fitpoly_max3low', 'var') | loc_pk_fitpoly_max3low > loc_trf_fitpoly_max3low
    loc_pk_fitpoly_max3low = [];
end

for i = 1:size(fit_poly_max3low ,1)-1
    if  fit_poly_max3low(i+1,2)<0 && fit_poly_max3low (i,2)>0 || fit_poly_max3low (i,2) ==0 % find first zero crossing
        UH_intercept_poly_max3 = fit_poly_max3low(i+1,1);
        
        break; %report first zero crossing
        % if there is no zero crossing, report peak
    else
        UH_intercept_poly_max3 = loc_pk_fitpoly_max3low;
    end
end

%%         %%
% For this, it is necessary to make the UH as X axis. Or subtract the y
% intercept of the UH

yforpoly_max5low(:,1) = y5Data;
yforpoly_max5low (:,2) = yuhmax5(1,1);
yforpoly_max5low (:,3) = yforpoly_max5low(:,1)- yforpoly_max5low(:,2);

yforpoly_max5_UHmin_low (:,1) = y5Data;
yforpoly_max5_UHmin_low (:,2) = yuhmin5(1,1);
yforpoly_max5_UHmin_low (:,3) =  yforpoly_max5_UHmin_low (:,1)- yforpoly_max5_UHmin_low (:,2);

% Set up fittype and options.
fit_type_poly_max5low = fittype('a*x^3 + b*x^2 + c*x + d', 'independent', 'x', 'dependent', 'y');
optspoly_max5low = fitoptions( 'Method', 'NonlinearLeastSquares' );
optspoly_max5low.Algorithm = 'Levenberg-Marquardt';
poly.Display = 'Off';
optspoly_max5low.Robust = 'Bisquare';
optspoly_max5low.StartPoint = [10 1 1 1];% changed

% Fit model to data.
[fitresult{68}, gof(68)] = fit( x5Data, yforpoly_max5low(:,3), fit_type_poly_max5low, optspoly_max5low );
coefficientspoly_max5low= coeffvalues(fitresult{68});

fitx_poly_max5low = [lcp:1:hcp];
fitx_poly_max5low =fitx_poly_max5low';
fity_poly_max5low = fitresult{68}(lcp:1:hcp);
fit_poly_max5low = [fitx_poly_max5low, fity_poly_max5low];

[pk_fitpoly_max5low, loc_pk_fitpoly_max5low] =   findpeaks (fit_poly_max5low (:,2), fit_poly_max5low (:,1));
[trf_fitpoly_max5low, loc_trf_fitpoly_max5low] = findpeaks (-fit_poly_max5low (:,2), fit_poly_max5low (:,1));

if ~exist('loc_pk_fitpoly_max5low', 'var') | loc_pk_fitpoly_max5low > loc_trf_fitpoly_max5low
    loc_pk_fitpoly_max5low = [];
end
for i = 1:size(fit_poly_max5low ,1)-1
    if  fit_poly_max5low(i+1,2)<0 && fit_poly_max5low (i,2)>0 || fit_poly_max5low (i,2) ==0 % find first zero crossing
        UH_intercept_poly_max5 = fit_poly_max5low(i+1,1);
        
        break; %report first zero crossing
        % if there is no zero crossing, report trough
    else
        UH_intercept_poly_max5 = loc_pk_fitpoly_max5low;
    end
end
%%
%figure (21)
%hold on

%plot(x4Data, y4Data, 'o', 'MarkerSize', 3, 'color', 'b'); %minratios
%plot(x5Data, y5Data, 'o', 'MarkerSize', 4, 'color', 'r'); % maxratios

%hminpoly = plot (fitresult{63});
%set (hminpoly, 'color', 'b', 'LineStyle', ':'); % Fitted polynomial

%hminpolylow3 = plot (fitresult{64});
%set (hminpolylow3, 'color', 'c', 'LineStyle', '-'); % Fitted polynomial for UHmin3intercept

%hminpolylow5 = plot (fitresult{65});
%set (hminpolylow5, 'color', 'b', 'LineStyle', '-.'); % Fitted polynomial for UHmin5 intercept

%hmaxpoly = plot (fitresult{66});
%set (hmaxpoly, 'color', 'r', 'LineStyle', ':'); % Fitted polynomial

%hmaxpolylow3 = plot (fitresult{67});
%set (hmaxpolylow3, 'color', 'm', 'LineStyle', '-'); % Fitted polynomial for UHmax3 intercept

%hmaxpolylow5 = plot (fitresult{68});
%set (hmaxpolylow5, 'color', 'r', 'LineStyle', '-.'); % Fitted polynomial for UHmax5 intercept

%hold off

%xlabel('cuff pressure');
%ylabel('PPG min and max ratios');

%legend ('third degree polynomial fit of min and max ratios');
%title (expt_id);

%xticks([0: 10: 1000])
%set(gca,'XMinorTick','on','YMinorTick','on')
%grid on
%ylim ([0 max(y5Data)+0.1]);

%saveas(gcf,[expt_id 'fig21.fig']);

%%
%Collect UH intercepts of poly (3 and 5), polymin (3 and 5) and polymax (3
%and 5)

labelUHpolymin = {'UHpolymin3', 'UHpolymin5'};
labelUHpolymin = string (labelUHpolymin)';
resultsUHpolymin = [round(UH_intercept_poly_min3),round(UH_intercept_poly_min5)]';

labelUHpolymax = {'UHpolymax3','UHpolymax5'};
labelUHpolymax = string (labelUHpolymax)';
resultsUHpolymax = [round(UH_intercept_poly_max3), round(UH_intercept_poly_max5)]';

diaPolymin = round(mean (resultsUHpolymin)); % This has been entered as avvg_UHpolymin in the next section
diaPolymax = round(mean (resultsUHpolymax));

if ~exist('diaPolymin', 'var')|| isempty(diaPolymin)
    diaPolymin = diaPolymax-4;
end

%%
labelXpolymin = {'Xpolymin'};
labelXpolymin = string (labelXpolymin)';

labelXpolymax = {'Xpolymax'};
labelXpolymax = string (labelXpolymax)';
X_intercepts_polyminmax = [labelXpolymin , round(X_intercept_poly_min), labelXpolymax, round(X_intercept_poly_max)];

midpoint_polymin = (X_intercept_poly_min + diaPolymin)/2;
midpoint_polymax = (X_intercept_poly_max + diaPolymax)/2;

%%
% Number of oscillations can exceed the number of arterial pulses. Delete
% the smaller oscillations ()
pulsesTotal(:,1) = [pktrfboth5{:,2}]';
pulsesTotal(:,2) = [pktrfboth5{:,3}]';
pulsesTotal(:,3) = [pktrfboth5{:,10}]';

for i = 1:min([size(pktrf_Osc_b,1),size(pulsesTotal,1)])
    %for i = 1:size(pulsesTotal,1)
    pulsesTotal(i,4) =pulsesTotal(i,2)+pulsesTotal(i,3);
    pulsesTotal(i,5)=size(pktrf_Osc_b{i,1},1);
    pulsesTotal(i,6) =pulsesTotal(i,4)- pulsesTotal(i,5);
end

if any(pulsesTotal(:,6)<0)
    for  i = 1:size(pktrf_Osc_b,1)
        if ~isempty(pktrf_Osc_b{i,1})
            for j=1:size(pulsesTotal,1)
                for k=1:size(pktrf_Osc_b{i,1},1)
                    if pulsesTotal(j,6)<0
                        pktrf_Osc_b{i,1}(:,10)=pktrf_Osc_b{i,1}(:,9)<pktrf_Osc_b{i,3}*0.8;
                        if pktrf_Osc_b{i,1}(k,10)==1
                            pktrf_Osc_b{i,1}(k,:)=0;
                        end
                    end
                end
            end
            pktrf_Osc_b{i,1}(:,10)=[];
        end
    end
end

for j = 1:size(pktrf_Osc_b,1)
    temp_Osc = pktrf_Osc_b{j,1};
    idx_Osc = ~any(temp_Osc==0, 2); % Find the rows without zero entries using logical indexing
    temp_Osc = temp_Osc(idx_Osc,:); % Select the rows without zero entries using logical indexing
    pktrf_Osc_b{j,1} = temp_Osc; % Assign the modified array back to the j-th cell of pktrf_Osc_a
end

%for i = 1:size(pulsesTotal,1)
for i = 1:min([size(pktrf_Osc_b,1),size(pulsesTotal,1)])
    pulsesTotal(i,7)=size(pktrf_Osc_b{i,1},1);
    pulsesTotal(i,8)=pulsesTotal(i,4)- pulsesTotal(i,7);
end


for i = 1:size(pktrf_Osc_b, 1)
    pktrf_Osc_b{i,3}= mean(pktrf_Osc_b{i, 1}(:,9)); % mean oscillation amplitude
    pktrf_Osc_b{i,4}= min(pktrf_Osc_b{i, 1}(:,9)); % min oscillation amplitude
    pktrf_Osc_b{i,5}= max( pktrf_Osc_b{i, 1}(:,9)); % max oscillation amplitude
end

%copying into another matrix
for i=1:size( pktrf_Osc_b,1)
    for_pktrf_Osc_b_mat{i,1}= pktrf_Osc_b{i,2}; % cuff pressure
    for_pktrf_Osc_b_mat{i,2}= pktrf_Osc_b{i,3}; % mean osc amp
    for_pktrf_Osc_b_mat{i,3}= pktrf_Osc_b{i,4}; % min osc amp
    for_pktrf_Osc_b_mat{i,4}= pktrf_Osc_b{i,5}; % max osc amp
end

%Remove empty rows

EmptyRows_pktrf_osc_b = any(cellfun(@isempty, for_pktrf_Osc_b_mat), 2);
for_pktrf_Osc_b_mat1 = for_pktrf_Osc_b_mat(~EmptyRows_pktrf_osc_b, :);

pktrf_Osc_b_mat = cell2mat(for_pktrf_Osc_b_mat1);

%Fit Oscillation amplitude vs cuff pressure with smoothing spline
cuffPresOsc = pktrf_Osc_b_mat(:,1);
meanOsc = pktrf_Osc_b_mat(:,2);
minOsc = pktrf_Osc_b_mat(:,3);
maxOsc = pktrf_Osc_b_mat(:,4);

%%
%figure (17)
%hold on

for i= 1:size(pktrf_Osc_b,1)
%    plot (cell{i,1} (:,1), cell{i,1} (:,2),'color', MediumGreen_1);
%    scatter (pktrf_Osc_b{i,1}(:,2),pktrf_Osc_b{i,1}(:,1));
%    scatter (pktrf_Osc_b{i,1}(:,6), pktrf_Osc_b{i,1}(:,5));
end
%hold off

%xlabel ('time in seconds');
%grid on
%legend 'pktrf_Osc_a';

%title (expt_id);
%saveas(gcf,[expt_id 'fig17.fig']);
%%
%The following is an attempt to understand PPG variability in the reference arm using the
%segments that are already there.
refPPGAmp = ratios;

for j = 1:size(refPPGAmp,1)
    
    minmaxrefmat(j,1) = refPPGAmp{j,2};%cuff pressure
    minmaxrefmat(j,2) = min(refPPGAmp{j,1}(:,2));% minimum ref PPG Amp
    minmaxrefmat(j,3) = max(refPPGAmp{j,1}(:,2));%maximum ref PPG Amp
    minmaxrefmat(j,4) = mean(refPPGAmp{j,1}(:,2));%mean ref PPG Amp
    minmaxrefmat (j,5)=  minmaxrefmat (j,3)- minmaxrefmat (j,2);% difference between min and max
    minmaxrefmat (j,6)=  minmaxrefmat (j,5)*100/ minmaxrefmat (j,2);% difference as percent of min
    minmaxrefmat (j,7)=  minmaxrefmat (j,5)*100/ minmaxrefmat (j,3);% difference as percent of min
end
%%
PPGvar_acrossPlateaus = max(minmaxrefmat(:,3))- min(minmaxrefmat(:,2));
PPGvar_acrossPlateaus_pcOfMin = (PPGvar_acrossPlateaus*100)/min(minmaxrefmat(:,2));
PPGvar_acrossPlateaus_pcOfMax = (PPGvar_acrossPlateaus*100)/max(minmaxrefmat(:,3));
% This would be variability within the plateaus, say 4 seconds. The
% variabilities here are the difference between min and max amplitudes
% expressed as a percent of minumum. Follow same strategy for full ref
% data as well (next part)

PPGvar_acrossPlateaus_prctileamp = prctile(minmaxrefmat(:,3),80)- prctile(minmaxrefmat(:,2), 20);
%PPGvar_acrossPlateaus_prctilepcOfMin = (PPGvar_acrossPlateaus_prctileamp*100)/prctile(minmaxrefmat(:,2), 20);
PPGvar_acrossPlateaus_prctile_pcOfMax = (PPGvar_acrossPlateaus_prctileamp*100)/prctile(minmaxrefmat(:,3),80);

%%
PPG_var_at_plateaus = minmaxrefmat(:,7); % Earlier this was column 6, which was PPG var as percent of min. Column 7 is percent of max
PPG_variability_avg_unfiltered = mean (PPG_var_at_plateaus);

PPG_variability_SD_unfiltered = std(PPG_var_at_plateaus);
PPG_variability_max = max(PPG_var_at_plateaus);
PPG_variability_min = min(PPG_var_at_plateaus);

%%percentile ranges for atPlateaus:
PPGvar_percentile_10_plateaus = prctile(PPG_var_at_plateaus, 10);
PPGvar_percentile_90_plateaus = prctile(PPG_var_at_plateaus, 90);
PPGvar_percentile_80_plateaus = prctile(PPG_var_at_plateaus, 80);
PPGvar_percentile_20_plateaus = prctile(PPG_var_at_plateaus, 20);

% Step 1: Calculate the 25th (Q1) and 75th (Q3) percentiles
Q1 = PPGvar_percentile_20_plateaus; % why do we need a lower value here? as percentile? PPGvar min should be good enough
%Q1 = PPG_variability_min;
Q3 = PPGvar_percentile_80_plateaus;% Do this to avoid huge artifactual PPG amp

% Step 2: Calculate the IQR (Interquartile Range)
IQR = Q3 - Q1;

% Step 3: Calculate the lower and upper bounds
lower_bound = Q1 - 1.5 * IQR;
upper_bound = Q3 + 1.5 * IQR;

filtered_PPG_var_at_plateaus =  PPG_var_at_plateaus(PPG_var_at_plateaus >= lower_bound & PPG_var_at_plateaus <= upper_bound);
PPG_variability_avg = mean(filtered_PPG_var_at_plateaus);
PPG_variability_SD = std(filtered_PPG_var_at_plateaus);
%%
%%Get the variability in PPG amplitudes from the full spectrum of reference
%PPGs - not just the plateaus

%for removing noise in PPG ref

cutoff_freq = 4; % to low pass signals

% Normalize the cutoff frequency with respect to the Nyquist frequency
normalized_cutoff = cutoff_freq / (0.5 * fs);

% Design a 4th-order lowpass Butterworth filter
[b, a] = butter(4, normalized_cutoff);

% Apply the lowpass filter to the selected columns of data using filtfilt
data3 = data1;
data3(:, 3) = filtfilt(b, a, data3(:,3));

% Find peaks in all of reference

for i = size(data3,1):-1:2
    if data3(i,1)< data3(i-1,1)
        if i>12
            stopFor_pref0full = i-10; % Sometimes time falls to zero. Pamelas data 24031803. So this is essential
            break
        end
    else
        stopFor_pref0full = size(data3,1);
    end
end

[pk_r_full,locpk_r_full,w_pk_r_full,p_pk_r_full]= findpeaks(data3(1:stopFor_pref0full,3), data3(1:stopFor_pref0full,1),'minPeakProminence', 0.001);
pref0_full=[pk_r_full,locpk_r_full,w_pk_r_full,p_pk_r_full];

[trf_r_full,loctrf_r_full,w_trf_r_full,p_trf_r_full]= findpeaks (-data3(1:stopFor_pref0full,3), data3(1:stopFor_pref0full,1),'minPeakProminence', 0.001);
trfref0_full=[trf_r_full,loctrf_r_full,w_trf_r_full,p_trf_r_full];

%%    %   To equal the number of peaks and troughs

pktrfcountref_full = abs(size(pref0_full,1)- size(trfref0_full,1));

% If more peaks than troughs, add zeros to troughs

if size(pref0_full,1)> size(trfref0_full,1)
    trfref0_full(end+pktrfcountref_full,:)=0;
end

% If more troughs than peaks, add zeros to peaks

if size(pref0_full,1)< size(trfref0_full,1)
    pref0_full(end+pktrfcountref_full,:)=0;
end

% Check if peak and trough numbers in every plateau is same for cuffed
% arm. The last column in pktrfafter should be 0,0.

pktrfcountref_fullafter = size(pref0_full,1)- size (trfref0_full,1);

% Now that peaks and troughs are the same, we can
% concatenate peaks and troughs

pktrfref0a_full = cat (2, pref0_full, trfref0_full);

%%
% To ensure each peak comes after a trough in ref

pktrfref0c_full = pktrfref0a_full;

for k =1:size(pktrfref0c_full,1)
    if   pktrfref0c_full(k,2) < pktrfref0c_full(k,6)
        addrowref_full(1:8) = zeros; %This is done so that the last ref data in 5:8 does not get deleted
        pktrfref0c_full = [pktrfref0c_full; addrowref_full];
        pktrfref0c_full(k+1:end,5:8)= pktrfref0c_full(k:end-1,5:8);
        pktrfref0c_full(k,5:8)= 0;% This line was 1:4 = 0 earlier. That is incorrect.
    end
end

%%
%To consider false peaks (defined as amplitude < 1/10 of mean amplitude of nonzero entries in that cell) in ref:

pktrfref0b_full = pktrfref0c_full;

% calculate amplitude of peaks
for j = 1: size (pktrfref0b_full,1)
    pktrfref0b_full (j,9) = pktrfref0b_full(j,1)- pktrfref0b_full(j,5); %actual amplitude of peaks
end

%Take mean of amplitudes and enter in second column of the cell array

mean_refAmp= mean(nonzeros(pktrfref0b_full(:,9)));

% Identify amplitudes less than one tenth the mean in each cell

for j = 1: size(pktrfref0b_full,1)
    pktrfref0b_full(j,10)= pktrfref0b_full(j,9) < mean_refAmp/10;% col 10 is logical array
end

pktrfref0d_full = pktrfref0b_full;
pktrfref0_full(:,1:9) = pktrfref0d_full(:,1:9);

% Remove rows with any zeros in columns 1 to 8
rows_with_zeros_ref_full = any(pktrfref0_full(:, 1:8) == 0, 2);
pktrfref0_full_cleaned = pktrfref0_full(~rows_with_zeros_ref_full, :);

%%
% Find mean and SD of PPG amplitudes in each plateau. That is one measure of variability
PPG_Amp_avg = mean (pktrfref0_full_cleaned(:,9));
PPG_Amp_SD = std(pktrfref0_full_cleaned(:,9));

%PPG_Amp_SD_percentOfMean = PPG_Amp_SD *100/PPG_Amp_avg;

PPG_Amp_percentile_10_full = prctile(pktrfref0_full_cleaned(:,9), 10);% 10th percentile for low amplitude
PPG_Amp_percentile_90_full = prctile(pktrfref0_full_cleaned(:,9), 90);% 90th percentile for high amplitude
PPG_Amp_percentile_80_full = prctile(pktrfref0_full_cleaned(:,9), 80);% 80th percentile for high amplitude
PPG_Amp_percentile_20_full = prctile(pktrfref0_full_cleaned(:,9), 20);% 20th percentile for high amplitude

%The following is analagous to what was done with the segments in the previous part
PPGAmp_percentageDiff_20_full = (PPG_Amp_percentile_80_full - PPG_Amp_percentile_20_full)*100/ PPG_Amp_percentile_20_full;

disp ('PPGAmp_percentageDiff_20_full');
disp (PPGAmp_percentageDiff_20_full);
%%

%%Get the variability in PPG amplitudes from the part spectrum of reference
%PPGs (Is th is after below diastolic cuff pressures have been reached?)

% Find peaks in all of reference

[pk_r_part,locpk_r_part,w_pk_r_part,p_pk_r_part]= findpeaks (PPGref (1:end/3), time (1:end/3),'minPeakProminence', 0.001);
pref0_part=[pk_r_part,locpk_r_part,w_pk_r_part,p_pk_r_part];

[trf_r_part,loctrf_r_part,w_trf_r_part,p_trf_r_part]= findpeaks (-PPGref (1:end/3), time (1:end/3),'minPeakProminence', 0.001);
trfref0_part=[trf_r_part,loctrf_r_part,w_trf_r_part,p_trf_r_part];

%%    %   To equal the number of peaks and troughs

pktrfcountref_part = abs(size(pref0_part,1)- size(trfref0_part,1));

% If more peaks than troughs, add zeros to troughs

if size(pref0_part,1)> size(trfref0_part,1)
    trfref0_part(end+pktrfcountref_part,:)=0;
end

% If more troughs than peaks, add zeros to peaks

if size(pref0_part,1)< size(trfref0_part,1)
    pref0_part(end+pktrfcountref_part,:)=0;
end

% Check if peak and trough numbers in every plateau is same for cuffed
% arm. The last column in pktrfafter should be 0,0.

pktrfcountref_partafter = size(pref0_part,1)- size (trfref0_part,1);

% Now that peaks and troughs are the same, we can
% concatenate peaks and troughs

pktrfref0a_part = cat (2, pref0_part, trfref0_part);

%%
% To ensure each peak comes after a trough in ref

pktrfref0c_part = pktrfref0a_part;

for k =1:size(pktrfref0c_part,1)
    if   pktrfref0c_part(k,2) < pktrfref0c_part(k,6)
        addrowref_part(1:8) = zeros; %This is done so that the last ref data in 5:8 does not get deleted
        pktrfref0c_part = [pktrfref0c_part; addrowref_part];
        pktrfref0c_part(k+1:end,5:8)= pktrfref0c_part(k:end-1,5:8);
        pktrfref0c_part(k,5:8)= 0;% This line was 1:4 = 0 earlier. That is incorrect.
    end
end

%%
%To consider false peaks (defined as amplitude < 1/10 of mean amplitude of nonzero entries in that cell) in ref:

pktrfref0b_part = pktrfref0c_part;

% calculate amplitude of peaks
for j = 1: size (pktrfref0b_part,1)
    pktrfref0b_part (j,9) = pktrfref0b_part(j,1)- pktrfref0b_part(j,5); %actual amplitude of peaks
end

%Take mean of amplitudes and enter in second column of the cell array

mean_refAmp= mean(nonzeros(pktrfref0b_part(:,9)));

% Identify amplitudes less than one tenth the mean in each cell

for j = 1: size (pktrfref0b_part,1)
    pktrfref0b_part(j,10)= pktrfref0b_part(j,9) < mean_refAmp/10;% col 10 is logical array
end

%The above strategy alone may not work. The wave after dicrotic notch
%can cause havoc. See 220303AP for example.

for j = 2:size (pktrfref0b_part,1)
    pktrfref0b_part(j,11)= pktrfref0b_part(j,9) < (pktrfref0b_part(j-1,9))/4;
    %If a peak amplitude is less than one fourth the peak amplitude
    %of the previous row, logical 1.
end

% If there is an anacrotic notch after a dicrotic notch,
%that does not get flagged with the previous code. 220303AP is again the example here.
%Compare against next pulse

for j = 1: size (pktrfref0b_part,1)-1
    pktrfref0b_part(j,12)= pktrfref0b_part(j,9) < (pktrfref0b_part(j+1,9))/4;
    %If a peak amplitude is less than one fourth the peak amplitude
    %of the succeeding row, logical 1.
end

% the following lines delete rows with logical 1 in columns 10, 11, 12

pktrfref0d_part = pktrfref0b_part;

for j = 1: size(pktrfref0d_part,1)
    if pktrfref0b_part(j,10)== 1
        pktrfref0d_part(j,1:8)= 0;
    end
    
    if pktrfref0b_part(j,11)== 1
        pktrfref0d_part(j,1:8)= 0;
    end
    
    if pktrfref0b_part(j,12)== 1
        pktrfref0d_part(j,1:8)= 0;
    end
end

pktrfref0_part(:,1:9) = pktrfref0d_part(:,1:9);

% Remove rows with any zeros in columns 1 to 8
rows_with_zeros_ref_part = any(pktrfref0_part(:, 1:8) == 0, 2);
pktrfref0_part_cleaned = pktrfref0_part(~rows_with_zeros_ref_part, :);

%%
% Find mean and SD of PPG amplitudes. That is one measure of variability
PPG_Amp_avg = mean (pktrfref0_part_cleaned(:,9));
PPG_Amp_SD = std(pktrfref0_part_cleaned(:,9));

PPG_Amp_SD_percentOfMean = PPG_Amp_SD *100/PPG_Amp_avg;
PPG_Amp_percentile_10_part = prctile(pktrfref0_part_cleaned(:,9), 10);% 10th percentile for low amplitude
PPG_Amp_percentile_90_part = prctile(pktrfref0_part_cleaned(:,9), 90);% 90th percentile for high amplitude
PPG_Amp_percentile_80_part = prctile(pktrfref0_part_cleaned(:,9), 80);% 80th percentile for high amplitude
PPG_Amp_percentile_20_part = prctile(pktrfref0_part_cleaned(:,9), 20);% 20th percentile for high amplitude

%The following is analagous to what was done with the segments in the previous part
PPGAmp_percentageDiff_20_part = (PPG_Amp_percentile_80_part - PPG_Amp_percentile_20_part)*100/PPG_Amp_percentile_20_part;% diff as percent of min amplitude
PPGAmp_percentageDiff_20_part2 = (PPG_Amp_percentile_80_part - PPG_Amp_percentile_20_part)*100/PPG_Amp_percentile_80_part;% diff as percent of max amplitude

%%
disp ('PPG_variability_avg')
disp (PPG_variability_avg);

disp ('PPG_variability_max')
disp (round(PPG_variability_max));

disp ('PPG_variability_min')
disp (round(PPG_variability_min));

disp ('PPGvar_percentile_80_plateaus');
disp (PPGvar_percentile_80_plateaus);

disp ('PPGAmp_percentageDiff_20_part');
disp (PPGAmp_percentageDiff_20_part);

disp ('PPGAmp_percentageDiff_20_full');
disp (PPGAmp_percentageDiff_20_full);

%%
labels_PPGvar = {'PPGvar_plat_avg', 'PPG var_plat_max', 'PPGvar_part_20_80', 'PPGvar_full_20_80'};
labels_PPGvar = string(labels_PPGvar);
results_PPGvar = [round(PPG_variability_avg), round(PPG_variability_max),round(PPGAmp_percentageDiff_20_part), round(PPGAmp_percentageDiff_20_full)];
Table3_PPGvar = cat (1, labels_PPGvar, results_PPGvar);

%%
%figure(12)
%hold on
%plot (data1(:,1), data1(:,3),'color', 'c', 'LineStyle', '-'); % pulse data
%plot(forHRV(:,1), forHRV(:,2)); % pulse intervals in seconds
%scatter (pktrfref0_full_cleaned(:,2), pktrfref0_full_cleaned(:,1));
%ylabel ('pulse amplitude arb units');
%yyaxis right
%plot (forHRV(:,1), forHRV (:,5),'color', 'b', 'LineStyle', '-'); %HR in bpm
%ylabel ('HR in beats per min - blue');
%plot (forHRV(:,1), forHRV (:,6)./1000,'color', 'r', 'LineStyle', '-.'); %HR in bpm
%title (expt_id);
%hold off

%saveas(gcf,[expt_id 'fig12.fig']);
%%
%The limits set for L and H points is max of UH intercepts of sigmoid fits
%on the right and loc pk poly on the left. Since locpk poly can be
%erroneous, ensure it is correct

%%
% limit for HLdetection

H_limitU = max([max(PSysDiaMay2025(1,5:8))-5, HrmsTrue+5]);
H_limitL = min(min(DiaEarlyArray(:,2)));
L_limitU = max([max(PSysDiaMay2025(1,5:8))-5, LrmsTrue+10]);
L_limitL = min(min(DiaEarlyArray(:,1)));

if L_limitL> H_limitL
    L_limitL = H_limitL;
end
disp([L_limitL, L_limitU, H_limitL, H_limitU]);

%%
forHpointmin = minratiomat(:,1:2);

fHPmin = zeros(size(forHpointmin, 1)-1,9);
fHPmin(:,1) = forHpointmin (1:end-1,1);%cuff pressure
fHPmin (:,2)= diff(forHpointmin(:,2));% difference between PPG amplitudes of successive cuff pressures

for i = 1: size (forHpointmin,1)-1
    if forHpointmin (i+1,2)==0  % if pulse amplitude is 0
        fHPmin(i,3)=0; %assign 0
    else
        fHPmin(i,3)= 1; % If there is no zero pulse, in that cuff pressure, assign 1
    end
end

fHPmin(:,4) = fHPmin (:,2)<0; % if differential is negative, logical 1
fHPmin(:,5)= diff(forHpointmin(:,1));
%
for i = 2:size(fHPmin,1)  % Here the row where there is no low point before it is removed
    fHPmin(i,6)= fHPmin(i,4)==1 & fHPmin(i-1,4)==0;
    fHPmin(i,7)= forHpointmin(i,2);
    fHPmin(i,8)= (fHPmin(i,2)/fHPmin(i,7))*100;
end

for i = 2: size(fHPmin,1)-1
    fHPmin(i,9)= (fHPmin(i,8)<5 && fHPmin(i,8)>0) && any(fHPmin(i+1:end,4)==1);
    fHPmin(i,6)= (fHPmin(i,4)==1&&fHPmin(i-1,4)==0)||(fHPmin(i,9)==1&&fHPmin(i+1,4)==1);%Redoing logical to account for plateus in H region
end

fHPminCandidates = fHPmin((fHPmin(:, 3) == 1) & (fHPmin(:, 6) == 1), :); % Choose rows where there is no zero pulse, but the differential is negative
fHPminCandidates_copy = fHPminCandidates;% Added on 22 Apr225

%%
forLpointmin = minmaxratiomat(:,1:2);

fLPmin(:,1) = forLpointmin (2:end,1);
fLPmin(:,2)= diff(forLpointmin(:,2));

for i = 1: size(forLpointmin,1)-1
    if forLpointmin (i+1,2)==0  % if pulse amplitude is 0
        fLPmin(i,3)=0; %assign 0
    else
        fLPmin(i,3)= 1; % If there is no zero pulse, in that cuff pressure, assign 1
    end
end

fLPmin(:,4) = fLPmin (:,2)<0; % if differential is negative, logical 1
fLPmin(:,5)= diff(forLpointmin(:,1));

for i = 1:size(fLPmin,1)-1
    fLPmin(i,6)= fLPmin(i,4)==1 & fLPmin(i+1,4)== 0;
    fLPmin(i,7)= forLpointmin(i,2);
end

fLPminCandidates = fLPmin((fLPmin(:, 3) == 1) & (fLPmin(:, 6) == 1), :); % Choose rows where there is no zero pulse, but the differential is negative
fLPminCandidates_copy = fLPminCandidates; %22 Apr2025

if ~isempty (fLPminCandidates)
    
    rowsToDeletefLPmin = fLPminCandidates(:,1)> L_limitU | fLPminCandidates(:,1) < L_limitL;%
    fLPminCandidates_0 = fLPminCandidates(~rowsToDeletefLPmin, :);
end

%%
forHpointmax = maxratiomat(:,1:2);

fHPmax = zeros(size(forHpointmax, 1)-1,2);
fHPmax(:,1) = forHpointmax (1:end-1,1); %Take cuff pressures and adjust row number to equal when differentiated
fHPmax(:,2)= diff(forHpointmax(:,2)); % Get the difference between successive PPG ratios

for i = 1: size(forHpointmax,1)-1
    if forHpointmax(i+1,2)==0
        fHPmax(i,3)=0;
    else
        fHPmax(i,3)= 1;
    end
end  % The above is to unconsider PPG ratios in the 0 ratio range?

fHPmax(:,4) = fHPmax (:,2)<0;% Taking points where the difference is negative (where the subsequent value is less)
fHPmax(:,5)= diff(forHpointmax(:,1));

for i = 2: size(fHPmax,1)
    fHPmax(i,6)= fHPmax(i,4)==1&fHPmax(i-1,4)== 0;
    fHPmax(i,7)= forHpointmax(i,2);
    fHPmax(i,8)= (fHPmax(i,2)/fHPmax(i,7))*100;
end

for i = 2: size(fHPmax,1)-1
    fHPmax(i,9)= (fHPmax(i,8)<5 &&fHPmax(i,8)>0) &&  any(fHPmax(i+1:end,4)==1);
    fHPmax(i,6)= (fHPmax(i,4)==1&&fHPmax(i-1,4)==0)||fHPmax(i,9)==1;%Redoing logical to account for plateus in H region
end

fHPmaxCandidates = fHPmax((fHPmax(:, 3) == 1) & (fHPmax(:, 6) == 1), :);
fHPmaxCandidates_copy =fHPmaxCandidates; %22 Apr2025
%%
forLpointmax = maxratiomat (:,1:2);
fLPmax(:,1) = forLpointmax (2:end,1);
fLPmax (:,2)= diff (forLpointmax(:,2));

for i = 1: size(forLpointmax,1)-1
    if forLpointmax (i+1,2)==0
        fLPmax(i,3)=0;
    else  fLPmax(i,3)= 1;
    end
end

fLPmax(:,4) = fLPmax (:,2)<0;

fLPmax(:,5)= diff (forLpointmax(:,1));

for i = 1:size(fLPmax,1)-1  % Lere the row where there is no low point before it is removed
    fLPmax(i,6)= fLPmax(i,4)==1 & fLPmax(i+1,4)== 0;
    fLPmax(i,7)= forLpointmax (i,2);
end

fLPmaxCandidates = fLPmax((fLPmax(:, 3) == 1) & (fLPmax(:, 6) == 1), :);
fLPmaxCandidates_copy = fLPmaxCandidates;
fitx_ratio_env_min = (20:1: round(max([xmin3new, x_min5new, x3new, x5_new, xmax3new, x_max5new])));
fitx_ratio_env_min =   fitx_ratio_env_min';
fity_ratio_env_min = (fitresult{73}(20:1:round(max([xmin3new, x_min5new, x3new, x5_new, xmax3new, x_max5new]))));

fit_ratio_env_min = [fitx_ratio_env_min, fity_ratio_env_min];

fitx_ratio_env_max = (20:1: round(max([xmin3new, x_min5new, x3new, x5_new, xmax3new, x_max5new])));
fitx_ratio_env_max =   fitx_ratio_env_max';
fity_ratio_env_max = (fitresult{74}(20:1:round(max([xmin3new, x_min5new, x3new, x5_new, xmax3new, x_max5new]))));

fit_ratio_env_max = [fitx_ratio_env_max, fity_ratio_env_max];

%%
try
    [pk_ratio_env_min, locpk_ratio_env_min, w_pk_ratio_env_min, P_pk_ratio_env_min] = findpeaks(fity_ratio_env_min, fitx_ratio_env_min);
    Hpoint_env_min = [locpk_ratio_env_min, pk_ratio_env_min];
    CATCH ME
end

Hpoint_env_min = sort(Hpoint_env_min, 'descend');

%%
try
    [trf_ratio_env_min, loctrf_ratio_env_min, w_trf_ratio_env_min, P_trf_ratio_env_min] = findpeaks (-fity_ratio_env_min, fitx_ratio_env_min);
    Lpoint_env_min = loctrf_ratio_env_min;
    CATCH ME
end

if exist('Lpoint_env_min','var')&& ~isempty (Lpoint_env_min)
    Lpoint_env_min_logical =  Lpoint_env_min(:,1)> L_limitL &  Lpoint_env_min(:,1)< L_limitU ;
    Lpoint_env_min_shortlist = Lpoint_env_min(Lpoint_env_min_logical, :);
end

Lpoint_env_min = sort(Lpoint_env_min, 'descend');
%%
try
    [pk_ratio_env_max, locpk_ratio_env_max, w_pk_ratio_env_max, P_pk_ratio_env_max] = findpeaks(fity_ratio_env_max, fitx_ratio_env_max);
    Hpoint_env_max = [locpk_ratio_env_max, pk_ratio_env_max];
    CATCH ME
end

if exist('Hpoint_env_max','var')&& ~isempty(Hpoint_env_max)
    Hpoint_env_max_logical = Hpoint_env_max(:,1)< H_limitU & Hpoint_env_max(:,1)> H_limitL;
    Hpoint_env_max_shortlist = Hpoint_env_max(Hpoint_env_max_logical, :);
end

Hpoint_env_max = sort(Hpoint_env_max, 'descend');
%%
try
    [trf_ratio_env_max, loctrf_ratio_env_max, w_trf_ratio_env_max, P_trf_ratio_env_max] = findpeaks (-fity_ratio_env_max, fitx_ratio_env_max);
    Lpoint_env_max = [loctrf_ratio_env_max, -trf_ratio_env_max];
    CATCH ME
end

if exist('Lpoint_env_max','var')&& ~isempty (Lpoint_env_max)
    Lpoint_env_max_logical = Lpoint_env_max(:,1)> L_limitL & Lpoint_env_max(:,1)< L_limitU;
    Lpoint_env_max_shortlist = Lpoint_env_max(Lpoint_env_max_logical, :);
end

Lpoint_env_max = sort(Lpoint_env_max, 'descend');

%%
cuffPPGAmp = ratios;%

for j = 1:size(cuffPPGAmp,1)
    minmaxcuffmat(j,1) = cuffPPGAmp{j,2};%cuff pressure
    minmaxcuffmat(j,2) = min(cuffPPGAmp{j,1}(:,1));% minimum cuff PPG Amp
    minmaxcuffmat(j,3) = max(cuffPPGAmp{j,1}(:,1));%maximum cuff PPG Amp
    minmaxcuffmat(j,4) = mean(cuffPPGAmp{j,1}(:,1));%mean cuff PPG Amp
    minmaxcuffmat (j,5)=  minmaxcuffmat (j,3)-  minmaxcuffmat (j,2);% difference between min and max
    minmaxcuffmat (j,6)=  minmaxcuffmat (j,5)*100/ minmaxcuffmat (j,2);% difference as percent of min
end

%%
%polyfits for cuff data
%Fit data to a third degree polynomial'.
% Set up fittype and options.
fitpolymincuff = fittype('a*x^3 + b*x^2 + c*x + d', 'independent', 'x', 'dependent', 'y');
optspolymincuff = fitoptions( 'Method', 'NonlinearLeastSquares' );
optspolymincuff.Algorithm = 'Levenberg-Marquardt';
polymincuff.Display = 'Off';
optspolymincuff.Robust = 'Bisquare';
optspolymincuff.StartPoint = [10 1 1 1];% changed

% Fit model to data.
[fitresult{33}, gof(33)] = fit( minmaxcuffmat(:,1), minmaxcuffmat(:,2), fitpolymincuff, optspolymincuff );
coefficientspoly_mincuff= coeffvalues(fitresult{33});
%
fitx_polymincuff = (lcp:1:hcp+30);
fitx_polymincuff = fitx_polymincuff';
fity_polymincuff = fitresult{33}(lcp:1:hcp+30);
fit_polymincuff = [fitx_polymincuff,fity_polymincuff]; % fit polymin from lowest cuff pressure to highest cuff pressure + 30

[pk_fitpolymincuff, loc_pk_fitpolymincuff]   = findpeaks (fit_polymincuff (:,2), fit_polymincuff (:,1));
[trf_fitpolymincuff, loc_trf_fitpolymincuff] = findpeaks (-fit_polymincuff (:,2), fit_polymincuff (:,1));

if ~exist('loc_pk_fitpolymincuff', 'var')
    loc_pk_fitpolymincuff = [];
elseif loc_pk_fitpolymincuff > loc_trf_fitpolymincuff
    loc_pk_fitpolymincuff = [];
end

for i = 1:size(fit_polymincuff ,1)-1
    if  fit_polymincuff(i+1,2)<0 && fit_polymincuff (i,2)>0 || fit_polymincuff (i,2) ==0 % find first zero crossing
        X_intercept_poly_mincuff = fit_polymincuff(i+1,1);
        
        break; %report first zero crossing
        % if there is no zero crossing, report trough
    else
        X_intercept_poly_mincuff = loc_trf_fitpolymincuff;
    end
end
%
%%
% different strategy for UH for cuff: Take average of all values below peak
% of poly and 5 mmHg to the right

for i = 1:size(fitx_polymincuff,1)
    if  fitx_polymincuff(i,1)==loc_pk_fitpolymincuff
        rI_fitxpoly_loc_pk_fitpolymincuff = i;
        break
    end
end

if ~isnan(loc_pk_fitpolymincuff)
    UH_polymincuff = mean(fity_polymincuff(1:loc_pk_fitpolymincuff+5));
else
    UH_polymincuff = mean(fity_polymincuff(1:cell{end-3,2})); % 19May2025
end
%FInd the lower diastolic pressure by taking the UH intercept of the third degree polynomial. Can use UH of the 3PL sigmoid

% For this, it is necessary to make the UH as X axis. Or subtract the y
% intercept of the UH

yforpoly_min3lowcuff(:,1) = minmaxcuffmat(:,2);
yforpoly_min3lowcuff (:,2) = UH_polymincuff;
yforpoly_min3lowcuff (:,3) = yforpoly_min3lowcuff(:,1)- yforpoly_min3lowcuff(:,2);

% Set up fittype and options.
fit_typepoly_mincuff3low = fittype('a*x^3 + b*x^2 + c*x + d', 'independent', 'x', 'dependent', 'y');
optspoly_mincuff3low = fitoptions( 'Method', 'NonlinearLeastSquares' );
optspoly_mincuff3low.Algorithm = 'Levenberg-Marquardt';
polymincuff.Display = 'Off';
optspoly_mincuff3low.Robust = 'Bisquare';
optspoly_mincuff3low.StartPoint = [10 1 1 1];% changed

% Fit model to data.
try
    [fitresult{34}, gof(34)] = fit( minmaxcuffmat(:,1), yforpoly_min3lowcuff(:,3), fit_typepoly_mincuff3low, optspoly_mincuff3low );
    
    coefficientspoly_mincuff3low= coeffvalues(fitresult{34});
    
    fitx_poly_mincuff3low = lcp:1:hcp;
    fitx_poly_mincuff3low =fitx_poly_mincuff3low';
    fity_poly_mincuff3low = fitresult{34}(lcp:1:hcp);
    fit_poly_mincuff3low = [fitx_poly_mincuff3low, fity_poly_mincuff3low];
    
    [pk_fitpoly_mincuff3low, loc_pk_fitpoly_mincuff3low] = findpeaks(fit_poly_mincuff3low (:,2), fit_poly_mincuff3low (:,1));
    [trf_fitpoly_mincuff3low, loc_trf_fitpoly_mincuff3low] = findpeaks (-fit_poly_mincuff3low (:,2), fit_poly_mincuff3low (:,1));
    
    for i = 1:size(fit_poly_mincuff3low ,1)-1
        if  fit_poly_mincuff3low (i,2)>=0 && fit_poly_mincuff3low(i+1,2)<0 %|| fit_poly_min3low (i,2) ==0 % find first zero crossing
            UH_intercept_poly_mincuff3 = fit_poly_mincuff3low(i,1);
            
            break % There will be 2 zero crossings for poly min3low. THe if condition already selects the second crossing
        else
            UH_intercept_poly_mincuff3 = loc_pk_fitpoly_mincuff3low;
        end
    end
catch ME
end

if ~exist('loc_pk_fitpoly_mincuff3low', 'var')
    loc_pk_fitpoly_mincuff3low = [];
elseif loc_pk_fitpoly_mincuff3low > loc_trf_fitpoly_mincuff3low % This condition did not work with || along with first condition sometimes when trf is empty
    loc_pk_fitpoly_mincuff3low = [];
end

if ~exist('UH_intercept_poly_mincuff3', 'var')
    for i = 1: size(minmaxcuffmat, 1)
        UH_intercept_poly_mincuff3_for = (minmaxcuffmat(:,1)< max(Hpointrms_array));
        UH_intercept_poly_mincuff3_for1(i,1) = UH_intercept_poly_mincuff3_for(i,1).*(minmaxcuffmat(i,1));
    end
    UH_equivalent_mincuff = round(mean(nonzeros(UH_intercept_poly_mincuff3_for1(:,1))));
    UH_intercept_poly_mincuff3 = UH_equivalent_mincuff;
end

%%
%Fit data to a third degree polynomial'.
% Set up fittype and options.
fitpolymaxcuff = fittype('a*x^3 + b*x^2 + c*x + d', 'independent', 'x', 'dependent', 'y');
optspolymaxcuff = fitoptions( 'Method', 'NonlinearLeastSquares' );
optspolymaxcuff.Algorithm = 'Levenberg-Marquardt';
polymaxcuff.Display = 'Off';
optspolymaxcuff.Robust = 'Bisquare';
optspolymaxcuff.StartPoint = [10 1 1 1];% changed

% Fit model to data.
[fitresult{35}, gof(35)] = fit( minmaxcuffmat(:,1), minmaxcuffmat(:,3), fitpolymaxcuff, optspolymaxcuff );
coefficientspoly_maxcuff= coeffvalues(fitresult{35});
%
fitx_polymaxcuff = (lcp:1:hcp+30);
fitx_polymaxcuff = fitx_polymaxcuff';
fity_polymaxcuff = fitresult{35}(lcp:1:hcp+30);
fit_polymaxcuff = [fitx_polymaxcuff,fity_polymaxcuff]; % fit polymin from lowest cuff pressure to highest cuff pressure + 30

[pk_fitpolymaxcuff, loc_pk_fitpolymaxcuff]   = findpeaks(fit_polymaxcuff (:,2), fit_polymaxcuff (:,1));
[trf_fitpolymaxcuff, loc_trf_fitpolymaxcuff] = findpeaks (-fit_polymaxcuff (:,2), fit_polymaxcuff (:,1));

if ~exist('loc_pk_fitpolymaxcuff', 'var')
    loc_pk_fitpolymaxcuff = [];
elseif loc_pk_fitpolymaxcuff > loc_trf_fitpolymaxcuff
    loc_pk_fitpolymaxcuff = [];
end

for i = 1:size(fit_polymaxcuff ,1)-1
    if  fit_polymaxcuff(i+1,2)<0 && fit_polymaxcuff (i,2)>0 || fit_polymaxcuff (i,2) ==0 % find first zero crossing
        X_intercept_poly_maxcuff = fit_polymaxcuff(i+1,1);
        break; %report first zero crossing
        % if there is no zero crossing, report trough
    else
        X_intercept_poly_maxcuff = loc_trf_fitpolymaxcuff;
    end
end

%%
% different strategy for UH for cuff: Take average of all values below peak
% of poly and 5 mmHg to the right

UH_polymaxcuff = mean(fity_polymaxcuff(lcp:loc_pk_fitpolymaxcuff+5));
%FInd the lower diastolic pressure by taking the UH intercept of the third degree polynomial. Can use UH of the 3PL sigmoid

% For this, it is necessary to make the UH as X axis. Or subtract the y
% intercept of the UH

yforpoly_max3lowcuff(:,1) = minmaxcuffmat(:,3);
yforpoly_max3lowcuff (:,2) = UH_polymaxcuff;
yforpoly_max3lowcuff (:,3) = yforpoly_max3lowcuff(:,1)- yforpoly_max3lowcuff(:,2);

% Set up fittype and options.
fit_typepoly_maxcuff3low = fittype('a*x^3 + b*x^2 + c*x + d', 'independent', 'x', 'dependent', 'y');
optspoly_maxcuff3low = fitoptions( 'Method', 'NonlinearLeastSquares' );
optspoly_maxcuff3low.Algorithm = 'Levenberg-Marquardt';
polymaxcuff.Display = 'Off';
optspoly_maxcuff3low.Robust = 'Bisquare';
optspoly_maxcuff3low.StartPoint = [10 1 1 1];% changed

% Fit model to data.
try
    [fitresult{36}, gof(36)] = fit( minmaxcuffmat(:,1), yforpoly_max3lowcuff(:,3), fit_typepoly_maxcuff3low, optspoly_maxcuff3low );
    
    coefficientspoly_maxcuff3low= coeffvalues(fitresult{36});
    
    fitx_poly_maxcuff3low = lcp:1:hcp;
    fitx_poly_maxcuff3low =fitx_poly_maxcuff3low';
    fity_poly_maxcuff3low = fitresult{36}(lcp:1:hcp);
    fit_poly_maxcuff3low = [fitx_poly_maxcuff3low, fity_poly_maxcuff3low];
    
    [pk_fitpoly_maxcuff3low, loc_pk_fitpoly_maxcuff3low] = findpeaks(fit_poly_maxcuff3low (:,2), fit_poly_maxcuff3low (:,1));
    [trf_fitpoly_maxcuff3low, loc_trf_fitpoly_maxcuff3low] = findpeaks (-fit_poly_maxcuff3low (:,2), fit_poly_maxcuff3low (:,1));
    
    for i = 1:size(fit_poly_maxcuff3low ,1)-1
        if  fit_poly_maxcuff3low (i,2)>=0 && fit_poly_maxcuff3low(i+1,2)<0 %|| fit_poly_min3low (i,2) ==0 % find first zero crossing
            UH_intercept_poly_maxcuff3 = fit_poly_maxcuff3low(i,1);
            
            break % There will be 2 zero crossings for poly min3low. THe if condition already selects the second crossing
        else
            UH_intercept_poly_maxcuff3 = loc_pk_fitpoly_maxcuff3low;
        end
    end
catch ME
end

if ~exist('loc_pk_fitpoly_maxcuff3low', 'var')
    loc_pk_fitpoly_maxcuff3low = [];
elseif loc_pk_fitpoly_maxcuff3low > loc_trf_fitpoly_maxcuff3low
    loc_pk_fitpoly_maxcuff3low = [];
end

if ~exist('UH_intercept_poly_maxcuff3', 'var')
    for i = 1: size(minmaxcuffmat, 1)
        UH_intercept_poly_maxcuff3_for = (minmaxcuffmat(:,1)< max(Hpointrms_array));
        UH_intercept_poly_maxcuff3_for1(i,1) = UH_intercept_poly_maxcuff3_for(i,1).*(minmaxcuffmat(i,1));
    end
    UH_equivalent_maxcuff = round(mean(nonzeros(UH_intercept_poly_maxcuff3_for1(:,1))));
    UH_intercept_poly_maxcuff3 = UH_equivalent_maxcuff;
end
%%
clearvars diff; %This is to remove an old variable

forHpointmincuff = minmaxcuffmat(:,1:2);

fHPmincuff = []; %initializing for reruns
fHPmincuff(:,1) = forHpointmincuff (1:end-1,1); %Take cuff pressures and adjust row number to equal when differentiated
fHPmincuff(:,2)= diff(forHpointmincuff(:,2)); %only difference in amp taken here. actual amplitudes are given later in columnn 7

for i = 1: size (forHpointmincuff,1)-1
    if forHpointmincuff (i+1,2)==0  % if pulse amplitude is 0
        fHPmincuff(i,3)=0; %assign 0
    else
        fHPmincuff(i,3)= 1; % If there is no zero pulse, in that cuff pressure, assign 1
    end
end

fHPmincuff(:,4) = fHPmincuff (:,2)<0; % if differential is negative, logical 1
fHPmincuff(:,5)= diff (forHpointmincuff(:,1));

for i = 2:size(fHPmincuff,1)  % Here the row where there is no low point before it is removed
    fHPmincuff(i,6)= fHPmincuff(i,4)==1 & fHPmincuff(i-1,4)== 0;
    fHPmincuff(i,7)= forHpointmincuff(i,2);
    fHPmincuff(i,8)= (fHPmincuff(i,2)/fHPmincuff(i,7))*100;
end

for i = 2: size(fHPmincuff,1)-1
    fHPmincuff(i,9)= (fHPmincuff(i,8)<5&& fHPmincuff(i,8)>0) &&  any(fHPmincuff(i+1:end,4)==1);
    fHPmincuff(i,6)= (fHPmincuff(i,4)==1&&fHPmincuff(i-1,4)==0)||(fHPmincuff(i,9)==1&&fHPmincuff(i+1,4)==1);%Redoing logical to account for plateus in H region
end

fHPmincuffCandidates = fHPmincuff((fHPmincuff(:, 3) == 1) & (fHPmincuff(:, 6) == 1), :); % Choose rows where there is no zero pulse, but the differential is negative

%%
forLpointmincuff  = minmaxcuffmat (:,1:2);

fLPmincuff(:,1) = forLpointmincuff (2:end,1);
fLPmincuff (:,2)= diff(forLpointmincuff(:,2));

for i = 1: size(forLpointmincuff,1)-1
    if forLpointmincuff (i+1,2)==0  % if pulse amplitude is 0
        fLPmincuff(i,3)=0; %assign 0
    else
        fLPmincuff(i,3)= 1; % If there is no zero pulse, in that cuff pressure, assign 1
    end
end

fLPmincuff(:,4) = fLPmincuff (:,2)<0; % if differential is negative, logical 1
fLPmincuff(:,5)= diff (forLpointmincuff(:,1));

for i = 1:size(fLPmincuff,1)-1  % Lere the row where there is no low point before it is removed
    fLPmincuff(i,6)= fLPmincuff(i,4)==1 & fLPmincuff(i+1,4)==0;
    fLPmincuff(i,7)= forLpointmincuff(i,2);
end

fLPmincuffCandidates = fLPmincuff((fLPmincuff(:, 3) == 1) & (fLPmincuff(:, 6) == 1), :); % Choose rows where there is no zero pulse, but the differential is negative

%%
forHpointmaxcuff (:,1) = minmaxcuffmat (:,1);
forHpointmaxcuff (:,2) = minmaxcuffmat (:,3);

fHPmaxcuff = []; %initializing for reruns
fHPmaxcuff(:,1) = forHpointmaxcuff (1:end-1,1); %Take cuff pressures and adjust row number to equal when differentiated
fHPmaxcuff (:,2)= diff(forHpointmaxcuff(:,2)); % Get the difference between successive PPG ratios

for i = 1: size(forHpointmaxcuff,1)-1
    if forHpointmaxcuff (i+1,2)==0
        fHPmaxcuff(i,3)=0;
    else
        fHPmaxcuff(i,3)= 1;
    end
end  % The above is to unconsider PPG ratios in the 0 ratio range?

fHPmaxcuff(:,4) = fHPmaxcuff(:,2)<0;% Taking points where the difference is negative (where the subsequent value is less)
fHPmaxcuff(:,5)= diff(forHpointmaxcuff(:,1));

for i = 2:size(fHPmaxcuff,1)  % Here the row where there is no low point before it is removed
    fHPmaxcuff(i,6)= fHPmaxcuff(i,4)==1 & fHPmaxcuff(i-1,4)== 0;
    fHPmaxcuff(i,7)= forHpointmaxcuff(i,2);
    fHPmaxcuff(i,8)= (fHPmaxcuff(i,2)/fHPmaxcuff(i,7))*100;
end

for i = 2: size(fHPmaxcuff,1)-1
    fHPmaxcuff(i,9)= (fHPmaxcuff(i,8)<5 && fHPmaxcuff(i,8)>0)  && any(fHPmaxcuff(i+1:end,4)==1);
    fHPmaxcuff(i,6)= (fHPmaxcuff(i,4)==1&&fHPmaxcuff(i-1,4)==0)||(fHPmaxcuff(i,9)==1&&fHPmaxcuff(i+1,4)==1);%Redoing logical to account for plateus in H region
end

fHPmaxcuffCandidates = fHPmaxcuff((fHPmaxcuff(:, 3) == 1) & (fHPmaxcuff(:, 6) == 1), :);

%%
forLpointmaxcuff (:,1) = minmaxcuffmat (:,1);
forLpointmaxcuff (:,2) = minmaxcuffmat (:,3);

fLPmaxcuff(:,1) = forLpointmaxcuff (2:end,1);
fLPmaxcuff (:,2)= diff(forLpointmaxcuff(:,2));

for i = 1: size(forLpointmaxcuff,1)-1
    if forLpointmaxcuff (i+1,2)==0
        fLPmaxcuff(i,3)=0;
    else
        fLPmaxcuff(i,3)= 1;
    end
end

fLPmaxcuff(:,4) = fLPmaxcuff (:,2)<0;
fLPmaxcuff(:,5)= diff (forLpointmaxcuff(:,1));

for i = 1:size(fLPmaxcuff,1)-1  % Lere the row where there is no low point before it is removed
    fLPmaxcuff(i,6)= fLPmaxcuff(i,4)==1 & fLPmaxcuff(i+1,4)==0;
    fLPmaxcuff(i,7)= forLpointmaxcuff(i,2);
end

fLPmaxcuffCandidates = fLPmaxcuff((fLPmaxcuff(:, 3) == 1) & (fLPmaxcuff(:, 6) == 1), :);

%%
ft_mincuff = fittype( 'smoothingspline' );
opts_mincuff = fitoptions( 'Method', 'SmoothingSpline' );
opts_mincuff.SmoothingParam = 0.999999023293969;

% Fit model to data.
[fitresult{76}, gof(76)] = fit(minmaxcuffmat(:,1), minmaxcuffmat(:,2), ft_mincuff, opts_mincuff );

% Set up fittype and options.
ft_maxcuff = fittype( 'smoothingspline' );
opts_maxcuff = fitoptions( 'Method', 'SmoothingSpline' );
opts_maxcuff.SmoothingParam = 0.9999999;

% Fit model to data.
[fitresult{77}, gof(77)] = fit( minmaxcuffmat(:,1), minmaxcuffmat(:,3), ft_maxcuff, opts_maxcuff );

% Set up fittype and options.
ft_meancuff = fittype( 'smoothingspline' );
opts_meancuff = fitoptions( 'Method', 'SmoothingSpline' );
opts_meancuff.SmoothingParam = 0.9999999;

% Fit model to data.
[fitresult{78}, gof(78)] = fit(minmaxcuffmat(:,1), minmaxcuffmat(:,4), ft_meancuff, opts_meancuff );

%%
%The following is an attempt to understand PPG variability in the reference arm using the
%segments that are already there.
refPPGAmp = ratios;

for j = 1:size(refPPGAmp,1)
    
    minmaxrefmat(j,1) = refPPGAmp{j,2};%cuff pressure
    minmaxrefmat(j,2) = min(refPPGAmp{j,1}(:,2));% minimum ref PPG Amp
    minmaxrefmat(j,3) = max(refPPGAmp{j,1}(:,2));%maximum ref PPG Amp
    minmaxrefmat(j,4) = mean(refPPGAmp{j,1}(:,2));%mean ref PPG Amp
    minmaxrefmat (j,5)=  minmaxrefmat (j,3)- minmaxrefmat (j,2);% difference between min and max
    minmaxrefmat (j,6)=  minmaxrefmat (j,5)*100/ minmaxrefmat (j,2);% difference as percent of min
    minmaxrefmat (j,7)=  minmaxrefmat (j,5)*100/ minmaxrefmat (j,3);% difference as percent of min
end
PPGvar_acrossPlateaus = max(minmaxrefmat(:,3))- min(minmaxrefmat(:,2));
PPGvar_acrossPlateaus_pcOfMin = (PPGvar_acrossPlateaus*100)/min(minmaxrefmat(:,2));
PPGvar_acrossPlateaus_pcOfMax = (PPGvar_acrossPlateaus*100)/max(minmaxrefmat(:,3));
PPGdelta = PPGvar_acrossPlateaus/(max(minmaxrefmat(:,3))+ min(minmaxrefmat(:,2))/2);
%%
ft_minref = fittype( 'smoothingspline' );
opts_minref = fitoptions( 'Method', 'SmoothingSpline' );
opts_minref.SmoothingParam = 0.999999023293969;

% Fit model to data.
[fitresult{80}, gof(80)] = fit(minmaxrefmat(:,1), minmaxrefmat(:,2), ft_minref, opts_minref );

% Set up fittype and options.
ft_maxref = fittype( 'smoothingspline' );
opts_maxref = fitoptions( 'Method', 'SmoothingSpline' );
opts_maxref.SmoothingParam = 0.9999999;

% Fit model to data.
[fitresult{81}, gof(81)] = fit( minmaxrefmat(:,1), minmaxrefmat(:,3), ft_maxref, opts_maxref );

% Set up fittype and options.
ft_meanref = fittype( 'smoothingspline' );
opts_meanref = fitoptions( 'Method', 'SmoothingSpline' );
opts_meanref.SmoothingParam = 0.9999999;

% Fit model to data.
[fitresult{82}, gof(82)] = fit(minmaxrefmat(:,1), minmaxrefmat(:,4), ft_meanref, opts_meanref );

%%
%figure (18)

%hold on
%h_minref = plot( fitresult{80}, minmaxrefmat(:,1), minmaxrefmat(:,2));
%set (h_minref(2,1), 'LineStyle', ':', 'color', 'b');
%set (h_minref(1,1), 'color', 'b');
%h_meanref = plot( fitresult{82}, minmaxrefmat(:,1), minmaxrefmat(:,4));
%set (h_meanref(2,1), 'LineStyle', ':','color', 'k');
%set (h_meanref(1,1), 'color', 'k');
%h_maxref = plot( fitresult{81}, minmaxrefmat(:,1), minmaxrefmat(:,3));
%set (h_maxref(2,1), 'LineStyle', ':','color', 'r');
%set (h_maxref(1,1), 'color', 'r');

%h_mincuff = plot( fitresult{76}, minmaxcuffmat(:,1), minmaxcuffmat(:,2));
%set (h_mincuff(2,1),'LineStyle', '-.', 'color', 'b');
%set (h_mincuff(1,1),'color', 'b');

%h_meancuff = plot( fitresult{78}, minmaxcuffmat(:,1), minmaxcuffmat(:,4));
%set (h_meancuff(2,1), 'LineStyle', '-.','color', 'k');
%set (h_meancuff(1,1), 'color', 'k');

%h_maxcuff = plot( fitresult{77}, minmaxcuffmat(:,1), minmaxcuffmat(:,3));
%set (h_maxcuff(2,1),'LineStyle', '-.', 'color', 'r');
%set (h_maxcuff(1,1),'color', 'r');

%ylabel 'min, max and mean ref and cuff';

%yyaxis right
%ylim ([-0.5 2]);
%h_meanratio = plot( fitresult{75});
%set (h_meanratio,'LineStyle', '-','color', 'k');
%h_minratio = plot( fitresult{73});
%set (h_minratio, 'LineStyle', '-','color', 'b');
%h_maxratio = plot( fitresult{74});
%set (h_maxratio, 'LineStyle', '-','color', 'r');

%ylabel 'min max and mean ratios';
%grid on
%xlabel 'cuff Pressure';
%legend off;

%hold off
%saveas(gcf,[expt_id 'fig18.fig']);

%%
fitx_env_mincuff = (20:1: round(max([xmin3new, x_min5new, x3new, x5_new, xmax3new, x_max5new])));
fitx_env_mincuff =  fitx_env_mincuff';
fity_env_mincuff = (fitresult{76}(20:1:round(max([xmin3new, x_min5new, x3new, x5_new, xmax3new, x_max5new]))));

fit_env_mincuff = [fitx_env_mincuff, fity_env_mincuff];
%%
try
    [pk_env_mincuff, locpk_env_mincuff] = findpeaks(fity_env_mincuff, fitx_env_mincuff);
    Hpoint_env_mincuff = [locpk_env_mincuff, pk_env_mincuff];
    CATCH ME
end
Hpoint_env_mincuff = sort(Hpoint_env_mincuff, 'descend');

%%
try
    [trf_env_mincuff, loctrf_env_mincuff] = findpeaks(-fity_env_mincuff, fitx_env_mincuff);
    Lpoint_env_mincuff = [loctrf_env_mincuff, -trf_env_mincuff];
    CATCH ME
end
Lpoint_env_mincuff = sort(Lpoint_env_mincuff, 'descend');

%%
fitx_env_maxcuff = (20:1: round(max([xmin3new, x_min5new, x3new, x5_new, xmax3new, x_max5new])));
fitx_env_maxcuff =  fitx_env_maxcuff';
fity_env_maxcuff = (fitresult{77}(20:1:round(max([xmin3new, x_min5new, x3new, x5_new, xmax3new, x_max5new]))));

fit_env_maxcuff = [fitx_env_maxcuff, fity_env_maxcuff];

%%
try
    [pk_env_maxcuff, locpk_env_maxcuff] = findpeaks(fity_env_maxcuff, fitx_env_maxcuff);
    Hpoint_env_maxcuff = [locpk_env_maxcuff, pk_env_maxcuff];
    CATCH ME
end
Hpoint_env_maxcuff = sort(Hpoint_env_maxcuff, 'descend');

%%
try
    [trf_env_maxcuff, loctrf_env_maxcuff] = findpeaks(-fity_env_maxcuff, fitx_env_maxcuff);
    Lpoint_env_maxcuff = [loctrf_env_maxcuff, -trf_env_maxcuff];
    CATCH ME
end
Lpoint_env_maxcuff = sort(Lpoint_env_maxcuff, 'descend');
%%
forHpointmean = meanratiomat (:,1:2);

fHPmean = zeros(size(forHpointmean, 1)-1,2);
fHPmean(:,1) = forHpointmean(1:end-1,1);%cuff pressure
fHPmean (:,2)= diff(forHpointmean(:,2));% difference between PPG amplitudes of successive cuff pressures

for i = 1: size(forHpointmean,1)-1
    if forHpointmean (i+1,2)==0  % if pulse amplitude is 0
        fHPmean(i,3)=0; %assign 0
    else
        fHPmean(i,3)= 1; % If there is no zero pulse, in that cuff pressure, assign 1
    end
end

fHPmean(:,4) = fHPmean (:,2)<0; % if differential is negative, logical 1
fHPmean(:,5)= diff(forHpointmean(:,1));
%
for i = 2:size(fHPmean,1)  % Here the row where there is no low point before it is removed
    fHPmean(i,6)= fHPmean(i,4)==1 & fHPmean(i-1,4)==0;
    fHPmean(i,7)= forHpointmean(i,2);
    fHPmean(i,8)= (fHPmean(i,2)/fHPmean(i,7))*100;
end

for i = 2: size(fHPmean,1)-1
    fHPmean(i,9)= (fHPmean(i,8)<5 && fHPmean(i,8)>0) &&  any(fHPmean(i+1:end,4)==1);
    fHPmean(i,6)= (fHPmean(i,4)==1&&fHPmean(i-1,4)==0)||(fHPmean(i,9)==1&&fHPmean(i+1,4)==1);%Redoing logical to account for plateus in H region
end

fHPmeanCandidates = fHPmean((fHPmean(:, 3) == 1) & (fHPmean(:, 6) == 1), :); % Choose rows where there is no zero pulse, but the differential is negative
%
%%
forLpointmean = meanratiomat (:,1:2);

fLPmean(:,1) = forLpointmean (2:end,1);
fLPmean(:,2)= diff(forLpointmean(:,2));

for i = 1: size(forLpointmean,1)-1
    if forLpointmean (i+1,2)==0  % if pulse amplitude is 0
        fLPmean(i,3)=0; %assign 0
    else
        fLPmean(i,3)= 1; % If there is no zero pulse, in that cuff pressure, assign 1
    end
end

fLPmean(:,4) = fLPmean (:,2)<0; % if differential is negative, logical 1
fLPmean(:,5)= diff(forLpointmean(:,1));

for i = 1:size(fLPmean,1)-1
    fLPmean(i,6)= fLPmean(i,4)==1 & fLPmean(i+1,4)== 0;
    fLPmean(i,7)= forLpointmean(i,2);
end

fLPmeanCandidates = fLPmean((fLPmean(:, 3) == 1) & (fLPmean(:, 6) == 1), :); % Choose rows where there is no zero pulse, but the differential is negative


fitx_ratio_env_mean = (20:1: round(max([xmin3new, x_min5new, x3new, x5_new, xmax3new, x_max5new])));
fitx_ratio_env_mean =   fitx_ratio_env_mean';
fity_ratio_env_mean = (fitresult{75}(20:1:round(max([xmin3new, x_min5new, x3new, x5_new, xmax3new, x_max5new]))));

fit_ratio_env_mean = [fitx_ratio_env_mean, fity_ratio_env_mean];

%%
try
    [pk_ratio_env_mean, locpk_ratio_env_mean, w_pk_ratio_env_mean, P_pk_ratio_env_mean] = findpeaks(fity_ratio_env_mean, fitx_ratio_env_mean);
    Hpoint_env_mean = [locpk_ratio_env_mean, pk_ratio_env_mean];
    CATCH ME
end

Hpoint_env_mean = sort(Hpoint_env_mean, 'descend');

%%
try
    [trf_ratio_env_mean, loctrf_ratio_env_mean, w_trf_ratio_env_mean, P_trf_ratio_env_mean] = findpeaks (-fity_ratio_env_mean, fitx_ratio_env_mean);
    Lpoint_env_mean = [loctrf_ratio_env_mean, -trf_ratio_env_mean];
    CATCH ME
end

Lpoint_env_mean = sort(Lpoint_env_mean, 'descend');

%%
forHpointmeancuff (:,1) = minmaxcuffmat (:,1);
forHpointmeancuff (:,2) = minmaxcuffmat (:,4);

fHPmeancuff = []; %initializing for reruns
fHPmeancuff(:,1) = forHpointmeancuff (1:end-1,1); %Take cuff pressures and adjust row number to equal when differentiated
fHPmeancuff (:,2)= diff(forHpointmeancuff(:,2)); % Get the difference between successive PPG ratios

for i = 1: size(forHpointmeancuff,1)-1
    if forHpointmeancuff (i+1,2)==0
        fHPmeancuff(i,3)=0;
    else
        fHPmeancuff(i,3)= 1;
    end
end  % The above is to unconsider PPG ratios in the 0 ratio range?

fHPmeancuff(:,4) = fHPmeancuff(:,2)<0;% Taking points where the difference is negative (where the subsequent value is less)
fHPmeancuff(:,5)= diff(forHpointmeancuff(:,1));

for i = 2:size(fHPmeancuff,1)  % Here the row where there is no low point before it is removed
    fHPmeancuff(i,6)= fHPmeancuff(i,4)==1 & fHPmeancuff(i-1,4)== 0;
    fHPmeancuff(i,7)= forHpointmeancuff(i,2);
    fHPmeancuff(i,8)= (fHPmeancuff(i,2)/fHPmeancuff(i,7))*100;
end
for i = 2: size(fHPmeancuff,1)-1
    fHPmeancuff(i,9)= fHPmeancuff(i,8)<5 &&  fHPmeancuff(i+1,4)==1;
    fHPmeancuff(i,6)= (fHPmeancuff(i,4)==1&&fHPmeancuff(i-1,4)==0)||(fHPmeancuff(i,9)==1&&any(fHPmeancuff(i+1:end,4)==1)); %Redoing logical to account for plateus in H region
end

fHPmeancuffCandidates = fHPmeancuff((fHPmeancuff(:, 3) == 1) & (fHPmeancuff(:, 6) == 1), :);

%%
forLpointmeancuff (:,1) = minmaxcuffmat (:,1);
forLpointmeancuff (:,2) = minmaxcuffmat (:,4);

fLPmeancuff(:,1) = forLpointmeancuff (2:end,1);
fLPmeancuff (:,2)= diff(forLpointmeancuff(:,2));

for i = 1: size(forLpointmeancuff,1)-1
    if forLpointmeancuff (i+1,2)==0
        fLPmeancuff(i,3)=0;
    else
        fLPmeancuff(i,3)= 1;
    end
end

fLPmeancuff(:,4) = fLPmeancuff (:,2)<0;
fLPmeancuff(:,5)= diff (forLpointmeancuff(:,1));

for i = 1:size(fLPmeancuff,1)-1  % Lere the row where there is no low point before it is removed
    fLPmeancuff(i,6)= fLPmeancuff(i,4)==1 & fLPmeancuff(i+1,4)==0;
    fLPmeancuff(i,7)= forLpointmeancuff(i,2);
end

fLPmeancuffCandidates = fLPmeancuff((fLPmeancuff(:, 3) == 1) & (fLPmeancuff(:, 6) == 1), :);

%%

fitx_env_meancuff = (20:1: round(max([xmin3new, x_min5new, x3new, x5_new, xmax3new, x_max5new])));%22Apr2025
fitx_env_meancuff =  fitx_env_meancuff';
fity_env_meancuff = (fitresult{78}(20:1: round(max([xmin3new, x_min5new, x3new, x5_new, xmax3new, x_max5new]))));

fit_env_meancuff = [fitx_env_meancuff, fity_env_meancuff];

%%
try
    [pk_env_meancuff, locpk_env_meancuff] = findpeaks(fity_env_meancuff, fitx_env_meancuff);
    Hpoint_env_meancuff = [locpk_env_meancuff, pk_env_meancuff];
    CATCH ME
end
%
Hpoint_env_meancuff = sort(Hpoint_env_meancuff, 'descend');

try
    [trf_env_meancuff, loctrf_env_meancuff] = findpeaks(-fity_env_meancuff, fitx_env_meancuff);
    Lpoint_env_meancuff = [loctrf_env_meancuff, -trf_env_meancuff];
    CATCH ME
end
Lpoint_env_meancuff = sort(Lpoint_env_meancuff, 'descend');

%%
% dia from poly

if ~isempty(diaPolymin) && ~isempty(diaPolymax)
    dialow6 = min(diaPolymin, diaPolymax);
    diahigh6 = max(diaPolymin, diaPolymax);
elseif ~isempty(diaPolymin)
    dialow6 = diaPolymin;
    diahigh6 = diaPolymin+3;
elseif ~isempty(diaPolymax)
    dialow6 = diaPolymax-3;
    diahigh6 = diaPolymax;
end

if ~exist('dialow6', 'var') || isempty(dialow6)
    dialow6 = PSysDiaMay2025(1,3)- 5;
end

if ~exist('diahigh6', 'var')|| isempty(diahigh6)
    diahigh6 = PSysDiaMay2025(1,4)-5;
end

%%
if ~isempty(fLPminCandidates)
    LPmin = fLPminCandidates(:,1);
else
    LPmin=0;
end

if ~isempty(fLPmeanCandidates)
    LPmean = fLPmeanCandidates(:,1);
else
    LPmean=0;
end

if ~isempty(fLPmaxCandidates)
    LPmax = fLPmaxCandidates(:,1);
else
    LPmax=0;
end

if ~isempty(fLPmincuffCandidates)
    LPmincuff = fLPmincuffCandidates(:,1);
else
    LPmincuff=0;
end

if ~isempty(fLPmeancuffCandidates)
    LPmeancuff = fLPmeancuffCandidates(:,1);
else
    LPmeancuff=0;
end

if ~isempty(fLPmaxcuffCandidates)
    LPmaxcuff = fLPmaxcuffCandidates(:,1);
else
    LPmaxcuff=0;
end

if ~isempty(fHPminCandidates)
    HPmin = fHPminCandidates(:,1);
else
    HPmin=0;
end

if ~isempty(fHPmeanCandidates)
    HPmean = fHPmeanCandidates(:,1);
else
    HPmean=0;
end

if ~isempty(fHPmaxCandidates)
    HPmax = fHPmaxCandidates(:,1);
else
    HPmax=0;
end

if ~isempty(fHPmincuffCandidates)
    HPmincuff = fHPmincuffCandidates(:,1);
else
    HPmincuff=0;
end

if ~isempty(fHPmeancuffCandidates)
    HPmeancuff = fHPmeancuffCandidates(:,1);
else
    HPmeancuff=0;
end

if ~isempty(fHPmaxcuffCandidates)
    HPmaxcuff = fHPmaxcuffCandidates(:,1);
else
    HPmaxcuff=0;
end

L_minmeanmax_size = max([size(LPmin,1),size(LPmean,1), size(LPmax,1), size(LPmincuff,1),size(LPmeancuff,1), size(LPmaxcuff,1)]);
H_minmeanmax_size = max([size(HPmin,1),size(HPmean,1), size(HPmax,1), size(HPmincuff,1),size(HPmeancuff,1), size(HPmaxcuff,1)]);

L_minmeanmax = zeros(L_minmeanmax_size,6);
H_minmeanmax = zeros(H_minmeanmax_size,6);

L_minmeanmax(1:size(LPmin,1),1)= LPmin(:,1);
L_minmeanmax(1:size(LPmean,1),2)= LPmean(:,1);
L_minmeanmax(1:size(LPmax,1),3)= LPmax(:,1);
L_minmeanmax(1:size(LPmincuff,1),4)= LPmincuff(:,1);
L_minmeanmax(1:size(LPmeancuff,1),5)= LPmeancuff(:,1);
L_minmeanmax(1:size(LPmaxcuff,1),6)= LPmaxcuff(:,1);

H_minmeanmax(1:size(HPmin,1),1)= HPmin(:,1);
H_minmeanmax(1:size(HPmean,1),2)= HPmean(:,1);
H_minmeanmax(1:size(HPmax,1),3)= HPmax(:,1);
H_minmeanmax(1:size(HPmincuff,1),4)= HPmincuff(:,1);
H_minmeanmax(1:size(HPmeancuff,1),5)= HPmeancuff(:,1);
H_minmeanmax(1:size(HPmaxcuff,1),6)= HPmaxcuff(:,1);

%% Fit: 'fit of mean osc amp'.
[x6Data, y6Data] = prepareCurveData(cuffPresOsc, meanOsc);

% Set up fittype and options.
ft_meanOsc = fittype( 'smoothingspline' );
opts_mean_Osc = fitoptions( 'Method', 'SmoothingSpline' );
opts_mean_Osc.SmoothingParam = 0.99999999999;

% Fit model to data.
[fitresult{70}, gof(70)] = fit( x6Data, y6Data, ft_meanOsc, opts_mean_Osc );

%% Fit: 'untitled fit 1'.
[x7Data, y7Data] = prepareCurveData( cuffPresOsc, minOsc );

% Set up fittype and options.
ft_minOsc = fittype( 'smoothingspline' );
opts_min_Osc = fitoptions( 'Method', 'SmoothingSpline' );
opts_min_Osc.SmoothingParam = 0.99999999999999999;

% Fit model to data.
[fitresult{71}, gof(71)] = fit( x7Data, y7Data, ft_minOsc, opts_min_Osc );

%%
[x8Data, y8Data] = prepareCurveData( cuffPresOsc, maxOsc );

% Set up fittype and options.
ft_maxOsc = fittype( 'smoothingspline' );
opts_max_Osc = fitoptions( 'Method', 'SmoothingSpline' );
opts_max_Osc.SmoothingParam = 0.9999999999999999;

% Fit model to data.
[fitresult{72}, gof(72)] = fit( x8Data, y8Data, ft_maxOsc, opts_max_Osc );

%%
forMinOsc_amp = pktrf_Osc_b_mat;

%Remove data in cuff pressures beyond systolic
for i = 1:size(forMinOsc_amp,1)
    if forMinOsc_amp (i,1)> max([Sys_rms, Sysguess_MMMSDandMAP])+5
        forMinOsc_amp (i,2:4)= 0;
    end
end

%Remove data in cuff pressures below Lpointmin and above MAP higher limit
for i = 1:size(forMinOsc_amp,1)
    if forMinOsc_amp (i,1)< dialow6 -5 || forMinOsc_amp (i,1)> MAP_higherlimitOscDatapoints_a +10
        forMinOsc_amp (i,2:4)= 0;
    end
end

% Remove rows with all zeros
NZR = any( forMinOsc_amp(:, 2:end) ~= 0, 2);
forMinOsc_amp1= forMinOsc_amp(NZR, :);

% Select cuff prssure at max osc amp
[maxOsc_amp, maxOscIndex_amp] = max(forMinOsc_amp1(:,4)); % index is the row number of the max value in column 2
maxOscill_amp_Pressure0 = round(forMinOsc_amp1(maxOscIndex_amp,1)); % for that index, find column 1 entry, ie, cuff pressure

% To find the second max value
forMinOsc_amp2 = forMinOsc_amp1; % Copy into a new array

for i = 1: size(forMinOsc_amp2,1)
    if round(forMinOsc_amp2(i,1))== maxOscill_amp_Pressure0
        forMinOsc_amp2(i,4)= -1000; % assign a very low value to the max value and find the second max
    end
end

[maxOsc_amp2, maxOscIndex_amp2] = max(forMinOsc_amp2(:,4)); % index is the row number of the max value in column 2
maxOscill_amp_Pressure0a = round(forMinOsc_amp2(maxOscIndex_amp2,1)); % for that index, find column 1 entry, ie, cuff pressure

maxOscill_amp_Pressure1 =  min (maxOscill_amp_Pressure0, maxOscill_amp_Pressure0a);
maxOscill_amp_Pressure2 =  max (maxOscill_amp_Pressure0, maxOscill_amp_Pressure0a);

%
% figure (100)
% hold on
% for i = 1: size (pktrf_Osc_b,1)
%     for j = 1:size(pktrf_Osc_b{i,1},1)
%         plot(pktrf_Osc_b{i,1}(j,1), pktrf_Osc_b{i,1}(j,9), 'o', 'MarkerSize', 4, 'color', 'k' );
%     end
% end
% hold off
%
% saveas(gcf,[expt_id 'fig100.fig']);
%%
L_env_size = max([size(Lpoint_env_min,1),size(Lpoint_env_mean,1), size(Lpoint_env_max,1), size(Lpoint_env_mincuff,1),size(Lpoint_env_meancuff,1), size(Lpoint_env_maxcuff,1)]);
L_env = zeros(L_env_size,6);

L_env(1:size(Lpoint_env_min,1),1)= Lpoint_env_min(:,1);
L_env(1:size(Lpoint_env_mean,1),2)= Lpoint_env_mean(:,1);
L_env(1:size(Lpoint_env_max,1),3)= Lpoint_env_max(:,1);
L_env(1:size(Lpoint_env_mincuff,1),4)= Lpoint_env_mincuff(:,1);
L_env(1:size(Lpoint_env_meancuff,1),5)= Lpoint_env_meancuff(:,1);
L_env(1:size(Lpoint_env_maxcuff,1),6)= Lpoint_env_maxcuff(:,1);

L_all = zeros(max(size(L_minmeanmax,1), size(L_env,1)), 12);
L_all (1: size(L_minmeanmax,1), 1:6)= L_minmeanmax(:,:);
L_all (1: size(L_env,1), 7:12)= L_env(:,:);

for k =1:4*(size(L_all ,1))-1 % The number of rows is set to twice that of the size of initial array, as the array length keeps increasing
    for j = 1:12
        if L_all(k,j)< max(L_all(k,:))
            addrowMMM_env(1,1:12) = zeros;
            L_all  = cat (1, L_all , addrowMMM_env);
            L_all(k+1:end,j)=L_all(k:end-1,j);
            L_all(k,j)=0;
        end
    end
end

temp_L_all = L_all;
idx_L_all = ~all(temp_L_all==0, 2); % Find the rows without zero entries using logical indexing
temp_L_all = temp_L_all(idx_L_all,:); % Select the rows without zero entries using logical indexing
L_all = temp_L_all; % Assign the modified array back

for i = 1: size(L_all,1)
    L_all(i,13)= round(mean(nonzeros(L_all(i,1:12))));
end

for i = 1: size(L_all,1)-1
    L_all(i+1,14)= L_all(i,13)- L_all(i+1,13);
end

for i = 2: size(L_all,1)
    for j = 1:12
        if  L_all(i,14)<= 5
            if L_all(i,j)>0
                L_all(i-1,j)= L_all(i,j);
                L_all(i,j)=0;
            end
        end
    end
end

temp_L_all_a = L_all;
for i = 1:size(temp_L_all_a,1)
    idx_L_all_a(i,1) = all(all(temp_L_all_a(i, 1:12)==0)); % Find the rows without zero entries using logical indexing
end
temp_L_all_a = temp_L_all_a(~idx_L_all_a,:); % Select the rows without zero entries using logical indexing
L_all = temp_L_all_a; % Assign the modified array back

%Repeat averages and the whole loop again
for i = 1: size(L_all,1)
    L_all(i,13)= round(mean(nonzeros(L_all(i,1:12))));
end

for i = 1: size(L_all,1)-1
    L_all(i+1,14)= L_all(i,13)- L_all(i+1,13);
end

for i = 2: size(L_all,1)
    for j = 1:12
        if  L_all(i,14)<= 5
            if L_all(i,j)>0
                L_all(i-1,j)= L_all(i,j);
                L_all(i,j)=0;
            end
        end
    end
end

temp_L_all_b = L_all;
for i = 1:size(temp_L_all_b,1)
    idx_L_all_b(i,1) = all(all(temp_L_all_b(i, 1:12)==0)); % Find the rows without zero entries using logical indexing
end
temp_L_all_b = temp_L_all_b(~idx_L_all_b,:); % Select the rows without zero entries using logical indexing
L_all = temp_L_all_b; % Assign the modified array back

%Repeat averages and the whole loop again
for i = 1: size(L_all,1)
    L_all(i,13)= round(mean(nonzeros(L_all(i,1:12))));
end

for i = 1: size(L_all,1)-1
    L_all(i+1,14)= L_all(i,13)- L_all(i+1,13);
end

for i = 2: size(L_all,1)
    for j = 1:12
        if  L_all(i,14)<= 5
            if L_all(i,j)>0
                L_all(i-1,j)= L_all(i,j);
                L_all(i,j)=0;
            end
        end
    end
end

temp_L_all_c = L_all;
for i = 1:size(temp_L_all_c,1)
    idx_L_all_c(i,1) = all(all(temp_L_all_c(i, 1:12)==0)); % Find the rows without zero entries using logical indexing
end
temp_L_all_c = temp_L_all_c(~idx_L_all_c,:); % Select the rows without zero entries using logical indexing
L_all = temp_L_all_c; % Assign the modified array back

%Repeat averages and the whole loop again
for i = 1: size(L_all,1)
    L_all(i,13)= round(mean(nonzeros(L_all(i,1:12))));
end

for i = 1: size(L_all,1)-1
    L_all(i+1,14)= L_all(i,13)- L_all(i+1,13);
end

for i = 1:size(L_all,1)
    for j = 1:12
        L_all_logical(i,j) = L_all(i,j)>0;
    end
    L_all(i,15)= sum(L_all_logical(i,:));
end

%L_all_logical_avg = round(mean(L_all(:,15)));
%%
for i = 1:size(L_all,1)
    %     if any(L_all(:,15)>=5)
    %         if L_all(i,15)< 5
    %             L_all(i,:) =0;
    %         end
    %     else
    if any(L_all(:,15)>=3)
        if L_all(i,15)< 3
            L_all(i,:) =0;
        end
    end
end

temp_L_all_d = L_all;
idx_L_all_d = ~all(temp_L_all_d==0, 2); % Find the rows without zero entries using logical indexing
temp_L_all_d = temp_L_all_d(idx_L_all_d,:); % Select the rows without zero entries using logical indexing
L_all = temp_L_all_d; % Assign the modified array back
%%
if (~isnan(MAP_lowerlimitOscDatapoints_a)&& ~isnan(maxOscill_amp_Pressure1)) && (abs(MAP_lowerlimitOscDatapoints_a - maxOscill_amp_Pressure1)<6)
    L_all_limit = maxOscill_amp_Pressure1-5;
elseif ~isnan(MAP_lowerlimitOscDatapoints_a)
    L_all_limit = MAP_lowerlimitOscDatapoints_a;
else
    L_all_limit = Diaguess_MMMSDandMAP_1+10;
end

L_all_trimmed = L_all;

for i = 1: size(L_all_trimmed,1)
    for j=1:12
        if  L_all_trimmed(i,j)< min(nonzeros(DiaEarlyArray)) ||L_all_trimmed(i,j) > L_all_limit % updated on 27Apr2025
            L_all_trimmed(i,j) = 0;
        end
    end
end

if sum(sum(L_all_trimmed(:,:)))==0 % added on 30Apr2025
    L_all_trimmed = L_all;
    for i = 1: size(L_all_trimmed,1)
        for j=1:12
            if ~isempty(loc_pk_fitpolymin) % condition added on 16May
                if  L_all_trimmed(i,j)< loc_pk_fitpolymin || L_all_trimmed(i,j)> L_all_limit % updated on 27Apr2025
                    L_all_trimmed(i,j) = 0;
                end
            elseif (L_all_trimmed(i,j)< PDialowMay2025) || (L_all_trimmed(i,j)> L_all_limit) % updated on 27Apr2025
                L_all_trimmed(i,j) = 0;% added on 16May2025
            end
        end
    end
end

for i=1:size(L_all_trimmed,1)
    if all(L_all_trimmed(i,1:12)==0)
        L_all_trimmed(i,:)=0;
    end
end

temp_L_all_trimmed = L_all_trimmed;
idx_L_all_trimmed = ~all(temp_L_all_trimmed==0, 2); % Find the rows without zero entries using logical indexing
temp_L_all_trimmed = temp_L_all_trimmed(idx_L_all_trimmed,:); % Select the rows without zero entries using logical indexing
L_all_trimmed = temp_L_all_trimmed; % Assign the modified array back

for i = 1:size(L_all_trimmed,1)
    for j = 1:12
        L_all_trimmed_logical(i,j) = L_all_trimmed(i,j)>0;
    end
    L_all_trimmed(i,15)= sum(L_all_trimmed_logical(i,:));
end

ClowDia_Candidates = L_all_trimmed(:,13)';

%%
H_env_size = max([size(Hpoint_env_min,1),size(Hpoint_env_mean,1), size(Hpoint_env_max,1), size(Hpoint_env_mincuff,1),size(Hpoint_env_meancuff,1), size(Hpoint_env_maxcuff,1)]);
H_env = zeros(H_env_size,6);

H_env(1:size(Hpoint_env_min,1),1)= Hpoint_env_min(:,1);
H_env(1:size(Hpoint_env_mean,1),2)= Hpoint_env_mean(:,1);
H_env(1:size(Hpoint_env_max,1),3)= Hpoint_env_max(:,1);
H_env(1:size(Hpoint_env_mincuff,1),4)= Hpoint_env_mincuff(:,1);
H_env(1:size(Hpoint_env_meancuff,1),5)= Hpoint_env_meancuff(:,1);
H_env(1:size(Hpoint_env_maxcuff,1),6)= Hpoint_env_maxcuff(:,1);

H_all = zeros(max(size(H_minmeanmax,1), size(H_env,1)), 12);
H_all (1: size(H_minmeanmax,1), 1:6)= H_minmeanmax(:,:);
H_all (1: size(H_env,1), 7:12)= H_env(:,:);

for k =1:4*(size(H_all ,1))-1 % The number of rows is set to twice that of the size of initiaH array, as the array Hength keeps increasing
    for j = 1:12
        if H_all(k,j)< max(H_all(k,:))
            addrowMMM_env(1,1:12) = zeros;
            H_all  = cat (1, H_all , addrowMMM_env);
            H_all(k+1:end,j)=H_all(k:end-1,j);
            H_all(k,j)=0;
        end
    end
end

temp_H_all = H_all;
idx_H_all = ~all(temp_H_all==0, 2); % Find the rows without zero entries using logical indexing
temp_H_all = temp_H_all(idx_H_all,:); % SeHect the rows without zero entries using logical indexing
H_all = temp_H_all; % Assign the modified array back

for i = 1: size(H_all,1)
    H_all(i,13)= round(mean(nonzeros(H_all(i,1:12))));
end

for i = 1: size(H_all,1)-1
    H_all(i+1,14)= H_all(i,13)- H_all(i+1,13);
end

for i = 2: size(H_all,1)
    for j = 1:12
        if  H_all(i,14)<= 5
            if H_all(i,j)>0
                H_all(i-1,j)= H_all(i,j);
                H_all(i,j)=0;
            end
        end
    end
end

temp_H_all_a = H_all;
for i = 1:size(temp_H_all_a,1)
    idx_H_all_a(i,1) = all(all(temp_H_all_a(i, 1:12)==0)); % Find the rows without zero entries using logical indexing
end
temp_H_all_a = temp_H_all_a(~idx_H_all_a,:); % Select the rows without zero entries using logical indexing
H_all = temp_H_all_a; % Assign the modified array back

%Repeat averages and the whole loop again
for i = 1: size(H_all,1)
    H_all(i,13)= round(mean(nonzeros(H_all(i,1:12))));
end

for i = 1: size(H_all,1)-1
    H_all(i+1,14)= H_all(i,13)- H_all(i+1,13);
end

for i = 2: size(H_all,1)
    for j = 1:12
        if  H_all(i,14)<= 5
            if H_all(i,j)>0
                H_all(i-1,j)= H_all(i,j);
                H_all(i,j)=0;
            end
        end
    end
end

temp_H_all_b = H_all;
for i = 1:size(temp_H_all_b,1)
    idx_H_all_b(i,1) = all(all(temp_H_all_b(i, 1:12)==0)); % Find the rows without zero entries using logical indexing
end
temp_H_all_b = temp_H_all_b(~idx_H_all_b,:); % Select the rows without zero entries using logical indexing
H_all = temp_H_all_b; % Assign the modified array back

%Repeat averages and the whole loop again
for i = 1: size(H_all,1)
    H_all(i,13)= round(mean(nonzeros(H_all(i,1:12))));
end

for i = 1: size(H_all,1)-1
    H_all(i+1,14)= H_all(i,13)- H_all(i+1,13);
end
%%
for i = 2: size(H_all,1)
    for j = 1:12
        if  H_all(i,14)<= 5
            if H_all(i,j)>0
                H_all(i-1,j)= H_all(i,j);
                H_all(i,j)=0;
            end
        end
    end
end

temp_H_all_c = H_all;
for i = 1:size(temp_H_all_c,1)
    idx_H_all_c(i,1) = all(all(temp_H_all_c(i, 1:12)==0)); % Find the rows without zero entries using logical indexing
end
temp_H_all_c = temp_H_all_c(~idx_H_all_c,:); % Select the rows without zero entries using logical indexing
H_all = temp_H_all_c; % Assign the modified array back

%Repeat averages and the whole loop again
for i = 1: size(H_all,1)
    H_all(i,13)= round(mean(nonzeros(H_all(i,1:12))));
end

for i = 1: size(H_all,1)-1
    H_all(i+1,14)= H_all(i,13)- H_all(i+1,13);
end

for i = 1:size(H_all,1)
    for j = 1:12
        H_all_logical(i,j) = H_all(i,j)>0;
    end
    H_all(i,15)= sum(H_all_logical(i,:));
end

temp_H_all_d = H_all;
idx_H_all_d = ~all(temp_H_all_d==0, 2); % Find the rows without zero entries using logical indexing
temp_H_all_d = temp_H_all_d(idx_H_all_d,:); % Select the rows without zero entries using logical indexing
H_all = temp_H_all_d; % Assign the modified array back


%%
H_all_trimmed = H_all;

if (~isnan(MAP_higherlimitOscDatapoints_a)&& ~isnan(maxOscill_amp_Pressure2)) && (abs(MAP_higherlimitOscDatapoints_a - maxOscill_amp_Pressure2)<10)
    H_all_limit = maxOscill_amp_Pressure2-5;
elseif ~isnan(MAP_higherlimitOscDatapoints_a)
    H_all_limit = MAP_higherlimitOscDatapoints_a;
    % elseif ~isnan(maxOscill_amp_Pressure2)
    %      H_all_limit = maxOscill_amp_Pressure2;
else
    H_all_limit = max(max(L_all_trimmed))+10;
end

for i = 1: size(H_all_trimmed,1)
    for j=1:12
        if H_all_trimmed(i,j)< min(nonzeros(DiaEarlyArray))|| H_all_trimmed(i,j) > H_all_limit -5% updated on 27Apr2025
            H_all_trimmed(i,j) = 0;
        end
    end
end

if sum(sum(H_all_trimmed(:,:)))==0 % added on 30Apr2025
    H_all_trimmed = H_all;
    for i = 1: size(H_all_trimmed,1)
        for j=1:12
            if ~isempty(loc_pk_fitpolymax) % condition added on 16May
                if  H_all_trimmed(i,j)< loc_pk_fitpolymax || H_all_trimmed(i,j)> MAP_higherlimitOscDatapoints_a-5 % updated on 27Apr2025
                    H_all_trimmed(i,j) = 0;
                end
            elseif (H_all_trimmed(i,j)< PDiahighMay2025) || (H_all_trimmed(i,j)> MAP_higherlimitOscDatapoints_a-5) % updated on 27Apr2025
                H_all_trimmed(i,j) = 0;
            end
        end
    end
end

for i=1:size(H_all_trimmed,1)
    if all(H_all_trimmed(i,1:12)==0)
        H_all_trimmed(i,:)=0;
    end
end

temp_H_all_trimmed = H_all_trimmed;
idx_H_all_trimmed = ~all(temp_H_all_trimmed==0, 2); % Find the rows without zero entries using logical indexing
temp_H_all_trimmed = temp_H_all_trimmed(idx_H_all_trimmed,:); % Select the rows without zero entries using logical indexing
H_all_trimmed = temp_H_all_trimmed; % Assign the modified array back

for i = 1:size(H_all_trimmed,1)
    for j = 1:12
        H_all_trimmed_logical(i,j) = H_all_trimmed(i,j)>0;
    end
    H_all_trimmed(i,15)= sum(H_all_trimmed_logical(i,:));
end

ChighDia_Candidates = H_all_trimmed(:,13)';

%%
syslow3= min(Xmin_new,Xmax_new);
syshigh3= max(Xmin_new,Xmax_new);

syslow4 = min(Xmin_down,Xmax_down);
syshigh4 = max(Xmin_down,Xmax_down);

syslow5 = min(Xmean_new, Xmean_down);
syshigh5 = max(Xmean_new,Xmean_down);

syslow6  = min(X_intercept_poly_min,X_intercept_poly_max);
syshigh6 = max(X_intercept_poly_min,X_intercept_poly_max);

syslowsigmoidMatrix = [syslow3; syslow4; syslow5];
syshighsigmoidMatrix = [syshigh3; syshigh4; syshigh5];

syssigmoidMatrix = [syslowsigmoidMatrix, syshighsigmoidMatrix];

Syssmsp_SigmoidPolyArray = []; % row 2 is min of Xnew and max of Xnew, row 3, min and max of Xdown, row 4, Xmeannew and Xmean down

Syssmsp_SigmoidPolyArray(1,1) = min(nonzeros(XcrossingMinArray));
Syssmsp_SigmoidPolyArray(1,2) = min(nonzeros(XcrossingMaxArray));

Syssmsp_SigmoidPolyArray(3:5, 1:2)= [syssigmoidMatrix(:,:)];
Syssmsp_SigmoidPolyArray(6, 1:2)= [syslow6, syshigh6];

%Important considerations: Poly values are taken as maximum

for i = 1: size(Syssmsp_SigmoidPolyArray,1)
    if Syssmsp_SigmoidPolyArray(i,1)> Syssmsp_SigmoidPolyArray(6,1)
        Syssmsp_SigmoidPolyArray(i,1)= Syssmsp_SigmoidPolyArray(6,1);
    end
    
    if Syssmsp_SigmoidPolyArray(i,2)> Syssmsp_SigmoidPolyArray(6,2)
        Syssmsp_SigmoidPolyArray(i,2)= Syssmsp_SigmoidPolyArray(6,2);
    end
end

Syssmsp_SigmoidPolyArray1 = Syssmsp_SigmoidPolyArray;

%%
if Syssmsp_SigmoidPolyArray1(1,1) < min(Syssmsp_SigmoidPolyArray1(3:6, 1))
    Syssmsp_SigmoidPolyArray1(1,1) = min(Syssmsp_SigmoidPolyArray1(3:6, 1));
end

if Syssmsp_SigmoidPolyArray1(1,2) < min(Syssmsp_SigmoidPolyArray1(3:6, 2)) % happens when there are false zeros, which cannot be corrected. eg, Pamela data PE - 24041101
    Syssmsp_SigmoidPolyArray1(1,2) = min(Syssmsp_SigmoidPolyArray1(3:6, 2));
end

PC_sysdiff_0(1, 1:2) = PSysDiaMay2025(1, 1:2)- Syssmsp_SigmoidPolyArray1(1, 1:2);

if abs(PC_sysdiff_0(1,1) - PC_sysdiff_0 (1,2)) > 20
    if PC_sysdiff_0 (1,1)> PC_sysdiff_0(1,2)
        if max(Syssmsp_SigmoidPolyArray1(3:6, 1))< PSysDiaMay2025(1,1)
            Syssmsp_SigmoidPolyArray1(1,1) = max(Syssmsp_SigmoidPolyArray1(3:6, 1));
        else
            Syssmsp_SigmoidPolyArray1(1,1) = PSysDiaMay2025(1,1);
        end
    elseif PC_sysdiff_0(1,2)> PC_sysdiff_0(1,1)
        if max(Syssmsp_SigmoidPolyArray1(3:6, 2))< PSysDiaMay2025(1,2)
            Syssmsp_SigmoidPolyArray1(1,2) = max(Syssmsp_SigmoidPolyArray1(3:6, 2));
        else
            Syssmsp_SigmoidPolyArray1(1,2) = PSysDiaMay2025(1,2);
        end
    end
end

Clowsys_guess_fig25 =  Syssmsp_SigmoidPolyArray1(1, 1);
Chighsys_guess_fig25 = Syssmsp_SigmoidPolyArray1(1, 2);
CsysGuessVar_fig25 = Chighsys_guess_fig25 - Clowsys_guess_fig25;

%%
dialow3 = min(UHmin_up, UHmax_up);
diahigh3 = max(UHmin_up, UHmax_up);

dialow4 = min(UHmin_new, UHmax_new);
diahigh4 = max(UHmin_new, UHmax_new);

dialow5 = min(UHmean_up, UHmean_new);
diahigh5 = max(UHmean_up, UHmean_new);

dialowsigmoidMatrix = [dialow3; dialow4; dialow5];
for i = 1:3
    if dialowsigmoidMatrix(i,1)<=0
        dialowsigmoidMatrix(i,1)=0;
        dialowsigmoidMatrix(i,1)= min(nonzeros(dialowsigmoidMatrix));
    end
end

diahighsigmoidMatrix = [diahigh3; diahigh4; diahigh5];

for i = 1:3
    if diahighsigmoidMatrix(i,1)<=0
        diahighsigmoidMatrix(i,1)=0;
        diahighsigmoidMatrix(i,1)= min(nonzeros(diahighsigmoidMatrix));
    end
end

diasigmoidMatrix = [dialowsigmoidMatrix, diahighsigmoidMatrix];

%%
fitx_osc_env_mean = (lcp:1:hcp); % lcp is lowest cuff pressure. It is declared in nibp part 2 rms
fitx_osc_env_mean = fitx_osc_env_mean';
fity_osc_env_mean = (fitresult{70}(lcp : 1: hcp));
fit_osc_env_mean = [fitx_osc_env_mean, fity_osc_env_mean];

fitx_osc_env_min = (lcp:1:hcp);
fitx_osc_env_min = fitx_osc_env_min';
fity_osc_env_min = (fitresult{71}(lcp : 1: hcp));
fit_osc_env_min = [fitx_osc_env_min, fity_osc_env_min];

fitx_osc_env_max = (lcp:1:hcp);
fitx_osc_env_max = fitx_osc_env_max';
fity_osc_env_max = (fitresult{72}(lcp : 1: hcp));
fit_osc_env_max = [fitx_osc_env_max, fity_osc_env_max];

%minpeakprominence changed to 0.03 from
[pk_osc_env_mean, loc_osc_env_mean, w_pk_OsEnMean, p_pk_OsEnMean] = findpeaks(fity_osc_env_mean, fitx_osc_env_mean, 'minPeakProminence', 0.05);
pk_loc_osc_env_mean = [pk_osc_env_mean, loc_osc_env_mean, w_pk_OsEnMean, p_pk_OsEnMean];

[pk_osc_env_min, loc_osc_env_min, w_pk_OsEnMin, p_pk_OsEnMin] = findpeaks (fity_osc_env_min, fitx_osc_env_min, 'minPeakProminence', 0.05);
pk_loc_osc_env_min = [pk_osc_env_min, loc_osc_env_min, w_pk_OsEnMin, p_pk_OsEnMin];

[pk_osc_env_max, loc_osc_env_max, w_pk_OsEnMin, p_pk_OsEnMin] = findpeaks (fity_osc_env_max, fitx_osc_env_max, 'minPeakProminence', 0.05);
pk_loc_osc_env_max = [pk_osc_env_max, loc_osc_env_max, w_pk_OsEnMin, p_pk_OsEnMin];

[trf_osc_env_mean, loc_osc_env_mean, w_trf_OsEnMean, p_trf_OsEnMean] = findpeaks (-fity_osc_env_mean, fitx_osc_env_mean, 'minPeakProminence', 0.01); % changing this to 0.01 on 15Feb2025.
trf_loc_osc_env_mean = [-trf_osc_env_mean, loc_osc_env_mean,w_trf_OsEnMean, p_trf_OsEnMean];

[trf_osc_env_min, loc_osc_env_min, w_trf_OsEnMin, p_trf_OsEnMin] = findpeaks (-fity_osc_env_min, fitx_osc_env_min, 'minPeakProminence', 0.01); % changing this to 0.01 on 15Feb2025. It was 0.05 earlier
trf_loc_osc_env_min = [-trf_osc_env_min, loc_osc_env_min, w_trf_OsEnMin, p_trf_OsEnMin];

[trf_osc_env_max, loc_osc_env_max, w_trf_OsEnMin, p_trf_OsEnMin] = findpeaks (-fity_osc_env_max, fitx_osc_env_max, 'minPeakProminence', 0.01); % changing this to 0.01 on 15Feb2025.
trf_loc_osc_env_max = [-trf_osc_env_max, loc_osc_env_max, w_trf_OsEnMin, p_trf_OsEnMin];

%%
%Getting all oscillation amplitude peaks in one matrix and aligning them in order
% First concatenate min and mean into MinMean. Then concatenate MinMean and max into MinMeanMin

%Getting min and mean together
% To equal the number of rows in pks of osc envelopes mean and min

if size(pk_loc_osc_env_min,1) == size(pk_loc_osc_env_mean,1)
    cat (2,pk_loc_osc_env_min, pk_loc_osc_env_mean);
elseif size(pk_loc_osc_env_min,1) < size(pk_loc_osc_env_mean,1)
    addrowsOscPkmin (:,1:4) = zeros(abs(size(pk_loc_osc_env_mean,1) - size(pk_loc_osc_env_min,1)),4);
    pk_loc_osc_env_min = cat (1, pk_loc_osc_env_min, addrowsOscPkmin);
else
    addrowsOscPkmean (:,1:4) = zeros(abs(size(pk_loc_osc_env_min,1) - size(pk_loc_osc_env_mean,1)),4);
    pk_loc_osc_env_mean = cat (1, pk_loc_osc_env_mean, addrowsOscPkmean);
end

% concatenate arrays of peaks of osc envelopes for min, mean
pk_loc_osc_env_MinMean = cat(2,  pk_loc_osc_env_min ,  pk_loc_osc_env_mean);
pk_loc_osc_env_MinMeanA = pk_loc_osc_env_MinMean;
pk_loc_osc_env_MinMeanA (end+1, :)=0; % Doing this because the next part of code asks for breaking iterations when all entries are zero. If pks and trfs are equal, then no entry will be zero.

% Reset rows so that matching cuff pressures (ie, diff less than 5 % mmHg)appear on a row

for k =1:2*(size(pk_loc_osc_env_MinMeanA,1))-1 % The number of rows is set to twice that of the size of initial array, as the array length keeps increasing
    if (pk_loc_osc_env_MinMeanA(k,2))>0
        if      abs(pk_loc_osc_env_MinMeanA(k,2) - pk_loc_osc_env_MinMeanA(k,6))>5 && pk_loc_osc_env_MinMeanA (k,2) < pk_loc_osc_env_MinMeanA (k,6)
            addrowOscMinMeanA(1,1:8) = zeros;
            pk_loc_osc_env_MinMeanA = cat (1, pk_loc_osc_env_MinMeanA, addrowOscMinMeanA);
            pk_loc_osc_env_MinMeanA(k+1:end,5:8)= pk_loc_osc_env_MinMeanA(k:end-1,5:8);
            pk_loc_osc_env_MinMeanA (k,5:8)= 0;
            
        elseif  abs (pk_loc_osc_env_MinMeanA(k,2) - pk_loc_osc_env_MinMeanA(k,6))>5 && pk_loc_osc_env_MinMeanA (k,2) > pk_loc_osc_env_MinMeanA (k,6)
            addrowOscMinMeanA(1, 1:8) = zeros;
            pk_loc_osc_env_MinMeanA = cat (1, pk_loc_osc_env_MinMeanA, addrowOscMinMeanA);
            pk_loc_osc_env_MinMeanA(k+1:end,1:4)= pk_loc_osc_env_MinMeanA(k:end-1,1:4);
            pk_loc_osc_env_MinMeanA (k,1:4)= 0;
        end
    end
    if      pk_loc_osc_env_MinMeanA (k, :)==0 % since the initial size is twice the size of the array, the program goes into error, when all rows are zero
        break
    end
end

%Remove rows where all entries are zero
temp_PkOscMinMean = pk_loc_osc_env_MinMeanA;
idx_PkOscMinMean = ~all(temp_PkOscMinMean==0, 2); % Find the rows without zero entries using logical indexing
temp_PkOscMinMean = temp_PkOscMinMean(idx_PkOscMinMean,:); % Select the rows without zero entries using logical indexing
pk_loc_osc_env_MinMeanA = temp_PkOscMinMean; % Assign the modified array back

%%
% Getting MinMean and max together
% To equal the number of rows in MinMean and max

if  size(pk_loc_osc_env_MinMeanA,1) == size(pk_loc_osc_env_max,1)
    cat (2,pk_loc_osc_env_MinMeanA, pk_loc_osc_env_max);
    
elseif size(pk_loc_osc_env_MinMeanA,1) < size(pk_loc_osc_env_max,1)
    addrowsOscPkMinMeanA (:,1:8) = zeros(abs(size(pk_loc_osc_env_max,1) - size(pk_loc_osc_env_MinMeanA,1)),8);
    pk_loc_osc_env_MinMeanA = cat (1, pk_loc_osc_env_MinMeanA, addrowsOscPkMinMeanA);
else
    addrowsOscPkmax (:,1:4) = zeros(abs(size(pk_loc_osc_env_MinMeanA,1) - size(pk_loc_osc_env_max,1)),4);
    pk_loc_osc_env_max = cat (1, pk_loc_osc_env_max, addrowsOscPkmax);
end

% concatenate arrays of peaks of osc envelopes for MinMean, max
pk_loc_osc_env_MinMeanMax = cat(2,  pk_loc_osc_env_MinMeanA,  pk_loc_osc_env_max);
%%
% Reset rows so that matching cuff pressures (ie, diff less than 5 % mmHg)appear on a row
col_2_6 = [2,6];

pk_loc_osc_env_MinMeanMaxA  = [];
pk_loc_osc_env_MinMeanMaxA = pk_loc_osc_env_MinMeanMax;
pk_loc_osc_env_MinMeanMaxA (end+1, :)=0; % Doing this because the next part of code asks for breaking iterations when all entries are zero. If there is no zero entry, then there will be trouble

% Reset rows so that matching cuff pressures (ie, diff less than 5 % mmHg)appear on a row

for k =1:2*(size(pk_loc_osc_env_MinMeanMaxA,1))-1 % The number of rows is set to twice that of the size of initial array, as the array length keeps increasing
    
    if any(pk_loc_osc_env_MinMeanMaxA(k, col_2_6)>0) && pk_loc_osc_env_MinMeanMaxA(k,10)>0
        
        if  abs(mean(nonzeros(pk_loc_osc_env_MinMeanMaxA(k,col_2_6))) - pk_loc_osc_env_MinMeanMaxA(k,10))>5 && mean(nonzeros(pk_loc_osc_env_MinMeanMaxA(k,col_2_6))) < pk_loc_osc_env_MinMeanMaxA (k,10)
            addrowOscMinMeanMaxA(1,1:12) = zeros;
            pk_loc_osc_env_MinMeanMaxA = cat (1, pk_loc_osc_env_MinMeanMaxA, addrowOscMinMeanMaxA);
            pk_loc_osc_env_MinMeanMaxA(k+1:end,9:12)= pk_loc_osc_env_MinMeanMaxA(k:end-1,9:12);
            pk_loc_osc_env_MinMeanMaxA (k,9:12)= 0;
            
        elseif   abs(mean(nonzeros(pk_loc_osc_env_MinMeanMaxA(k,col_2_6))) - pk_loc_osc_env_MinMeanMaxA(k,10))>5 && mean(nonzeros(pk_loc_osc_env_MinMeanMaxA(k,col_2_6))) > pk_loc_osc_env_MinMeanMaxA (k,10)
            addrowOscMinMeanMaxA(1, 12) = zeros;
            pk_loc_osc_env_MinMeanMaxA = cat (1, pk_loc_osc_env_MinMeanMaxA, addrowOscMinMeanMaxA);
            pk_loc_osc_env_MinMeanMaxA(k+1:end,1:8)= pk_loc_osc_env_MinMeanMaxA(k:end-1,1:8);
            pk_loc_osc_env_MinMeanMaxA (k,1:8)= 0;
        end
    end
    
    if      pk_loc_osc_env_MinMeanMaxA (k, :)==0 % since the initial size is twice the size of the array, the program goes into error, when all rows are zero
        break
    end
end

%Remove rows where all entries are zero
temp_PkOscMinMeanMax = pk_loc_osc_env_MinMeanMaxA;
idx_PkOscMinMeanMax = ~all(temp_PkOscMinMeanMax==0, 2); % Find the rows without zero entries using logical indexing
temp_PkOscMinMeanMax = temp_PkOscMinMeanMax(idx_PkOscMinMeanMax,:); % Select the rows without zero entries using logical indexing
pk_loc_osc_env_MinMeanMaxA = temp_PkOscMinMeanMax; % Assign the modified array back

% Repeat again alignment of max with min

for k =1:size(pk_loc_osc_env_MinMeanMaxA,1)-1 % The number of rows is set to twice that of the size of initial array, as the array length keeps increasing
    
    if pk_loc_osc_env_MinMeanMaxA(k,2)>0 && pk_loc_osc_env_MinMeanMaxA(k,10)== 0
        
        if  abs(pk_loc_osc_env_MinMeanMaxA(k,2) - pk_loc_osc_env_MinMeanMaxA(k+1,10))< 5
            pk_loc_osc_env_MinMeanMaxA(k,9:12)= pk_loc_osc_env_MinMeanMaxA(k+1,9:12);
        end
    end
    
    if  pk_loc_osc_env_MinMeanMaxA (k, :)==0 % since the initial size is twice the size of the array, the program goes into error, when all rows are zero
        break
    end
    
    if   pk_loc_osc_env_MinMeanMaxA(k,9:12)== pk_loc_osc_env_MinMeanMaxA(k+1,9:12)
        pk_loc_osc_env_MinMeanMaxA(k+1,9:12)=0;
    end
end
%
%Remove rows where all entries are zero
temp_PkOscMinMeanMax = pk_loc_osc_env_MinMeanMaxA;
idx_PkOscMinMeanMax = ~all(temp_PkOscMinMeanMax==0, 2); % Find the rows without zero entries using logical indexing
temp_PkOscMinMeanMax = temp_PkOscMinMeanMax(idx_PkOscMinMeanMax,:); % Select the rows without zero entries using logical indexing
pk_loc_osc_env_MinMeanMaxA = temp_PkOscMinMeanMax; % Assign the modified array back

%%
Pk_osc_MinMeanMaxA =[]; %Initializing to enable reruns

Pk_osc_MinMeanMaxA (:,1:2) = pk_loc_osc_env_MinMeanMaxA (:,1:2);
Pk_osc_MinMeanMaxA (:,3:4) = pk_loc_osc_env_MinMeanMaxA (:,5:6);
Pk_osc_MinMeanMaxA (:,5:6) = pk_loc_osc_env_MinMeanMaxA (:,9:10);
%%
% To equal the number of rows in trfs of osc envelopes mean and min

if  size(trf_loc_osc_env_min,1) == size(trf_loc_osc_env_mean,1)
    cat (2,trf_loc_osc_env_min, trf_loc_osc_env_mean);
    
elseif  size(trf_loc_osc_env_min,1) < size(trf_loc_osc_env_mean,1)
    addrowsOscTrfmin (:,1:4) = zeros(abs(size(trf_loc_osc_env_mean,1) - size(trf_loc_osc_env_min,1)),4);
    trf_loc_osc_env_min = cat (1, trf_loc_osc_env_min, addrowsOscTrfmin);
else
    addrowsOscTrfmean (:,1:4) = zeros(abs(size(trf_loc_osc_env_min,1) - size(trf_loc_osc_env_mean,1)),4);
    trf_loc_osc_env_mean = cat (1, trf_loc_osc_env_mean, addrowsOscTrfmean);
end
% concatenate arrays of peaks of osc envelopes for min, mean
trf_loc_osc_env_MinMean = cat(2,  trf_loc_osc_env_min ,  trf_loc_osc_env_mean);
trf_loc_osc_env_MinMeanA = trf_loc_osc_env_MinMean;
trf_loc_osc_env_MinMeanA (end+1, :)=0; % Doing this because the next part of code asks for breaking iterations when all entries are zero. If pks and trfs are equal, then no entry will be zero.
% Reset rows so that matching cuff pressures (ie, diff less than 5 % mmHg)appear on a row

% Reset rows so that matching cuff pressures (ie, diff less than 5 % mmHg)appear on a row

for k =1:2*(size(trf_loc_osc_env_MinMeanA,1))-1 % The number of rows is set to twice that of the size of initial array, as the array length keeps increasing
    if (trf_loc_osc_env_MinMeanA(k,2))> 0
        if      abs(trf_loc_osc_env_MinMeanA(k,2) - trf_loc_osc_env_MinMeanA(k,6)) > 5 && trf_loc_osc_env_MinMeanA (k,2) < trf_loc_osc_env_MinMeanA (k,6)
            addrowOscMinMeanA(1,1:8) = zeros;
            trf_loc_osc_env_MinMeanA = cat (1, trf_loc_osc_env_MinMeanA, addrowOscMinMeanA);
            trf_loc_osc_env_MinMeanA(k+1:end,5:8)= trf_loc_osc_env_MinMeanA(k:end-1,5:8);
            trf_loc_osc_env_MinMeanA (k,5:8)= 0;
            
        elseif  abs (trf_loc_osc_env_MinMeanA(k,2) - trf_loc_osc_env_MinMeanA(k,6))>5 && trf_loc_osc_env_MinMeanA (k,2) > trf_loc_osc_env_MinMeanA (k,6)
            addrowOscMinMeanA(1, 1:8) = zeros;
            trf_loc_osc_env_MinMeanA = cat (1, trf_loc_osc_env_MinMeanA, addrowOscMinMeanA);
            trf_loc_osc_env_MinMeanA(k+1:end,1:4)= trf_loc_osc_env_MinMeanA(k:end-1,1:4);
            trf_loc_osc_env_MinMeanA (k,1:4)= 0;
        end
    end
    
    if      trf_loc_osc_env_MinMeanA (k, :)==0 % since the initial size is twice the size of the array, the program goes into error, when all rows are zero
        break
    end
end

%Remove rows where all entries are zero
temp_TrfOscMinMean = trf_loc_osc_env_MinMeanA;
idx_TrfOscMinMean = ~all(temp_TrfOscMinMean==0, 2); % Find the rows without zero entries using logical indexing
temp_TrfOscMinMean = temp_TrfOscMinMean(idx_TrfOscMinMean,:); % Select the rows without zero entries using logical indexing
trf_loc_osc_env_MinMeanA = temp_TrfOscMinMean; % Assign the modified array back

%%
% To equal the number of rows in MinMean and max

if  size(trf_loc_osc_env_MinMeanA,1) == size(trf_loc_osc_env_max,1)
    trf_loc_osc_env_MinMeanMax = cat (2,trf_loc_osc_env_MinMeanA, trf_loc_osc_env_max);
    
elseif size(trf_loc_osc_env_MinMeanA,1) < size(trf_loc_osc_env_max,1)
    addrowsOscTrfMinMeanA (:,1:8) = zeros (abs(size(trf_loc_osc_env_max,1) - size(trf_loc_osc_env_MinMeanA,1)), 8);
    trf_loc_osc_env_MinMeanA = cat (1, trf_loc_osc_env_MinMeanA, addrowsOscTrfMinMeanA);
else
    addrowsOscTrfmax (:,1:4) = zeros (abs(size(trf_loc_osc_env_MinMeanA,1) - size(trf_loc_osc_env_max,1)),4);
    trf_loc_osc_env_max = cat (1, trf_loc_osc_env_max, addrowsOscTrfmax);
end

% concatenate arrays of peaks of osc envelopes for MinMean, max
trf_loc_osc_env_MinMeanMax = cat(2,  trf_loc_osc_env_MinMeanA,  trf_loc_osc_env_max);
trf_loc_osc_env_MinMeanMaxA = trf_loc_osc_env_MinMeanMax;
trf_loc_osc_env_MinMeanMaxA (end+1, :)=0; % Doing this because the next part of code asks for breaking iterations when all entries are zero. If pks and trfs are equal, then no entry will be zero.

% Reset rows so that matching cuff pressures (ie, diff less than 5 % mmHg)appear on a row

for k =1:2*(size(trf_loc_osc_env_MinMeanMaxA,1))-1 % The number of rows is set to twice that of the size of initial array, as the array length keeps increasing
    
    if any(trf_loc_osc_env_MinMeanMaxA(k,col_2_6)>0) && trf_loc_osc_env_MinMeanMaxA(k,10)>0
        
        if  abs(mean(nonzeros(trf_loc_osc_env_MinMeanMaxA(k,col_2_6))) - trf_loc_osc_env_MinMeanMaxA(k,10))>5 && mean(nonzeros(trf_loc_osc_env_MinMeanMaxA(k,col_2_6))) < trf_loc_osc_env_MinMeanMaxA (k,10)
            addrowOscMinMeanMaxA(1,1:12) = zeros;
            trf_loc_osc_env_MinMeanMaxA = cat (1, trf_loc_osc_env_MinMeanMaxA, addrowOscMinMeanMaxA);
            trf_loc_osc_env_MinMeanMaxA(k+1:end,9:12)= trf_loc_osc_env_MinMeanMaxA(k:end-1,9:12);
            trf_loc_osc_env_MinMeanMaxA (k,9:12)= 0;
            
        elseif   abs(mean(nonzeros(trf_loc_osc_env_MinMeanMaxA(k,col_2_6))) - trf_loc_osc_env_MinMeanMaxA(k,10))>5 && mean(nonzeros(trf_loc_osc_env_MinMeanMaxA(k,col_2_6))) > trf_loc_osc_env_MinMeanMaxA (k,10)
            addrowOscMinMeanMaxA(1, 12) = zeros;
            trf_loc_osc_env_MinMeanMaxA = cat (1, trf_loc_osc_env_MinMeanMaxA, addrowOscMinMeanMaxA);
            trf_loc_osc_env_MinMeanMaxA(k+1:end,1:8)= trf_loc_osc_env_MinMeanMaxA(k:end-1,1:8);
            trf_loc_osc_env_MinMeanMaxA (k,1:8)= 0;
        end
    end
    
    if trf_loc_osc_env_MinMeanMaxA(k, :)==0 % since the initial size is twice the size of the array, the program goes into error, when all rows are zero
        break
    end
end

%Remove rows where all entries are zero
temp_TrfOscMinMeanMax = trf_loc_osc_env_MinMeanMaxA;
idx_TrfOscMinMeanMax = ~all(temp_TrfOscMinMeanMax==0, 2); % Find the rows without zero entries using logical indexing
temp_TrfOscMinMeanMax = temp_TrfOscMinMeanMax(idx_TrfOscMinMeanMax,:); % Select the rows without zero entries using logical indexing
trf_loc_osc_env_MinMeanMaxA = temp_TrfOscMinMeanMax; % Assign the modified array back
%
%%
Trf_osc_MinMeanMaxA =[]; %Initializing to enable reruns

Trf_osc_MinMeanMaxA(:,1:2) = trf_loc_osc_env_MinMeanMaxA (:,1:2);
Trf_osc_MinMeanMaxA(:,3:4) = trf_loc_osc_env_MinMeanMaxA (:,5:6);
Trf_osc_MinMeanMaxA(:,5:6) = trf_loc_osc_env_MinMeanMaxA (:,9:10);

%Trf_osc_MinMeanMaxA = Trf_osc_MinMeanMaxA0.*ProminenceTrf_logical;

%%
%Programs written by Vish
% Trf_osc_MinMeanMaxA = arrayReorg1(Trf_osc_MinMeanMaxA(:,1:2),Trf_osc_MinMeanMaxA(:,3:4),Trf_osc_MinMeanMaxA(:,5:6));
% Pk_osc_MinMeanMaxA  = arrayReorg1(Pk_osc_MinMeanMaxA(:,1:2),Pk_osc_MinMeanMaxA(:,3:4),Pk_osc_MinMeanMaxA(:,5:6));
%%
PTO_MMM_A0 = [];
addrowsOscMinMeanMaxA = [];

% To equal the number of rows in Pk and Trf oscillations

if  size(Trf_osc_MinMeanMaxA,1) < size(Pk_osc_MinMeanMaxA ,1)
    addrowsOscMinMeanMaxA(:,1:6) = zeros (abs(size(Trf_osc_MinMeanMaxA,1) - size(Pk_osc_MinMeanMaxA,1)), 6);
    Trf_osc_MinMeanMaxA = cat (1,Trf_osc_MinMeanMaxA, addrowsOscMinMeanMaxA);
elseif size(Trf_osc_MinMeanMaxA,1) > size(Pk_osc_MinMeanMaxA ,1)
    addrowsOscMinMeanMaxA (:,1:6) = zeros (abs(size(Trf_osc_MinMeanMaxA,1) - size(Pk_osc_MinMeanMaxA,1)), 6);
    Pk_osc_MinMeanMaxA = cat (1,Pk_osc_MinMeanMaxA, addrowsOscMinMeanMaxA);
end

PTO_MMM_A0 = cat (2,  Trf_osc_MinMeanMaxA , Pk_osc_MinMeanMaxA );

% Doing this to break the next loop if all are zero
PTO_MMM_A0 (end+1, :)= 0;

for k =1:2*(size(PTO_MMM_A0 ,1))-1 % The number of rows is set to twice that of the size of initial array, as the array length keeps increasing
    
    if any(PTO_MMM_A0 (k,1:6)>0) && any(PTO_MMM_A0(k,7:12)>0)
        colToConsiderTrf = [2, 4, 6];
        colToConsiderPk = [8, 10, 12];
        
        averageTroughValue = mean(nonzeros(PTO_MMM_A0(k,colToConsiderTrf)));
        averagePeakValue   = mean(nonzeros(PTO_MMM_A0(k,colToConsiderPk)));
        
        addrowOscMinMeanMaxA = [];
        
        if      abs(averageTroughValue - averagePeakValue)>5 && averageTroughValue < averagePeakValue
            addrowOscMinMeanMaxA(1,1:12) = zeros;
            PTO_MMM_A0  = cat (1, PTO_MMM_A0 , addrowOscMinMeanMaxA);
            PTO_MMM_A0 (k+1:end,7:12)= PTO_MMM_A0 (k:end-1,7:12);
            PTO_MMM_A0  (k,7:12)= 0;
            
        elseif  abs(averageTroughValue - averagePeakValue)>5 && averageTroughValue > averagePeakValue
            addrowOscMinMeanMaxA(1,1:12) = zeros;
            PTO_MMM_A0  = cat (1, PTO_MMM_A0 , addrowOscMinMeanMaxA);
            PTO_MMM_A0 (k+1:end,1:6)= PTO_MMM_A0 (k:end-1,1:6);
            PTO_MMM_A0  (k,1:6)= 0;
        end
    end
    
    if      PTO_MMM_A0(k, :)==0 % since the initial size is twice the size of the array, the program goes into error, when all rows are zero
        break
    end
end

temp_PkTrfOscMinMeanMax = PTO_MMM_A0;
idx_PkTrfOscMinMeanMin = ~all(temp_PkTrfOscMinMeanMax==0, 2); % Find the rows without zero entries using logical indexing
temp_PkTrfOscMinMeanMax = temp_PkTrfOscMinMeanMax(idx_PkTrfOscMinMeanMin,:); % Select the rows without zero entries using logical indexing
PTO_MMM_A0 = temp_PkTrfOscMinMeanMax; % Assign the modified array back

%%
colMin = [1,7];
colMean = [3,9];
colMax = [5,11];
%added on 24Sep2025

for i = 1:size(PTO_MMM_A0,1)
    if PTO_MMM_A0(i,7) >0 && PTO_MMM_A0(i,11)>0
    Score_forThrhld(i,1)= PTO_MMM_A0(i,7) > 0.95*PTO_MMM_A0(i,11);% there is an error
    else
        Score_forThrhld(i,1)=0;
    end
%change from 19 Sep: If the highest feature of min and max in PTOMMM is the same, then there is only one oscillation peak there.    
    if Score_forThrhld(i,1)==1
        PTO_MMM_A0(i,7:12)=0;%remove that row of peaks
        if i >1
        PTO_MMM_A0(i-1,1:6)=0;% remove the previous row of troughs
        end
    end
end

temp_PkTrfOscMinMeanMax = PTO_MMM_A0;
idx_PkTrfOscMinMeanMin = ~all(temp_PkTrfOscMinMeanMax==0, 2); % Find the rows without zero entries using logical indexing
temp_PkTrfOscMinMeanMax = temp_PkTrfOscMinMeanMax(idx_PkTrfOscMinMeanMin,:); % Select the rows without zero entries using logical indexing
PTO_MMM_A0 = temp_PkTrfOscMinMeanMax; % Assign the modified array back

LowestFeatureMin = min(nonzeros(PTO_MMM_A0(:,colMin)));
LowestFeatureMean = min(nonzeros(PTO_MMM_A0(:,colMean)));
LowestFeatureMax = min(nonzeros(PTO_MMM_A0(:,colMax)));

%For getting highest feature, which should be MAP, remove values beyond Chighsys_guess_fig25
%Case 18091102 where there are very high oscillations beyond systolic,
%therefore deleting real MAPs in mean and max.

PTO_MMM_A0_peaks = PTO_MMM_A0(:, 7:12);

%col_PTO_MMM_A0_peaks = [2,4,6];

for i=1: size(PTO_MMM_A0_peaks,1)
    for j = 2:2:6
        if PTO_MMM_A0_peaks(i, j)> Chighsys_guess_fig25 || PTO_MMM_A0_peaks(i, j)< min(min(DiaEarlyArray)) %change made on 28May
            PTO_MMM_A0_peaks (i,j-1:j)=0;
        end
    end
end

rTD_PTO_MMM_A0peaks = all(PTO_MMM_A0_peaks==0,2);
PTO_MMM_A0_peaks(rTD_PTO_MMM_A0peaks, :)=[];

if all(PTO_MMM_A0_peaks(:,1)==0) || all(PTO_MMM_A0_peaks(:,2)==0) % case of 220318AP where there was an erroneously high Clowdia due to an artifact
    PTO_MMM_A0_peaks = PTO_MMM_A0 (:, 7:12);
    for i=1: size(PTO_MMM_A0_peaks,1)
        for j = 2:2:6
            if PTO_MMM_A0_peaks(i, j)> Chighsys_guess_fig25
                PTO_MMM_A0_peaks (i,j-1:j)=0;
            end
        end
    end
end

rTD_PTO_MMM_A0peaks = all(PTO_MMM_A0_peaks==0,2);
PTO_MMM_A0_peaks(rTD_PTO_MMM_A0peaks, :)=[];

% HighestFeatureMin = max(nonzeros(PTO_MMM_A0(:,1))); % atrocius. This was fine on 18Sep. In 24 Sep, I have used A0 peaks instead of A0. 
% HighestFeatureMean = max(nonzeros(PTO_MMM_A0(:,3)));
% HighestFeatureMax = max(nonzeros(PTO_MMM_A0(:,5)));

% corrected on 26Sep2025
HighestFeatureMin = max(nonzeros(PTO_MMM_A0_peaks(:,1)));
HighestFeatureMean = max(nonzeros(PTO_MMM_A0_peaks(:,3)));
HighestFeatureMax = max(nonzeros(PTO_MMM_A0_peaks(:,5)));

%change from 19 Sep: If the highest feature of min mad and mean in PTOMMM is the same, then there is only one oscillation peak there.  

DiffPeakmin = HighestFeatureMin  - LowestFeatureMin;
DiffPeakmean = HighestFeatureMean  - LowestFeatureMean;
DiffPeakmax = HighestFeatureMax  - LowestFeatureMax;
%
Thresholdmin = (DiffPeakmin*0.65) + LowestFeatureMin;%Find peaks at more than two-thirds amplitude for MAP
Thresholdmean = (DiffPeakmean*0.65) + LowestFeatureMean;
Thresholdmax = (DiffPeakmax*0.65) + LowestFeatureMax;

Thresholdmin2 = (DiffPeakmin*0.33) + LowestFeatureMin;% find troughs at less than one-third amplitude for sys and dia
Thresholdmean2 = (DiffPeakmean*0.33) + LowestFeatureMean;
Thresholdmax2 = (DiffPeakmax*0.33) + LowestFeatureMax;
%
Thresholdmin3 = (DiffPeakmin*0.4) + LowestFeatureMin; % find peaks at less than 0.4 amplitude for sys and dia
Thresholdmean3 = (DiffPeakmean*0.4) + LowestFeatureMean;
Thresholdmax3 = (DiffPeakmax*0.4) + LowestFeatureMax;

Thresholdmin45 = (DiffPeakmin*0.45) + LowestFeatureMin;% find troughs at less than 0.45 amplitude for sys and dia
Thresholdmean45 = (DiffPeakmean*0.45) + LowestFeatureMean;
Thresholdmax45 = (DiffPeakmax*0.45) + LowestFeatureMax;
%
Thresholdmin5 = (DiffPeakmin*0.5) + LowestFeatureMin; % find peaks at less than half amplitude for sys and dia
Thresholdmean5 = (DiffPeakmean*0.5) + LowestFeatureMean;
Thresholdmax5= (DiffPeakmax*0.5) + LowestFeatureMax;

 PTO_MMM_A = PTO_MMM_A0;

PTO_MMM_A(:,13)= PTO_MMM_A(:,1)-Thresholdmin; %finding 2/3 of amplitude of oscillations for troughs in min?
PTO_MMM_A(:,14)= PTO_MMM_A(:,7)-Thresholdmin;%finding 2/3 of amplitude of oscillations for peaks in min?
PTO_MMM_A(:,15)= PTO_MMM_A(:,3)-Thresholdmean;%finding 2/3 of amplitude of oscillations for troughs in mean?
PTO_MMM_A(:,16)= PTO_MMM_A(:,9)-Thresholdmean;%finding 2/3 of amplitude of oscillations for peaks in mean?
PTO_MMM_A(:,17)= PTO_MMM_A(:,5)-Thresholdmax;%finding 2/3 of amplitude of oscillations for troughs in max?
PTO_MMM_A(:,18)= PTO_MMM_A(:,11)-Thresholdmax;%finding 2/3 of amplitude of oscillations for peaks in max?

%scoring system to check if the HighestFeatureMin is correct. Sometimes,
%there isonly one oscillation and that detracks everything. eg, 100
%dataset batch 3 220402AP

for i = 1:size(PTO_MMM_A,1)
    if PTO_MMM_A(i,1)==0
        PTO_MMM_A(i, 13)=0;
    end
    
    if PTO_MMM_A(i,7)==0
        PTO_MMM_A(i, 14)=0;
    end
    
    if PTO_MMM_A(i,3)==0
        PTO_MMM_A(i, 15)=0;
    end
    if PTO_MMM_A(i,9)==0
        PTO_MMM_A(i, 16)=0;
    end
    
    if PTO_MMM_A(i,5)==0
        PTO_MMM_A(i, 17)=0;
    end
    if PTO_MMM_A(i,11)==0
        PTO_MMM_A(i, 18)=0;
    end
end
%%
PTO_MMM_B = PTO_MMM_A;
%In ibp/nibp 18091102, there is a peak after Csys, which confuses code
%further. Delete those peaks that come after Csys

for i = 1:size(PTO_MMM_B,1)
    
    if PTO_MMM_B(i,2)> Chighsys_guess_fig25
        PTO_MMM_B(i,1:2)=0;
    end
    
    if PTO_MMM_B(i,4)> Chighsys_guess_fig25
        PTO_MMM_B(i,3:4)=0;
    end
    
    if PTO_MMM_B(i,6)> Chighsys_guess_fig25
        PTO_MMM_B(i,5:6)=0;
    end
    
    if PTO_MMM_B(i,8)> Chighsys_guess_fig25
        PTO_MMM_B(i,7:8)=0;
    end
    
    if PTO_MMM_B(i,10)> Chighsys_guess_fig25
        PTO_MMM_B(i,9:10)=0;
    end
    
    if PTO_MMM_B(i,12)> Chighsys_guess_fig25
        PTO_MMM_B(i,11:12)=0;
    end
end

for i = 1:size(PTO_MMM_B,1)
    
    if PTO_MMM_B (i,13)<0 %If the peak or trough is below threshold, it is not likely to be MAP
        PTO_MMM_B (i, 1:2)=0;
    end
    
    if PTO_MMM_B(i,1:2)==0
        PTO_MMM_B(i, 13)=0;
    end
    
    if PTO_MMM_B(i,14)<0
        PTO_MMM_B(i, 7:8)=0;
    end
    
    if PTO_MMM_B(i,7:8)==0
        PTO_MMM_B(i, 14)=0;
    end
    
    if PTO_MMM_B(i,15)<0
        PTO_MMM_B(i, 3:4)=0;
    end
    
    if PTO_MMM_B(i,3:4)==0
        PTO_MMM_B(i, 15)=0;
    end
    
    if PTO_MMM_B (i,16)<0
        PTO_MMM_B (i, 9:10)=0;
    end
    
    if PTO_MMM_B(i,9:10)==0
        PTO_MMM_B(i, 16)=0;
    end
    
    if PTO_MMM_B(i,17)<0
        PTO_MMM_B(i, 5:6)=0;
    end
    
    if PTO_MMM_B(i,5:6)==0
        PTO_MMM_B(i, 17)=0;
    end
    
    if PTO_MMM_B(i,18)<0
        PTO_MMM_B(i, 11:12)=0;
    end
    
    if PTO_MMM_B(i,11:12)==0
        PTO_MMM_B(i, 18)=0;
    end
end

%Remove rows where all entries are zero - to get the rows for MAP
PTO_MMM_M = PTO_MMM_B;
PTO_MMM_M12 = PTO_MMM_M(:,1:12);
for i = 1:size(PTO_MMM_M12,1)
    PTO_MMM_M12Logical(i,1) = all(PTO_MMM_M12(i, :)==0);
end

PTO_MMM_M12 = PTO_MMM_M12(~PTO_MMM_M12Logical, :);

%%
PTO_MMM_SD = PTO_MMM_A;

PTO_MMM_SD(:,13)= PTO_MMM_SD(:,1)-Thresholdmin2; %finding 1/3 of amplitude of oscillations for troughs in min?
PTO_MMM_SD(:,14)= PTO_MMM_SD(:,7)-Thresholdmin3;%finding 0.4 of amplitude of oscillations for peaks in min?
PTO_MMM_SD(:,15)= PTO_MMM_SD(:,3)-Thresholdmean2;%finding 1/3 of amplitude of oscillations for troughs in mean?
PTO_MMM_SD(:,16)= PTO_MMM_SD(:,9)-Thresholdmean3;%finding 0.4  of amplitude of oscillations for peaks in mean?
%PTO_MMM_SD(:,17)= PTO_MMM_SD(:,5)-Thresholdmax2;%finding 1/3 of amplitude of oscillations for troughs in max?
PTO_MMM_SD(:,17)= PTO_MMM_SD(:,5)-Thresholdmax3;%finding 0.4 of amplitude of oscillations for even peaks in max
PTO_MMM_SD(:,18)= PTO_MMM_SD(:,11)-Thresholdmax3;%finding 0.4 of amplitude of oscillations for peaks in max?

for i = 1:size(PTO_MMM_SD,1)
    
    if PTO_MMM_SD (i,13)>0 %If the peak or trough is above threshold2, it is not likely to be sys or dia
        PTO_MMM_SD (i, 1:2)=0;
    end
    
    if PTO_MMM_SD(i,1:2)==0
        PTO_MMM_SD(i, 13)=0;
    end
    
    if PTO_MMM_SD(i,14)>0
        PTO_MMM_SD(i, 7:8)=0;
    end
    
    if PTO_MMM_SD(i,7:8)==0
        PTO_MMM_SD(i, 14)=0;
    end
    
    if PTO_MMM_SD(i,15)>0
        PTO_MMM_SD(i, 3:4)=0;
    end
    
    if PTO_MMM_SD(i,3:4)==0
        PTO_MMM_SD(i, 15)=0;
    end
    
    if PTO_MMM_SD (i,16)>0
        PTO_MMM_SD (i, 9:10)=0;
    end
    
    if PTO_MMM_SD(i,9:10)==0
        PTO_MMM_SD(i, 16)=0;
    end
    
    if PTO_MMM_SD(i,17)>0
        PTO_MMM_SD(i, 5:6)=0;
    end
    
    if PTO_MMM_SD(i,5:6)==0
        PTO_MMM_SD(i, 17)=0;
    end
    
    if PTO_MMM_SD(i,18)>0
        PTO_MMM_SD(i, 11:12)=0;
    end
    
    if PTO_MMM_SD(i,11:12)==0
        PTO_MMM_SD(i, 18)=0;
    end
end

temp_PTO_MMM_SD = PTO_MMM_SD;
idx_PTO_MMM_SD = ~all(temp_PTO_MMM_SD==0, 2); % Find the rows without zero entries using logical indexing
temp_PTO_MMM_SD = temp_PTO_MMM_SD(idx_PTO_MMM_SD,:); % Select the rows without zero entries using logical indexing
PTO_MMM_SD = temp_PTO_MMM_SD;

PTO_MMM_D = PTO_MMM_SD;

colwithPressure = [2,4,6,8,10,12];

for i =1:size(PTO_MMM_D,1)
    for j = colwithPressure
        if PTO_MMM_D(i,j) > min(max(xmax3new,x_max5new), MAP_higherlimitOscDatapoints_a) % changed on 27Apr2025; further on 11Jun
            PTO_MMM_D(i,j)=0;
            PTO_MMM_D(i,j-1)=0;
        end
    end
end

temp_PTO_MMM_D = PTO_MMM_D (:,1:12);
idx_PTO_MMM_D = ~all(temp_PTO_MMM_D==0, 2); % Find the rows without zero entries using logical indexing
temp_PTO_MMM_D = temp_PTO_MMM_D(idx_PTO_MMM_D,:); % Select the rows without zero entries using logical indexing
PTO_MMM_D = temp_PTO_MMM_D;
%%
PTO_MMM_S = PTO_MMM_SD;

colwithPressure = [2,4,6,8,10,12];

for i =1:size(PTO_MMM_S,1)
    for j = colwithPressure
        if PTO_MMM_S(i,j) < min(max(xmax3new,x_max5new), MAP_higherlimitOscDatapoints_a) % changed on 27Apr 2025
            PTO_MMM_S(i,j)=0;
            PTO_MMM_S(i,j-1)=0;
        end
    end
end

for i = 1:size(PTO_MMM_S,1)
    
    if PTO_MMM_S (i,13)>0 %If the peak or trough is above threshold2, it is not likely to be sys or dia
        PTO_MMM_S (i, 1:2)=0;
    end
    
    if PTO_MMM_S(i,1:2)==0
        PTO_MMM_S(i, 13)=0;
    end
    
    if PTO_MMM_S(i,14)>0
        PTO_MMM_S(i, 7:8)=0;
    end
    
    if PTO_MMM_S(i,7:8)==0
        PTO_MMM_S(i, 14)=0;
    end
    
    if PTO_MMM_S(i,15)>0
        PTO_MMM_S(i, 3:4)=0;
    end
    
    if PTO_MMM_S(i,3:4)==0
        PTO_MMM_S(i, 15)=0;
    end
    
    if PTO_MMM_S (i,16)>0
        PTO_MMM_S (i, 9:10)=0;
    end
    
    if PTO_MMM_S(i,9:10)==0
        PTO_MMM_SD(i, 16)=0;
    end
    
    if PTO_MMM_S(i,17)>0
        PTO_MMM_S(i, 5:6)=0;
    end
    
    if PTO_MMM_S(i,5:6)==0
        PTO_MMM_S(i, 17)=0;
    end
    
    if PTO_MMM_S(i,18)>0
        PTO_MMM_S(i, 11:12)=0;
    end
    
    if PTO_MMM_S(i,11:12)==0
        PTO_MMM_S(i, 18)=0;
    end
end

temp_PTO_MMM_S = PTO_MMM_S (:,1:12);
idx_PTO_MMM_S = ~all(temp_PTO_MMM_S==0, 2); % Find the rows without zero entries using logical indexing
temp_PTO_MMM_S = temp_PTO_MMM_S(idx_PTO_MMM_S,:); % Select the rows without zero entries using logical indexing
PTO_MMM_S = temp_PTO_MMM_S;
%%
%sometimes systolic pressures is above the threshold we set so PTO_MMM_S is
%empty.if empty then raise teh threshold
if isempty(PTO_MMM_S) | all(all(PTO_MMM_S(:,1:6)==0))
    PTO_MMM_S = PTO_MMM_A;
    
    for i =1:size(PTO_MMM_S,1)
        for j = colwithPressure
            if PTO_MMM_S(i,j) < min(max(xmax3new,x_max5new), MAP_higherlimitOscDatapoints_a) % changed on 27Apr 2025
                PTO_MMM_S(i,j)=0;
                PTO_MMM_S(i,j-1)=0;
            end
        end
    end
    
    PTO_MMM_S(:,13)= PTO_MMM_S(:,1)-Thresholdmin45; %finding 0.45 of amplitude of oscillations for troughs in min?
    PTO_MMM_S(:,14)= PTO_MMM_S(:,7)-Thresholdmin5;%finding 0.5 of amplitude of oscillations for peaks in min?
    PTO_MMM_S(:,15)= PTO_MMM_S(:,3)-Thresholdmean45;%finding 0.45 of amplitude of oscillations for troughs in mean?
    PTO_MMM_S(:,16)= PTO_MMM_S(:,9)-Thresholdmean5;%finding 0.5  of amplitude of oscillations for peaks in mean?
    PTO_MMM_S(:,17)= PTO_MMM_S(:,5)-Thresholdmax45;%finding 0.45 of amplitude of oscillations for troughs in max?
    PTO_MMM_S(:,18)= PTO_MMM_S(:,11)-Thresholdmax5;%finding 0.5 of amplitude of oscillations for peaks in max?
    
    for i = 1:size(PTO_MMM_S,1)
        
        if PTO_MMM_S (i,13)>0 %If the peak or trough is above threshold2, it is not likely to be sys or dia
            PTO_MMM_S (i, 1:2)=0;
        end
        
        if PTO_MMM_S(i,1:2)==0
            PTO_MMM_S(i, 13)=0;
        end
        
        if PTO_MMM_S(i,14)>0
            PTO_MMM_S(i, 7:8)=0;
        end
        
        if PTO_MMM_S(i,7:8)==0
            PTO_MMM_S(i, 14)=0;
        end
        
        if PTO_MMM_S(i,15)>0
            PTO_MMM_S(i, 3:4)=0;
        end
        
        if PTO_MMM_S(i,3:4)==0
            PTO_MMM_S(i, 15)=0;
        end
        
        if PTO_MMM_S (i,16)>0
            PTO_MMM_S (i, 9:10)=0;
        end
        
        if PTO_MMM_S(i,9:10)==0
            PTO_MMM_SD(i, 16)=0;
        end
        
        if PTO_MMM_S(i,17)>0
            PTO_MMM_S(i, 5:6)=0;
        end
        
        if PTO_MMM_S(i,5:6)==0
            PTO_MMM_S(i, 17)=0;
        end
        
        if PTO_MMM_S(i,18)>0
            PTO_MMM_S(i, 11:12)=0;
        end
        
        if PTO_MMM_S(i,11:12)==0
            PTO_MMM_S(i, 18)=0;
        end
    end
end

%%
temp_PTO_MMM_S = PTO_MMM_S;
idx_PTO_MMM_S = ~all(temp_PTO_MMM_S==0, 2); % Find the rows without zero entries using logical indexing
temp_PTO_MMM_S = temp_PTO_MMM_S(idx_PTO_MMM_S,:); % Select the rows without zero entries using logical indexing
PTO_MMM_S = temp_PTO_MMM_S;
%%
if isempty(PTO_MMM_S) | all(all(PTO_MMM_S(:,1:6)==0))
    PTO_MMM_S = PTO_MMM_A;
    colwithPressure = [2,4,6,8,10,12];
    
    for i =1:size(PTO_MMM_S,1)
        for j = colwithPressure
            %if PTO_MMM_S(i,j) < min(xmin3new,x_min5new)
            if PTO_MMM_S(i,j) < min(max(xmax3new,x_max5new), MAP_higherlimitOscDatapoints_a) % changed on 27Apr 2025
                PTO_MMM_S(i,j)=0;
                PTO_MMM_S(i,j-1)=0;
            end
        end
    end
    
    temp_PTO_MMM_S = PTO_MMM_S (:,1:12);
    idx_PTO_MMM_S = ~all(temp_PTO_MMM_S==0, 2); % Find the rows without zero entries using logical indexing
    temp_PTO_MMM_S = temp_PTO_MMM_S(idx_PTO_MMM_S,:); % Select the rows without zero entries using logical indexing
    PTO_MMM_S = temp_PTO_MMM_S;
end
%%
%figure(25)

%h_meanOsc = plot(fitresult{70}, x6Data, y6Data);
%set (h_meanOsc, 'color', 'k');
%hold on

%h_minOsc = plot( fitresult{71}, x7Data, y7Data);
%set (h_minOsc, 'color', 'b');

%h_maxOsc = plot( fitresult{72}, x8Data, y8Data);
%set (h_maxOsc, 'color', 'r');
%ylabel 'cuff pressure oscillation amplitude in mmHg';

%yyaxis right

%ylim ([-(0.2*(max(maxratiomat(:,2))))  (max(maxratiomat(:,2))+ 0.2*(max(maxratiomat(:,2))))]);

%h_minratio = plot(fitresult{73}); % fit results 84 etc are for ratios_0. These fits are correct. Dont change
%set (h_minratio, 'LineStyle', ':','color', 'b');
%h_maxratio = plot( fitresult{74});
%set (h_maxratio, 'LineStyle', ':','color', 'r');
%h_meanratio = plot( fitresult{75});
%set (h_meanratio,'LineStyle', ':','color', 'k');  %Have been plotting actual ratios without smsp till 17 Feb 2025

% hold on
% plot(fitx_tanTopsmsp_min ,fity_tanTopsmsp_min, 'LineStyle', '--','color', 'b' ); % tangent to smooth spline ratios min
% plot(fitx_tanTopsmsp_max ,fity_tanTopsmsp_max, 'LineStyle', '--','color', 'r' ); % tangent to smooth spline ratios max
%
%xlabel 'cuff pressure in mmHg';
%ylabel 'PPG amplitude ratio - arbitrary units';
%hold off
%legend ('off');
%title (expt_id);
%saveas(gcf,[expt_id 'fig25.fig']);

%%
if isempty(PTO_MMM_D)
    PTO_MMM_D = PTO_MMM_A;
end

for i= 1:size(PTO_MMM_D,1)
    if any(PTO_MMM_D(i,colwithPressure)>= Clowsys_guess_fig25)
        PTO_MMM_D(i:end, :)=0;
    end
end

if ~isempty(PTO_MMM_D)
    OscpointD1 = PTO_MMM_D (:,colwithPressure); %In the case of 18092102, the troughs in MAP range were too low and got included in dia troughs
    
    for i = 1:size(OscpointD1,1)
        for j= 1: size(OscpointD1,2)
            if OscpointD1(i,j)> max(H_all_trimmed(:,13))
                OscpointD1(i,j)=0;
            end
        end
    end
    
    OscpointD1(:, 7:10)= 0;
    OscpointD1(:, 6:8)= OscpointD1(:, 4:6);
    OscpointD1(:, 4:5)=0;
    
    temp_OscpointD1 = OscpointD1;
    
    idx_OscpointD1 = ~all(temp_OscpointD1==0, 2); % Find the rows without zero entries using logical indexing
    temp_OscpointD1 = temp_OscpointD1(idx_OscpointD1,:); % Select the rows without zero entries using logical indexing
    OscpointD1 = temp_OscpointD1;
    
    colwithPressureSD=[1,2,3,6,7,8];
end

%%
if exist('OscpointD1', 'var') && ~isempty(OscpointD1) %In case 18092002 there were no features below MAP peak
    if any(any(OscpointD1(:,1:3))>0)
        for i = size(OscpointD1,1):-1:1
            if any(any(OscpointD1(i, 1:3))>0)
                Phighdia = round(mean(nonzeros(OscpointD1(i,1:3))));
                if i > 1 && any(any(OscpointD1(i-1, 1:3))>0)
                    Plowdia = round(mean(nonzeros(OscpointD1(i-1,1:3))));
                else
                    Plowdia = min(nonzeros(OscpointD1(i,1:3)));
                end
                break
            end
        end
    end
end

if ~exist('Plowdia', 'var')
    Plowdia = PSysDiaMay2025(1,3);
end

if ~exist('Phighdia', 'var')
    Phighdia = PSysDiaMay2025(1,4);
end
%%
OscpointS0 = PTO_MMM_S(:,colwithPressure);

OscpointS1_logical = zeros(size(OscpointS0,1), size(OscpointS0,2));

for i = 1:size(OscpointS0,1)
    for j = 1:size(OscpointS0,2)
        if OscpointS0(i, j)>0
            OscpointS1_logical(i,j) = OscpointS0(i,j)> min(nonzeros([LSP, Clowsys_guess_fig25])) -2;
        else
            OscpointS1_logical(i,j) = 0;
        end
    end
end

OscpointS1 = OscpointS0.*OscpointS1_logical;

OscpointS1(:, 7:10)= 0;
OscpointS1(:, 6:8)= OscpointS1(:, 4:6);
OscpointS1(:, 4:5)=0;

for i = 1:size(OscpointS1,1)
    rTD_OscpointS1(i,1) = all(OscpointS1(i, :)==0); %Removal of row with all zeros
end

OscpointS1 = OscpointS1(~rTD_OscpointS1, :);

%%
colwithPressureSD =[1,2,3,6,7,8];

if size(OscpointS1,1)==1
    Plowsys_guess_fig25 = min(nonzeros(OscpointS1(1,colwithPressureSD)));
    if CsysGuessVar_fig25 <=20
        Phighsys_guess_fig25 = Plowsys_guess_fig25 + CsysGuessVar_fig25;
    else
        Phighsys_guess_fig25 = max(OscpointS1(1,colwithPressureSD));
    end
    
elseif size(OscpointS1,1)==2
    if any(OscpointS1(1,1:3)>0)
        Plowsys_guess_fig25 = round(mean(nonzeros(OscpointS1(1,1:3))));
    else
        Plowsys_guess_fig25 = round(mean(nonzeros(OscpointS1(1,colwithPressureSD))));
    end
    
    if mean(nonzeros(OscpointS1(2,colwithPressureSD)))- Plowsys_guess_fig25 >= CsysGuessVar_fig25
        Phighsys_guess_fig25 = mean(nonzeros(OscpointS1(2,colwithPressureSD)));
        
        %elseif max(nonzeros(OscpointS1(2,colwithPressureSD)))- Plowsys_guess_fig25 >= CsysGuessVar_fig25
        %Phighsys_guess_fig25 = max(nonzeros(OscpointS1(2,colwithPressureSD)));
    else
        %Phighsys_guess_fig25 = Plowsys_guess_fig25 + CsysGuessVar_fig25;
        Phighsys_guess_fig25 = max(nonzeros(OscpointS1(2,colwithPressureSD)));
    end
    
elseif size(OscpointS1,1)>2
    for i = 1:size(OscpointS1,1)-1 % Thoush the loop goes till end-1, the case of end is incorporated in this loop
        if any(OscpointS1(i,1:3)>0)
            if max(nonzeros(OscpointS1(i,1:3)))- min(nonzeros(OscpointS1(i,1:3)))>= CsysGuessVar_fig25
                Plowsys_guess_fig25 = min(nonzeros(OscpointS1(i,1:3)));
                Phighsys_guess_fig25 = max(nonzeros(OscpointS1(i,1:3)));
                break
                
            elseif min(nonzeros(OscpointS1(i+1,colwithPressureSD)))- mean(nonzeros(OscpointS1(i,1:3)))>= CsysGuessVar_fig25
                Plowsys_guess_fig25 = round(mean(nonzeros(OscpointS1(i,1:3))));
                Phighsys_guess_fig25 = min(nonzeros(OscpointS1(i+1,colwithPressureSD)));
                break
                
            elseif mean(nonzeros(OscpointS1(i+1,colwithPressureSD)))- mean(nonzeros(OscpointS1(i,1:3)))>= CsysGuessVar_fig25
                Plowsys_guess_fig25 = round(mean(nonzeros(OscpointS1(i,1:3))));
                Phighsys_guess_fig25 = round(mean(nonzeros(OscpointS1(i+1,colwithPressureSD))));
                break
                
            elseif (max(nonzeros(OscpointS1(i+1,colwithPressureSD)))- min(nonzeros(OscpointS1(i,1:3))))>= CsysGuessVar_fig25
                Plowsys_guess_fig25 = min(nonzeros(OscpointS1(i,1:3)));
                Phighsys_guess_fig25 = max(nonzeros(OscpointS1(i+1,colwithPressureSD)));
                break
            else
                Plowsys_guess_fig25 = mean(nonzeros(OscpointS1(i,1:3)));
                if i+2 <= size(OscpointS1,1)
                    if mean(nonzeros(OscpointS1(i+2,colwithPressureSD)))- Plowsys_guess_fig25 >= CsysGuessVar_fig25
                        Phighsys_guess_fig25 = mean(nonzeros(OscpointS1(i+2,colwithPressureSD)));
                        break
                    elseif max(nonzeros(OscpointS1(i+2,colwithPressureSD)))- Plowsys_guess_fig25 >= CsysGuessVar_fig25
                        Phighsys_guess_fig25 = max(nonzeros(OscpointS1(i+2,colwithPressureSD)));
                        break
                    else
                        OscpointS2 (:,:) = OscpointS1(i+1:end, :);
                        break
                    end
                end
            end
            
        elseif any(any(OscpointS1(end, 1:3)>0))
            Plowsys_guess_fig25 = round(mean(nonzeros(OscpointS1(end,1:3))));
            Phighsys_guess_fig25 = Plowsys_guess_fig25 + CsysGuessVar_fig25;
            break
        else
            Plowsys_guess_fig25 = round(mean(nonzeros(OscpointS1(i,1:3))));
            OscpointS2 (:,:) = OscpointS1(i+1:end, :);
            break
        end
    end
    
    if ~exist ('Phighsys_guess_fig25', 'var')|| isnan(Phighsys_guess_fig25)
        if ~isempty(OscpointS2)
            if size(OscpointS2,1)==2 % The case of size being one is dealt with in the previous loop as i+1
                
                if mean(nonzeros(OscpointS2(1:2,colwithPressureSD)))-Plowsys_guess_fig25 > CsysGuessVar_fig25 %the more than is given alone purposefully
                    Phighsys_guess_fig25 = round(mean(nonzeros(OscpointS2(1:2,colwithPressureSD))));
                    
                elseif min(nonzeros(OscpointS2(2,colwithPressureSD)))-Plowsys_guess_fig25 > CsysGuessVar_fig25 %the more than is given alone purposefully
                    Phighsys_guess_fig25 = min(nonzeros(OscpointS2(2,colwithPressureSD)));
                    
                elseif mean(nonzeros(OscpointS2(2,colwithPressureSD)))-Plowsys_guess_fig25 >= CsysGuessVar_fig25
                    Phighsys_guess_fig25 = round(mean(nonzeros(OscpointS2(2,colwithPressureSD))));
                    
                elseif max(nonzeros(OscpointS2(2,colwithPressureSD)))-Plowsys_guess_fig25 >= CsysGuessVar_fig25
                    Phighsys_guess_fig25 = max(nonzeros(OscpointS2(2,colwithPressureSD)));
                else
                    Phighsys_guess_fig25 = Plowsys_guess_fig25 + CsysGuessVar_fig25;
                end
                
            elseif size(OscpointS2,1)> 2 % rows 1 and 2 have been considered in the previous loop
                
                if mean(nonzeros(OscpointS2(2:3,colwithPressureSD)))-Plowsys_guess_fig25 >= CsysGuessVar_fig25
                    Phighsys_guess_fig25 = round(mean(nonzeros(OscpointS2(2:3,colwithPressureSD))));
                    
                elseif min(nonzeros(OscpointS2(3,colwithPressureSD)))-Plowsys_guess_fig25 > CsysGuessVar_fig25 %the more than is given alone purposefully
                    Phighsys_guess_fig25 = min(nonzeros(OscpointS2(3,colwithPressureSD)));
                    
                elseif mean(nonzeros(OscpointS2(3,colwithPressureSD)))-Plowsys_guess_fig25 >= CsysGuessVar_fig25
                    Phighsys_guess_fig25 = round(mean(nonzeros(OscpointS2(3,colwithPressureSD))));
                    
                elseif max(nonzeros(OscpointS2(3,colwithPressureSD)))-Plowsys_guess_fig25 >= CsysGuessVar_fig25
                    Phighsys_guess_fig25 = max(nonzeros(OscpointS2(3,colwithPressureSD)));
                else
                    Phighsys_guess_fig25 = Plowsys_guess_fig25 + CsysGuessVar_fig25;
                end
            else
                Phighsys_guess_fig25 = Plowsys_guess_fig25 + CsysGuessVar_fig25;
            end
        else
            Phighsys_guess_fig25 = Plowsys_guess_fig25 + CsysGuessVar_fig25;
        end
    end
end

if ~exist('Plowsys_guess_fig25', 'var')
    Plowsys_guess_fig25 = Clowsys_guess_fig25;
end

if ~exist('Phighsys_guess_fig25', 'var')
    Phighsys_guess_fig25 = Chighsys_guess_fig25;
end

Psysvar = Phighsys_guess_fig25 -  Plowsys_guess_fig25;
Csysvar = Chighsys_guess_fig25 -  Clowsys_guess_fig25;

%%
PDialow_arrayMay2025 = [Plowdia, PDialowMay2025];
PDiahigh_arrayMay2025 = [Phighdia, PDiahighMay2025];

DiaMatureArray = [PDialow_arrayMay2025,  PDiahigh_arrayMay2025, ClowDia_Candidates, 1, ChighDia_Candidates];% check: First and third columns are values from troughs, second and fourth columns from MMMandSD

if DiaMatureArray(1,2)- DiaMatureArray(1,1)> 15 || (DiaMatureArray(1,3)- DiaMatureArray(1,1)>= max([CsysGuessVar_fig25, Psysvar])&& max([CsysGuessVar_fig25, Psysvar])>=4)
    % Go back to MMMSDandMAP
    MMMSDandMAP_2 = MMMSDandMAP(MMMSDandMAP(:,1)<=DiaMatureArray(1,2),:);
    if any(~isnan(MMMSDandMAP_2(:,2)))
        for i = 1:size(MMMSDandMAP_2,1)-1
            if ~isnan(MMMSDandMAP_2(i,2)) && isnan(MMMSDandMAP_2(i+1, 2))
                MMMSDandMAP_3 = MMMSDandMAP_2(i+1:end, :) ;
            end
        end
        DiaMatureArray(1,2) = MMMSDandMAP_3(1,1) ;
    end
end

if DiaMatureArray(1,4)- DiaMatureArray(1,2)>= max([CsysGuessVar_fig25, Psysvar]) && max([CsysGuessVar_fig25, Psysvar])>=4
    % Go back to MMMSDandMAP
    MMMSDandMAP_4 = MMMSDandMAP(MMMSDandMAP(:,1)<=DiaMatureArray(1,4),:);
    if any(~isnan(MMMSDandMAP_4(:,2)))
        for i = 1:size(MMMSDandMAP_4,1)-1
            if ~isnan(MMMSDandMAP_4(i,2)) && isnan(MMMSDandMAP_4(i+1, 2))
                MMMSDandMAP_5 = MMMSDandMAP_4(i+1:end, :) ;
            end
        end
        DiaMatureArray(1,4) = MMMSDandMAP_5(1,1);
    end
end

if abs(DiaMatureArray(1,4)- DiaMatureArray(1,3))>= 15 && DiaMatureArray(1,3)> DiaMatureArray(1,4)%the second condition was added on Aug14, 2025
    % Go back to OscpointD1 and change DiaMatureArray(1,3)    
    OscpointD_forDMA = OscpointD1;
    for i = size(OscpointD_forDMA,1):-1:1
        if abs(mean(nonzeros(OscpointD_forDMA(i, 1:3)))- DiaMatureArray(1,3))<=2
            OscpointD_forDMA(i,:)= 0;
        end
    end
    DiaMatureArray(1,3) = max(OscpointD_forDMA(:,1));
end

% columns 1 and 3 are troughs and are more important. If there are entries
% here, and have support from C values that are in columns 5 upwards, take them as P dia.

%Arrange similar values in a row
for i = 1:size(DiaMatureArray,2)% yes 2 and not 1
    for j = 1:size(DiaMatureArray,2)
        if i <= size(DiaMatureArray,1)
            if DiaMatureArray(i,j)> min(nonzeros(DiaMatureArray(i,:)))+3
                addrowsDMA = zeros(1, size(DiaMatureArray,2));
                DiaMatureArray = [DiaMatureArray; addrowsDMA];
                DiaMatureArray(i+1,j)= DiaMatureArray(i,j);
                DiaMatureArray(i,j)=0;
            end
        end
    end
end

for i = 1:size(DiaMatureArray,1)
    DiaMatureArrayLogical(i,1) = sum(DiaMatureArray(i,:))==0;
end

DiaMatureArray = DiaMatureArray(~DiaMatureArrayLogical,:);
% columns 1 and 3 are troughs and are more important. If there are entries
% here, and have support from C values that are in columns 5 upwards, take them as P dia.

[~, colindexDMA] = find(DiaMatureArray(1,:)==1);
%%
addcol = zeros(size(DiaMatureArray,1), 4);
DiaMatureArray = [DiaMatureArray, addcol];

diavarGuessmax = min(CsysGuessVar_fig25, Psysvar);

for i = 1:size(DiaMatureArray,1)
    DiaMatureArray(i,end-3)= round(mean(nonzeros(DiaMatureArray(i, 1:2)))); %mean of Plowdia candidates
    DiaMatureArray(i,end-2)= round(mean(nonzeros(DiaMatureArray(i, 3:4)))); %mean of Phighdia candidates
    DiaMatureArray(i,end-1)= round(mean(nonzeros(DiaMatureArray(i, 5:colindexDMA)))); %mean of L points or Clowdia candidates
    DiaMatureArray(i,end)= round(mean(nonzeros(DiaMatureArray(i, colindexDMA+1:end-4)))); %mean of H points or Chighdia candidates
end

%make all NANs to 0

for i= 1:size(DiaMatureArray,1)
    for j= 1:size(DiaMatureArray,2)
        if isnan(DiaMatureArray(i,j))|| DiaMatureArray(i,j)==1 %The col separating L and H has an entry 1
            DiaMatureArray(i,j)=0;
        end
    end
end

% Merge rows further
for i = 2: size(DiaMatureArray,1)
    if mean(nonzeros(DiaMatureArray(i,end-3:end-2)))- mean(nonzeros(DiaMatureArray(i-1,end-3:end-2)))<=6
        for j=1:4
            if DiaMatureArray(i,j)>0 && DiaMatureArray(i-1,j)==0
                DiaMatureArray(i-1,j)=DiaMatureArray(i,j);
                DiaMatureArray(i,j)=0;
            end
        end
    end
end

%make all NANs to 0

for i= 1:size(DiaMatureArray,1)
    for j= 1:size(DiaMatureArray,2)
        if isnan(DiaMatureArray(i,j))|| DiaMatureArray(i,j)==1 %The col separating L and H has an entry 1
            DiaMatureArray(i,j)=0;
        end
    end
end

%Recalculate means
for i = 1: size(DiaMatureArray,1)
    DiaMatureArray(i,end-3)= round(mean(nonzeros(DiaMatureArray(i, 1:2)))); %mean of Plowdia candidates
    DiaMatureArray(i,end-2)= round(mean(nonzeros(DiaMatureArray(i, 3:4)))); %mean of Phighdia candidates
end
% Rearrange C as well
for i = 2: size(DiaMatureArray,1)
    if mean(nonzeros(DiaMatureArray(i,end-1:end)))- mean(nonzeros(DiaMatureArray(i-1,end-3:end-2)))<5 || mean(nonzeros(DiaMatureArray(i,end-3:end-2)))- mean(nonzeros(DiaMatureArray(i-1,end-1:end)))<5
        for j=5:(size(DiaMatureArray,2)-4)
            if DiaMatureArray(i,j)>0 && DiaMatureArray(i-1,j)==0
                DiaMatureArray(i-1,j)=DiaMatureArray(i,j);
                DiaMatureArray(i,j)=0;
            end
        end
    end
end

%make all NANs to 0
for i= 1:size(DiaMatureArray,1)
    for j= 1:size(DiaMatureArray,2)
        if isnan(DiaMatureArray(i,j))|| DiaMatureArray(i,j)==1 %The col separating L and H has an entry 1
            DiaMatureArray(i,j)=0;
        end
    end
end
%Recalculate means
for i = 1: size(DiaMatureArray,1)
    DiaMatureArray(i,end-1)= round(mean(nonzeros(DiaMatureArray(i, 5:colindexDMA-1)))); %mean of Plowdia candidates
    DiaMatureArray(i,end)= round(mean(nonzeros(DiaMatureArray(i, colindexDMA+1:end-4)))); %mean of Phighdia candidates
end

%make all NANs to 0

for i= 1:size(DiaMatureArray,1)
    for j= 1:size(DiaMatureArray,2)
        if isnan(DiaMatureArray(i,j))|| DiaMatureArray(i,j)==1 %The col separating L and H has an entry 1
            DiaMatureArray(i,j)=0;
        end
    end
end

%%
%Get Phighdia or diahigh2
sizeDMA_row = size(DiaMatureArray,1);
sizeDMA_col = size(DiaMatureArray,2);

for i = sizeDMA_row:-1:2 % Top row is always 0, because of insertion of 1 as a divider
    if any(DiaMatureArray(i,sizeDMA_col-3:sizeDMA_col-2)>0) && any(DiaMatureArray(i,sizeDMA_col-1:sizeDMA_col)>0)
        if any(DiaMatureArray(i,3:4)>0)
            diahigh2 = max(DiaMatureArray(i, 3:4));
            break
        end
    end
end

%In the following loop, if any C value is missing in the row with P, but there
%are C values close to but above and below P values above diahigh2,
%consider them

if exist('diahigh2','var') && diahigh2 < max(max(DiaMatureArray(:, sizeDMA_col-3:sizeDMA_col-2)))
    %get those values
    diahigh2_OtherCand_logical = DiaMatureArray(:, sizeDMA_col-3:sizeDMA_col-2)>diahigh2;
    diahigh2_OtherCand = nonzeros(DiaMatureArray(:, sizeDMA_col-3:sizeDMA_col-2).*diahigh2_OtherCand_logical);
    diahigh2for_CheckC = nonzeros(DiaMatureArray(:, sizeDMA_col-1:sizeDMA_col));
    if any(diahigh2for_CheckC>min(nonzeros(diahigh2_OtherCand))-5)
        for j= 1:size(diahigh2for_CheckC,1)
        for i = 1:size(diahigh2_OtherCand,1)            
                diahigh2_OtherCand(i,j+1)= diahigh2for_CheckC (j,1)-diahigh2_OtherCand(i,1);
            end
        end
    end
    if any(any(abs(diahigh2_OtherCand(:,2:end))<=5))
        absDiff_diahigh2_OtherCand= abs(diahigh2_OtherCand(:,2:end));
        rI_diahigh2_OtherCand_1 = min(absDiff_diahigh2_OtherCand, [],2);
        [~,rI_diahigh2_OtherCand]=min(rI_diahigh2_OtherCand_1);
        diahigh2 = diahigh2_OtherCand(rI_diahigh2_OtherCand,1);
    end
end

if ~exist('diahigh2', 'var')|| isempty(diahigh2)
    diahigh2 = max(max(DiaMatureArray(:, sizeDMA_col-3:sizeDMA_col-2)));
end

%Get dialow2
for i = sizeDMA_row:-1:2
    if any(DiaMatureArray(i,sizeDMA_col-3:sizeDMA_col-2)>0) && any(DiaMatureArray(i,sizeDMA_col-1:sizeDMA_col)>0)
        if any(DiaMatureArray(i,1:2)>0)
            dialow2 = max(DiaMatureArray(i, 1:2));
            break
        else
            dialow2_cand = nonzeros(DiaMatureArray(:,1:2));
            dialow2_cand = dialow2_cand(dialow2_cand< diahigh2);
            dialow2 = max(dialow2_cand);
        end
    end
end

for i = size(DiaMatureArray,1):-1:2
    if any(DiaMatureArray(i,sizeDMA_col-3:sizeDMA_col-2)>0) && any(DiaMatureArray(i,sizeDMA_col-1:sizeDMA_col)>0)
        if any(DiaMatureArray(i,colindexDMA+1:end-4)>0)
            diahigh1 = max(DiaMatureArray(i, colindexDMA+1:end-4));
            break
        end
    end
end

if (~exist('diahigh1', 'var') || diahigh1 < (diahigh2-5)) %reconsider
    diahigh1_cand = nonzeros(DiaMatureArray(:,sizeDMA_col-1:sizeDMA_col));
    diahigh1_cand = diahigh1_cand(diahigh1_cand >= diahigh2 & diahigh1_cand <= diahigh2+6);% +4 was changed to +6 on 20Aug2025
    if exist('diahigh1_cand', 'var')&& ~isempty(diahigh1_cand)
        diahigh1 = min(diahigh1_cand);
    else
        diahigh1=diahigh2;
    end
end

%Get dialow1
for i = size(DiaMatureArray,1):-1:2
    if any(DiaMatureArray(i,sizeDMA_col-3:sizeDMA_col-2)>0) && any(DiaMatureArray(i,sizeDMA_col-1:sizeDMA_col)>0)
       if any(DiaMatureArray(i,sizeDMA_col-1)>0)
            dialow1 = DiaMatureArray(i, sizeDMA_col-1);
            break
        else
            dialow1_cand = nonzeros(DiaMatureArray(:,sizeDMA_col-1:sizeDMA_col));
            dialow1_cand = dialow1_cand(dialow1_cand < diahigh1);
        end
        
        if exist('dialow1_cand', 'var')&& ~isempty(dialow1_cand)
            dialow1 = max(dialow1_cand);
        else
            dialow1 = diahigh1;
        end
    else
        dialow1 = diahigh1;
    end
end

if ~exist('dialow1', 'var')
    dialow1 = dialow2;
end

if ~exist('dialow2', 'var')
    dialow2 = dialow1;
end

if ~exist('diahigh1', 'var')
    diahigh1 = diahigh2;
end

if ~exist('diahigh2', 'var')
    diahigh2 = diahigh1;
end

if diahigh1-dialow1 > 2*(diahigh2-dialow2) && diahigh2-dialow2 > 4 % Cdiavar more than twice Pdiavar
   dia1_cand = nonzeros(DiaMatureArray(:,sizeDMA_col-1:sizeDMA_col));
    dia1_cand = dia1_cand(dia1_cand >= dialow2); 
    if ~isempty(dia1_cand)
    dialow1 = min(dia1_cand);
    end
    diahigh1_cand2 = dia1_cand(dia1_cand > dialow1);
    if~isempty(diahigh1_cand2)
    diahigh1 = min(diahigh1_cand2);
    end
end

if dialow2 > diahigh2
    dialow2hold = dialow2;
    dialow2 = diahigh2;
    diahigh2 = dialow2hold;
end

if dialow2 == diahigh2
    dialow2 = dialow2-2;
    diahigh2 = diahigh2+2;
end

if dialow1 == diahigh1
    dialow1 = dialow1-2;
    diahigh1 = diahigh1+2;
end
    
if dialow1 > diahigh1
    dialow1hold = dialow1;
    dialow1 = diahigh1;
    diahigh1 = dialow1hold;
end

DiaCPSep2025 = ([dialow1, diahigh1; dialow2, diahigh2]);
DiaCPSep2025(:,3)= DiaCPSep2025(:,2)-DiaCPSep2025(:,1);
DiaCPSep2025(3,:)= DiaCPSep2025(1,:)-DiaCPSep2025(2,:);

if DiaCPSep2025(1,3)> (max(Csysvar, Psysvar)+3) && DiaCPSep2025(2,3)< (max(Csysvar, Psysvar)+3)
    %revise Cdia
    [~,cIDia]= min(abs(DiaCPSep2025(3,1:2)));
    if cIDia ==2 %Chigh dia close to Phighdia. Change Clowdia
        for i = size(DiaMatureArray,1):-1:2
            if DiaMatureArray(i,sizeDMA_col-1)>0 && DiaMatureArray(i,sizeDMA_col-1)< diahigh1
                dialow1 = DiaMatureArray(i, sizeDMA_col-1);
                break
            end
        end      
    end
end

% Case of C high dia being too high is not dealt here as it is still
% imaginary. Will do if situation arises.         
        
%%
%dia values from tangents to sigmoid fits
Dia_LH_SigmoidPolyArray(1,1)= dialow1;
Dia_LH_SigmoidPolyArray(1,2)= diahigh1;
%
Dia_LH_SigmoidPolyArray(3:5,1)= diasigmoidMatrix(1:3, 1);
Dia_LH_SigmoidPolyArray(3:5,2)= diasigmoidMatrix(1:3, 2);
Dia_LH_SigmoidPolyArray(6,1:2)= [dialow6 ,diahigh6];
%%
SysDia_SSParray = [Syssmsp_SigmoidPolyArray1, Dia_LH_SigmoidPolyArray];
SysDia_SSParray(:,5)= SysDia_SSParray(:,2)- SysDia_SSParray(:,1);
SysDia_SSParray(:,6)= SysDia_SSParray(:,4)- SysDia_SSParray(:,3);
%%
%Dia_matrix_low1 = [dialow1, dialow2, SysDia_SSParray(3,3), SysDia_SSParray(4,3), SysDia_SSParray(5,3), dialow6];
Dia_matrix_low1 = [dialow1, dialow2, SysDia_SSParray(3,3), SysDia_SSParray(4,3), SysDia_SSParray(5,3), SysDia_SSParray(6,3)];

Dia_matrix_low1 = Dia_matrix_low1';

%Dia_matrix_high1 = [diahigh1, diahigh2, SysDia_SSParray(3,4), SysDia_SSParray(4,4), SysDia_SSParray(5,4), diahigh6];
Dia_matrix_high1 = [diahigh1, diahigh2, SysDia_SSParray(3,4), SysDia_SSParray(4,4), SysDia_SSParray(5,4), SysDia_SSParray(6,4)];

Dia_matrix_high1 = Dia_matrix_high1';
Dia_matrix = cat(2, Dia_matrix_low1, Dia_matrix_high1);
Dia_matrix1 = round (Dia_matrix);
%%
syslow1 =   Clowsys_guess_fig25;
syshigh1 =  Chighsys_guess_fig25;

syslow2 = Plowsys_guess_fig25;
syshigh2= Phighsys_guess_fig25;

Sys_matrix_low = [syslow1, syslow2, SysDia_SSParray(3,1), SysDia_SSParray(4,1), SysDia_SSParray(5,1), SysDia_SSParray(6,1)];
Sys_matrix_low = Sys_matrix_low';
Sys_matrix_high = [syshigh1, syshigh2, SysDia_SSParray(3,2), SysDia_SSParray(4,2), SysDia_SSParray(5,2), SysDia_SSParray(6,2)];
Sys_matrix_high = Sys_matrix_high';
Sys_matrix = cat(2, Sys_matrix_low, Sys_matrix_high);

Sys_matrix1 = round (Sys_matrix);
Sys_Dia_matrix = cat (2, Sys_matrix1, Dia_matrix1);

%Case of 18092502 where the mean sigmoids were NaN or a wrong value

if any(isnan(Sys_Dia_matrix(3,1:4)))
    Sys_Dia_matrix(3,1:4)= Sys_Dia_matrix(4,1:4);
end

if any(isnan(Sys_Dia_matrix(4,1:4)))
    Sys_Dia_matrix(4,1:4)= Sys_Dia_matrix(5,1:4);
end

if any(isnan(Sys_Dia_matrix(5,1:4)))
    Sys_Dia_matrix(5,1:4)= Sys_Dia_matrix(4,1:4);
end

for i = 3:6
    for j = 3:4
        if Sys_Dia_matrix(i,j)<0
            Sys_Dia_matrix(i,j)=0;
            Sys_Dia_matrix(i,j)= min(nonzeros(Sys_Dia_matrix(3:5, j)));
        end
    end
end

for i = 3:5
    for j = 3:4
        if Sys_Dia_matrix(i,j)< Sys_Dia_matrix(6,j)
            Sys_Dia_matrix(i,j)= Sys_Dia_matrix(6,j);
        end
    end
end

for i = 3:5
    if Sys_Dia_matrix(i,4)- Sys_Dia_matrix(i,3)> 3*(max(Sys_Dia_matrix(1:2,4))- min(Sys_Dia_matrix(1:2,3)))
        if Sys_Dia_matrix(i,4)> max(Sys_Dia_matrix(1:2,4))- min(Sys_Dia_matrix(1:2,3))
            Sys_Dia_matrix(i,3)= Sys_Dia_matrix(i,4)- (max(Sys_Dia_matrix(1:2,4))- min(Sys_Dia_matrix(1:2,3)));
        end
    end
end

for i = 3:5
    if Sys_Dia_matrix(i,3)>Sys_Dia_matrix(i,1)% when dia is higher than sys for low
        Sys_Dia_matrix(i,3)=Sys_Dia_matrix(i,1)-15;
    end
    
    if Sys_Dia_matrix(i,4)>Sys_Dia_matrix(i,2)% when dia is higher than sys for low
        Sys_Dia_matrix(i,4)=Sys_Dia_matrix(i,2)-15;
    end
end
%%

for i = 1: size(Sys_Dia_matrix,1)
    %Sys_Dia_matrix (i, 5)= Sys_Dia_matrix (i, 3) + (0.36 * (Sys_Dia_matrix (i, 1)-Sys_Dia_matrix (i, 3)));  %To be very careful, since low MAP is going to be chosen from column 5, multiply with lowest ratio, say 0.24
    Sys_Dia_matrix (i, 5)= Sys_Dia_matrix (i, 3) + (0.3 * (Sys_Dia_matrix (i, 1)-Sys_Dia_matrix (i, 3)));  %To be very careful, since low MAP is going to be chosen from column 5, multiply with lowest ratio, say 0.36 or 0.3
    %Sys_Dia_matrix (i, 6)= Sys_Dia_matrix (i, 4) + (0.36 * (Sys_Dia_matrix (i, 2)-Sys_Dia_matrix (i, 4)));
    Sys_Dia_matrix (i, 6)= Sys_Dia_matrix (i, 4) + (0.4 * (Sys_Dia_matrix (i, 2)-Sys_Dia_matrix (i, 4))); %To be very careful, since high MAP is going to be chosen from column 5, multiply with highest ratio, say 0.45
    Sys_Dia_matrix (i, 7)= Sys_Dia_matrix (i, 2) - Sys_Dia_matrix (i, 1); %Sysvar
    Sys_Dia_matrix (i, 8)= Sys_Dia_matrix (i, 4) - Sys_Dia_matrix (i, 3); %Diavar
    Sys_Dia_matrix (i, 9)= Sys_Dia_matrix (i, 6) - Sys_Dia_matrix (i, 5); %MAPvar
    Sys_Dia_matrix (i, 10)= Sys_Dia_matrix (i, 3) + (0.4 * (Sys_Dia_matrix (i, 1)-Sys_Dia_matrix (i, 3)));
    Sys_Dia_matrix (i, 11)= Sys_Dia_matrix (i, 4) + (0.33 * (Sys_Dia_matrix (i, 2)-Sys_Dia_matrix (i, 4)));
    Sys_Dia_matrix (i, 12)= Sys_Dia_matrix (i, 3) + (0.36 * (Sys_Dia_matrix (i, 1)-Sys_Dia_matrix (i, 3)));
    Sys_Dia_matrix (i, 13)= Sys_Dia_matrix (i, 4) + (0.27 * (Sys_Dia_matrix (i, 2)-Sys_Dia_matrix (i, 4)));
    Sys_Dia_matrix (i, 14)= Sys_Dia_matrix (i, 3) + (0.45 * (Sys_Dia_matrix (i, 1)-Sys_Dia_matrix (i, 3)));
    Sys_Dia_matrix (i, 15)= Sys_Dia_matrix (i, 4) + (0.36 * (Sys_Dia_matrix (i, 2)-Sys_Dia_matrix (i, 4)));
    Sys_Dia_matrix(:,:)= round(Sys_Dia_matrix(:,:));
end
disp ('Sys_Dia_matrix with MAP guess');
disp (Sys_Dia_matrix);

%%
MAP_lowerLimit = min(Sys_Dia_matrix(1:2,5))-5;  %
MAP_higherLimit = max(Sys_Dia_matrix(1:3,6))+5;

col_lowMAP_SDM = [10, 12, 14];
col_highMAP_SDM = [11, 13, 15];
col_withMAP_SDM = sort([col_lowMAP_SDM, col_highMAP_SDM]);

MAP_lowCompare = round(mean(mean(Sys_Dia_matrix(1:2,col_lowMAP_SDM), 'omitnan')));
MAP_highCompare = round(mean(mean(Sys_Dia_matrix(1:2,col_highMAP_SDM),'omitnan')));

%The above was not enough for 18091902. The MAP iger limit came to 79 and
%te real peak in oscillation was missed. Therefore resetting to +5 or using
%the max of three rows, including sigmoid values

%%
OscpointM1 =[];

OscpointM1= PTO_MMM_M12(:, [2,4,6,8,10,12]);

OscpointM1(:, 7:10)= 0;
OscpointM1(:, 6:8)= OscpointM1(:, 4:6);
OscpointM1(:, 4:5)=0;

OscpointM1copy = OscpointM1;

colwithPressureM = [1,2,3,6,7,8];

for i = 1: size(OscpointM1,1)
    for j = [colwithPressureM]
        if OscpointM1(i,j)< MAP_lowerLimit - 10 || OscpointM1(i,j) > MAP_higherLimit+10
            OscpointM1(i,j)=0;
        end
    end
end

for i = 1: size(OscpointM1,1)
    rTDOscpointM1_Jun2025(i,1) = all(OscpointM1(i, :)==0);
end

OscpointM1(rTDOscpointM1_Jun2025, :)=[];

for i = 1:size(OscpointM1,1)
    if any(OscpointM1(i,6:8)>0) %Norms for MAP lower limit may have to be relaxed even here
        if max(nonzeros(OscpointM1(i,6:8)))>= MAP_lowerLimit && min(nonzeros(OscpointM1(i,6:8)))<= MAP_higherLimit
            OscpointM1(i,9)= MAP_lowCompare - mean(nonzeros(OscpointM1(i,6:8))); % +5 to account for the -5 while setting the limit
        else
            OscpointM1(i,9)=NaN;
        end
    else
        OscpointM1(i,9)=NaN;
    end
    
    if any(OscpointM1(i,1:3)>0)
        if max(nonzeros(OscpointM1(i,1:3)))>= MAP_lowerLimit && min(nonzeros(OscpointM1(i,1:3)))<= MAP_higherLimit
            OscpointM1(i,4)= MAP_lowCompare - mean(nonzeros(OscpointM1(i,1:3))); % +5 to account for the -5 while setting the limit
        else
            OscpointM1(i,4)=NaN;
        end
    else
        OscpointM1(i,4)=NaN;
    end
end

for i = 1:size(OscpointM1,1)
    if any(OscpointM1(i,6:8)>0)
        if max(nonzeros(OscpointM1(i,6:8)))>= MAP_lowerLimit && min(nonzeros(OscpointM1(i,6:8)))<= MAP_higherLimit
            OscpointM1(i,10)=  MAP_highCompare - mean(nonzeros(OscpointM1(i,6:8))); % -5 to account for the +5 while setting the limit
        else
            OscpointM1(i,10)=NaN;
        end
    else
        OscpointM1(i,10)=NaN;
    end
    
    if any(OscpointM1(i,1:3)>0)
        if max(nonzeros(OscpointM1(i,1:3)))>= MAP_lowerLimit && min(nonzeros(OscpointM1(i,1:3)))<= MAP_higherLimit
            OscpointM1(i,5)= MAP_highCompare - mean(nonzeros(OscpointM1(i,1:3)));
        else
            OscpointM1(i,5)=NaN;
        end
    else
        OscpointM1(i,5)=NaN;
    end
end

if all(all(isnan(OscpointM1(:, [4,5,9,10])))) % added on 17May
    OscpointM1 = OscpointM1copy;
    for i = 1:size(OscpointM1,1)
        if any(OscpointM1(i,6:8)>0) %Norms for MAP lower limit may have to be relaxed even here
            if max(nonzeros(OscpointM1(i,6:8)))>= MAP_lowerLimit && min(nonzeros(OscpointM1(i,6:8)))<= MAP_higherLimit
                OscpointM1(i,9)= MAP_lowCompare - mean(nonzeros(OscpointM1(i,6:8)));
            else
                OscpointM1(i,9)=NaN;
            end
        else
            OscpointM1(i,9)=NaN;
        end
        
        if any(OscpointM1(i,1:3)>0)
            if max(nonzeros(OscpointM1(i,1:3)))>= MAP_lowerLimit-5 && min(nonzeros(OscpointM1(i,1:3)))<= MAP_higherLimit+5
                OscpointM1(i,4)= MAP_lowCompare - mean(nonzeros(OscpointM1(i,1:3)));
            else
                OscpointM1(i,4)=NaN;
            end
        else
            OscpointM1(i,4)=NaN;
        end
    end
    
    for i = 1:size(OscpointM1,1)
        if any(OscpointM1(i,6:8)>0)
            if max(nonzeros(OscpointM1(i,6:8)))>= MAP_lowerLimit-5 && min(nonzeros(OscpointM1(i,6:8)))<= MAP_higherLimit+5
                OscpointM1(i,10)= MAP_highCompare - mean(nonzeros(OscpointM1(i,6:8)));
            else
                OscpointM1(i,10)=NaN;
            end
        else
            OscpointM1(i,10)=NaN;
        end
        
        if any(OscpointM1(i,1:3)>0)
            if max(nonzeros(OscpointM1(i,1:3)))>= MAP_lowerLimit && min(nonzeros(OscpointM1(i,1:3)))<= MAP_higherLimit+5
                OscpointM1(i,5)= MAP_highCompare - mean(nonzeros(OscpointM1(i,1:3)));
            else
                OscpointM1(i,5)=NaN;
            end
        else
            OscpointM1(i,5)=NaN;
        end
    end
end

OscpointM2 = OscpointM1;

for i = 1:size(OscpointM2,1)-1 % if there are 2 rows with negative values in col 5 or 10, remove the last one
    if ~isnan(OscpointM2(i,10)) || ~isnan(OscpointM2(i,5))
        if OscpointM2 (i,10)<0  || OscpointM2(i,5)<0
            if OscpointM2(i+1, 10)<0 || OscpointM2(i+1,5)<0
                OscpointM2(i+1:end, :)= [];
            end
            break
        end
    end
end

%%
% all rows where there is NAN in col 9 and 10 are zeroed. The zeros are not
% removed to preserve row numbers equal to PTOMMA. This is to retrieve any
% trough between MAP peaks that might have been deleted by the threshold (0.65 used currently)

for i = 1: size(OscpointM2,1)
    rTZ_MAP(i,1) = isnan(OscpointM2(i,9));
    rTZ_MAP(i,2) = isnan(OscpointM2(i,10));
end

for i = 1: size(rTZ_MAP,1)
    rTZ_MAP_1(i,1) = rTZ_MAP(i,1) == 1 && rTZ_MAP(i,2) ==1;
end

if ~isnan(all(all(OscpointM2(:,9:10)))) % condition added on 31Mar2025 to avoid situations where actual MAP is out of the range predicted by sysdiamatrix, and all 9 and 10 are isnans
    for i = 1:size(OscpointM2,1)
        if rTZ_MAP_1 (i,1) == 1
            OscpointM2(i, 6:8)=0; % zeroing pressures if col 9 and 10 are nan.
        end
    end
end

for i = 1: size(OscpointM2,1)
    rTZ_MAP(i,3) = isnan(OscpointM2(i,4));
    rTZ_MAP(i,4) = isnan(OscpointM2(i,5));
end

for i = 1: size(rTZ_MAP,1)
    rTZ_MAP_2(i,1) = rTZ_MAP(i,3) == 1 && rTZ_MAP(i,4) ==1;
end

for i = 1:size(OscpointM2,1)
    if rTZ_MAP_2 (i,1) == 1
        OscpointM2(i, 1:3)=0; % zeroing pressures if col 9 and 10 are nan.
    end
end
%%
%Rows below which all entries are 0 can be removed now.

for i = 1:size(OscpointM2,1)
    rTD_MAP(i,1) = all(all(all(OscpointM2(i:end, colwithPressureM)==0)));% if all entries in col 6:8 in all rows of i and below are zero, delete them.
end

OscpointM2 = OscpointM2(~rTD_MAP, :);
OscpointM2copy = OscpointM2;

%%
%Having saved M2copy, getting back to M2
% Now the rows above the first peak can be deleted.
%Have to get careful here. In 18092102, there was only one row in peak. SO,
%none of the troughs were considered.

for i = 1:size(OscpointM2,1)
    if any(OscpointM2(i,1:3)>0)
        if max(nonzeros(OscpointM2(i,1:3)))>= MAP_lowerLimit-2 && min(nonzeros(OscpointM2(i,1:3)))<= MAP_higherLimit+2
            OscpointM2(i,4)= round(MAP_lowCompare - mean(nonzeros(OscpointM2(i,1:3)))); % The plus five here is to take away the -5 that was added to MAP lower limit
        else
            OscpointM2(i,4)=NaN;
        end
    else
        OscpointM2(i,4)=NaN;
    end
end

for i = 1:size(OscpointM2,1)
    if any(OscpointM2(i,1:3)>0)
        if max(nonzeros(OscpointM2(i,1:3)))>= MAP_lowerLimit-2 && min(nonzeros(OscpointM2(i,1:3)))<= MAP_higherLimit+2
            OscpointM2(i,5)= round(MAP_highCompare - mean(nonzeros(OscpointM2(i,1:3)))); % The minus 5 here is to take away the 5 that was added
        else
            OscpointM2(i,5)=NaN;
        end
    else
        OscpointM2(i,5)=NaN;
    end
end

for i = 1:size(OscpointM2,1)
    if any(OscpointM2(i,6:8)>0)
        if max(nonzeros(OscpointM2(i,6:8)))>= MAP_lowerLimit-2 && min(nonzeros(OscpointM2(i,6:8)))<= MAP_higherLimit+2
            OscpointM2(i,9)= round(MAP_lowCompare - mean(nonzeros(OscpointM2(i,6:8)))); % The plus five here is to take away the -5 that was added to MAP lower limit
        else
            OscpointM2(i,9)=NaN;
        end
    else
        OscpointM2(i,9)=NaN;
    end
end

for i = 1:size(OscpointM2,1)
    if any(OscpointM2(i,6:8)>0)
        if max(nonzeros(OscpointM2(i,6:8)))>= MAP_lowerLimit-2 && min(nonzeros(OscpointM2(i,6:8)))<= MAP_higherLimit+2
            OscpointM2(i,10)= round(MAP_highCompare - mean(nonzeros(OscpointM2(i,6:8)))); % The minus 5 here is to take away the 5 that was added
        else
            OscpointM2(i,10)=NaN;
        end
    else
        OscpointM2(i,10)=NaN;
    end
end

if ~isempty(OscpointM2)
    for i = 1:size(OscpointM2,1)
        rTD_MAP1(i,1:2) = isnan(OscpointM2(i,4:5))& isnan(OscpointM2(i,9:10));% if all entries in col 6:8 in all rows of i and below are zero, delete them.
    end
    for i = 1:size(rTD_MAP1,1)
        if rTD_MAP1(i,1:2) == 1
            rTD_MAP2(i,1)=1;
        else
            rTD_MAP2(i,1)=0;
        end
    end
    
    for i = 1:size(rTD_MAP1,1)
        rTD_MAP2(i,1) = all(rTD_MAP1(i,1:2)==1);
    end
    
    for i = 1:size(rTD_MAP2,1)
        if rTD_MAP2(i,1)==1
            OscpointM2(i,colwithPressureM)=0;
        end
    end
    
    rTD_MAP2 = all(isnan(OscpointM2) | OscpointM2 == 0, 2);
    
    % Remove the identified rows
    OscpointM2(rTD_MAP2, :) = [];
end
%
if all(all(OscpointM2(:,6:8)==0)) % If there is no peak at all in the range proposed, find the earlier peaks
    OscpointM2_Apr2025 = OscpointM1;
end

if exist('OscpointM2_Apr2025', 'var')&& ~isempty(OscpointM2_Apr2025)
    for i = 1: size(OscpointM2_Apr2025,1)
        if any(any(OscpointM2_Apr2025(i,6:8)>0))
            OscpointM2_start = i;
            break
        end
    end
    
    for i = size(OscpointM2_Apr2025,1):-1:1
        if any(any(OscpointM2_Apr2025(i,6:8)>0))
            OscpointM2_stop = i;
            break
        end
    end
end

% The above did not find earlier peaks in ibp 18092502. Infact it found
% later peaks. This happens because there is a plateau above the threshold
% and peaks do not have a prominence above threshold. In this case, it is
% better to chevk the iniital MMMSD or somethind.

%%
%added on 26 Sep2025
if all(OscpointM2(1, 6:8)==0) && size(OscpointM2,1)>1% if there are no peaks in first row and there are more than 1 row
    if round(mean(nonzeros(OscpointM2(1,1:3))))< min(min(Sys_Dia_matrix(1:2, col_withMAP_SDM)))  % if the mean of first row is less than min of calc MAPS
        OscpointM2(1,:)=[];
    elseif round(mean(nonzeros(OscpointM2(2,colwithPressureM))))< 100 && round(mean(nonzeros(OscpointM2(2,colwithPressureM))))- round(mean(nonzeros(OscpointM2(1,colwithPressureM))))>12 % if MAP var is more than 12 when high MAP is less than 100
        OscpointM2(1,:)=[];
    end
end

%%
if ~isempty(OscpointM2) && size(OscpointM2,1)==1
    if ~isnan(OscpointM2(1,9))% if there are peaks
        MAPselect_lowP1 = min(nonzeros(OscpointM2(1,6:8)));
        MAPselect_highP1 = max(OscpointM2(1,6:8));
    else % This is unnecessary as there is no instance with just troughs
        MAPselect_lowP1 = min(nonzeros(OscpointM2(1,colwithPressureM)));
        MAPselect_highP1 = max(OscpointM2(1,colwithPressureM));
    end
end
%%
if ~isempty(OscpointM2) && size(OscpointM2,1)==2
    %Get MAP low
    if (~isnan(OscpointM2(1,9)) && abs(OscpointM2(1,9))<=2) || (~isnan(OscpointM2(1,4))&&abs(OscpointM2(1,4))<=2)
        MAPselect_lowP1 = round(mean(nonzeros(OscpointM2(1,colwithPressureM))));
        
    elseif (~isnan(OscpointM2(1,9)) && OscpointM2(1,9)<-2) || (~isnan(OscpointM2(1,4)) && OscpointM2(1,4)<-2) % if close to MAP lower limit
        MAPselect_lowP1 = min(nonzeros(OscpointM2(1,colwithPressureM)));
        
    elseif (~isnan(OscpointM2(1,9)) && OscpointM2(1,9)>2) || (~isnan(OscpointM2(1,4)) && OscpointM2(1,4)>2) % if rows are lower than MAP guess
        
        if (~isnan(OscpointM2(2,9)) && abs(OscpointM2(2,9))<=2) || (~isnan(OscpointM2(2,4))&&abs(OscpointM2(2,4))<=2) % if second row is closer to MAP guess
            MAPselect_lowP1 = round(mean(nonzeros(OscpointM2(2,colwithPressureM))));
            
        elseif (~isnan(OscpointM2(2,9)) && OscpointM2(2,9)> 2) || (~isnan(OscpointM2(2,4))&& OscpointM2(2,4))>2 % if second row is closer to MAP guess
            MAPselect_lowP1 = max(nonzeros(OscpointM2(2,colwithPressureM)));
            %added on 5August2025, to give respect to peaks in row 1
            %even if the value in col9 or 10 is more than 2
        elseif min(nonzeros(Sys_Dia_matrix(1:2, col_withMAP_SDM)))- max(OscpointM2(1, colwithPressureM))<=5 % if the min of sysdiamatrix MAPs is close to the first row
            if all(OscpointM2(2, 6:8)==0) &&(abs(OscpointM2(2,9))> 2*abs(OscpointM2(1,9)) || abs(OscpointM2(2,4))> 2*abs(OscpointM2(1,4)))% if there are peaks in first row, but only troughs in second row, give importance to peaks || if the difference in second row is twice the diff in first row
                MAPselect_lowP1 = max(OscpointM2(1,colwithPressureM));
                
            elseif mean(nonzeros(OscpointM2(2,colwithPressureM)))- mean(nonzeros(OscpointM2(1,colwithPressureM)))> MeanPlus2SD_StepSize % if the peaks are more than step size apart
                if abs(OscpointM2(2,9))> 1.5*abs(OscpointM2(1,9))||abs(OscpointM2(2,4))> 1.5*abs(OscpointM2(1,9)) % if the diff in second row is 1.5 times that in the first row
                    MAPselect_lowP1 = max(OscpointM2(1,colwithPressureM)); % In the previous line, (2,4) > (1,9) is correct
                    % sometimes there are entries only in (1,.4) and (2,9)
                    
                elseif abs(OscpointM2(2,9))> 1.5*abs(OscpointM2(1,4)) || abs(OscpointM2(2,4))> 1.5*abs(OscpointM2(1,4))
                    MAPselect_lowP1 = max(OscpointM2(1,colwithPressureM)); % since row 1 has positive difference, take max of row 1
                    
                elseif abs(OscpointM2(1,9))> 1.5*abs(OscpointM2(2,9))||abs(OscpointM2(1,4))> 1.5*abs(OscpointM2(2,4)) % if the diff in second row is 1.5 times that in the first row
                    MAPselect_lowP1 = max(OscpointM2(1,colwithPressureM)); % In the previous line, (2,4) > (1,9) is correct
                    
                elseif abs(OscpointM2(1,4))> 1.5*abs(OscpointM2(2,9)) || abs(OscpointM2(1,9))> 1.5*abs(OscpointM2(2,4))
                    MAPselect_lowP1 = round(mean(nonzeros(OscpointM2(2,colwithPressureM))));
                else
                    for i = 1:2
                        OscpointM2_logical(i,colwithPressureM)= OscpointM2(i,colwithPressureM)>0;
                        sum_OscpointM2_logical(i,1) = sum(OscpointM2_logical(i,:));
                    end
                    [~,  rIOPM2]= max(sum_OscpointM2_logical);
                    MAPselect_lowP1 = round(mean(nonzeros(OscpointM2(rIOPM2,colwithPressureM))));
                end
                
            else %The same conditions above are repeated again. 12 Sep 2025
                
                if abs(OscpointM2(2,9))> 1.5*abs(OscpointM2(1,9))||abs(OscpointM2(2,4))> 1.5*abs(OscpointM2(1,9)) % if the diff in second row is 1.5 times that in the first row
                    MAPselect_lowP1 = max(OscpointM2(1,colwithPressureM)); % In the previous line, (2,4) > (1,9) is correct
                    % sometimes there are entries only in (1,.4) and (2,9)
                    
                elseif abs(OscpointM2(2,9))> 1.5*abs(OscpointM2(1,4)) || abs(OscpointM2(2,4))> 1.5*abs(OscpointM2(1,4))
                    MAPselect_lowP1 = max(OscpointM2(1,colwithPressureM)); % since row 1 has positive difference, take max of row 1
                    
                elseif abs(OscpointM2(1,9))> 1.5*abs(OscpointM2(2,9))||abs(OscpointM2(1,4))> 1.5*abs(OscpointM2(2,4)) % if the diff in second row is 1.5 times that in the first row
                    MAPselect_lowP1 = max(OscpointM2(1,colwithPressureM)); % In the previous line, (2,4) > (1,9) is correct
                    
                elseif abs(OscpointM2(1,4))> 1.5*abs(OscpointM2(2,9)) || abs(OscpointM2(1,9))> 1.5*abs(OscpointM2(2,4))
                    MAPselect_lowP1 = round(mean(nonzeros(OscpointM2(2,colwithPressureM))));
                else % This else was added on 18 Sep2025
                    MAPselect_lowP1 = (round(mean(nonzeros(OscpointM2(1:2,colwithPressureM)))));
                end
            end
            
        elseif (~isnan(OscpointM2(2,9)) && OscpointM2(2,9)<-2) || (~isnan(OscpointM2(2,4)) && OscpointM2(2,4)<-2)%This is the tricky part, where a decision may have to be made carefully
            if abs(OscpointM2(1,9))- abs(OscpointM2(2,9)) > 2*min(abs(OscpointM2(1:2, 9)))% clearly one row is far away, avoid that
                if abs(OscpointM2(1,9))<abs(OscpointM2(2,9))%row 1 is closer to MAP low guess
                    MAPselect_lowP1 = max(OscpointM2(1,6:8));
                    
                elseif abs(OscpointM2(1,9))> abs(OscpointM2(2,9))%row 2 is closer to MAP low guess
                    MAPselect_lowP1 = min(nonzeros(OscpointM2(2, 6:8)));
                end
                
            elseif abs(OscpointM2(1,4))- abs(OscpointM2(2,4)) > 2*min(abs(OscpointM2(1:2, 4)))% clearly one row is far away, avoid that
                if abs(OscpointM2(1,4))<abs(OscpointM2(2,4))%row 1 is closer to MAP low guess
                    MAPselect_lowP1 = max(OscpointM2(1,colwithPressureM));
                elseif abs(OscpointM2(1,4))> abs(OscpointM2(2,4))%row 2 is closer to MAP low guess
                    MAPselect_lowP1 = min(nonzeros(OscpointM2(2, colwithPressureM)));
                end
                
            elseif mean(nonzeros(OscpointM2(2,colwithPressureM)))- mean(nonzeros(OscpointM2(1,colwithPressureM)))>MeanPlus2SD_StepSize % again if the peaks are more than stepSize apart and
                if abs(OscpointM2(1,9))> 1.5*abs(OscpointM2(2,9))||abs(OscpointM2(1,9))> 1.5*abs(OscpointM2(2,4)) % if the diff in first row is 1.5 times that in the second row
                    MAPselect_lowP1 = min(nonzeros(OscpointM2(2,colwithPressureM)));
                    
                elseif abs(OscpointM2(1,4))> 1.5*abs(OscpointM2(2,9)) || abs(OscpointM2(1,4))> 1.5*abs(OscpointM2(2,4))
                    MAPselect_lowP1 = min(nonzeros(OscpointM2(2,colwithPressureM)));
                    
                elseif abs(OscpointM2(2,9))> 1.5*abs(OscpointM2(1,9)) || abs(OscpointM2(2,9))> 1.5*abs(OscpointM2(1,4))
                    MAPselect_lowP1 = round(mean(nonzeros(OscpointM2(1,colwithPressureM))));
                    
                elseif abs(OscpointM2(2,4))> 1.5*abs(OscpointM2(1,9)) || abs(OscpointM2(2,4))> 1.5*abs(OscpointM2(1,4))
                    MAPselect_lowP1 = round(mean(nonzeros(OscpointM2(1,colwithPressureM))));
                    
                else %since everything else is not working AND the rows are far apart, look at actual amplitudes of peaks as well as H points lower than them. Get PTO_MMM_M12, H all and L all. Get both MAP low and high
                    
                    for i = 1:size(PTO_MMM_M12,1)
                        PTO_MMM_M1Decide(i,1)= mean(nonzeros(PTO_MMM_M12(i, colwithPressure)));
                        PTO_MMM_M12Decide(i,2)= mean(nonzeros(PTO_MMM_M12(i, colwithPressure-1)));
                    end
                    
                    for i = 1:size(OscpointM2,1)
                        OscpointM2Decide(i,1)= mean(nonzeros(OscpointM2(i, colwithPressureM)));
                    end
                    
                    for i = 1:size(OscpointM2Decide,1)
                        for j = 1:size(PTO_MMM_M12Decide,1)
                            if OscpointM2Decide(i,1)== PTO_MMM_M12Decide(j,1)
                                OscpointM2Decide(i,2)= PTO_MMM_M12Decide(j,2);
                            end
                        end
                    end
                    %Collect L and H points alongside Osc
                    
                    H_allDecide = H_all(H_all(:,13)< max(OscpointM2Decide(:,1))-5,13);
                    L_allDecide = L_all(L_all(:,13)< max(OscpointM2Decide(:,1))-5,13);
                    for i = 1:size(OscpointM2Decide,1)
                        for j = 1:size(H_allDecide,1)
                            %                             if H_allDecide(j,1)< OscpointM2Decide(i,1)
                            if H_allDecide(j,1)< OscpointM2Decide(i,1)-5 % change made on 18 Sep2025, as dia has to be at least 5 less than MAP
                                OscpointM2Decide(i,3)= H_allDecide(j,1);
                                break
                            end
                        end
                    end
                    
                    for i = 1:size(OscpointM2Decide,1)
                        for j = 1:size(L_allDecide,1)
                            if L_allDecide(j,1)< OscpointM2Decide(i,1)
                                OscpointM2Decide(i,4)= L_allDecide(j,1);
                                break
                            end
                        end
                    end
                    % Find the actual amplitude of the short listed L and Hpoints in OscpointM2Decide:Use fitresult 75 for mean ratio smsp
                    
                    for i = 1:size(OscpointM2Decide,1)
                        OscpointM2Decide(i,5)=fitresult{75}(OscpointM2Decide(i,3));
                        OscpointM2Decide(i,6)=fitresult{75}(OscpointM2Decide(i,4));
                        % sometimes finding highest L point does not help.
                        % Especially if both L points have the same value, saying max does not help distinguish
                        OscpointM2Decide(i,7)= OscpointM2Decide(i,5) + OscpointM2Decide(i,6);
                    end
                    
                    %Find the highest L point if the L points in both rows are not the same. If same, then choose based on total of L and H
                    if OscpointM2Decide (1,6)~= OscpointM2Decide (2,6)
                        [~,rI_OscpointM2Decide] = max(OscpointM2Decide(:,6));
                    else
                        [~,rI_OscpointM2Decide] = max(OscpointM2Decide(:,7));
                    end
                    
                    MAPselect_lowP1 = min(nonzeros(OscpointM2(rI_OscpointM2Decide,colwithPressureM)));
                    MAPselect_highP1 = max(nonzeros(OscpointM2(rI_OscpointM2Decide,colwithPressureM))); %Decide on MAP high also here itself.
                end
            else
                MAPselect_lowP1 = (round(mean(nonzeros(OscpointM2(1:2,colwithPressureM)))));
            end
            
        elseif (~isnan(OscpointM2(2,9)) && OscpointM2(2,9)>2) || (~isnan(OscpointM2(2,4)) && OscpointM2(2,4)>2)
            MAPselect_lowP1 = max(OscpointM2(2,colwithPressureM));
        end
    end
    
    %Get MAP high (if it has not been decided earlier)
    if ~exist('MAPselect_highP1', 'var')
        if (~isnan(OscpointM2(1,10)) && abs(OscpointM2(1,10))<=2) || (~isnan(OscpointM2(1,5))&&abs(OscpointM2(1,5))<=2)
            MAPselect_highP1 = round(mean(nonzeros(OscpointM2(1,colwithPressureM))));
            
        elseif (~isnan(OscpointM2(1,10)) && OscpointM2(1,10)<-2) || (~isnan(OscpointM2(1,5)) && OscpointM2(1,5)<-2) % if close to MAP lower limit
            MAPselect_highP1 = min(nonzeros(OscpointM2(1,colwithPressureM)));
            
        elseif (~isnan(OscpointM2(1,10)) && OscpointM2(1,10)>2) || (~isnan(OscpointM2(1,5)) && OscpointM2(1,5)>2) % if rows are lower than MAP guess
            
            if (~isnan(OscpointM2(2,10)) && abs(OscpointM2(2,10))<=2) || (~isnan(OscpointM2(2,5))&&abs(OscpointM2(2,5))<=2) % if second row is closer to MAP guess
                MAPselect_highP1 = round(mean(nonzeros(OscpointM2(2,colwithPressureM))));
                
            elseif (~isnan(OscpointM2(2,10)) && abs(OscpointM2(2,10))> 2) || (~isnan(OscpointM2(2,5))&&abs(OscpointM2(2,5))>2) % if second row is closer to MAP guess
                MAPselect_highP1 = max(nonzeros(OscpointM2(2,colwithPressureM)));
                %added on 5August2025, to give respect to peaks in row 1
                %even if the value in col9 or 10 is more than 2
            elseif min(nonzeros(Sys_Dia_matrix(1:2, col_withMAP_SDM)))- max(OscpointM2(1, colwithPressureM))<=5 % if the min of sysdiamatrix MAPs is close to the first row
                if all(OscpointM2(2, 6:8)==0) &&(abs(OscpointM2(2,10))> 2*(OscpointM2(1,10)) || abs(OscpointM2(2,5))> 2*(OscpointM2(1,5)))% if there are peaks in first row, but only troughs in second row, give importance to peaks || if the difference in second row is twice the diff in first row
                    MAPselect_highP1 = max(OscpointM2(1,colwithPressureM));
                    
                elseif mean(nonzeros(OscpointM2(2,colwithPressureM)))- mean(nonzeros(OscpointM2(1,colwithPressureM)))> MeanPlus2SD_StepSize % if the peaks are more than step size apart
                    if abs(OscpointM2(2,10))> 1.5*abs(OscpointM2(1,10))||abs(OscpointM2(2,5))> 1.5*abs(OscpointM2(1,10)) % if the diff in second row is 1.5 times that in the first row
                        MAPselect_highP1 = max(OscpointM2(1,colwithPressureM)); % In the previous line, (2,5) > (1,10) is correct
                        % sometimes there are entries only in (1,.5) and (2,10)
                        
                    elseif abs(OscpointM2(2,10))> 1.5*abs(OscpointM2(1,5)) || abs(OscpointM2(2,5))> 1.5*abs(OscpointM2(1,5))
                        MAPselect_highP1 = max(OscpointM2(1,colwithPressureM)); % since row 1 has positive difference, take max of row 1
                        
                    elseif abs(OscpointM2(1,10))> 1.5*abs(OscpointM2(2,10))||abs(OscpointM2(1,5))> 1.5*abs(OscpointM2(2,5)) % if the diff in second row is 1.5 times that in the first row
                        MAPselect_highP1 = max(OscpointM2(1,colwithPressureM)); % In the previous line, (2,5) > (1,10) is correct
                        
                    elseif abs(OscpointM2(1,5))> 1.5*abs(OscpointM2(2,10)) || abs(OscpointM2(1,10))> 1.5*abs(OscpointM2(2,5))
                        MAPselect_highP1 = round(mean(nonzeros(OscpointM2(2,colwithPressureM))));
                        
                    else
                        for i = 1:2
                            OscpointM2_logical_high(i,colwithPressureM)= OscpointM2(i,colwithPressureM)>0;
                            sum_OscpointM2_logical_high(i,1) = sum(OscpointM2_logical_high(i,:));
                        end                        
                        [~,  rIOPM2_high]= max(sum_OscpointM2_logical_high);
                        MAPselect_highP1 = round(mean(nonzeros(OscpointM2(rIOPM2_high,colwithPressureM))));
                    end
                else %The same conditions above are repeated again. 12Sep 2025
                    if abs(OscpointM2(2,10))> 1.5*abs(OscpointM2(1,10))||abs(OscpointM2(2,5))> 1.5*abs(OscpointM2(1,10)) % if the diff in second row is 1.5 times that in the first row
                        MAPselect_highP1 = max(OscpointM2(1,colwithPressureM)); % In the previous line, (2,5) > (1,10) is correct
                        % sometimes there are entries only in (1,.5) and (2,10)
                        
                    elseif abs(OscpointM2(2,10))> 1.5*abs(OscpointM2(1,5)) || abs(OscpointM2(2,5))> 1.5*abs(OscpointM2(1,5))
                        MAPselect_highP1 = max(OscpointM2(1,colwithPressureM)); % since row 1 has positive difference, take max of row 1
                        
                    elseif abs(OscpointM2(1,10))> 1.5*abs(OscpointM2(2,10))||abs(OscpointM2(1,5))> 1.5*abs(OscpointM2(2,5)) % if the diff in second row is 1.5 times that in the first row
                        MAPselect_highP1 = max(OscpointM2(1,colwithPressureM)); % In the previous line, (2,5) > (1,10) is correct
                        
                    elseif abs(OscpointM2(1,5))> 1.5*abs(OscpointM2(2,10)) || abs(OscpointM2(1,10))> 1.5*abs(OscpointM2(2,5))
                        MAPselect_highP1 = round(mean(nonzeros(OscpointM2(2,colwithPressureM))));
                    end
                end
                
            elseif (~isnan(OscpointM2(2,10)) && OscpointM2(2,10)<-2) || (~isnan(OscpointM2(2,5)) && OscpointM2(2,5)<-2)%This is the tricky part, where a decision may have to be made carefully
                if abs(OscpointM2(1,10))- abs(OscpointM2(2,10)) > 2*min(abs(OscpointM2(1:2, 10)))% clearly one row is far away, avoid that
                    if abs(OscpointM2(1,10))<abs(OscpointM2(2,10))%row 1 is closer to MAP low guess
                        MAPselect_highP1 = max(OscpointM2(1,6:8));
                        
                    elseif abs(OscpointM2(1,10))> abs(OscpointM2(2,10))%row 2 is closer to MAP low guess
                        MAPselect_highP1 = min(nonzeros(OscpointM2(2, 6:8)));
                    end
                    
                elseif abs(OscpointM2(1,5))- abs(OscpointM2(2,5)) > 2*min(abs(OscpointM2(1:2, 5)))% clearly one row is far away, avoid that
                    if abs(OscpointM2(1,5))<abs(OscpointM2(2,5))%row 1 is closer to MAP low guess
                        MAPselect_highP1 = max(OscpointM2(1,colwithPressureM));
                    elseif abs(OscpointM2(1,5))> abs(OscpointM2(2,5))%row 2 is closer to MAP low guess
                        MAPselect_highP1 = min(nonzeros(OscpointM2(2, colwithPressureM)));
                    end
                end
                
            elseif (~isnan(OscpointM2(2,10)) && OscpointM2(2,10)>2) || (~isnan(OscpointM2(2,5)) && OscpointM2(2,5)>2)
                MAPselect_highP1 = max(OscpointM2(2,colwithPressureM));
            end
        end
    end
end

%%
if ~isempty(OscpointM2) && size(OscpointM2,1)==3
    % case of all in first row being >0 is deliberately avoided
    
    if all(OscpointM2(2, 6:8)>0)
        
        if (~isnan(OscpointM2(2,9)) && abs(OscpointM2(2,9))<=2) || (~isnan(OscpointM2(2,4))&&abs(OscpointM2(2,4))<=2)
            MAPselect_lowP1 = round(mean(nonzeros(OscpointM2(2,colwithPressureM))));
            
        elseif (~isnan(OscpointM2(2,9)) && OscpointM2(2,9)<-2) || (~isnan(OscpointM2(2,4)) && OscpointM2(2,4)<-2) % if close to MAP lower limit
            MAPselect_lowP1 = mean(nonzeros(OscpointM2(1:2,colwithPressureM)));
            
        elseif (~isnan(OscpointM2(2,9)) && OscpointM2(2,9)>2) || (~isnan(OscpointM2(2,4)) && OscpointM2(2,4)>2) % if rows are lower and higher than MAPlimit
            
            if (~isnan(OscpointM2(3,9)) && abs(OscpointM2(3,9))<=2) || (~isnan(OscpointM2(3,4))&&abs(OscpointM2(3,4))<=2)
                MAPselect_lowP1 = round(mean(nonzeros(OscpointM2(2:3,colwithPressureM))));
                
            elseif (~isnan(OscpointM2(3,9)) && OscpointM2(3,9)<-2) || (~isnan(OscpointM2(3,4)) && OscpointM2(3,4)<-2)
                MAPselect_lowP1 = (round(mean(nonzeros(OscpointM2(2,colwithPressureM))))+ min(nonzeros(OscpointM2(3,colwithPressureM))))/2;
                
            elseif (~isnan(OscpointM2(3,9)) && OscpointM2(3,9)>2) || (~isnan(OscpointM2(3,4)) && OscpointM2(3,4)>2)
                MAPselect_lowP1 = max(OscpointM2(3,colwithPressureM));
            end
        end
        
        if (~isnan(OscpointM2(2,10)) && abs(OscpointM2(2,10))<=2) || (~isnan(OscpointM2(2,5))&& abs(OscpointM2(2,5))<=2)
            MAPselect_highP1 = round(mean(nonzeros(OscpointM2(2,colwithPressureM))));
            
        elseif (~isnan(OscpointM2(2,10)) && OscpointM2(2,10)<-2) || (~isnan(OscpointM2(2,5)) && OscpointM2(2,5)<-2) % if close to MAP lower limit
            MAPselect_highP1 = mean(nonzeros(OscpointM2(1:2,colwithPressureM)));
            
        elseif (~isnan(OscpointM2(2,10)) && OscpointM2(2,10)>2) || (~isnan(OscpointM2(2,5)) && OscpointM2(2,5)>2) % if rows are lower and higher than MAPlimit
            
            if (~isnan(OscpointM2(3,10)) && abs(OscpointM2(3,10))<=2) || (~isnan(OscpointM2(3,5))&&abs(OscpointM2(3,5))<=2)
                MAPselect_highP1 = round(mean(nonzeros(OscpointM2(3,colwithPressureM))));
                
            elseif (~isnan(OscpointM2(3,10)) && OscpointM2(3,10)<-2) || (~isnan(OscpointM2(3,5)) && OscpointM2(3,5)<-2)
                MAPselect_highP1 = round(mean(nonzeros(OscpointM2(2:3,colwithPressureM))));
                
            elseif (~isnan(OscpointM2(3,10)) && OscpointM2(3,10)>2) || (~isnan(OscpointM2(3,5)) && OscpointM2(3,5)>2)
                MAPselect_highP1 = max(OscpointM2(3,colwithPressureM));
            end
        end
        
    elseif all(OscpointM2(3, 6:8)>0)
        
        if abs(OscpointM2(3, 10))<=2
            MAPselect_highP1 = round(mean(nonzeros(OscpointM2(3,6:8))));
        elseif OscpointM2(3, 10)<-2
            MAPselect_highP1 = min(nonzeros(OscpointM2(3,6:8)));
        else
            MAPselect_highP1 = max(nonzeros(OscpointM2(3,6:8)));
        end
        
        if (~isnan(OscpointM2(2,9)) && abs(OscpointM2(2,9))<=2) || (~isnan(OscpointM2(2,4))&&abs(OscpointM2(2,4))<=2)
            MAPselect_lowP1 = round(mean(nonzeros(OscpointM2(2,colwithPressureM))));
            
        elseif (~isnan(OscpointM2(2,9)) && OscpointM2(2,9)<-2) || (~isnan(OscpointM2(2,4)) && OscpointM2(2,4)<-2) % if close to MAP lower limit
            MAPselect_lowP1 = mean(nonzeros(OscpointM2(1:2,colwithPressureM)));
            
        elseif (~isnan(OscpointM2(2,9)) && OscpointM2(2,9)>2) || (~isnan(OscpointM2(2,4)) && OscpointM2(2,4)>2) % if rows are lower and higher than MAPlimit
            
            if (~isnan(OscpointM2(3,9)) && abs(OscpointM2(3,9))<=2) || (~isnan(OscpointM2(3,4))&&abs(OscpointM2(3,4))<=2)
                MAPselect_lowP1 = round(mean(nonzeros(OscpointM2(2:3,colwithPressureM))));
                
            elseif (~isnan(OscpointM2(3,9)) && OscpointM2(3,9)<-2) || (~isnan(OscpointM2(3,4)) && OscpointM2(3,4)<-2)
                MAPselect_lowP1 = (round(mean(nonzeros(OscpointM2(2,colwithPressureM))))+ min(nonzeros(OscpointM2(3,colwithPressureM))))/2;
            else % when the value is more than 2
                MAPselect_lowP1 = max(nonzeros(OscpointM2(3,colwithPressureM)));
            end
        end
    else
        for i = 1:2
            if (~isnan(OscpointM2(i,9)) && abs(OscpointM2(i,9))<=2) || (~isnan(OscpointM2(i,4))&&abs(OscpointM2(i,4))<=2)
                MAPselect_lowP1 = round(mean(nonzeros(OscpointM2(i,colwithPressureM))));
                break
                
            elseif (~isnan(OscpointM2(i,9)) && OscpointM2(i,9)<-2) || (~isnan(OscpointM2(i,4)) && OscpointM2(i,4)<-2)
                if i == 1
                    MAPselect_lowP1 = min(nonzeros(OscpointM2(1,colwithPressureM)));
                    break
                elseif i==2
                    MAPselect_lowP1 = mean(nonzeros(OscpointM2(1:2,colwithPressureM)));
                    break
                end
            elseif (~isnan(OscpointM2(i,9)) && OscpointM2(i,9)>2) || (~isnan(OscpointM2(i,4)) && OscpointM2(i,4)>2) % if rows are lower and higher than MAPlimit
                
                if (~isnan(OscpointM2(i+1,9)) && abs(OscpointM2(i+1,9))<=2) || (~isnan(OscpointM2(i+1,4))&&abs(OscpointM2(i+1,4))<=2)
                    MAPselect_lowP1 = round(mean(nonzeros(OscpointM2(i:i+1,colwithPressureM))));
                    break
                    
                elseif (~isnan(OscpointM2(i+1,9)) && OscpointM2(i+1,9)<-2) || (~isnan(OscpointM2(i+1,4)) && OscpointM2(i+1,4)<-2)
                    MAPselect_lowP1 = (round(mean(nonzeros(OscpointM2(i,colwithPressureM))))+ min(nonzeros(OscpointM2(i+1,colwithPressureM))))/2;
                    break
                    
                elseif (~isnan(OscpointM2(3,9)) && OscpointM2(3,9)>2) || (~isnan(OscpointM2(3,4)) && OscpointM2(3,4)>2)
                    MAPselect_lowP1 = max(OscpointM2(i+1,colwithPressureM));
                    break
                end
            end
        end
        
        for i = 2:3
            if (~isnan(OscpointM2(i,10)) && abs(OscpointM2(i,10))<=2) || (~isnan(OscpointM2(i,5))&&abs(OscpointM2(i,5))<=2)
                MAPselect_highP1 = round(mean(nonzeros(OscpointM2(i,colwithPressureM))));
                break
                
            elseif (~isnan(OscpointM2(i,10)) && OscpointM2(i,10)<-2) || (~isnan(OscpointM2(i,5)) && OscpointM2(i,5)<-2) % if close to MAP lower limit
                MAPselect_highP1 = mean(nonzeros(OscpointM2(i-1:i,colwithPressureM)));
                break
                
            elseif (~isnan(OscpointM2(i,10)) && OscpointM2(i,10)>2) || (~isnan(OscpointM2(i,5)) && OscpointM2(i,5)>2) % if rows are lower and higher than MAPlimit
                if i ==2
                    if (~isnan(OscpointM2(3,10)) && abs(OscpointM2(3,10))<=2) || (~isnan(OscpointM2(3,5))&&abs(OscpointM2(3,5))<=2)
                        MAPselect_highP1 = round(mean(nonzeros(OscpointM2(3,colwithPressureM))));
                        break
                        
                    elseif (~isnan(OscpointM2(3,10)) && OscpointM2(3,10)<-2) || (~isnan(OscpointM2(3,5)) && OscpointM2(3,5)<-2)
                        MAPselect_highP1 = round(mean(nonzeros(OscpointM2(2:3,colwithPressureM))));
                        break
                        
                    elseif (~isnan(OscpointM2(3,10)) && OscpointM2(3,10)>2) || (~isnan(OscpointM2(3,5)) && OscpointM2(3,5)>2)
                        MAPselect_highP1 = max(OscpointM2(3,colwithPressureM));
                        break
                    end
                elseif i ==3
                    MAPselect_highP1 = max(OscpointM2(3,colwithPressureM));
                    break
                end
            end
        end
    end
end
%%
if ~isempty(OscpointM2) && size(OscpointM2,1)>3
    % case of all in first row being >0 is deliberately avoided
    
    if all(OscpointM2(2, 6:8)>0)
        
        if (~isnan(OscpointM2(2,9)) && abs(OscpointM2(2,9))<=2) || (~isnan(OscpointM2(2,4))&&abs(OscpointM2(2,4))<=2)
            MAPselect_lowP1 = round(mean(nonzeros(OscpointM2(2,colwithPressureM))));
            
        elseif (~isnan(OscpointM2(2,9)) && OscpointM2(2,9)<-2) || (~isnan(OscpointM2(2,4)) && OscpointM2(2,4)<-2) % if close to MAP lower limit
            MAPselect_lowP1 = mean(nonzeros(OscpointM2(1:2,colwithPressureM)));
            
        elseif (~isnan(OscpointM2(2,9)) && OscpointM2(2,9)>2) || (~isnan(OscpointM2(2,4)) && OscpointM2(2,4)>2) % if rows are lower and higher than MAPlimit
            
            if (~isnan(OscpointM2(3,9)) && abs(OscpointM2(3,9))<=2) || (~isnan(OscpointM2(3,4))&&abs(OscpointM2(3,4))<=2)
                MAPselect_lowP1 = round(mean(nonzeros(OscpointM2(2:3,colwithPressureM))));
                
            elseif (~isnan(OscpointM2(3,9)) && OscpointM2(3,9)<-2) || (~isnan(OscpointM2(3,4)) && OscpointM2(3,4)<-2)
                MAPselect_lowP1 = (round(mean(nonzeros(OscpointM2(2,colwithPressureM))))+ min(nonzeros(OscpointM2(3,colwithPressureM))))/2;
                
            elseif (~isnan(OscpointM2(3,9)) && OscpointM2(3,9)>2) || (~isnan(OscpointM2(3,4)) && OscpointM2(3,4)>2)
                MAPselect_lowP1 = max(OscpointM2(3,colwithPressureM));
            end
        end
        
        if (~isnan(OscpointM2(2,10)) && abs(OscpointM2(2,10))<=2) || (~isnan(OscpointM2(2,5))&&abs(OscpointM2(2,5))<=2)
            MAPselect_highP1 = round(mean(nonzeros(OscpointM2(2,colwithPressureM))));
            
        elseif (~isnan(OscpointM2(2,10)) && OscpointM2(2,10)<-2) || (~isnan(OscpointM2(2,5)) && OscpointM2(2,5)<-2) % if close to MAP lower limit
            MAPselect_highP1 = mean(nonzeros(OscpointM2(1:2,colwithPressureM)));
            
        elseif (~isnan(OscpointM2(2,10)) && OscpointM2(2,10)>2) || (~isnan(OscpointM2(2,5)) && OscpointM2(2,5)>2) % if rows are lower and higher than MAPlimit
            
            if (~isnan(OscpointM2(3,10)) && abs(OscpointM2(3,10))<=2) || (~isnan(OscpointM2(3,5))&&abs(OscpointM2(3,5))<=2)
                MAPselect_highP1 = round(mean(nonzeros(OscpointM2(3,colwithPressureM))));
                
            elseif (~isnan(OscpointM2(3,10)) && OscpointM2(3,10)<-2) || (~isnan(OscpointM2(3,5)) && OscpointM2(3,5)<-2)
                MAPselect_highP1 = round(mean(nonzeros(OscpointM2(2:3,colwithPressureM))));
                
            elseif (~isnan(OscpointM2(3,10)) && OscpointM2(3,10)>2) || (~isnan(OscpointM2(3,5)) && OscpointM2(3,5)>2)
                MAPselect_highP1 = max(OscpointM2(3,colwithPressureM));
            end
        end
        
    elseif all(OscpointM2(3, 6:8)>0)
        
        if abs(OscpointM2(3, 10))<=2
            MAPselect_highP1 = round(mean(nonzeros(OscpointM2(3,6:8))));
        elseif OscpointM2(3, 10)<-2
            MAPselect_highP1 = min(nonzeros(OscpointM2(3,6:8)));
        else % when the value is more than 2
            MAPselect_highP1 = max(nonzeros(OscpointM2(3,6:8)));
        end
        
        if (~isnan(OscpointM2(2,9)) && abs(OscpointM2(2,9))<=2) || (~isnan(OscpointM2(2,4))&&abs(OscpointM2(2,4))<=2)
            MAPselect_lowP1 = round(mean(nonzeros(OscpointM2(2,colwithPressureM))));
            
        elseif (~isnan(OscpointM2(2,9)) && OscpointM2(2,9)<-2) || (~isnan(OscpointM2(2,4)) && OscpointM2(2,4)<-2) % if close to MAP lower limit
            MAPselect_lowP1 = mean(nonzeros(OscpointM2(1:2,colwithPressureM)));
            
        elseif (~isnan(OscpointM2(2,9)) && OscpointM2(2,9)>2) || (~isnan(OscpointM2(2,4)) && OscpointM2(2,4)>2) % if rows are lower and higher than MAPlimit
            
            if (~isnan(OscpointM2(3,9)) && abs(OscpointM2(3,9))<=2) || (~isnan(OscpointM2(3,4))&&abs(OscpointM2(3,4))<=2)
                MAPselect_lowP1 = round(mean(nonzeros(OscpointM2(2:3,colwithPressureM))));
                
            elseif (~isnan(OscpointM2(3,9)) && OscpointM2(3,9)<-2) || (~isnan(OscpointM2(3,4)) && OscpointM2(3,4)<-2)
                MAPselect_lowP1 = (round(mean(nonzeros(OscpointM2(2,colwithPressureM))))+ min(nonzeros(OscpointM2(3,colwithPressureM))))/2;
                
            else % when the value is more than 2
                MAPselect_lowP1 = max(nonzeros(OscpointM2(3,colwithPressureM)));
            end
        end
    else
        for i = 1:size(OscpointM2,1)-1
            if (~isnan(OscpointM2(i,9)) && abs(OscpointM2(i,9))<=2) || (~isnan(OscpointM2(i,4))&&abs(OscpointM2(i,4))<=2)
                MAPselect_lowP1 = round(mean(nonzeros(OscpointM2(i,colwithPressureM))));
                break
                
            elseif (~isnan(OscpointM2(i,9)) && OscpointM2(i,9)<-2) || (~isnan(OscpointM2(i,4)) && OscpointM2(i,4)<-2)
                if i == 1
                    MAPselect_lowP1 = min(nonzeros(OscpointM2(1,colwithPressureM)));
                    break
                elseif i>1
                    MAPselect_lowP1 = mean(nonzeros(OscpointM2(i-1:i,colwithPressureM)));
                    break
                end
                
            elseif (~isnan(OscpointM2(i,9)) && OscpointM2(i,9)>2) || (~isnan(OscpointM2(i,4)) && OscpointM2(i,4)>2) % if rows are lower and higher than MAPlimit
                
                if (~isnan(OscpointM2(i+1,9)) && abs(OscpointM2(i+1,9))<=2) || (~isnan(OscpointM2(i+1,4))&&abs(OscpointM2(i+1,4))<=2)
                    MAPselect_lowP1 = round(mean(nonzeros(OscpointM2(i+1,colwithPressureM))));
                    break
                    
                elseif (~isnan(OscpointM2(i+1,9)) && OscpointM2(i+1,9)<-2) || (~isnan(OscpointM2(i+1,4)) && OscpointM2(i+1,4)<-2)
                    MAPselect_lowP1 = (round(mean(nonzeros(OscpointM2(i,colwithPressureM))))+ min(nonzeros(OscpointM2(i+1,colwithPressureM))))/2;
                    break
                    
                elseif (~isnan(OscpointM2(i+1,9)) && OscpointM2(i+1,9)>2) || (~isnan(OscpointM2(i+1,4)) && OscpointM2(i+1,4)>2)
                    if (~isnan(OscpointM2(i+2,9)) && OscpointM2(i+2,9)<0) || (~isnan(OscpointM2(i+2,4)) && OscpointM2(i+2,4)<0)
                        MAPselect_lowP1 = max(OscpointM2(i+1,colwithPressureM));
                        break
                    end
                end
            end
        end
        
        for i = 2:size(OscpointM2,1)
            if (~isnan(OscpointM2(i,10)) && abs(OscpointM2(i,10))<=2) || (~isnan(OscpointM2(i,5))&&abs(OscpointM2(i,5))<=2)
                MAPselect_highP1 = round(mean(nonzeros(OscpointM2(i,colwithPressureM))));
                break
                
            elseif (~isnan(OscpointM2(i,10)) && OscpointM2(i,10)<-2) || (~isnan(OscpointM2(i,5)) && OscpointM2(i,5)<-2) % if close to MAP lower limit
                MAPselect_highP1 = mean(nonzeros(OscpointM2(i-1:i,colwithPressureM)));
                break
                
            elseif (~isnan(OscpointM2(i,10)) && OscpointM2(i,10)>2) || (~isnan(OscpointM2(i,5)) && OscpointM2(i,5)>2) % if rows are lower and higher than MAPlimit
                if i < size(OscpointM2,1)
                    if (~isnan(OscpointM2(i+1,10)) && abs(OscpointM2(i+1,10))<=2) || (~isnan(OscpointM2(i+1,5))&&abs(OscpointM2(i+1,5))<=2)
                        MAPselect_highP1 = round(mean(nonzeros(OscpointM2(i+1,colwithPressureM))));
                        break
                        
                    elseif (~isnan(OscpointM2(i+1,10)) && OscpointM2(i+1,10)<-2) || (~isnan(OscpointM2(i+1,5)) && OscpointM2(i+1,5)<-2)
                        MAPselect_highP1 = round(mean(nonzeros(OscpointM2(i-1:i,colwithPressureM))));
                        break
                        
                    elseif (~isnan(OscpointM2(i+1,10)) && OscpointM2(i+1,10)>2) || (~isnan(OscpointM2(i+1,5)) && OscpointM2(i+1,5)>2)
                        if i <= size(OscpointM2,1)-1
                            if (~isnan(OscpointM2(i+2,10)) && OscpointM2(i+2,10)<0) || (~isnan(OscpointM2(i+2,5)) && OscpointM2(i+2,5)<0)
                                MAPselect_highP1 = round(mean(nonzeros(OscpointM2(i+1:i+2,colwithPressureM))));
                                break
                            end
                        elseif i == size(OscpointM2,1)-1
                            MAPselect_highP1 = max(OscpointM2(i+1,colwithPressureM));
                            break
                        end
                    end
                end
            end
        end
    end
end
%%
if isempty(OscpointM2)
    if MAP_lowCompare > minMeanMaxMAPcandidates(end,7)
        if  MAP_lowCompare < minMeanMaxMAPcandidates(1,7)
            MAPselect_lowP1 = MAP_lowCompare;
        else
            MAPselect_lowP1 = minMeanMaxMAPcandidates(1,7);
        end
    else
        MAPselect_lowP1 = minMeanMaxMAPcandidates(end,7);
    end
    
    if MAP_highCompare > minMeanMaxMAPcandidates(end,7)
        if MAP_highCompare < minMeanMaxMAPcandidates(1,7)
            MAPselect_highP1 = MAP_highCompare;
        else
            MAPselect_highP1 = minMeanMaxMAPcandidates(1,7);
        end
    else
        MAPselect_highP1 = minMeanMaxMAPcandidates(end,7);
    end
end
%%
if ~exist('MAPselect_lowP1', 'var') || isempty(MAPselect_lowP1)
    MAPselect_lowP1 = PSysDiaMay2025(1,5);
end

if ~exist('MAPselect_highP1', 'var') || isempty(MAPselect_highP1)
    MAPselect_highP1 = PSysDiaMay2025(1,6);
end

if MAPselect_lowP1 == MAPselect_highP1
    MAPselect_lowP1 = MAPselect_lowP1-1;
    MAPselect_highP1 = MAPselect_highP1+1;
end

MAPselect_lowP = round(MAPselect_lowP1);
MAPselect_highP = round(MAPselect_highP1);

MAPvar1 = MAPselect_highP - MAPselect_lowP;

%%
PressureGuesses0 = Sys_Dia_matrix;

PressureGuesses0(:, 5) = round(PressureGuesses0(:,3)+ 0.4*(PressureGuesses0(:,1) - PressureGuesses0(:,3)));
PressureGuesses0(:, 6) = round(PressureGuesses0(:,4)+ 0.33*(PressureGuesses0(:,2) - PressureGuesses0(:,4)));

PressureGuesses0(:, 7) = PressureGuesses0(:,2)- PressureGuesses0(:,1);%sysvar
PressureGuesses0(:, 8) = PressureGuesses0(:,4)- PressureGuesses0(:,3);%diavar

PressureGuesses0(:,9) = PressureGuesses0(:,6)-PressureGuesses0(:,5);%MAPvar

PressureGuesses0(:, 10) = round(PressureGuesses0(:,3)+ 0.36*(PressureGuesses0(:,1) - PressureGuesses0(:,3)));
PressureGuesses0(:, 11) = round(PressureGuesses0(:,4)+ 0.27*(PressureGuesses0(:,2) - PressureGuesses0(:,4)));
PressureGuesses0(:, 12) = PressureGuesses0(:,11)- PressureGuesses0 (:,10);

PressureGuesses0(:, 13) = round(PressureGuesses0(:,3)+ 0.45*(PressureGuesses0(:,1) - PressureGuesses0(:,3)));
PressureGuesses0(:, 14) = round(PressureGuesses0(:,4)+ 0.36*(PressureGuesses0(:,2) - PressureGuesses0(:,4)));
PressureGuesses0(:, 15) = PressureGuesses0(:,14)- PressureGuesses0(:,13);

col_withLowMAP = [5, 10, 13];
col_withHighMAP = [6, 11, 14];

%%
PressureGuesses = PressureGuesses0;
rowHeadings = {'Central Pressure guesses', 'Peripheral Pressure guesses'};
colHeadings = {'LowSystolic', 'HighSystolic', 'LowDiastolic', 'HighDiastolic', 'LowMAP', 'HighMAP', 'sysvar','diavar','MAPvar'};
Table_Guesses1 = array2table(PressureGuesses(1:2, 1:9), 'VariableNames', colHeadings, 'RowNames', rowHeadings);
disp(Table_Guesses1);

%sometimes there is only one oscillometric feature for systolic. Therefore
%Psyslow and Psyshigh are the same. Correct that based on differences from C

%%
%Redo Psys again
PTO_MMM_SD_relaxThreshold = PTO_MMM_A;

PTO_MMM_SD_relaxThreshold(:,13)= PTO_MMM_SD_relaxThreshold(:,1)-Thresholdmin3; %finding 1/2 of amplitude of oscillations for troughs in min?
PTO_MMM_SD_relaxThreshold(:,14)= PTO_MMM_SD_relaxThreshold(:,7)-Thresholdmin;
PTO_MMM_SD_relaxThreshold(:,15)= PTO_MMM_SD_relaxThreshold(:,3)-Thresholdmean3;
PTO_MMM_SD_relaxThreshold(:,16)= PTO_MMM_SD_relaxThreshold(:,9)-Thresholdmean;
PTO_MMM_SD_relaxThreshold(:,17)= PTO_MMM_SD_relaxThreshold(:,5)-Thresholdmax3;
PTO_MMM_SD_relaxThreshold(:,18)= PTO_MMM_SD_relaxThreshold(:,11)-Thresholdmax;

for i = 1:size(PTO_MMM_SD_relaxThreshold,1)
    
    if PTO_MMM_SD_relaxThreshold (i,13)>0 %If the peak or trough is above threshold2, it is not likely to be sys or dia
        PTO_MMM_SD_relaxThreshold (i, 1:2)=0;
    end
    
    if PTO_MMM_SD_relaxThreshold(i,1:2)==0
        PTO_MMM_SD_relaxThreshold(i, 13)=0;
    end
    
    if PTO_MMM_SD_relaxThreshold(i,14)>0
        PTO_MMM_SD_relaxThreshold(i, 7:8)=0;
    end
    
    if PTO_MMM_SD_relaxThreshold(i,7:8)==0
        PTO_MMM_SD_relaxThreshold(i, 14)=0;
    end
    
    if PTO_MMM_SD_relaxThreshold(i,15)>0
        PTO_MMM_SD_relaxThreshold(i, 3:4)=0;
    end
    
    if PTO_MMM_SD_relaxThreshold(i,3:4)==0
        PTO_MMM_SD_relaxThreshold(i, 15)=0;
    end
    
    if PTO_MMM_SD_relaxThreshold (i,16)>0
        PTO_MMM_SD_relaxThreshold (i, 9:10)=0;
    end
    
    if PTO_MMM_SD_relaxThreshold(i,9:10)==0
        PTO_MMM_SD_relaxThreshold(i, 16)=0;
    end
    
    if PTO_MMM_SD_relaxThreshold(i,17)>0
        PTO_MMM_SD_relaxThreshold(i, 5:6)=0;
    end
    
    if PTO_MMM_SD_relaxThreshold(i,5:6)==0
        PTO_MMM_SD_relaxThreshold(i, 17)=0;
    end
    
    if PTO_MMM_SD_relaxThreshold(i,18)>0
        PTO_MMM_SD_relaxThreshold(i, 11:12)=0;
    end
    
    if PTO_MMM_SD_relaxThreshold(i,11:12)==0
        PTO_MMM_SD_relaxThreshold(i, 18)=0;
    end
end

temp_PTO_MMM_SD_relaxThreshold = PTO_MMM_SD_relaxThreshold;
idx_PTO_MMM_SD_relaxThreshold = ~all(temp_PTO_MMM_SD_relaxThreshold==0, 2); % Find the rows without zero entries using logical indexing
temp_PTO_MMM_SD_relaxThreshold = temp_PTO_MMM_SD_relaxThreshold(idx_PTO_MMM_SD_relaxThreshold,:); % Select the rows without zero entries using logical indexing
PTO_MMM_SD_relaxThreshold = temp_PTO_MMM_SD_relaxThreshold;

OscpointSD_relaxThreshold = PTO_MMM_SD_relaxThreshold(:,colwithPressure);

OscpointSD_relaxThreshold(:, 7:10)= 0;
OscpointSD_relaxThreshold(:, 6:8)= OscpointSD_relaxThreshold(:, 4:6);
OscpointSD_relaxThreshold(:, 4:5)=0;


for i = 1:size(OscpointSD_relaxThreshold,1)
    for j = 1:size(OscpointSD_relaxThreshold,2)
        if OscpointSD_relaxThreshold(i, j)>0
            OscpoinSD_relaxThreshold_logical3(i,j) = OscpointSD_relaxThreshold(i,j)>= max(PressureGuesses(1,1), mean(nonzeros(PressureGuesses(3:5,1))));%There was a zero in 18092402
        else  % The revision in the above line was done on 10Mar2025
            OscpoinSD_relaxThreshold_logical3(i,j) = 0;
        end
    end
end

OscpointS_relaxThreshold = OscpointSD_relaxThreshold.*OscpoinSD_relaxThreshold_logical3;
%%
for i = 1:size(OscpointS_relaxThreshold,1)
    rTD_OsSD_nT_2(i,1) = all(OscpointS_relaxThreshold(i, :)==0); %Removal of row with all zeros
end

OscpointS_relaxThreshold = OscpointS_relaxThreshold(~rTD_OsSD_nT_2, :);

%%
if size(OscpointS_relaxThreshold,1)==1
    Plowsys_guess_fig25_new = min(nonzeros(OscpointS_relaxThreshold(1,colwithPressureSD)));
    if PressureGuesses(1,7)< 20
        Phighsys_guess_fig25_new = Plowsys_guess_fig25_new + PressureGuesses(1,7);
    else
        Phighsys_guess_fig25_new = max(nonzeros(OscpointS_relaxThreshold(1,colwithPressureSD)));
    end
    
elseif size(OscpointS_relaxThreshold,1)==2
    P_hs_limit = max(nonzeros(OscpointS_relaxThreshold(2,colwithPressureSD)));
    P_ls_limit = min(nonzeros(OscpointS_relaxThreshold(1,colwithPressureSD)));
    
    if any(OscpointS_relaxThreshold(1,1:3)>0) && any(OscpointS_relaxThreshold(2,1:3)>0)
        meanOSRT_low = round(mean(nonzeros(OscpointS_relaxThreshold(1,1:3))));
        meanOSRT_high = round(mean(nonzeros(OscpointS_relaxThreshold(2,1:3))));
        if PressureGuesses(1,7)< 20
            if meanOSRT_high- meanOSRT_low >= PressureGuesses(1,7)
                Plowsys_guess_fig25_new = meanOSRT_low;
                Phighsys_guess_fig25_new = meanOSRT_high;
            else
                Plowsys_guess_fig25_new = min(nonzeros(OscpointS_relaxThreshold(1,1:3)));
                Phighsys_guess_fig25_new = max(nonzeros(OscpointS_relaxThreshold(2,1:3)));
            end
        else
            Plowsys_guess_fig25_new = min(nonzeros(OscpointS_relaxThreshold(1,1:3)));
            Phighsys_guess_fig25_new = max(nonzeros(OscpointS_relaxThreshold(2,1:3)));
        end
    elseif any(OscpointS_relaxThreshold(1,1:3)>0)
        meanOSRT_low = round(mean(nonzeros(OscpointS_relaxThreshold(1,1:3))));
        meanOSRT_high = round(mean(nonzeros(OscpointS_relaxThreshold(2,colwithPressureSD))));
        
        Plowsys_guess_fig25_new = meanOSRT_low;
        Phighsys_guess_fig25_new = meanOSRT_high;
        
    elseif any(OscpointS_relaxThreshold(2,1:3)>0)
        Plowsys_guess_fig25_new = min(nonzeros(OscpointS_relaxThreshold(2,1:3)));
        Phighsys_guess_fig25_new = max(nonzeros(OscpointS_relaxThreshold(2,1:3)));
    end
    
elseif size(OscpointS_relaxThreshold,1)>2
    lastRowOSRT = size(OscpointS_relaxThreshold,1);
    for i = 1:lastRowOSRT-1
        if any(any(OscpointS_relaxThreshold(1:(lastRowOSRT-1),1:3)>0))
            if min(nonzeros(OscpointS_relaxThreshold(i,1:3))) >= PressureGuesses(1,1)
                Plowsys_guess_fig25_new = min(nonzeros(OscpointS_relaxThreshold(i,1:3)));
                Phighsys_guess_fig25_new = round(mean(nonzeros(OscpointS_relaxThreshold(i+1,colwithPressureSD))));
                break
            elseif round(mean(nonzeros(OscpointS_relaxThreshold(i,1:3)))) >= PressureGuesses(1,1)
                Plowsys_guess_fig25_new = round(mean(nonzeros(OscpointS_relaxThreshold(i,1:3))));
                Phighsys_guess_fig25_new = round(mean(nonzeros(OscpointS_relaxThreshold(i+1,colwithPressureSD))));
                break
            elseif max(nonzeros(OscpointS_relaxThreshold(i,1:3))) >= PressureGuesses(1,1)
                Plowsys_guess_fig25_new = max(nonzeros(OscpointS_relaxThreshold(i,1:3)));
                Phighsys_guess_fig25_new = round(mean(nonzeros(OscpointS_relaxThreshold(i+1,colwithPressureSD))));
                break
            end
        elseif any(OscpointS_relaxThreshold(lastRowOSRT,1:3)>0)
            Plowsys_guess_fig25_new = min(nonzeros(OscpointS_relaxThreshold(lastRowOSRT,1:3)));
            Phighsys_guess_fig25_new = max(OscpointS_relaxThreshold(lastRowOSRT, colwithPressureSD));
        end
    end
end
%%
if ~exist('Plowsys_guess_fig25_new', 'var')
    Plowsys_guess_fig25_new = Clowsys_guess_fig25;
end

if ~exist('Phighsys_guess_fig25_new', 'var')
    Phighsys_guess_fig25_new = Chighsys_guess_fig25;
end

%%
SysMatureArray = [Plowsys_guess_fig25, Phighsys_guess_fig25 ; Plowsys_guess_fig25_new, Phighsys_guess_fig25_new; PSysDiaMay2025(1,1), PSysDiaMay2025(1,2); Clowsys_guess_fig25, Chighsys_guess_fig25; PressureGuesses(3:6, 1:2)];
%The first 3 rows are P and the next 5 rows are C
%%
PressureGuesses(2, 1)= round(Plowsys_guess_fig25_new);
PressureGuesses(2, 2)= round(Phighsys_guess_fig25_new);

PressureGuesses(2, 5) = round(PressureGuesses(2,3)+ 0.4*(PressureGuesses(2,1) - PressureGuesses(2,3)));
PressureGuesses(2, 6) = round(PressureGuesses(2,4)+ 0.33*(PressureGuesses(2,2) - PressureGuesses(2,4)));

PressureGuesses(2, 7) = PressureGuesses(2,2)- PressureGuesses(2,1);
PressureGuesses(2, 8) = PressureGuesses(2,4)- PressureGuesses(2,3);
PressureGuesses(2, 9) = PressureGuesses(2,6)- PressureGuesses(2,5);

PressureGuesses(2, 10) = round(PressureGuesses(2,3)+ 0.36*(PressureGuesses(2,2) - PressureGuesses(2,3)));
PressureGuesses(2, 11) = round(PressureGuesses(2,4)+ 0.27*(PressureGuesses(2,1) - PressureGuesses(2,4)));
PressureGuesses(2, 12) = PressureGuesses(2,11)- PressureGuesses(2,10);

PressureGuesses(:, 13) = round(PressureGuesses(:,3)+ 0.45*(PressureGuesses(:,1) - PressureGuesses(:,3)));
PressureGuesses(:, 14) = round(PressureGuesses(:,4)+ 0.36*(PressureGuesses(:,2) - PressureGuesses(:,4)));
PressureGuesses(:, 15) = PressureGuesses(:,14)- PressureGuesses(:,13);

PC_diff_1(1,1:4)= PressureGuesses(2, 1:4)- PressureGuesses(1, 1:4);

%%
% Redo Pdia
for i = 1:size(OscpointSD_relaxThreshold,1)
    for j = 1:size(OscpointSD_relaxThreshold,2)
        if OscpointSD_relaxThreshold(i, j)>0
            if PressureGuesses (1,4)> 55
                OscpoinD_relaxThreshold_logical(i,j) = OscpointSD_relaxThreshold(i,j)<= PressureGuesses(1,4) + 2;
            else
                OscpoinD_relaxThreshold_logical(i,j) = OscpointSD_relaxThreshold(i,j)<= MAPselect_lowP;
            end
        else
            OscpoinD_relaxThreshold_logical(i,j)=0;
        end
    end
end

OscpointD_relaxThreshold = OscpointSD_relaxThreshold.*OscpoinD_relaxThreshold_logical;

% Added on 25July 2025

for i = 1:size(OscpointD_relaxThreshold,1)
    if all(OscpointD_relaxThreshold(i,2:3)==0)
        OscpointD_relaxThreshold(i,1:3)=0;
    end
end

for i = 1:size(OscpointD_relaxThreshold,1)
    rTD_OD_nT_2(i,1) = all(OscpointD_relaxThreshold(i, :)==0); %Removal of row with all zeros
end

OscpointD_relaxThreshold = OscpointD_relaxThreshold(~rTD_OD_nT_2, :);

%%
if ~isempty (OscpointD_relaxThreshold) %In case 18092002 there were no features below MAP peak
    
    if size(OscpointD_relaxThreshold,1) ==1
      
        if PressureGuesses(1,8)<15 && PressureGuesses(1,7)-PressureGuesses(1,8)>=0 % added on 26Sep2025
            CdiavarHalf = PressureGuesses(1,8)/2 ;
        else
            CdiavarHalf = PressureGuesses(1,7)/2 ;
        end
            
        Plowdia_new = round(mean(nonzeros(OscpointD_relaxThreshold(1, :))) - CdiavarHalf);
        Phighdia_new = round(mean(nonzeros(OscpointD_relaxThreshold(1, :))) + CdiavarHalf);
        
    elseif size(OscpointD_relaxThreshold,1)==2
        
        if round(mean(nonzeros(OscpointD_relaxThreshold(2, colwithPressureSD))))- round(mean(nonzeros(OscpointD_relaxThreshold(1, colwithPressureSD)))) >= PressureGuesses(1,8)-2
            Phighdia_new = round(mean(nonzeros(OscpointD_relaxThreshold(2, colwithPressureSD))));
            Plowdia_new  = round(mean(nonzeros(OscpointD_relaxThreshold(1, colwithPressureSD))));
            
        elseif max(nonzeros(OscpointD_relaxThreshold(1, colwithPressureSD)))- min(nonzeros(OscpointD_relaxThreshold(1, colwithPressureSD)))>= PressureGuesses(1,8)
            Phighdia_new = max(nonzeros(OscpointD_relaxThreshold(1, colwithPressureSD)));
            Plowdia_new  = min(nonzeros(OscpointD_relaxThreshold(1, colwithPressureSD)));
            
        else
            Phighdia_new = round(mean(nonzeros(OscpointD_relaxThreshold(2, colwithPressureSD))));
            Plowdia_new = Phighdia_new - PressureGuesses(1,8);
        end
        
    elseif size(OscpointD_relaxThreshold,1)>2
        
        if max(nonzeros(OscpointD_relaxThreshold(end,colwithPressureSD))) - min(nonzeros(OscpointD_relaxThreshold(end,colwithPressureSD)))>= PressureGuesses(1,8)
            
            Phighdia_new = max(nonzeros(OscpointD_relaxThreshold(end,colwithPressureSD)));
            Plowdia_new = min(nonzeros(OscpointD_relaxThreshold(end,colwithPressureSD)));
        else
            Phighdia_new = round(mean(nonzeros(OscpointD_relaxThreshold(end,colwithPressureSD))));
            
            for i = (size(OscpointD_relaxThreshold,1)-1):-1:2
                if (Phighdia_new - mean(nonzeros(OscpointD_relaxThreshold(i,colwithPressureSD))))>= PressureGuesses(1,8)
                    Plowdia_new = round(mean(nonzeros(OscpointD_relaxThreshold(i,colwithPressureSD))));
                    break
                elseif (Phighdia_new - min(nonzeros(OscpointD_relaxThreshold(i,colwithPressureSD))))>= PressureGuesses(1,8) %another condition to keep the loop going
                    Plowdia_new = min(nonzeros(OscpointD_relaxThreshold(i, colwithPressureSD)));
                    break
                else
                    Plowdia_new = Phighdia_new - PressureGuesses(1,8);
                end
            end
        end
    else        
        Plowdia_new = Plowdia;
        Phighdia_new = Phighdia;
    end
end

if ~exist('Plowdia_new', 'var') %case of 18092102
    Plowdia_new = Plowdia;
end

if  ~exist('Phighdia_new', 'var') %case of 18092102
    Phighdia_new = Phighdia;
end

if isnan(Plowdia_new) %case of 18092102
    Plowdia_new = Plowdia;
end

if isnan(Phighdia_new) %case of 18092102
    Phighdia_new = Phighdia;
end

%%
PressureGuesses(2, 1)= round(Plowsys_guess_fig25_new);
PressureGuesses(2, 2)= round(Phighsys_guess_fig25_new);
%Recalculate after changing systolic
PressureGuesses(2, 5) = round(PressureGuesses(2,3)+ 0.4*(PressureGuesses(2,1) - PressureGuesses(2,3)));
PressureGuesses(2, 6) = round(PressureGuesses(2,4)+ 0.33*(PressureGuesses(2,2) - PressureGuesses(2,4)));

PressureGuesses(2, 7) = PressureGuesses(2,2)- PressureGuesses(2,1);
PressureGuesses(2, 8) = PressureGuesses(2,4)- PressureGuesses(2,3);
PressureGuesses(2, 9) = PressureGuesses(2,6)- PressureGuesses(2,5);

PressureGuesses(2, 10) = round(PressureGuesses(2,3)+ 0.36*(PressureGuesses(2,1) - PressureGuesses(2,3)));
PressureGuesses(2, 11) = round(PressureGuesses(2,4)+ 0.27*(PressureGuesses(2,2) - PressureGuesses(2,4)));
PressureGuesses(2, 12) = PressureGuesses (2,11)- PressureGuesses (2,10);

PressureGuesses(2, 13) = round(PressureGuesses(2,3)+ 0.45*(PressureGuesses(2,1) - PressureGuesses(2,3)));
PressureGuesses(2, 14) = round(PressureGuesses(2,4)+ 0.36*(PressureGuesses(2,2) - PressureGuesses(2,4)));
PressureGuesses(2, 15) = PressureGuesses(2,14)- PressureGuesses(2,13);

% redo diastolic
PDialow_arrayMay2025_new = [Plowdia_new, PDialowMay2025]';
PDialow_arrayMay2025_new(:,2) = PDialow_arrayMay2025_new(:,1)- PressureGuesses(1,3);
[mindiff_PDialow_arrayMay2025_new, rI_PDialow_arrayMay2025_new] = min(abs(PDialow_arrayMay2025_new(:,2))); % selecting value closer to Clowdia

PDiahigh_arrayMay2025_new = [Phighdia_new, PDiahighMay2025]';
PDiahigh_arrayMay2025_new(:,2) = PDiahigh_arrayMay2025_new(:,1)- PressureGuesses(1,4);

[mindiff_PDiahigh_arrayMay2025_new, rI_PDiahigh_arrayMay2025_new] = min(abs(PDiahigh_arrayMay2025_new(:,2))); % selecting value closer to Clowdia

PDia_arrayMay2025_new = [PDialow_arrayMay2025_new, PDiahigh_arrayMay2025_new];
PDia_lowCandSep2025 = round(PDialow_arrayMay2025_new(rI_PDialow_arrayMay2025_new,1));
PDia_highCandSep2025 = round(PDiahigh_arrayMay2025_new(rI_PDiahigh_arrayMay2025_new,1));

if abs(PressureGuesses(2,3)- PDia_lowCandSep2025) > 10
    if (PDia_highCandSep2025 - PDia_lowCandSep2025) <= max(PressureGuesses (1:2, 7)) % dia var cannot be more than sysvar
        PressureGuesses(2, 3)= PDia_lowCandSep2025;
    end
end

if abs(PressureGuesses(2,4)- PDia_highCandSep2025) > 10
    if (PDia_highCandSep2025 -  PressureGuesses(2, 3)) <= max(PressureGuesses (1:2, 7)) % dia var cannot be more than sysvar
        PressureGuesses(2, 4)= PDia_highCandSep2025;
    end
end

PressureGuesses(2, 5) = round(PressureGuesses(2,3)+ 0.4*(PressureGuesses(2,1) - PressureGuesses(2,3)));
PressureGuesses(2, 6) = round(PressureGuesses(2,4)+ 0.33*(PressureGuesses(2,2) - PressureGuesses(2,4)));

PressureGuesses(2, 7) = PressureGuesses(2,2)- PressureGuesses(2,1);
PressureGuesses(2, 8) = PressureGuesses(2,4)- PressureGuesses(2,3);
PressureGuesses(2, 9) = PressureGuesses(2,6)- PressureGuesses(2,5);

PressureGuesses(2, 10) = round(PressureGuesses(2,3)+ 0.36*(PressureGuesses(2,1) - PressureGuesses(2,3)));
PressureGuesses(2, 11) = round(PressureGuesses(2,4)+ 0.27*(PressureGuesses(2,2) - PressureGuesses(2,4)));
PressureGuesses(2, 12) = PressureGuesses (2,11)- PressureGuesses (2,10);

PressureGuesses(2, 13) = round(PressureGuesses(2,3)+ 0.45*(PressureGuesses(2,1) - PressureGuesses(2,3)));
PressureGuesses(2, 14) = round(PressureGuesses(2,4)+ 0.36*(PressureGuesses(2,2) - PressureGuesses(2,4)));
PressureGuesses(2, 15) = PressureGuesses(2,14)- PressureGuesses(2,13);

PC_diff_2(1,1:4)= PressureGuesses(2, 1:4)- PressureGuesses(1, 1:4);

%%
col_withMAP = sort([col_withLowMAP, col_withHighMAP]);

MAP_newlimit_low = min(nonzeros(min(nonzeros(PressureGuesses(1:2,col_withMAP)))))-3;
MAP_newlowCompare = round(mean(PressureGuesses(1:2, 5)));

MAP_newlimit_high = max(max(PressureGuesses(1:2,col_withMAP)));
MAP_newhighCompare = round(mean(PressureGuesses(1:2, 6)));

%%
OscpointM4 = OscpointM1;

%%
for i = 1: size(OscpointM4,1)
    for j = [colwithPressureM]
        if OscpointM4(i,j)< MAP_newlimit_low-2 || OscpointM4(i,j) > MAP_newlimit_high+2
            OscpointM4(i,j)=0;
        end
    end
end

for i = 1: size(OscpointM4,1)
    rTDOscpointM4_Jun2025(i,1) = all(OscpointM4(i, :)==0);
end

OscpointM4(rTDOscpointM4_Jun2025, :)=[];

%%
%Having saved M2copy, getting back to M2
% Now the rows above the first peak can be deleted.
%Have to get careful here. In 18092102, there was only one row in peak. SO,
%none of the troughs were considered.

for i = 1:size(OscpointM4,1)
    if any(OscpointM4(i,1:3)>0)
        if max(nonzeros(OscpointM4(i,1:3)))>= MAP_newlimit_low-2 && min(nonzeros(OscpointM4(i,1:3)))<= MAP_newlimit_high+2
            OscpointM4(i,4)= MAP_newlowCompare - mean(nonzeros(OscpointM4(i,1:3))); % The plus five here is to take away the -5 that was added to MAP lower limit
        else
            OscpointM4(i,4)=NaN;
        end
    else
        OscpointM4(i,4)=NaN;
    end
end

for i = 1:size(OscpointM4,1)
    if any(OscpointM4(i,1:3)>0)
        if max(nonzeros(OscpointM4(i,1:3)))>= MAP_newlimit_low-2 && min(nonzeros(OscpointM4(i,1:3)))<= MAP_newlimit_high+2
            OscpointM4(i,5)= MAP_newhighCompare - mean(nonzeros(OscpointM4(i,1:3))); % The minus 5 here is to take away the 5 that was added
        else
            OscpointM4(i,5)=NaN;
        end
    else
        OscpointM4(i,5)=NaN;
    end
end

for i = 1:size(OscpointM4,1)
    if any(OscpointM4(i,6:8)>0)
        if max(nonzeros(OscpointM4(i,6:8)))>= MAP_newlimit_low-2 && min(nonzeros(OscpointM4(i,6:8)))<= MAP_newlimit_high+2
            OscpointM4(i,9)= MAP_newlowCompare - mean(nonzeros(OscpointM4(i,6:8))); % The plus five here is to take away the -5 that was added to MAP lower limit
        else
            OscpointM4(i,9)=NaN;
        end
    else
        OscpointM4(i,9)=NaN;
    end
end

for i = 1:size(OscpointM4,1)
    if any(OscpointM4(i,6:8)>0)
        if max(nonzeros(OscpointM4(i,6:8)))>= MAP_newlimit_low-2 && min(nonzeros(OscpointM4(i,6:8)))<= MAP_newlimit_high+2
            OscpointM4(i,10)= MAP_newhighCompare - mean(nonzeros(OscpointM4(i,6:8))); % The minus 5 here is to take away the 5 that was added
        else
            OscpointM4(i,10)=NaN;
        end
    else
        OscpointM4(i,10)=NaN;
    end
end

if ~isempty(OscpointM4)
    for i = 1:size(OscpointM4,1)
        rTD_MAP1_4(i,1:2) = isnan(OscpointM4(i,4:5))& isnan(OscpointM4(i,9:10));% if all entries in col 6:8 in all rows of i and below are zero, delete them.
    end
    for i = 1:size(rTD_MAP1_4,1)
        if rTD_MAP1_4(i,1:2) == 1
            rTD_MAP2_4(i,1)=1;
        else
            rTD_MAP2_4(i,1)=0;
        end
    end
    
    for i = 1:size(rTD_MAP1_4,1)
        rTD_MAP2_4(i,1) = all(rTD_MAP1_4(i,1:2)==1);
    end
    
    for i = 1:size(rTD_MAP2_4,1)
        if rTD_MAP2_4(i,1)==1
            OscpointM4(i,colwithPressureM)=0;
        end
    end
    
    rTD_MAP2_4 = all(isnan(OscpointM4) | OscpointM4 == 0, 2);
    % Remove the identified rows
    OscpointM4(rTD_MAP2_4, :) = [];
end

for i = 1:size(OscpointM4,1)-1 % if there are 2 rows with negative values in col 5 or 10, remove the last one
    if ~isnan(OscpointM4(i,10))|| ~isnan(OscpointM4(i,5))
        if OscpointM4 (i,10)<0 || OscpointM4(i,5)<0
            if OscpointM4(i+1, 10)<0 || OscpointM4(i+1,5)<0
                OscpointM4(i+1:end, :)= [];
            end
            break
        end
    end
end

if all(all(OscpointM4(:,6:8)==0)) % If there is no peak at all in the range proposed, find the earlier peaks
    OscpointM4_Apr2025 = OscpointM1;
end

if exist('OscpointM4_Apr2025', 'var')&& ~isempty(OscpointM4_Apr2025)
    for i = 1: size(OscpointM4_Apr2025,1)
        if any(any(OscpointM4_Apr2025(i,6:8)>0))
            OscpointM4_start = i;
            break
        end
    end
    
    for i = size(OscpointM4_Apr2025,1):-1:1
        if any(any(OscpointM4_Apr2025(i,6:8)>0))
            OscpointM4_stop = i;
            break
        end
    end
end

OscpointM4copy = OscpointM4;

%%
%added on 26 Sep2025
if all(OscpointM4(1, 6:8)==0) && size(OscpointM4,1)>1% if there are no peaks in first row and there are more than 1 row
    if round(mean(nonzeros(OscpointM4(1,1:3))))< min(min(PressureGuesses(1:2, col_withMAP)))  % if the mean of first row is less than min of calc MAPS
        OscpointM4(1,:)=[];
    elseif round(mean(nonzeros(OscpointM4(2,colwithPressureM))))< 100 && round(mean(nonzeros(OscpointM4(2,colwithPressureM))))- round(mean(nonzeros(OscpointM4(1,colwithPressureM))))>12 % if MAP var is more than 12 when high MAP is less than 100
        OscpointM4(1,:)=[];
    end
end

%%
if ~isempty(OscpointM4) && size(OscpointM4,1)==1
    if ~isnan(OscpointM4(1,9))% if there are peaks
        MAPselect_lowP3 = min(nonzeros(OscpointM4(1,6:8)));
        MAPselect_highP3 = max(OscpointM4(1,6:8));
    else % This is unnecessary as there is no instance with just troughs
        MAPselect_lowP3 = min(nonzeros(OscpointM4(1,colwithPressureM)));
        MAPselect_highP3 = max(OscpointM4(1,colwithPressureM));
    end
end

%%

if ~isempty(OscpointM4) && size(OscpointM4,1)==2
    %Get MAP low
    if (~isnan(OscpointM4(1,9)) && abs(OscpointM4(1,9))<=2) || (~isnan(OscpointM4(1,4))&&abs(OscpointM4(1,4))<=2)
        MAPselect_lowP3 = round(mean(nonzeros(OscpointM4(1,colwithPressureM))));
        
    elseif (~isnan(OscpointM4(1,9)) && OscpointM4(1,9)<-2) || (~isnan(OscpointM4(1,4)) && OscpointM4(1,4)<-2) % if close to MAP lower limit
        MAPselect_lowP3 = min(nonzeros(OscpointM4(1,colwithPressureM)));
        
    elseif (~isnan(OscpointM4(1,9)) && OscpointM4(1,9)>2) || (~isnan(OscpointM4(1,4)) && OscpointM4(1,4)>2) % if rows are lower than MAP guess
        
        if (~isnan(OscpointM4(2,9)) && abs(OscpointM4(2,9))<=2) || (~isnan(OscpointM4(2,4))&&abs(OscpointM4(2,4))<=2) % if second row is closer to MAP guess
            MAPselect_lowP3 = round(mean(nonzeros(OscpointM4(2,colwithPressureM))));
            
        elseif (~isnan(OscpointM4(2,9)) && OscpointM4(2,9)> 2) || (~isnan(OscpointM4(2,4))&& OscpointM4(2,4))>2 % if second row is closer to MAP guess
            MAPselect_lowP3 = max(nonzeros(OscpointM4(2,colwithPressureM)));
            %added on 5August2025, to give respect to peaks in row 1
            %even if the value in col9 or 10 is more than 2
        elseif min(nonzeros(PressureGuesses(1:2, col_withMAP)))- max(OscpointM4(1, colwithPressureM))<=5 % if the min of sysdiamatrix MAPs is close to the first row
            if all(OscpointM4(2, 6:8)==0) &&(abs(OscpointM4(2,9))> 2*abs(OscpointM4(1,9)) || abs(OscpointM4(2,4))> 2*abs(OscpointM4(1,4)))% if there are peaks in first row, but only troughs in second row, give importance to peaks || if the difference in second row is twice the diff in first row
                MAPselect_lowP3 = max(OscpointM4(1,colwithPressureM));
                
            elseif mean(nonzeros(OscpointM4(2,colwithPressureM)))- mean(nonzeros(OscpointM4(1,colwithPressureM)))> MeanPlus2SD_StepSize % if the peaks are more than step size apart
                if abs(OscpointM4(2,9))> 1.5*abs(OscpointM4(1,9))||abs(OscpointM4(2,4))> 1.5*abs(OscpointM4(1,9)) % if the diff in second row is 1.5 times that in the first row
                    MAPselect_lowP3 = max(OscpointM4(1,colwithPressureM)); % In the previous line, (2,4) > (1,9) is correct
                    % sometimes there are entries only in (1,.4) and (2,9)
                    
                elseif abs(OscpointM4(2,9))> 1.5*abs(OscpointM4(1,4)) || abs(OscpointM4(2,4))> 1.5*abs(OscpointM4(1,4))
                    MAPselect_lowP3 = max(OscpointM4(1,colwithPressureM)); % since row 1 has positive difference, take max of row 1
                    
                elseif abs(OscpointM4(1,9))> 1.5*abs(OscpointM4(2,9))||abs(OscpointM4(1,4))> 1.5*abs(OscpointM4(2,4)) % if the diff in second row is 1.5 times that in the first row
                    MAPselect_lowP3 = max(OscpointM4(1,colwithPressureM)); % In the previous line, (2,4) > (1,9) is correct
                    
                elseif abs(OscpointM4(1,4))> 1.5*abs(OscpointM4(2,9)) || abs(OscpointM4(1,9))> 1.5*abs(OscpointM4(2,4))
                    MAPselect_lowP3 = round(mean(nonzeros(OscpointM4(2,colwithPressureM))));
                    
                else
                    for i = 1:2
                        OscpointM4_logical(i,colwithPressureM)= OscpointM4(i,colwithPressureM)>0;
                        sum_OscpointM4_logical(i,1) = sum(OscpointM4_logical(i,:));
                    end
                    [~,  rIOPM4]= max(sum_OscpointM4_logical);
                    MAPselect_lowP3 = round(mean(nonzeros(OscpointM4(rIOPM4,colwithPressureM))));
                end
            else %The same conditions above are repeated again. 12 Sep 2025
                
                if abs(OscpointM4(2,9))> 1.5*abs(OscpointM4(1,9))||abs(OscpointM4(2,4))> 1.5*abs(OscpointM4(1,9)) % if the diff in second row is 1.5 times that in the first row
                    MAPselect_lowP3 = max(OscpointM4(1,colwithPressureM)); % In the previous line, (2,4) > (1,9) is correct
                    % sometimes there are entries only in (1,.4) and (2,9)
                    
                elseif abs(OscpointM4(2,9))> 1.5*abs(OscpointM4(1,4)) || abs(OscpointM4(2,4))> 1.5*abs(OscpointM4(1,4))
                    MAPselect_lowP3 = max(OscpointM4(1,colwithPressureM)); % since row 1 has positive difference, take max of row 1
                    
                elseif abs(OscpointM4(1,9))> 1.5*abs(OscpointM4(2,9))||abs(OscpointM4(1,4))> 1.5*abs(OscpointM4(2,4)) % if the diff in second row is 1.5 times that in the first row
                    MAPselect_lowP3 = max(OscpointM4(1,colwithPressureM)); % In the previous line, (2,4) > (1,9) is correct
                    
                elseif abs(OscpointM4(1,4))> 1.5*abs(OscpointM4(2,9)) || abs(OscpointM4(1,9))> 1.5*abs(OscpointM4(2,4))
                    MAPselect_lowP3 = round(mean(nonzeros(OscpointM4(2,colwithPressureM))));
                else % This else was added on 18 Sep2025
                    MAPselect_lowP3 = (round(mean(nonzeros(OscpointM4(1:2,colwithPressureM)))));
                end
            end
            
        elseif (~isnan(OscpointM4(2,9)) && OscpointM4(2,9)<-2) || (~isnan(OscpointM4(2,4)) && OscpointM4(2,4)<-2)%This is the tricky part, where a decision may have to be made carefully
            if abs(OscpointM4(1,9))- abs(OscpointM4(2,9)) > 2*min(abs(OscpointM4(1:2, 9)))% clearly one row is far away, avoid that
                if abs(OscpointM4(1,9))<abs(OscpointM4(2,9))%row 1 is closer to MAP low guess
                    MAPselect_lowP3 = max(OscpointM4(1,6:8));
                    
                elseif abs(OscpointM4(1,9))> abs(OscpointM4(2,9))%row 2 is closer to MAP low guess
                    MAPselect_lowP3 = min(nonzeros(OscpointM4(2, 6:8)));
                end
                
            elseif abs(OscpointM4(1,4))- abs(OscpointM4(2,4)) > 2*min(abs(OscpointM4(1:2, 4)))% clearly one row is far away, avoid that
                if abs(OscpointM4(1,4))<abs(OscpointM4(2,4))%row 1 is closer to MAP low guess
                    MAPselect_lowP3 = max(OscpointM4(1,colwithPressureM));
                elseif abs(OscpointM4(1,4))> abs(OscpointM4(2,4))%row 2 is closer to MAP low guess
                    MAPselect_lowP3 = min(nonzeros(OscpointM4(2, colwithPressureM)));
                end
                
            elseif mean(nonzeros(OscpointM4(2,colwithPressureM)))- mean(nonzeros(OscpointM4(1,colwithPressureM)))>MeanPlus2SD_StepSize % again if the peaks are more than stepSize apart and
                if abs(OscpointM4(1,9))> 1.5*abs(OscpointM4(2,9))||abs(OscpointM4(1,9))> 1.5*abs(OscpointM4(2,4)) % if the diff in first row is 1.5 times that in the second row
                    MAPselect_lowP3 = min(nonzeros(OscpointM4(2,colwithPressureM)));
                    
                elseif abs(OscpointM4(1,4))> 1.5*abs(OscpointM4(2,9)) || abs(OscpointM4(1,4))> 1.5*abs(OscpointM4(2,4))
                    MAPselect_lowP3 = min(nonzeros(OscpointM4(2,colwithPressureM)));
                    
                elseif abs(OscpointM4(2,9))> 1.5*abs(OscpointM4(1,9)) || abs(OscpointM4(2,9))> 1.5*abs(OscpointM4(1,4))
                    MAPselect_lowP3 = round(mean(nonzeros(OscpointM4(1,colwithPressureM))));
                    
                elseif abs(OscpointM4(2,4))> 1.5*abs(OscpointM4(1,9)) || abs(OscpointM4(2,4))> 1.5*abs(OscpointM4(1,4))
                    MAPselect_lowP3 = round(mean(nonzeros(OscpointM4(1,colwithPressureM))));
                    
                else %since everything else is not working AND the rows are far apart, look at actual amplitudes of peaks as well as H points lower than them. Get PTO_MMM_M12, H all and L all. Get both MAP low and high
                    
                    for i = 1:size(PTO_MMM_M12,1)
                        PTO_MMM_M1Decide(i,1)= mean(nonzeros(PTO_MMM_M12(i, colwithPressure)));
                        PTO_MMM_M12Decide(i,2)= mean(nonzeros(PTO_MMM_M12(i, colwithPressure-1)));
                    end
                    
                    for i = 1:size(OscpointM4,1)
                        OscpointM4Decide(i,1)= mean(nonzeros(OscpointM4(i, colwithPressureM)));
                    end
                    
                    for i = 1:size(OscpointM4Decide,1)
                        for j = 1:size(PTO_MMM_M12Decide,1)
                            if OscpointM4Decide(i,1)== PTO_MMM_M12Decide(j,1)
                                OscpointM4Decide(i,2)= PTO_MMM_M12Decide(j,2);
                            end
                        end
                    end
                    %Collect L and H points alongside Osc
                    
                    H_allDecide = H_all(H_all(:,13)< max(OscpointM4Decide(:,1))-5,13);
                    L_allDecide = L_all(L_all(:,13)< max(OscpointM4Decide(:,1))-5,13);
                    for i = 1:size(OscpointM4Decide,1)
                        for j = 1:size(H_allDecide,1)
                            %                             if H_allDecide(j,1)< OscpointM4Decide(i,1)
                            if H_allDecide(j,1)< OscpointM4Decide(i,1)-5 % change made on 18 Sep2025, as dia has to be at least 5 less than MAP
                                OscpointM4Decide(i,3)= H_allDecide(j,1);
                                break
                            end
                        end
                    end
                    
                    for i = 1:size(OscpointM4Decide,1)
                        for j = 1:size(L_allDecide,1)
                            if L_allDecide(j,1)< OscpointM4Decide(i,1)
                                OscpointM4Decide(i,4)= L_allDecide(j,1);
                                break
                            end
                        end
                    end
                    % Find the actual amplitude of the short listed L and Hpoints in OscpointM4Decide:Use fitresult 75 for mean ratio smsp
                    
                    for i = 1:size(OscpointM4Decide,1)
                        OscpointM4Decide(i,5)=fitresult{75}(OscpointM4Decide(i,3));
                        OscpointM4Decide(i,6)=fitresult{75}(OscpointM4Decide(i,4));
                        % sometimes finding highest L point does not help.
                        % Especially if both L points have the same value, saying max does not help distinguish
                        OscpointM4Decide(i,7)= OscpointM4Decide(i,5) + OscpointM4Decide(i,6);
                    end
                    
                    %Find the highest L point if the L points in both rows are not the same. If same, then choose based on total of L and H
                    if OscpointM4Decide (1,6)~= OscpointM4Decide (2,6)
                        [~,rI_OscpointM4Decide] = max(OscpointM4Decide(:,6));
                    else
                        [~,rI_OscpointM4Decide] = max(OscpointM4Decide(:,7));
                    end
                    
                    MAPselect_lowP3 = min(nonzeros(OscpointM4(rI_OscpointM4Decide,colwithPressureM)));
                    MAPselect_highP3 = max(nonzeros(OscpointM4(rI_OscpointM4Decide,colwithPressureM))); %Decide on MAP high also here itself.
                end
            else
                MAPselect_lowP3 = (round(mean(nonzeros(OscpointM4(1:2,colwithPressureM)))));
            end
            
        elseif (~isnan(OscpointM4(2,9)) && OscpointM4(2,9)>2) || (~isnan(OscpointM4(2,4)) && OscpointM4(2,4)>2)
            MAPselect_lowP3 = max(OscpointM4(2,colwithPressureM));
        end
    end
    
    %Get MAP high (if it has not been decided earlier)
    if ~exist('MAPselect_highP3', 'var')
        if (~isnan(OscpointM4(1,10)) && abs(OscpointM4(1,10))<=2) || (~isnan(OscpointM4(1,5))&&abs(OscpointM4(1,5))<=2)
            MAPselect_highP3 = round(mean(nonzeros(OscpointM4(1,colwithPressureM))));
            
        elseif (~isnan(OscpointM4(1,10)) && OscpointM4(1,10)<-2) || (~isnan(OscpointM4(1,5)) && OscpointM4(1,5)<-2) % if close to MAP lower limit
            MAPselect_highP3 = min(nonzeros(OscpointM4(1,colwithPressureM)));
            
        elseif (~isnan(OscpointM4(1,10)) && OscpointM4(1,10)>2) || (~isnan(OscpointM4(1,5)) && OscpointM4(1,5)>2) % if rows are lower than MAP guess
            
            if (~isnan(OscpointM4(2,10)) && abs(OscpointM4(2,10))<=2) || (~isnan(OscpointM4(2,5))&&abs(OscpointM4(2,5))<=2) % if second row is closer to MAP guess
                MAPselect_highP3 = round(mean(nonzeros(OscpointM4(2,colwithPressureM))));
                
            elseif (~isnan(OscpointM4(2,10)) && abs(OscpointM4(2,10))> 2) || (~isnan(OscpointM4(2,5))&&abs(OscpointM4(2,5))>2) % if second row is closer to MAP guess
                MAPselect_highP3 = max(nonzeros(OscpointM4(2,colwithPressureM)));
                %added on 5August2025, to give respect to peaks in row 1
                %even if the value in col9 or 10 is more than 2
            elseif min(nonzeros(PressureGuesses(1:2, col_withMAP)))- max(OscpointM4(1, colwithPressureM))<=5 % if the min of sysdiamatrix MAPs is close to the first row
                if all(OscpointM4(2, 6:8)==0) &&(abs(OscpointM4(2,10))> 2*(OscpointM4(1,10)) || abs(OscpointM4(2,5))> 2*(OscpointM4(1,5)))% if there are peaks in first row, but only troughs in second row, give importance to peaks || if the difference in second row is twice the diff in first row
                    MAPselect_highP3 = max(OscpointM4(1,colwithPressureM));
                    
                elseif mean(nonzeros(OscpointM4(2,colwithPressureM)))- mean(nonzeros(OscpointM4(1,colwithPressureM)))> MeanPlus2SD_StepSize % if the peaks are more than step size apart
                    if abs(OscpointM4(2,10))> 1.5*abs(OscpointM4(1,10))||abs(OscpointM4(2,5))> 1.5*abs(OscpointM4(1,10)) % if the diff in second row is 1.5 times that in the first row
                        MAPselect_highP3 = max(OscpointM4(1,colwithPressureM)); % In the previous line, (2,5) > (1,10) is correct
                        % sometimes there are entries only in (1,.5) and (2,10)
                        
                    elseif abs(OscpointM4(2,10))> 1.5*abs(OscpointM4(1,5)) || abs(OscpointM4(2,5))> 1.5*abs(OscpointM4(1,5))
                        MAPselect_highP3 = max(OscpointM4(1,colwithPressureM)); % since row 1 has positive difference, take max of row 1
                        
                    elseif abs(OscpointM4(1,10))> 1.5*abs(OscpointM4(2,10))||abs(OscpointM4(1,5))> 1.5*abs(OscpointM4(2,5)) % if the diff in second row is 1.5 times that in the first row
                        MAPselect_highP3 = max(OscpointM4(1,colwithPressureM)); % In the previous line, (2,5) > (1,10) is correct
                        
                    elseif abs(OscpointM4(1,5))> 1.5*abs(OscpointM4(2,10)) || abs(OscpointM4(1,10))> 1.5*abs(OscpointM4(2,5))
                        MAPselect_highP3 = round(mean(nonzeros(OscpointM4(2,colwithPressureM))));
                    else
                        for i = 1:2
                            OscpointM4_logical_high(i,colwithPressureM)= OscpointM4(i,colwithPressureM)>0;
                            sum_OscpointM4_logical_high(i,1) = sum(OscpointM4_logical_high(i,:));
                        end
                        [~,  rIOPM4_high]= max(sum_OscpointM4_logical_high);
                        MAPselect_highP3 = round(mean(nonzeros(OscpointM4(rIOPM4_high,colwithPressureM))));
                    end
                else %The same conditions above are repeated again. 12Sep 2025
                    if abs(OscpointM4(2,10))> 1.5*abs(OscpointM4(1,10))||abs(OscpointM4(2,5))> 1.5*abs(OscpointM4(1,10)) % if the diff in second row is 1.5 times that in the first row
                        MAPselect_highP3 = max(OscpointM4(1,colwithPressureM)); % In the previous line, (2,5) > (1,10) is correct
                        % sometimes there are entries only in (1,.5) and (2,10)
                        
                    elseif abs(OscpointM4(2,10))> 1.5*abs(OscpointM4(1,5)) || abs(OscpointM4(2,5))> 1.5*abs(OscpointM4(1,5))
                        MAPselect_highP3 = max(OscpointM4(1,colwithPressureM)); % since row 1 has positive difference, take max of row 1
                        
                    elseif abs(OscpointM4(1,10))> 1.5*abs(OscpointM4(2,10))||abs(OscpointM4(1,5))> 1.5*abs(OscpointM4(2,5)) % if the diff in second row is 1.5 times that in the first row
                        MAPselect_highP3 = max(OscpointM4(1,colwithPressureM)); % In the previous line, (2,5) > (1,10) is correct
                        
                    elseif abs(OscpointM4(1,5))> 1.5*abs(OscpointM4(2,10)) || abs(OscpointM4(1,10))> 1.5*abs(OscpointM4(2,5))
                        MAPselect_highP3 = round(mean(nonzeros(OscpointM4(2,colwithPressureM))));
                    end
                end
                
            elseif (~isnan(OscpointM4(2,10)) && OscpointM4(2,10)<-2) || (~isnan(OscpointM4(2,5)) && OscpointM4(2,5)<-2)%This is the tricky part, where a decision may have to be made carefully
                if abs(OscpointM4(1,10))- abs(OscpointM4(2,10)) > 2*min(abs(OscpointM4(1:2, 10)))% clearly one row is far away, avoid that
                    if abs(OscpointM4(1,10))<abs(OscpointM4(2,10))%row 1 is closer to MAP low guess
                        MAPselect_highP3 = max(OscpointM4(1,6:8));
                        
                    elseif abs(OscpointM4(1,10))> abs(OscpointM4(2,10))%row 2 is closer to MAP low guess
                        MAPselect_highP3 = min(nonzeros(OscpointM4(2, 6:8)));
                    end
                    
                elseif abs(OscpointM4(1,5))- abs(OscpointM4(2,5)) > 2*min(abs(OscpointM4(1:2, 5)))% clearly one row is far away, avoid that
                    if abs(OscpointM4(1,5))<abs(OscpointM4(2,5))%row 1 is closer to MAP low guess
                        MAPselect_highP3 = max(OscpointM4(1,colwithPressureM));
                    elseif abs(OscpointM4(1,5))> abs(OscpointM4(2,5))%row 2 is closer to MAP low guess
                        MAPselect_highP3 = min(nonzeros(OscpointM4(2, colwithPressureM)));
                    end
                end
                
            elseif (~isnan(OscpointM4(2,10)) && OscpointM4(2,10)>2) || (~isnan(OscpointM4(2,5)) && OscpointM4(2,5)>2)
                MAPselect_highP3 = max(OscpointM4(2,colwithPressureM));
            end
        end
    end
end

%%
if ~isempty(OscpointM4) && size(OscpointM4,1)==3
    %case of all in first row being >0 is deliberately avoided
    
    if all(OscpointM4(2, 6:8)>0)
        
        if (~isnan(OscpointM4(2,9)) && abs(OscpointM4(2,9))<=2) || (~isnan(OscpointM4(2,4))&&abs(OscpointM4(2,4))<=2)
            MAPselect_lowP3 = round(mean(nonzeros(OscpointM4(2,colwithPressureM))));
            
        elseif (~isnan(OscpointM4(2,9)) && OscpointM4(2,9)<-2) || (~isnan(OscpointM4(2,4)) && OscpointM4(2,4)<-2) % if close to MAP lower limit
            MAPselect_lowP3 = mean(nonzeros(OscpointM4(1:2,colwithPressureM)));
            
        elseif (~isnan(OscpointM4(2,9)) && OscpointM4(2,9)>2) || (~isnan(OscpointM4(2,4)) && OscpointM4(2,4)>2) % if rows are lower and higher than MAPlimit
            
            if (~isnan(OscpointM4(3,9)) && abs(OscpointM4(3,9))<=2) || (~isnan(OscpointM4(3,4))&&abs(OscpointM4(3,4))<=2)
                MAPselect_lowP3 = round(mean(nonzeros(OscpointM4(2:3,colwithPressureM))));
                
            elseif (~isnan(OscpointM4(3,9)) && OscpointM4(3,9)<-2) || (~isnan(OscpointM4(3,4)) && OscpointM4(3,4)<-2)
                MAPselect_lowP3 = (round(mean(nonzeros(OscpointM4(2,colwithPressureM))))+ min(nonzeros(OscpointM4(3,colwithPressureM))))/2;
                
            elseif (~isnan(OscpointM4(3,9)) && OscpointM4(3,9)>2) || (~isnan(OscpointM4(3,4)) && OscpointM4(3,4)>2)
                MAPselect_lowP3 = max(OscpointM4(3,colwithPressureM));
            end
        end
        
        if (~isnan(OscpointM4(2,10)) && abs(OscpointM4(2,10))<=2) || (~isnan(OscpointM4(2,5))&& abs(OscpointM4(2,5))<=2)
            MAPselect_highP3 = round(mean(nonzeros(OscpointM4(2,colwithPressureM))));
            
        elseif (~isnan(OscpointM4(2,10)) && OscpointM4(2,10)<-2) || (~isnan(OscpointM4(2,5)) && OscpointM4(2,5)<-2) % if close to MAP lower limit
            MAPselect_highP3 = mean(nonzeros(OscpointM4(1:2,colwithPressureM)));
            
        elseif (~isnan(OscpointM4(2,10)) && OscpointM4(2,10)>2) || (~isnan(OscpointM4(2,5)) && OscpointM4(2,5)>2) % if rows are lower and higher than MAPlimit
            
            if (~isnan(OscpointM4(3,10)) && abs(OscpointM4(3,10))<=2) || (~isnan(OscpointM4(3,5))&&abs(OscpointM4(3,5))<=2)
                MAPselect_highP3 = round(mean(nonzeros(OscpointM4(3,colwithPressureM))));
                
            elseif (~isnan(OscpointM4(3,10)) && OscpointM4(3,10)<-2) || (~isnan(OscpointM4(3,5)) && OscpointM4(3,5)<-2)
                MAPselect_highP3 = round(mean(nonzeros(OscpointM4(2:3,colwithPressureM))));
                
            elseif (~isnan(OscpointM4(3,10)) && OscpointM4(3,10)>2) || (~isnan(OscpointM4(3,5)) && OscpointM4(3,5)>2)
                MAPselect_highP3 = max(OscpointM4(3,colwithPressureM));
            end
        end
        
    elseif all(OscpointM4(3, 6:8)>0)
        
        if abs(OscpointM4(3, 10))<=2
            MAPselect_highP3 = round(mean(nonzeros(OscpointM4(3,6:8))));
        elseif OscpointM4(3, 10)<-2
            MAPselect_highP3 = min(nonzeros(OscpointM4(3,6:8)));
        else
            MAPselect_highP3 = max(nonzeros(OscpointM4(3,6:8)));
        end
        
        if (~isnan(OscpointM4(2,9)) && abs(OscpointM4(2,9))<=2) || (~isnan(OscpointM4(2,4))&&abs(OscpointM4(2,4))<=2)
            MAPselect_lowP3 = round(mean(nonzeros(OscpointM4(2,colwithPressureM))));
            
        elseif (~isnan(OscpointM4(2,9)) && OscpointM4(2,9)<-2) || (~isnan(OscpointM4(2,4)) && OscpointM4(2,4)<-2) % if close to MAP lower limit
            MAPselect_lowP3 = mean(nonzeros(OscpointM4(1:2,colwithPressureM)));
            
        elseif (~isnan(OscpointM4(2,9)) && OscpointM4(2,9)>2) || (~isnan(OscpointM4(2,4)) && OscpointM4(2,4)>2) % if rows are lower and higher than MAPlimit
            
            if (~isnan(OscpointM4(3,9)) && abs(OscpointM4(3,9))<=2) || (~isnan(OscpointM4(3,4))&&abs(OscpointM4(3,4))<=2)
                MAPselect_lowP3 = round(mean(nonzeros(OscpointM4(2:3,colwithPressureM))));
                
            elseif (~isnan(OscpointM4(3,9)) && OscpointM4(3,9)<-2) || (~isnan(OscpointM4(3,4)) && OscpointM4(3,4)<-2)
                MAPselect_lowP3 = (round(mean(nonzeros(OscpointM4(2,colwithPressureM))))+ min(nonzeros(OscpointM4(3,colwithPressureM))))/2;
            else % when the value is more than 2
                MAPselect_lowP3 = max(nonzeros(OscpointM4(3,colwithPressureM)));
            end
        end
    else
        for i = 1:2
            if (~isnan(OscpointM4(i,9)) && abs(OscpointM4(i,9))<=2) || (~isnan(OscpointM4(i,4))&&abs(OscpointM4(i,4))<=2)
                MAPselect_lowP3 = round(mean(nonzeros(OscpointM4(i,colwithPressureM))));
                break
                
            elseif (~isnan(OscpointM4(i,9)) && OscpointM4(i,9)<-2) || (~isnan(OscpointM4(i,4)) && OscpointM4(i,4)<-2)
                if i == 1
                    MAPselect_lowP3 = min(nonzeros(OscpointM4(1,colwithPressureM)));
                    break
                elseif i==2
                    MAPselect_lowP3 = mean(nonzeros(OscpointM4(1:2,colwithPressureM)));
                    break
                end
            elseif (~isnan(OscpointM4(i,9)) && OscpointM4(i,9)>2) || (~isnan(OscpointM4(i,4)) && OscpointM4(i,4)>2) % if rows are lower and higher than MAPlimit
                
                if (~isnan(OscpointM4(i+1,9)) && abs(OscpointM4(i+1,9))<=2) || (~isnan(OscpointM4(i+1,4))&&abs(OscpointM4(i+1,4))<=2)
                    MAPselect_lowP3 = round(mean(nonzeros(OscpointM4(i:i+1,colwithPressureM))));
                    break
                    
                elseif (~isnan(OscpointM4(i+1,9)) && OscpointM4(i+1,9)<-2) || (~isnan(OscpointM4(i+1,4)) && OscpointM4(i+1,4)<-2)
                    MAPselect_lowP3 = (round(mean(nonzeros(OscpointM4(i,colwithPressureM))))+ min(nonzeros(OscpointM4(i+1,colwithPressureM))))/2;
                    break
                    
                elseif (~isnan(OscpointM4(3,9)) && OscpointM4(3,9)>2) || (~isnan(OscpointM4(3,4)) && OscpointM4(3,4)>2)
                    MAPselect_lowP3 = max(OscpointM4(i+1,colwithPressureM));
                    break
                end
            end
        end
        
        for i = 2:3
            if (~isnan(OscpointM4(i,10)) && abs(OscpointM4(i,10))<=2) || (~isnan(OscpointM4(i,5))&&abs(OscpointM4(i,5))<=2)
                MAPselect_highP3 = round(mean(nonzeros(OscpointM4(i,colwithPressureM))));
                break
                
            elseif (~isnan(OscpointM4(i,10)) && OscpointM4(i,10)<-2) || (~isnan(OscpointM4(i,5)) && OscpointM4(i,5)<-2) % if close to MAP lower limit
                MAPselect_highP3 = mean(nonzeros(OscpointM4(i-1:i,colwithPressureM)));
                break
                
            elseif (~isnan(OscpointM4(i,10)) && OscpointM4(i,10)>2) || (~isnan(OscpointM4(i,5)) && OscpointM4(i,5)>2) % if rows are lower and higher than MAPlimit
                if i ==2
                    if (~isnan(OscpointM4(3,10)) && abs(OscpointM4(3,10))<=2) || (~isnan(OscpointM4(3,5))&&abs(OscpointM4(3,5))<=2)
                        MAPselect_highP3 = round(mean(nonzeros(OscpointM4(3,colwithPressureM))));
                        break
                        
                    elseif (~isnan(OscpointM4(3,10)) && OscpointM4(3,10)<-2) || (~isnan(OscpointM4(3,5)) && OscpointM4(3,5)<-2)
                        MAPselect_highP3 = round(mean(nonzeros(OscpointM4(2:3,colwithPressureM))));
                        break
                        
                    elseif (~isnan(OscpointM4(3,10)) && OscpointM4(3,10)>2) || (~isnan(OscpointM4(3,5)) && OscpointM4(3,5)>2)
                        MAPselect_highP3 = max(OscpointM4(3,colwithPressureM));
                        break
                    end
                elseif i ==3
                    MAPselect_highP3 = max(OscpointM4(3,colwithPressureM));
                    break
                end
            end
        end
    end
end
%%
if ~isempty(OscpointM4) && size(OscpointM4,1)>3
    % case of all in first row being >0 is deliberately avoided
    
    if all(OscpointM4(2, 6:8)>0)
        
        if (~isnan(OscpointM4(2,9)) && abs(OscpointM4(2,9))<=2) || (~isnan(OscpointM4(2,4))&&abs(OscpointM4(2,4))<=2)
            MAPselect_lowP3 = round(mean(nonzeros(OscpointM4(2,colwithPressureM))));
            
        elseif (~isnan(OscpointM4(2,9)) && OscpointM4(2,9)<-2) || (~isnan(OscpointM4(2,4)) && OscpointM4(2,4)<-2) % if close to MAP lower limit
            MAPselect_lowP3 = mean(nonzeros(OscpointM4(1:2,colwithPressureM)));
            
        elseif (~isnan(OscpointM4(2,9)) && OscpointM4(2,9)>2) || (~isnan(OscpointM4(2,4)) && OscpointM4(2,4)>2) % if rows are lower and higher than MAPlimit
            
            if (~isnan(OscpointM4(3,9)) && abs(OscpointM4(3,9))<=2) || (~isnan(OscpointM4(3,4))&&abs(OscpointM4(3,4))<=2)
                MAPselect_lowP3 = round(mean(nonzeros(OscpointM4(2:3,colwithPressureM))));
                
            elseif (~isnan(OscpointM4(3,9)) && OscpointM4(3,9)<-2) || (~isnan(OscpointM4(3,4)) && OscpointM4(3,4)<-2)
                MAPselect_lowP3 = (round(mean(nonzeros(OscpointM4(2,colwithPressureM))))+ min(nonzeros(OscpointM4(3,colwithPressureM))))/2;
                
            elseif (~isnan(OscpointM4(3,9)) && OscpointM4(3,9)>2) || (~isnan(OscpointM4(3,4)) && OscpointM4(3,4)>2)
                MAPselect_lowP3 = max(OscpointM4(3,colwithPressureM));
            end
        end
        
        if (~isnan(OscpointM4(2,10)) && abs(OscpointM4(2,10))<=2) || (~isnan(OscpointM4(2,5))&&abs(OscpointM4(2,5))<=2)
            MAPselect_highP3 = round(mean(nonzeros(OscpointM4(2,colwithPressureM))));
            
        elseif (~isnan(OscpointM4(2,10)) && OscpointM4(2,10)<-2) || (~isnan(OscpointM4(2,5)) && OscpointM4(2,5)<-2) % if close to MAP lower limit
            MAPselect_highP3 = mean(nonzeros(OscpointM4(1:2,colwithPressureM)));
            
        elseif (~isnan(OscpointM4(2,10)) && OscpointM4(2,10)>2) || (~isnan(OscpointM4(2,5)) && OscpointM4(2,5)>2) % if rows are lower and higher than MAPlimit
            
            if (~isnan(OscpointM4(3,10)) && abs(OscpointM4(3,10))<=2) || (~isnan(OscpointM4(3,5))&&abs(OscpointM4(3,5))<=2)
                MAPselect_highP3 = round(mean(nonzeros(OscpointM4(3,colwithPressureM))));
                
            elseif (~isnan(OscpointM4(3,10)) && OscpointM4(3,10)<-2) || (~isnan(OscpointM4(3,5)) && OscpointM4(3,5)<-2)
                MAPselect_highP3 = round(mean(nonzeros(OscpointM4(2:3,colwithPressureM))));
                
            elseif (~isnan(OscpointM4(3,10)) && OscpointM4(3,10)>2) || (~isnan(OscpointM4(3,5)) && OscpointM4(3,5)>2)
                MAPselect_highP3 = max(OscpointM4(3,colwithPressureM));
            end
        end
        
    elseif all(OscpointM4(3, 6:8)>0)
        
        if abs(OscpointM4(3, 10))<=2
            MAPselect_highP3 = round(mean(nonzeros(OscpointM4(3,6:8))));
        elseif OscpointM4(3, 10)<-2
            MAPselect_highP3 = min(nonzeros(OscpointM4(3,6:8)));
        else % when the value is more than 2
            MAPselect_highP3 = max(nonzeros(OscpointM4(3,6:8)));
        end
        
        if (~isnan(OscpointM4(2,9)) && abs(OscpointM4(2,9))<=2) || (~isnan(OscpointM4(2,4))&&abs(OscpointM4(2,4))<=2)
            MAPselect_lowP3 = round(mean(nonzeros(OscpointM4(2,colwithPressureM))));
            
        elseif (~isnan(OscpointM4(2,9)) && OscpointM4(2,9)<-2) || (~isnan(OscpointM4(2,4)) && OscpointM4(2,4)<-2) % if close to MAP lower limit
            MAPselect_lowP3 = mean(nonzeros(OscpointM4(1:2,colwithPressureM)));
            
        elseif (~isnan(OscpointM4(2,9)) && OscpointM4(2,9)>2) || (~isnan(OscpointM4(2,4)) && OscpointM4(2,4)>2) % if rows are lower and higher than MAPlimit
            
            if (~isnan(OscpointM4(3,9)) && abs(OscpointM4(3,9))<=2) || (~isnan(OscpointM4(3,4))&&abs(OscpointM4(3,4))<=2)
                MAPselect_lowP3 = round(mean(nonzeros(OscpointM4(2:3,colwithPressureM))));
                
            elseif (~isnan(OscpointM4(3,9)) && OscpointM4(3,9)<-2) || (~isnan(OscpointM4(3,4)) && OscpointM4(3,4)<-2)
                MAPselect_lowP3 = (round(mean(nonzeros(OscpointM4(2,colwithPressureM))))+ min(nonzeros(OscpointM4(3,colwithPressureM))))/2;
                
            else % when the value is more than 2
                MAPselect_lowP3 = max(nonzeros(OscpointM4(3,colwithPressureM)));
            end
        end
    else
        for i = 1:size(OscpointM4,1)-1
            if (~isnan(OscpointM4(i,9)) && abs(OscpointM4(i,9))<=2) || (~isnan(OscpointM4(i,4))&&abs(OscpointM4(i,4))<=2)
                MAPselect_lowP3 = round(mean(nonzeros(OscpointM4(i,colwithPressureM))));
                break
                
            elseif (~isnan(OscpointM4(i,9)) && OscpointM4(i,9)<-2) || (~isnan(OscpointM4(i,4)) && OscpointM4(i,4)<-2)
                if i == 1
                    MAPselect_lowP3 = min(nonzeros(OscpointM4(1,colwithPressureM)));
                    break
                elseif i>1
                    MAPselect_lowP3 = mean(nonzeros(OscpointM4(i-1:i,colwithPressureM)));
                    break
                end
                
            elseif (~isnan(OscpointM4(i,9)) && OscpointM4(i,9)>2) || (~isnan(OscpointM4(i,4)) && OscpointM4(i,4)>2) % if rows are lower and higher than MAPlimit
                
                if (~isnan(OscpointM4(i+1,9)) && abs(OscpointM4(i+1,9))<=2) || (~isnan(OscpointM4(i+1,4))&&abs(OscpointM4(i+1,4))<=2)
                    MAPselect_lowP3 = round(mean(nonzeros(OscpointM4(i+1,colwithPressureM))));
                    break
                    
                elseif (~isnan(OscpointM4(i+1,9)) && OscpointM4(i+1,9)<-2) || (~isnan(OscpointM4(i+1,4)) && OscpointM4(i+1,4)<-2)
                    MAPselect_lowP3 = (round(mean(nonzeros(OscpointM4(i,colwithPressureM))))+ min(nonzeros(OscpointM4(i+1,colwithPressureM))))/2;
                    break
                    
                elseif (~isnan(OscpointM4(i+1,9)) && OscpointM4(i+1,9)>2) || (~isnan(OscpointM4(i+1,4)) && OscpointM4(i+1,4)>2)
                    if (~isnan(OscpointM4(i+2,9)) && OscpointM4(i+2,9)<0) || (~isnan(OscpointM4(i+2,4)) && OscpointM4(i+2,4)<0)
                        MAPselect_lowP3 = max(OscpointM4(i+1,colwithPressureM));
                        break
                    end
                end
            end
        end
        
        for i = 2:size(OscpointM4,1)
            if (~isnan(OscpointM4(i,10)) && abs(OscpointM4(i,10))<=2) || (~isnan(OscpointM4(i,5))&&abs(OscpointM4(i,5))<=2)
                MAPselect_highP3 = round(mean(nonzeros(OscpointM4(i,colwithPressureM))));
                break
                
            elseif (~isnan(OscpointM4(i,10)) && OscpointM4(i,10)<-2) || (~isnan(OscpointM4(i,5)) && OscpointM4(i,5)<-2) % if close to MAP lower limit
                MAPselect_highP3 = mean(nonzeros(OscpointM4(i-1:i,colwithPressureM)));
                break
                
            elseif (~isnan(OscpointM4(i,10)) && OscpointM4(i,10)>2) || (~isnan(OscpointM4(i,5)) && OscpointM4(i,5)>2) % if rows are lower and higher than MAPlimit
                if i < size(OscpointM4,1)
                    if (~isnan(OscpointM4(i+1,10)) && abs(OscpointM4(i+1,10))<=2) || (~isnan(OscpointM4(i+1,5))&&abs(OscpointM4(i+1,5))<=2)
                        MAPselect_highP3 = round(mean(nonzeros(OscpointM4(i+1,colwithPressureM))));
                        break
                        
                    elseif (~isnan(OscpointM4(i+1,10)) && OscpointM4(i+1,10)<-2) || (~isnan(OscpointM4(i+1,5)) && OscpointM4(i+1,5)<-2)
                        MAPselect_highP3 = round(mean(nonzeros(OscpointM4(i-1:i,colwithPressureM))));
                        break
                        
                    elseif (~isnan(OscpointM4(i+1,10)) && OscpointM4(i+1,10)>2) || (~isnan(OscpointM4(i+1,5)) && OscpointM4(i+1,5)>2)
                        if i <= size(OscpointM4,1)-1
                            if (~isnan(OscpointM4(i+2,10)) && OscpointM4(i+2,10)<0) || (~isnan(OscpointM4(i+2,5)) && OscpointM4(i+2,5)<0)
                                MAPselect_highP3 = round(mean(nonzeros(OscpointM4(i+1:i+2,colwithPressureM))));
                                break
                            end
                        elseif i == size(OscpointM4,1)-1
                            MAPselect_highP3 = max(OscpointM4(i+1,colwithPressureM));
                            break
                        end
                    end
                end
            end
        end
    end
end

if isempty(OscpointM4) % till 8 Sep 2025 code, if this was empty MAP newCompare was taken as MAP. it is changed here on 10 Sep 2025 . 
            MAPselect_lowP3 = MAPselect_lowP1;
            MAPselect_highP3 = MAPselect_highP1;
end
%%  
if MAPselect_lowP3 == MAPselect_highP3
    MAPselect_lowP3 = MAPselect_lowP3-1;
    MAPselect_highP3 = MAPselect_highP3+1;
end

if MAPselect_lowP3 > MAPselect_highP3
    MAPselect_lowP3_hold = MAPselect_lowP3;
    MAPselect_lowP3 = MAPselect_highP3;
    MAPselect_highP3 = MAPselect_lowP3_hold;
end

MAPselect_lowP = round(MAPselect_lowP3);
MAPselect_highP = round(MAPselect_highP3);

MAP_table = [MAPselect_lowP1, MAPselect_highP1; MAPselect_lowP3, MAPselect_highP3];
MAP_table(:,3) = MAP_table(:,2)- MAP_table(:,1);
MAP_table(:,4) = mean([MAP_table(:,1:2)]);
MAP_table(:,5) = std([MAP_table(:,1:2)]);
MAP_table(3,1:2)= MAP_table(1,1:2)- MAP_table(2, 1:2);

if MAP_table(3,1)>5 || MAP_table(3,2)>5
    disp('MAP_table');
    disp(MAP_table);
end

%%
% At this point it is important to check dia again: 9 Sep 2025

%Revise P dia
PTO_MMM_D_late = PTO_MMM_SD;

colwithPressure = [2,4,6,8,10,12];

for i =1:size(PTO_MMM_D_late,1)
    for j = colwithPressure
        if PTO_MMM_D_late(i,j) > MAPselect_highP  
            PTO_MMM_D_late(i,j)=0;
            PTO_MMM_D_late(i,j-1)=0;
        end
    end
end

temp_PTO_MMM_D_late = PTO_MMM_D_late (:,1:12);
idx_PTO_MMM_D_late = ~all(temp_PTO_MMM_D_late==0, 2); % Find the rows without zero entries using logical indexing
temp_PTO_MMM_D_late = temp_PTO_MMM_D_late(idx_PTO_MMM_D_late,:); % Select the rows without zero entries using logical indexing
PTO_MMM_D_late = temp_PTO_MMM_D_late;

if ~isempty (PTO_MMM_D_late)
    OscpointD1_late = PTO_MMM_D_late(:,colwithPressure); %In the case of 18092102, the troughs in MAP range were too low and got included in dia troughs
end

if exist('OscpointD1_late', 'var') && ~isempty(OscpointD1_late) %In case 18092002 there were no features below MAP peak
    if any(any(OscpointD1_late(:,1:3))>0)
        for i = size(OscpointD1_late,1):-1:1
            if any(any(OscpointD1_late(i, 1:3))>0)
                Phighdia_late = round(mean(nonzeros(OscpointD1_late(i,1:3))));
                if i > 1 && any(any(OscpointD1_late(i-1, 1:3))>0)
                    if round(mean(nonzeros(OscpointD1_late(i,1:3))))- round(mean(nonzeros(OscpointD1_late(i-1,1:3))))< 2*(MAPselect_highP-MAPselect_lowP)
                        Plowdia_late = round(mean(nonzeros(OscpointD1_late(i-1,1:3))));
                    else
                        Plowdia_late = min(nonzeros(OscpointD1_late(i,1:3)));
                    end
                else
                    Plowdia_late = min(nonzeros(OscpointD1_late(i,1:3)));
                end
                break
            end
        end
    end
end

% Revise C dia

L_all_trimmed_late = L_all;
    L_all_limit_late = MAPselect_lowP-10;

for i = 1: size(L_all_trimmed_late,1)
    for j=1:12
        if L_all_trimmed_late(i,j)< min(nonzeros(DiaEarlyArray))|| L_all_trimmed_late(i,j) > L_all_limit_late
            L_all_trimmed_late(i,j) = 0;
        end
    end
end

for i=1:size(L_all_trimmed_late,1)
    if all(L_all_trimmed_late(i,1:12)==0)
        L_all_trimmed_late(i,:)=0;
    end
end

temp_L_all_trimmed = L_all_trimmed_late;
idx_L_all_trimmed = ~all(temp_L_all_trimmed==0, 2); % Find the rows without zero entries using logical indexing
temp_L_all_trimmed = temp_L_all_trimmed(idx_L_all_trimmed,:); % Select the rows without zero entries using logical indexing
L_all_trimmed_late = temp_L_all_trimmed; % Assign the modified array back

for i = 1:size(L_all_trimmed_late,1)
    for j = 1:12
        L_all_trimmed_logical(i,j) = L_all_trimmed_late(i,j)>0;
    end
    L_all_trimmed_late(i,15)= sum(L_all_trimmed_logical(i,:));
end

ClowDia_Candidates_late = L_all_trimmed_late(:,13)';


H_all_trimmed_late = H_all;

    H_all_limit_late = MAPselect_highP-10;

for i = 1: size(H_all_trimmed_late,1)
    for j=1:12
        if H_all_trimmed_late(i,j)< min(nonzeros(DiaEarlyArray))|| H_all_trimmed_late(i,j) > H_all_limit_late
            H_all_trimmed_late(i,j) = 0;
        end
    end
end

for i=1:size(H_all_trimmed_late,1)
    if all(H_all_trimmed_late(i,1:12)==0)
        H_all_trimmed_late(i,:)=0;
    end
end

temp_H_all_trimmed = H_all_trimmed_late;
idx_H_all_trimmed = ~all(temp_H_all_trimmed==0, 2); % Find the rows without zero entries using logical indexing
temp_H_all_trimmed = temp_H_all_trimmed(idx_H_all_trimmed,:); % Select the rows without zero entries using logical indexing
H_all_trimmed_late = temp_H_all_trimmed; % Assign the modified array back

for i = 1:size(H_all_trimmed_late,1)
    for j = 1:12
        H_all_trimmed_logical(i,j) = H_all_trimmed_late(i,j)>0;
    end
    H_all_trimmed_late(i,15)= sum(H_all_trimmed_logical(i,:));
end

ChighDia_Candidates_late = H_all_trimmed_late(:,13)';

if ~exist('Plowdia_late', 'var')
    Plowdia_late = Plowdia;
end

if ~exist('Phighdia_late', 'var')
    Phighdia_late = Phighdia;
end

DiaMatureArray_late = [Plowdia_late, PDialowMay2025, Phighdia_late, PDiahighMay2025, ClowDia_Candidates_late, 1, ChighDia_Candidates_late];% check: First and third columns are values from troughs, second and fourth columns from MMMandSD

%%
%Arrange similar values in a row
for i = 1:size(DiaMatureArray_late,2)% yes 2 and not 1
    for j = 1:size(DiaMatureArray_late,2)
        if i <= size(DiaMatureArray_late,1)
            if DiaMatureArray_late(i,j)> min(nonzeros(DiaMatureArray_late(i,:)))+3
                addrowsDMA = zeros(1, size(DiaMatureArray_late,2));
                DiaMatureArray_late = [DiaMatureArray_late; addrowsDMA];
                DiaMatureArray_late(i+1,j)= DiaMatureArray_late(i,j);
                DiaMatureArray_late(i,j)=0;
            end
        end
    end
end

for i = 1:size(DiaMatureArray_late,1)
    DiaMatureArray_lateLogical(i,1) = sum(DiaMatureArray_late(i,:))==0;
end

DiaMatureArray_late = DiaMatureArray_late(~DiaMatureArray_lateLogical,:);
% columns 1 and 3 are troughs and are more important. If there are entries
% here, and have support from C values that are in columns 5 upwards, take them as P dia.

[~, colindexDMA_late] = find(DiaMatureArray_late(1,:)==1);
%%
addcol_late = zeros(size(DiaMatureArray_late,1), 4);
DiaMatureArray_late = [DiaMatureArray_late, addcol_late];

%diavarGuessmax = min(CsysGuessVar_fig25, Psysvar);

for i = 1:size(DiaMatureArray_late,1)
    DiaMatureArray_late(i,end-3)= round(mean(nonzeros(DiaMatureArray_late(i, 1:2)))); %mean of Plowdia candidates
    DiaMatureArray_late(i,end-2)= round(mean(nonzeros(DiaMatureArray_late(i, 3:4)))); %mean of Phighdia candidates
    DiaMatureArray_late(i,end-1)= round(mean(nonzeros(DiaMatureArray_late(i, 5:colindexDMA_late)))); %mean of L points or Clowdia candidates
    DiaMatureArray_late(i,end)= round(mean(nonzeros(DiaMatureArray_late(i, colindexDMA_late+1:end-4)))); %mean of H points or Chighdia candidates
end

%make all NANs to 0

for i= 1:size(DiaMatureArray_late,1)
    for j= 1:size(DiaMatureArray_late,2)
        if isnan(DiaMatureArray_late(i,j))|| DiaMatureArray_late(i,j)==1 %The col separating L and H has an entry 1
            DiaMatureArray_late(i,j)=0;
        end
    end
end

% Merge rows further
for i = 2: size(DiaMatureArray_late,1)
    if mean(nonzeros(DiaMatureArray_late(i,end-3:end-2)))- mean(nonzeros(DiaMatureArray_late(i-1,end-3:end-2)))<=6
        for j=1:4
            if DiaMatureArray_late(i,j)>0 && DiaMatureArray_late(i-1,j)==0
                DiaMatureArray_late(i-1,j)=DiaMatureArray_late(i,j);
                DiaMatureArray_late(i,j)=0;
            end
        end
    end
end

%make all NANs to 0

for i= 1:size(DiaMatureArray_late,1)
    for j= 1:size(DiaMatureArray_late,2)
        if isnan(DiaMatureArray_late(i,j))|| DiaMatureArray_late(i,j)==1 %The col separating L and H has an entry 1
            DiaMatureArray_late(i,j)=0;
        end
    end
end

%Recalculate means
for i = 1: size(DiaMatureArray_late,1)
    DiaMatureArray_late(i,end-3)= round(mean(nonzeros(DiaMatureArray_late(i, 1:2)))); %mean of Plowdia candidates
    DiaMatureArray_late(i,end-2)= round(mean(nonzeros(DiaMatureArray_late(i, 3:4)))); %mean of Phighdia candidates
end
% Rearrange C as well
for i = 2: size(DiaMatureArray_late,1)
    if mean(nonzeros(DiaMatureArray_late(i,end-1:end)))- mean(nonzeros(DiaMatureArray_late(i-1,end-3:end-2)))<5 || mean(nonzeros(DiaMatureArray_late(i,end-3:end-2)))- mean(nonzeros(DiaMatureArray_late(i-1,end-1:end)))<5
        for j=5:(size(DiaMatureArray_late,2)-4)
            if DiaMatureArray_late(i,j)>0 && DiaMatureArray_late(i-1,j)==0
                DiaMatureArray_late(i-1,j)=DiaMatureArray_late(i,j);
                DiaMatureArray_late(i,j)=0;
            end
        end
    end
end

%make all NANs to 0
for i= 1:size(DiaMatureArray_late,1)
    for j= 1:size(DiaMatureArray_late,2)
        if isnan(DiaMatureArray_late(i,j))|| DiaMatureArray_late(i,j)==1 %The col separating L and H has an entry 1
            DiaMatureArray_late(i,j)=0;
        end
    end
end
%Recalculate means
for i = 1: size(DiaMatureArray_late,1)
    DiaMatureArray_late(i,end-1)= round(mean(nonzeros(DiaMatureArray_late(i, 5:colindexDMA_late-1)))); %mean of Plowdia candidates
    DiaMatureArray_late(i,end)= round(mean(nonzeros(DiaMatureArray_late(i, colindexDMA_late+1:end-4)))); %mean of Phighdia candidates
end

%make all NANs to 0

for i= 1:size(DiaMatureArray_late,1)
    for j= 1:size(DiaMatureArray_late,2)
        if isnan(DiaMatureArray_late(i,j))|| DiaMatureArray_late(i,j)==1 %The col separating L and H has an entry 1
            DiaMatureArray_late(i,j)=0;
        end
    end
end

%%
%Get Phighdia or diahigh2
sizeDMA_row_late = size(DiaMatureArray_late,1);
sizeDMA_col_late = size(DiaMatureArray_late,2);

for i = sizeDMA_row_late:-1:2 % Top row is always 0, because of insertion of 1 as a divider
    if any(DiaMatureArray_late(i,sizeDMA_col_late-3:sizeDMA_col_late-2)>0) && any(DiaMatureArray_late(i,sizeDMA_col_late-1:sizeDMA_col_late)>0)
        if any(DiaMatureArray_late(i,3:4)>0)
            diahigh2_late = max(DiaMatureArray_late(i, 3:4));
            break
        end
    end
end

%In the following loop, if any C value is missing in the row with P, but there
%are C values close to but above and below P values above diahigh2,
%consider them

if exist('diahigh2_late','var') && diahigh2_late < max(max(DiaMatureArray_late(:, sizeDMA_col_late-3:sizeDMA_col_late-2)))
    %get those values
    diahigh2_OtherCand_logical_late = DiaMatureArray_late(:, sizeDMA_col_late-3:sizeDMA_col_late-2)>diahigh2_late;
    diahigh2_OtherCand_late = nonzeros(DiaMatureArray_late(:, sizeDMA_col_late-3:sizeDMA_col_late-2).*diahigh2_OtherCand_logical_late);
    diahigh2for_CheckC_late = nonzeros(DiaMatureArray_late(:, sizeDMA_col_late-1:sizeDMA_col_late));
    if any(diahigh2for_CheckC_late>min(nonzeros(diahigh2_OtherCand_late))-5)
        for j= 1:size(diahigh2for_CheckC_late,1)
        for i = 1:size(diahigh2_OtherCand_late,1)            
                diahigh2_OtherCand_late(i,j+1)= diahigh2for_CheckC_late (j,1)-diahigh2_OtherCand_late(i,1);
            end
        end
    end
    if any(any(abs(diahigh2_OtherCand_late(:,2:end))<=5))
        absDiff_diahigh2_OtherCand_late= abs(diahigh2_OtherCand_late(:,2:end));
        rI_diahigh2_OtherCand_1_late = min(absDiff_diahigh2_OtherCand_late, [],2);
        [~,rI_diahigh2_OtherCand_late]=min(rI_diahigh2_OtherCand_1_late);
        diahigh2_late = diahigh2_OtherCand_late(rI_diahigh2_OtherCand_late,1);
    end
end

if ~exist('diahigh2_late', 'var')|| isempty(diahigh2_late)
    diahigh2_late = max(max(DiaMatureArray_late(:, sizeDMA_col_late-3:sizeDMA_col_late-2)));
end

%Get dialow2
for i = sizeDMA_row_late:-1:2
    if any(DiaMatureArray_late(i,sizeDMA_col_late-3:sizeDMA_col_late-2)>0) && any(DiaMatureArray_late(i,sizeDMA_col_late-1:sizeDMA_col_late)>0)
        if any(DiaMatureArray_late(i,1:2)>0)
            dialow2_late = max(DiaMatureArray_late(i, 1:2));
            break
        else
            dialow2_cand_late = nonzeros(DiaMatureArray_late(:,1:2));
            dialow2_cand_late = dialow2_cand_late(dialow2_cand_late< diahigh2_late);
            dialow2_late = max(dialow2_cand_late);
        end
    end
end

for i = size(DiaMatureArray_late,1):-1:2
    if any(DiaMatureArray_late(i,sizeDMA_col_late-3:sizeDMA_col_late-2)>0) && any(DiaMatureArray_late(i,sizeDMA_col_late-1:sizeDMA_col_late)>0)
        if any(DiaMatureArray_late(i,colindexDMA_late+1:end-4)>0)
            diahigh1_late = max(DiaMatureArray_late(i, colindexDMA_late+1:end-4));
            break
        end
    end
end

if (~exist('diahigh1_late', 'var') || diahigh1_late < (diahigh2_late-5)) %reconsider
    diahigh1_cand_late = nonzeros(DiaMatureArray_late(:,sizeDMA_col_late-1:sizeDMA_col_late));
    diahigh1_cand_late = diahigh1_cand_late(diahigh1_cand_late >= diahigh2_late & diahigh1_cand_late <= diahigh2_late+6);% +4 was changed to +6 on 20Aug2025
    if exist('diahigh1_cand_late', 'var')&& ~isempty(diahigh1_cand_late)
        diahigh1_late = min(diahigh1_cand_late);
    else
        diahigh1_late=diahigh2_late;
    end
end

%Get dialow1
for i = size(DiaMatureArray_late,1):-1:2
    if any(DiaMatureArray_late(i,sizeDMA_col_late-3:sizeDMA_col_late-2)>0) && any(DiaMatureArray_late(i,sizeDMA_col_late-1:sizeDMA_col_late)>0)
       if any(DiaMatureArray_late(i,sizeDMA_col_late-1)>0)
            dialow1_late = DiaMatureArray_late(i, sizeDMA_col_late-1);
            break
        else
            dialow1_cand_late = nonzeros(DiaMatureArray_late(:,sizeDMA_col_late-1:sizeDMA_col_late));
            dialow1_cand_late = dialow1_cand_late(dialow1_cand_late < diahigh1_late);
        end
        
        if exist('dialow1_cand_late', 'var')&& ~isempty(dialow1_cand_late)
            dialow1_late = max(dialow1_cand_late);
        else
            dialow1_late = diahigh1_late;
        end
    else
        dialow1_late = diahigh1_late;
    end
end

if ~exist('dialow1_late', 'var') || isempty(dialow1_late)
    dialow1_late = dialow2_late;
end

if ~exist('dialow2_late', 'var')|| isempty(dialow2_late)
    dialow2_late = dialow1_late;
end

if ~exist('diahigh1_late', 'var') || isempty(diahigh1_late)
    diahigh1_late = diahigh2_late;
end

if ~exist('diahigh2_late', 'var') isempty(diahigh2_late)
    diahigh2_late = diahigh1_late;
end

if diahigh1_late- dialow1_late > 2*(diahigh2_late-dialow2_late) && diahigh2_late-dialow2_late > 4 % Cdiavar more than twice Pdiavar
   dia1_cand_late = nonzeros(DiaMatureArray_late(:,sizeDMA_col_late-1:sizeDMA_col_late));
   dia1_cand_late = dia1_cand_late(dia1_cand_late >= dialow2_late); 
    if ~isempty(dia1_cand_late)
    dialow1_late = min(dia1_cand_late);
    end
    diahigh1_cand2 = dia1_cand_late(dia1_cand_late > dialow1_late);
    if~isempty(diahigh1_cand2)
    diahigh1_late = min(diahigh1_cand2);
    end
end

if dialow2_late > diahigh2_late
    dialow2hold_late = dialow2_late;
    dialow2_late = diahigh2_late;
    diahigh2_late = dialow2hold_late;
end

if dialow2_late == diahigh2_late
    dialow2_late = dialow2_late-2;
    diahigh2_late = diahigh2_late+2;
end

if dialow1_late == diahigh1_late
    dialow1_late = dialow1_late-2;
    diahigh1_late = diahigh1_late+2;
end
    
if dialow1_late > diahigh1_late
    dialow1hold_late = dialow1_late;
    dialow1_late = diahigh1_late;
    diahigh1_late = dialow1hold_late;
end

DiaCPSep2025_late = ([dialow1_late, diahigh1_late; dialow2_late, diahigh2_late]);
DiaCPSep2025_late(:,3)= DiaCPSep2025_late(:,2)-DiaCPSep2025_late(:,1);
DiaCPSep2025_late(3,:)= DiaCPSep2025_late(1,:)-DiaCPSep2025_late(2,:);

Csysvar_PG = PressureGuesses(1,2)- PressureGuesses(1,1);
Psysvar_PG = PressureGuesses(2,2)- PressureGuesses(2,1);

if DiaCPSep2025_late(1,3)> (max(Csysvar_PG, Psysvar_PG)+3) && DiaCPSep2025_late(2,3)< (max(Csysvar_PG, Psysvar_PG)+3)
    %revise Cdia
    [~,cIDia_late]= min(abs(DiaCPSep2025_late(3,1:2)));
    if cIDia_late ==2 %Chigh dia close to Phighdia. Change Clowdia
        for i = size(DiaMatureArray_late,1):-1:2
            if DiaMatureArray_late(i,sizeDMA_col_late-1)>0 && DiaMatureArray_late(i,sizeDMA_col_late-1)< diahigh1_late
                dialow1_late = DiaMatureArray_late(i, sizeDMA_col_late-1);
                break
            end
        end      
    end
end

disp ([dialow1_late, diahigh1_late; dialow2_late, diahigh2_late]);

%%
Pressure_selection = []; %initializing for reruns
Pressure_selection(:,:) = round(PressureGuesses(:,:));

Pressure_selection(1,3:4)= [dialow1_late, diahigh1_late];
Pressure_selection(2,3:4)= [dialow2_late, diahigh2_late];

if Pressure_selection(1,3)~= round(PressureGuesses(1,3)) || Pressure_selection(2,3)~= round(PressureGuesses(2,3))
    for i = 1:2
        Pressure_selection(i, 5) = round(Pressure_selection(i,3)+ 0.4*(Pressure_selection(i,1) - Pressure_selection(i,3)));
        Pressure_selection(i, 6) = round(Pressure_selection(i,4)+ 0.33*(Pressure_selection(i,2) - Pressure_selection(i,4)));
        
        Pressure_selection(i, 7) = Pressure_selection(i,2)- Pressure_selection(i,1);
        Pressure_selection(i, 8) = Pressure_selection(i,4)- Pressure_selection(i,3);
        Pressure_selection(i, 9) = Pressure_selection(i,6)- Pressure_selection(i,5);
        
        Pressure_selection(i, 10) = round(Pressure_selection(i,3)+ 0.36*(Pressure_selection(i,1) - Pressure_selection(i,3)));
        Pressure_selection(i, 11) = round(Pressure_selection(i,4)+ 0.27*(Pressure_selection(i,2) - Pressure_selection(i,4)));
        Pressure_selection(i, 12) = Pressure_selection (i,11)- Pressure_selection (i,10);
        
        Pressure_selection(i, 13) = round(Pressure_selection(i,3)+ 0.45*(Pressure_selection(i,1) - Pressure_selection(i,3)));
        Pressure_selection(i, 14) = round(Pressure_selection(i,4)+ 0.36*(Pressure_selection(i,2) - Pressure_selection(i,4)));
        Pressure_selection(i, 15) = Pressure_selection (i,14)- Pressure_selection (i,13);
    end
end

%%
%if the selected MAPs and calc MAPs in Pressure selection dont agree
MAPdifferenceTable(:,1:3) = Pressure_selection(:,[5,10,13])- MAPselect_lowP;
MAPdifferenceTable(:,4:6) = Pressure_selection(:,[6,11,14])- MAPselect_highP;

[mindiffMAPdt_lowC, col_index_MAPdT_lowC] = min(MAPdifferenceTable(1,1:3));
[mindiffMAPdt_highC, col_index_MAPdT_highC] = min(MAPdifferenceTable(1,4:6));

if abs(mindiffMAPdt_lowC)>3 % Must reconsider pressure selection
    
    if all(MAPdifferenceTable(1,1:3)>3) %(the else condition already says that these values are more than 3 or less than -3)
        %reduce Clowdia using Lpoints and Hpoints less than the current value
        
        DMA_for_PS_lowC = DiaMatureArray_late(:, (size(DiaMatureArray_late,2)-1):size(DiaMatureArray_late,2));
        SMA_for_PS_lowC = SysMatureArray(4:8, 1);
        
        for i = 1:size(DMA_for_PS_lowC,1)
            for j = 1:2
                if DMA_for_PS_lowC(i,j)>= Pressure_selection(1,3)
                    DMA_for_PS_lowC(i,j)=0;
                end
            end
        end
        
        DMA_for_PS_lowC_cand = nonzeros(DMA_for_PS_lowC);
        SMA_for_PS_lowC_cand = SMA_for_PS_lowC(SMA_for_PS_lowC < Pressure_selection(1,1));
        
        PS_central_low = []; %initializing for reruns
        PS_central_low = Pressure_selection(1,:);
        PS_central_low(2,[1,2,4])= PS_central_low(1,[1,2,4]);
        if ~isempty(DMA_for_PS_lowC_cand)
            PS_central_low(2,3)= max(DMA_for_PS_lowC_cand); %changing low dia alone to max of DMAlowC
        end
        PS_central_low(3,[1,2,4])= PS_central_low(1,[1,2,4]);
        if ~isempty(DMA_for_PS_lowC_cand)
            PS_central_low(3,3)= round(mean(DMA_for_PS_lowC_cand)); %changing low dia alone to mean of DMA lowC
        end
        PS_central_low(4,2:4)= PS_central_low(1,2:4);
        if ~isempty(SMA_for_PS_lowC_cand)
            PS_central_low(4,1)= max(SMA_for_PS_lowC_cand); % changing low sys alone to min of SMA
        end
        PS_central_low(5,[1,2,4])= PS_central_low(4,[1,2,4]);
        PS_central_low(5,3)= PS_central_low(2,3); % changing low sys and low dia
        PS_central_low(6,[1,2,4])= PS_central_low(5,[1,2,4]);
        PS_central_low(6,3)= PS_central_low(3,3); % changing low sys and low dia
        
    elseif all(MAPdifferenceTable(1,1:3)<-3) % The identified MAP is higher. Try to increase Clowdia
        DMA_for_PS_lowC = DiaMatureArray_late(:, (size(DiaMatureArray_late,2)-1):size(DiaMatureArray_late,2)); % columns 1 and 2 are for Pdia and 3 and 4 are for Cdia
        SMA_for_PS_lowC = SysMatureArray(4:8, 1);
        
        for i = 1:size(DMA_for_PS_lowC,1)
            for j = 1:2
                if DMA_for_PS_lowC(i,j)<= Pressure_selection(1,3)
                    DMA_for_PS_lowC(i,j)=0;
                end
            end
        end
        DMA_for_PS_lowC_cand = nonzeros(DMA_for_PS_lowC);
        SMA_for_PS_lowC_cand = SMA_for_PS_lowC(SMA_for_PS_lowC > Pressure_selection(1,1));
        
        PS_central_low = Pressure_selection(1,:);
        PS_central_low(2,[1,2,4])= PS_central_low(1,[1,2,4]);
        if ~isempty(DMA_for_PS_lowC_cand)
            PS_central_low(2,3)= min(DMA_for_PS_lowC_cand); %changing low dia alone to min of DMAlowC
        end
        PS_central_low(3,[1,2,4])= PS_central_low(1,[1,2,4]);
        if ~isempty(DMA_for_PS_lowC_cand)
            PS_central_low(3,3)= mean(DMA_for_PS_lowC_cand); %changing low dia alone to mean of DMA lowC
        end
        PS_central_low(4,2:4)= PS_central_low(1,2:4);
        if ~isempty(SMA_for_PS_lowC_cand)
            PS_central_low(4,1)= min(nonzeros(SMA_for_PS_lowC_cand)); % changing low sys alone to min of SMA
        end
        PS_central_low(5,[1,2,4])= PS_central_low(4,[1,2,4]);
        PS_central_low(5,3)= PS_central_low(2,3); % changing low sys and low dia
        PS_central_low(6,[1,2,4])= PS_central_low(5,[1,2,4]);
        PS_central_low(6,3)= PS_central_low(3,3); % changing low sys and low dia
    end
end

if exist('PS_central','var')
    for i = 1:size(PS_central_low,1)
        PS_central_low(i, 5) = round(PS_central_low(i,3)+ 0.4*(PS_central_low(i,1) - PS_central_low(i,3)));
        PS_central_low(i, 6) = round(PS_central_low(i,4)+ 0.33*(PS_central_low(i,2) - PS_central_low(i,4)));
        
        PS_central_low(i, 7) = PS_central_low(i,2)- PS_central_low(i,1);
        PS_central_low(i, 8) = PS_central_low(i,4)- PS_central_low(i,3);
        PS_central_low(i, 9) = PS_central_low(i,6)- PS_central_low(i,5);
        
        PS_central_low(i, 10) = round(PS_central_low(i,3)+ 0.36*(PS_central_low(i,1) - PS_central_low(i,3)));
        PS_central_low(i, 11) = round(PS_central_low(i,4)+ 0.27*(PS_central_low(i,2) - PS_central_low(i,4)));
        PS_central_low(i, 12) = PS_central_low (i,11)- PS_central_low (i,10);
        
        PS_central_low(i, 13) = round(PS_central_low(i,3)+ 0.45*(PS_central_low(i,1) - PS_central_low(i,3)));
        PS_central_low(i, 14) = round(PS_central_low(i,4)+ 0.36*(PS_central_low(i,2) - PS_central_low(i,4)));
        PS_central_low(i, 15) = PS_central_low (i,14)- PS_central_low (i,13);
    end
    
    MAPdifferenceTable_PS_central_low(:,1:3) = PS_central_low(:,[5,10,13])- MAPselect_lowP;
    MAPdifferenceTable_PS_central_low(:,4:6) = PS_central_low(:,[6,11,14])- MAPselect_highP;
end

if exist('MAPdifferenceTable_PS_central_low', 'var')
    for i = 1:size(MAPdifferenceTable_PS_central_low,1)
        for j = 1: size(MAPdifferenceTable_PS_central_low,2)
            MAPdifferenceTable_PS_central_low_logical(i,j) = MAPdifferenceTable_PS_central_low(i,j)==min(abs(MAPdifferenceTable_PS_central_low(:,j)));
        end
    end
    
    for i = 1:size(MAPdifferenceTable_PS_central_low,1)
        for j= 1:3
            MAPdifferenceTable_PS_central_low_logical2(i,j) = MAPdifferenceTable_PS_central_low_logical(i,j)==1 && MAPdifferenceTable_PS_central_low_logical(i,j+3)==1;
        end
    end
    
    for i = 1:size(MAPdifferenceTable_PS_central_low_logical2,1)
        MAPdifferenceTable_PS_central_low_logical2(i,4)= sum(MAPdifferenceTable_PS_central_low_logical2(i,1:3));
    end
    
    for i = 1:size(MAPdifferenceTable_PS_central_low,1)
        for j = [1,3]
            PS_central_lowselected(i,j) = PS_central_low(i,j).* MAPdifferenceTable_PS_central_low_logical2(i,4);
        end
    end
    
    if any(MAPdifferenceTable_PS_central_low_logical2(:,4)>0)
        for j = [1,3]
            Pressure_selection(1,j)= round(mean(nonzeros(PS_central_lowselected(:,j))));
        end
    end
end
%%
if abs(mindiffMAPdt_highC)>3 % Must reconsider pressure selection
    %Pressure_selection_highdia_hold = Pressure_selection(1,4);
    
    if all(MAPdifferenceTable(1,4:6)>3) %(the else condition already says that these values are more than 3 or less than -3)
        %reduce Chighdia using Lpoints and Hpoints less than the current value
        
        DMA_for_PS_highC = DiaMatureArray_late(:, (size(DiaMatureArray_late,2)-1):size(DiaMatureArray_late,2));
        SMA_for_PS_highC = SysMatureArray(4:8, 2);
        
        for i = 1:size(DMA_for_PS_highC,1)
            for j = 1:2
                if DMA_for_PS_highC(i,j)>= Pressure_selection(1,4)
                    DMA_for_PS_highC(i,j)=0;
                end
            end
        end
        
        DMA_for_PS_highC_cand = nonzeros(DMA_for_PS_highC);
        SMA_for_PS_highC_cand = SMA_for_PS_highC(SMA_for_PS_highC < Pressure_selection(1,2));
        
        PS_central_high = Pressure_selection(1,:);
        PS_central_high(2,[1,2,3])= PS_central_high(1,[1,2,3]);
        if ~isempty(DMA_for_PS_highC_cand)
            PS_central_high(2,4)= max(DMA_for_PS_highC_cand); %changing high dia alone to max of DMAhighC
        end
        PS_central_high(3,[1,2,3])= PS_central_high(1,[1,2,3]);
        if ~isempty(DMA_for_PS_highC_cand)
            PS_central_high(3,4)= mean(DMA_for_PS_highC_cand); %changing high dia alone to mean of DMA highC
        end
        PS_central_high(4,[1,3,4])= PS_central_high(1,[1,3,4]);
        if ~isempty(SMA_for_PS_highC_cand)
            PS_central_high(4,2)= max(SMA_for_PS_highC_cand); % changing high sys alone
        end
        PS_central_high(5,[1,2,3])= PS_central_high(4,[1,2,3]);
        PS_central_high(5,4)= PS_central_high(2,4); % changing high sys and high dia
        PS_central_high(6,[1,2,3])= PS_central_high(5,[1,2,3]);
        PS_central_high(6,4)= PS_central_high(3,4); % changing low sys and low dia
        
    elseif all(MAPdifferenceTable(1,1:3)<-3) % The identified MAP is higher. Try to increase Chighdia
        DMA_for_PS_highC = DiaMatureArray_late(:, (size(DiaMatureArray_late,2)-1):size(DiaMatureArray_late,2)); % columns 1 and 2 are for Pdia and 3 and 4 are for Cdia
        SMA_for_PS_highC = SysMatureArray(4:8, 2);
        
        for i = 1:size(DMA_for_PS_highC,1)
            for j = 1:2
                if DMA_for_PS_highC(i,j)<= Pressure_selection(1,4)
                    DMA_for_PS_highC(i,j)=0;
                end
            end
        end
        DMA_for_PS_highC_cand = nonzeros(DMA_for_PS_highC);
        SMA_for_PS_highC_cand = SMA_for_PS_highC(SMA_for_PS_highC > Pressure_selection(1,2));
        
        PS_central_high = Pressure_selection(1,:);
        PS_central_high(2,[1,2,3])= PS_central_high(1,[1,2,3]);
        if ~isempty(DMA_for_PS_highC_cand)
            PS_central_high(2,4)= min(DMA_for_PS_highC_cand); %changing high dia alone to min of DMAhighC
        end
        PS_central_high(3,[1,2,3])= PS_central_high(1,[1,2,3]);
        if ~isempty(DMA_for_PS_highC_cand)
            PS_central_high(3,4)= round(mean(DMA_for_PS_highC_cand)); %changing high dia alone to mean of DMA highC
        end
        PS_central_high(4,[1,3,4])= PS_central_high(1,[1,3,4]);
        if ~isempty(SMA_for_PS_highC_cand)
            PS_central_high(4,2)= min(nonzeros(SMA_for_PS_highC_cand)); % changing high sys alone
        end
        PS_central_high(5,1:3)= PS_central_high(4,1:3);
        PS_central_high(5,4)= PS_central_high(2,4); % changing high sys and high dia
        PS_central_high(6,1:3)= PS_central_high(5,1:3);
        PS_central_high(6,4)= PS_central_high(3,4); % changing high sys and high dia
    end
end

if exist('PS_central_high','var')
    for i = 1:size(PS_central_high,1)
        PS_central_high(i, 5) = round(PS_central_high(i,3)+ 0.4*(PS_central_high(i,1) - PS_central_high(i,3)));
        PS_central_high(i, 6) = round(PS_central_high(i,4)+ 0.33*(PS_central_high(i,2) - PS_central_high(i,4)));
        
        PS_central_high(i, 7) = PS_central_high(i,2)- PS_central_high(i,1);
        PS_central_high(i, 8) = PS_central_high(i,4)- PS_central_high(i,3);
        PS_central_high(i, 9) = PS_central_high(i,6)- PS_central_high(i,5);
        
        PS_central_high(i, 10) = round(PS_central_high(i,3)+ 0.36*(PS_central_high(i,1) - PS_central_high(i,3)));
        PS_central_high(i, 11) = round(PS_central_high(i,4)+ 0.27*(PS_central_high(i,2) - PS_central_high(i,4)));
        PS_central_high(i, 12) = PS_central_high (i,11)- PS_central_high (i,10);
        
        PS_central_high(i, 13) = round(PS_central_high(i,3)+ 0.45*(PS_central_high(i,1) - PS_central_high(i,3)));
        PS_central_high(i, 14) = round(PS_central_high(i,4)+ 0.36*(PS_central_high(i,2) - PS_central_high(i,4)));
        PS_central_high(i, 15) = PS_central_high (i,14)- PS_central_high (i,13);
    end
    
    MAPdifferenceTable_PS_central_high(:,1:3) = PS_central_high(:,[5,10,13])- MAPselect_lowP;
    MAPdifferenceTable_PS_central_high(:,4:6) = PS_central_high(:,[6,11,14])- MAPselect_highP;
end

if exist('MAPdifferenceTable_PS_central_high', 'var')
    for i = 1:size(MAPdifferenceTable_PS_central_high,1)
        for j = 1: size(MAPdifferenceTable_PS_central_high,2)
            MAPdifferenceTable_PS_central_high_logical(i,j) = MAPdifferenceTable_PS_central_high(i,j)==min(abs(MAPdifferenceTable_PS_central_high(:,j)));
        end
    end
    
    for i = 1:size(MAPdifferenceTable_PS_central_high,1)
        for j= 1:3
            MAPdifferenceTable_PS_central_high_logical2(i,j) = MAPdifferenceTable_PS_central_high_logical(i,j)==1 && MAPdifferenceTable_PS_central_high_logical(i,j+3)==1;
        end
    end
    
    for i = 1:size(MAPdifferenceTable_PS_central_high_logical2,1)
        MAPdifferenceTable_PS_central_high_logical2(i,4)= sum(MAPdifferenceTable_PS_central_high_logical2(i,1:3));
    end
    
    for i = 1:size(MAPdifferenceTable_PS_central_high,1)
        for j = [2,4]
            PS_central_highselected(i,j) = PS_central_high(i,j).* MAPdifferenceTable_PS_central_high_logical2(i,4);
        end
    end
    
    if any(MAPdifferenceTable_PS_central_high_logical2(:,4)>0)
        for j = [2,4]
            Pressure_selection(1,j)= round(mean(nonzeros(PS_central_highselected(:,j))));
        end
    end
end
%%
[mindiffMAPdt_lowP, col_index_MAPdT_lowP] = min(MAPdifferenceTable(2,1:3));
[mindiffMAPdt_highP, col_index_MAPdT_highP] = min(MAPdifferenceTable(2,4:6));

if abs(mindiffMAPdt_lowP)>3 % Must reconsider pressure selection
    
    if all(MAPdifferenceTable(2,1:3)>3) %(the else condition already says that these values are more than 3 or less than -3)
        %reduce Plowdia using Lpoints and Hpoints less than the current value
        
        DMA_for_PS_lowP = DiaMatureArray_late(:, (size(DiaMatureArray_late,2)-3):size(DiaMatureArray_late,2)-2);
        SMA_for_PS_lowP = SysMatureArray(1:3, 1);
        
        for i = 1:size(DMA_for_PS_lowP,1)
            for j = 1:2
                if DMA_for_PS_lowP(i,j)>= Pressure_selection(2,3)
                   DMA_for_PS_lowP(i,j)=0;
                end
            end
        end
        
        DMA_for_PS_lowP_cand = nonzeros(DMA_for_PS_lowP);
        SMA_for_PS_lowP_cand = SMA_for_PS_lowP(SMA_for_PS_lowP < Pressure_selection(2,1) & SMA_for_PS_lowP >= Pressure_selection(1,1));
        %sometimes very low values get selected. eg. IBP 18092102.
                
        PS_peripheral_low = []; %initializing for reruns
        PS_peripheral_low = Pressure_selection(2,:);
        PS_peripheral_low(2,[1,2,4])= PS_peripheral_low(1,[1,2,4]);
        if ~isempty(DMA_for_PS_lowP_cand)
            PS_peripheral_low(2,3)= max(DMA_for_PS_lowP_cand); %changing low dia alone to max of DMAlowP
        end
        PS_peripheral_low(3,[1,2,4])= PS_peripheral_low(1,[1,2,4]);
        if ~isempty(DMA_for_PS_lowP_cand)
            PS_peripheral_low(3,3)= round(mean(DMA_for_PS_lowP_cand)); %changing low dia alone to mean of DMA lowP
        end
        PS_peripheral_low(4,2:4)= PS_peripheral_low(1,2:4);
        if ~isempty(SMA_for_PS_lowP_cand)
            PS_peripheral_low(4,1)= max(SMA_for_PS_lowP_cand); % changing low sys alone to min of SMA
        end
        PS_peripheral_low(5,[1,2,4])= PS_peripheral_low(4,[1,2,4]);
        PS_peripheral_low(5,3)= PS_peripheral_low(2,3); % changing low sys and low dia
        PS_peripheral_low(6,[1,2,4])= PS_peripheral_low(5,[1,2,4]);
        PS_peripheral_low(6,3)= PS_peripheral_low(3,3); % changing low sys and low dia
        
    elseif all(MAPdifferenceTable(1,1:3)<-3) % The identified MAP is higher. Try to increase Plowdia
        DMA_for_PS_lowP = DiaMatureArray_late(:, (size(DiaMatureArray_late,2)-3):size(DiaMatureArray_late,2)-2); % columns 1 and 2 are for Pdia and 3 and 4 are for Pdia
        SMA_for_PS_lowP = SysMatureArray(1:3, 1);
        
        for i = 1:size(DMA_for_PS_lowP,1)
            for j = 1:2
                if DMA_for_PS_lowP(i,j)<= Pressure_selection(2,3)
                    DMA_for_PS_lowP(i,j)=0;
                end
            end
        end
        DMA_for_PS_lowP_cand = nonzeros(DMA_for_PS_lowP);
        SMA_for_PS_lowP_cand = SMA_for_PS_lowP(SMA_for_PS_lowP > Pressure_selection(2,1));
        
        PS_peripheral_low = Pressure_selection(2,:);
        PS_peripheral_low(2,[1,2,4])= PS_peripheral_low(1,[1,2,4]);
        if ~isempty(DMA_for_PS_lowP_cand)
            PS_peripheral_low(2,3)= min(DMA_for_PS_lowP_cand); %changing low dia alone to min of DMAlowP
        end
        PS_peripheral_low(3,[1,2,4])= PS_peripheral_low(1,[1,2,4]);
        if ~isempty(DMA_for_PS_lowP_cand)
            PS_peripheral_low(3,3)= mean(DMA_for_PS_lowP_cand); %changing low dia alone to mean of DMA lowP
        end
        PS_peripheral_low(4,2:4)= PS_peripheral_low(1,2:4);
        if ~isempty(SMA_for_PS_lowP_cand)
            PS_peripheral_low(4,1)= min(nonzeros(SMA_for_PS_lowP_cand)); % changing low sys alone to min of SMA
        end
        PS_peripheral_low(5,[1,2,4])= PS_peripheral_low(4,[1,2,4]);
        PS_peripheral_low(5,3)= PS_peripheral_low(2,3); % changing low sys and low dia
        PS_peripheral_low(6,[1,2,4])= PS_peripheral_low(5,[1,2,4]);
        PS_peripheral_low(6,3)= PS_peripheral_low(3,3); % changing low sys and low dia
    end
end

if exist('PS_peripheral_low','var')
    for i = 1:size(PS_peripheral_low,1)
        PS_peripheral_low(i, 5) = round(PS_peripheral_low(i,3)+ 0.4*(PS_peripheral_low(i,1) - PS_peripheral_low(i,3)));
        PS_peripheral_low(i, 6) = round(PS_peripheral_low(i,4)+ 0.33*(PS_peripheral_low(i,2) - PS_peripheral_low(i,4)));
        
        PS_peripheral_low(i, 7) = PS_peripheral_low(i,2)- PS_peripheral_low(i,1);
        PS_peripheral_low(i, 8) = PS_peripheral_low(i,4)- PS_peripheral_low(i,3);
        PS_peripheral_low(i, 9) = PS_peripheral_low(i,6)- PS_peripheral_low(i,5);
        
        PS_peripheral_low(i, 10) = round(PS_peripheral_low(i,3)+ 0.36*(PS_peripheral_low(i,1) - PS_peripheral_low(i,3)));
        PS_peripheral_low(i, 11) = round(PS_peripheral_low(i,4)+ 0.27*(PS_peripheral_low(i,2) - PS_peripheral_low(i,4)));
        PS_peripheral_low(i, 12) = PS_peripheral_low (i,11)- PS_peripheral_low (i,10);
        
        PS_peripheral_low(i, 13) = round(PS_peripheral_low(i,3)+ 0.45*(PS_peripheral_low(i,1) - PS_peripheral_low(i,3)));
        PS_peripheral_low(i, 14) = round(PS_peripheral_low(i,4)+ 0.36*(PS_peripheral_low(i,2) - PS_peripheral_low(i,4)));
        PS_peripheral_low(i, 15) = PS_peripheral_low (i,14)- PS_peripheral_low (i,13);
    end
    
    MAPdifferenceTable_PS_peripheral_low(:,1:3) = PS_peripheral_low(:,[5,10,13])- MAPselect_lowP;
    MAPdifferenceTable_PS_peripheral_low(:,4:6) = PS_peripheral_low(:,[6,11,14])- MAPselect_highP;
end

if exist('MAPdifferenceTable_PS_peripheral_low', 'var')
    for i = 1:size(MAPdifferenceTable_PS_peripheral_low,1)
        for j = 1: size(MAPdifferenceTable_PS_peripheral_low,2)
            MAPdifferenceTable_PS_peripheral_low_logical(i,j) = MAPdifferenceTable_PS_peripheral_low(i,j)==min(abs(MAPdifferenceTable_PS_peripheral_low(:,j)));
        end
    end
    
    for i = 1:size(MAPdifferenceTable_PS_peripheral_low,1)
        for j= 1:3
            MAPdifferenceTable_PS_peripheral_low_logical2(i,j) = MAPdifferenceTable_PS_peripheral_low_logical(i,j)==1 && MAPdifferenceTable_PS_peripheral_low_logical(i,j+3)==1;
        end
    end
    
    for i = 1:size(MAPdifferenceTable_PS_peripheral_low_logical2,1)
        MAPdifferenceTable_PS_peripheral_low_logical2(i,4)= sum(MAPdifferenceTable_PS_peripheral_low_logical2(i,1:3));
    end
    
    for i = 1:size(MAPdifferenceTable_PS_peripheral_low,1)
        for j = [1,3]
            PS_peripheral_lowselected(i,j) = PS_peripheral_low(i,j).* MAPdifferenceTable_PS_peripheral_low_logical2(i,4);
        end
    end
    
    if any(MAPdifferenceTable_PS_peripheral_low_logical2(:,4)>0)
        for j = [1,3]
            Pressure_selection(2,j)= round(mean(nonzeros(PS_peripheral_lowselected(:,j))));
        end
    end
end
%%
if abs(mindiffMAPdt_highP)>3 % Must reconsider pressure selection
    %Pressure_selection_highdia_hold = Pressure_selection(1,4);
    
    if all(MAPdifferenceTable(2,4:6)>3) %(the else condition already says that these values are more than 3 or less than -3)
        %reduce Phighdia using Lpoints and Hpoints less than the current value
        
        DMA_for_PS_highP = DiaMatureArray_late(:, (size(DiaMatureArray_late,2)-3):size(DiaMatureArray_late,2)-2);
        SMA_for_PS_highP = SysMatureArray(1:3, 2);
        
        for i = 1:size(DMA_for_PS_highP,1)
            for j = 1:2
                if DMA_for_PS_highP(i,j)>= Pressure_selection(2,4)
                    DMA_for_PS_highP(i,j)=0;
                end
            end
        end
        
        DMA_for_PS_highP_cand = nonzeros(DMA_for_PS_highP);
        SMA_for_PS_highP_cand = SMA_for_PS_highP(SMA_for_PS_highP < Pressure_selection(2,2));
        
            PS_peripheral_high = Pressure_selection(2,:);
            PS_peripheral_high(2,[1,2,3])= PS_peripheral_high(1,[1,2,3]);
            if ~isempty(DMA_for_PS_highP_cand)
                PS_peripheral_high(2,4)= max(DMA_for_PS_highP_cand); %changing high dia alone to max of DMAhighP
            end
            PS_peripheral_high(3,[1,2,3])= PS_peripheral_high(1,[1,2,3]);
            if ~isempty(DMA_for_PS_highP_cand)
                PS_peripheral_high(3,4)= mean(DMA_for_PS_highP_cand); %changing high dia alone to mean of DMA highP
            end
            PS_peripheral_high(4,[1,3,4])= PS_peripheral_high(1,[1,3,4]);
            if ~isempty(SMA_for_PS_highP_cand)
                PS_peripheral_high(4,2)= max(SMA_for_PS_highP_cand); % changing high sys alone
            end
            PS_peripheral_high(5,[1,2,3])= PS_peripheral_high(4,[1,2,3]);
            PS_peripheral_high(5,4)= PS_peripheral_high(2,4); % changing high sys and high dia
            PS_peripheral_high(6,[1,2,3])= PS_peripheral_high(5,[1,2,3]);
            PS_peripheral_high(6,4)= PS_peripheral_high(3,4); % changing low sys and low dia       
        
    elseif all(MAPdifferenceTable(1,1:3)<-3) % The identified MAP is higher. Try to increase Phighdia
        DMA_for_PS_highP = DiaMatureArray_late(:, (size(DiaMatureArray_late,2)-3):size(DiaMatureArray_late,2)-2); % columns 1 and 2 are for Pdia and 3 and 4 are for Pdia
        SMA_for_PS_highP = SysMatureArray(1:3, 2);
        
        for i = 1:size(DMA_for_PS_highP,1)
            for j = 1:2
                if DMA_for_PS_highP(i,j)<= Pressure_selection(2,4)
                    DMA_for_PS_highP(i,j)=0;
                end
            end
        end
        DMA_for_PS_highP_cand = nonzeros(DMA_for_PS_highP);
        SMA_for_PS_highP_cand = SMA_for_PS_highP(SMA_for_PS_highP > Pressure_selection(2,2));
        
        PS_peripheral_high = Pressure_selection(2,:);
        PS_peripheral_high(2,[1,2,3])= PS_peripheral_high(1,[1,2,3]);
        if ~isempty(DMA_for_PS_highP_cand)
            PS_peripheral_high(2,4)= min(DMA_for_PS_highP_cand); %changing high dia alone to min of DMAhighP
        end
        PS_peripheral_high(3,[1,2,3])= PS_peripheral_high(1,[1,2,3]);
        if ~isempty(DMA_for_PS_highP_cand)
            PS_peripheral_high(3,4)= round(mean(DMA_for_PS_highP_cand)); %changing high dia alone to mean of DMA highP
        end
        PS_peripheral_high(4,[1,3,4])= PS_peripheral_high(1,[1,3,4]);
        if ~isempty(SMA_for_PS_highP_cand)
            PS_peripheral_high(4,2)= min(nonzeros(SMA_for_PS_highP_cand)); % changing high sys alone
        end
        PS_peripheral_high(5,1:3)= PS_peripheral_high(4,1:3);
        PS_peripheral_high(5,4)= PS_peripheral_high(2,4); % changing high sys and high dia
        PS_peripheral_high(6,1:3)= PS_peripheral_high(5,1:3);
        PS_peripheral_high(6,4)= PS_peripheral_high(3,4); % changing high sys and high dia
    end
end

if exist('PS_peripheral','var')
    for i = 1:size(PS_peripheral_high,1)
        PS_peripheral_high(i, 5) = round(PS_peripheral_high(i,3)+ 0.4*(PS_peripheral_high(i,1) - PS_peripheral_high(i,3)));
        PS_peripheral_high(i, 6) = round(PS_peripheral_high(i,4)+ 0.33*(PS_peripheral_high(i,2) - PS_peripheral_high(i,4)));
        
        PS_peripheral_high(i, 7) = PS_peripheral_high(i,2)- PS_peripheral_high(i,1);
        PS_peripheral_high(i, 8) = PS_peripheral_high(i,4)- PS_peripheral_high(i,3);
        PS_peripheral_high(i, 9) = PS_peripheral_high(i,6)- PS_peripheral_high(i,5);
        
        PS_peripheral_high(i, 10) = round(PS_peripheral_high(i,3)+ 0.36*(PS_peripheral_high(i,1) - PS_peripheral_high(i,3)));
        PS_peripheral_high(i, 11) = round(PS_peripheral_high(i,4)+ 0.27*(PS_peripheral_high(i,2) - PS_peripheral_high(i,4)));
        PS_peripheral_high(i, 12) = PS_peripheral_high (i,11)- PS_peripheral_high (i,10);
        
        PS_peripheral_high(i, 13) = round(PS_peripheral_high(i,3)+ 0.45*(PS_peripheral_high(i,1) - PS_peripheral_high(i,3)));
        PS_peripheral_high(i, 14) = round(PS_peripheral_high(i,4)+ 0.36*(PS_peripheral_high(i,2) - PS_peripheral_high(i,4)));
        PS_peripheral_high(i, 15) = PS_peripheral_high (i,14)- PS_peripheral_high (i,13);
    end
    
    MAPdifferenceTable_PS_peripheral(:,1:3) = PS_peripheral_high(:,[5,10,13])- MAPselect_lowP;
    MAPdifferenceTable_PS_peripheral(:,4:6) = PS_peripheral_high(:,[6,11,14])- MAPselect_highP;
end

if exist('MAPdifferenceTable_PS_peripheral_high', 'var')
    for i = 1:size(MAPdifferenceTable_PS_peripheral_high,1)
        for j = 1: size(MAPdifferenceTable_PS_peripheral_high,2)
            MAPdifferenceTable_PS_peripheral_high_logical(i,j) = MAPdifferenceTable_PS_peripheral_high(i,j)==min(abs(MAPdifferenceTable_PS_peripheral_high(:,j)));
        end
    end
    
    for i = 1:size(MAPdifferenceTable_PS_peripheral_high,1)
        for j= 1:3
            MAPdifferenceTable_PS_peripheral_high_logical2(i,j) = MAPdifferenceTable_PS_peripheral_high_logical(i,j)==1 && MAPdifferenceTable_PS_peripheral_high_logical(i,j+3)==1;
        end
    end
    
    for i = 1:size(MAPdifferenceTable_PS_peripheral_high_logical2,1)
        MAPdifferenceTable_PS_peripheral_high_logical2(i,4)= sum(MAPdifferenceTable_PS_peripheral_high_logical2(i,1:3));
    end
    
    for i = 1:size(MAPdifferenceTable_PS_peripheral_high,1)
        for j = [2,4]
            PS_peripheral_highselected(i,j) = PS_peripheral_high(i,j).* MAPdifferenceTable_PS_peripheral_high_logical2(i,4);
        end
    end
    
    if any(MAPdifferenceTable_PS_peripheral_high_logical2(:,4)>0)
        for j = [2,4]
            Pressure_selection(2,j)= round(mean(nonzeros(PS_peripheral_highselected(:,j))));
        end
    end
end
%%
if Pressure_selection(1,3)> Pressure_selection(1,4)
    PS1_hold = Pressure_selection(1,3);
    Pressure_selection(1,3)= Pressure_selection(1,4);
    Pressure_selection(1,4)= PS1_hold;
end

if Pressure_selection(2,3)> Pressure_selection(2,4)
    PS2_hold = Pressure_selection(2,3);
    Pressure_selection(2,3)= Pressure_selection(2,4);
    Pressure_selection(2,4)= PS2_hold;
end

for i = 1:2
    for j = 1:4
        PrSel_logicTable (i,j) = Pressure_selection (i,j)~= PressureGuesses(i,j);
    end
end

if any(any(PrSel_logicTable(:,:)==1))
    for i = 1:2
        Pressure_selection(i, 5) = round(Pressure_selection(i,3)+ 0.4*(Pressure_selection(i,1) - Pressure_selection(i,3)));
        Pressure_selection(i, 6) = round(Pressure_selection(i,4)+ 0.33*(Pressure_selection(i,2) - Pressure_selection(i,4)));
        
        Pressure_selection(i, 7) = Pressure_selection(i,2)- Pressure_selection(i,1);
        Pressure_selection(i, 8) = Pressure_selection(i,4)- Pressure_selection(i,3);
        Pressure_selection(i, 9) = Pressure_selection(i,6)- Pressure_selection(i,5);
        
        Pressure_selection(i, 10) = round(Pressure_selection(i,3)+ 0.36*(Pressure_selection(i,1) - Pressure_selection(i,3)));
        Pressure_selection(i, 11) = round(Pressure_selection(i,4)+ 0.27*(Pressure_selection(i,2) - Pressure_selection(i,4)));
        Pressure_selection(i, 12) = Pressure_selection (i,11)- Pressure_selection (i,10);
        
        Pressure_selection(i, 13) = round(Pressure_selection(i,3)+ 0.45*(Pressure_selection(i,1) - Pressure_selection(i,3)));
        Pressure_selection(i, 14) = round(Pressure_selection(i,4)+ 0.36*(Pressure_selection(i,2) - Pressure_selection(i,4)));
        Pressure_selection(i, 15) = Pressure_selection (i,14)- Pressure_selection (i,13);
    end
end

disp ('PressureGuesses');
disp(PressureGuesses);
disp ('Pressure_selection');
disp(Pressure_selection);
%%
rowHeadings = {'Central Pressure guesses', 'Peripheral Pressure guesses', 'sigmoidnew', 'sigmoidDown','sigmoidMean_new_Down','Poly_Oscmeans'};
colHeadings = {'LowSystolic', 'HighSystolic', 'LowDiastolic', 'HighDiastolic', 'LowMAP', 'HighMAP', 'sysvar', 'diavar', 'MAPvar'};

rowHeadingsS = {'Central Pressure selection', 'Peripheral Pressure selection', 'sigmoidnew', 'sigmoidDown','sigmoidMean_new_Down','Poly_Oscmeans'};
Table_selection = array2table(Pressure_selection (:,1:9), 'VariableNames', colHeadings, 'RowNames', rowHeadingsS);
disp(Table_selection);

%%
CrossCheckSelection (1,1)= Pressure_selection (1,1) <= Pressure_selection (2,1);
CrossCheckSelection (1,2)= Pressure_selection (1,2) <= Pressure_selection (2,2);

CrossCheckSelection (1,3)= Pressure_selection (1,3)>= Pressure_selection (2,3);
CrossCheckSelection (1,4)= Pressure_selection (1,4)>= Pressure_selection (2,4);

disp (CrossCheckSelection);
%%
Multiplier_1PC = 0.4;%For MAP calculation
Multiplier_2PC = 0.33;
Multiplier_3PC = 0.3;

%%
Syslowcandidates = [Pressure_selection(1:end, 1)];
Syshighcandidates = [Pressure_selection(1:end, 2)];

Dialowcandidates = [Pressure_selection(1:end, 3)];
Diahighcandidates = [Pressure_selection(1:end, 4)];

PressureCandidates = Pressure_selection(:, 1:4);
PressureCandidates (7, 1:4) = [(min(PressureCandidates(:,1))-3), (max(PressureCandidates(:,2))+ 3), (min(PressureCandidates(:,3))-2),  (max(PressureCandidates(:,4))+2)];

PressCand = PressureCandidates;
for i = 1: size(PressCand,1)
    PressCand (i,5) = PressCand(i,1)> min(PressCand(:,2));
    PressCand (i,6) = PressCand(i,2)< max(PressCand(:,1));
    PressCand (i,7) = PressCand(i,3)> min(PressCand(:,4));
    PressCand (i,8) = PressCand(i,4)< max(PressCand(:,3));
end

%%
% maximum rows o be added
max_rows_to_add = size(PressCand, 1);

% matrix with zeros
zeros_to_add = zeros(max_rows_to_add, size(PressCand, 2));

% Concatenate both matrix
PressCand = [PressCand; zeros_to_add];
max_num_rows = size(PressCand,1)/2; %since we are adding extra rows below

for i = 1: (max_num_rows)
    if(PressCand(i,1)> min(PressCand(1:max_num_rows,2)))
        PressCand (i+max_num_rows,2) = PressCand(i,1);
    end
    if(PressCand(i,2)< max(PressCand(1:(size(PressCand,1)/2),1)))
        PressCand (i+max_num_rows,1)=PressCand(i,2);
    end
    if(PressCand(i,3)> min(PressCand(1:max_num_rows,4)))
        PressCand (i+max_num_rows,4) = PressCand(i,3);
    end
    if(PressCand(i,4)< max(PressCand(1:max_num_rows,3)))
        PressCand (i+max_num_rows,3)=PressCand(i,4);
    end
end

for col = 1:size(PressCand, 2)
    % To Filter out zeros from the column
    column_values = PressCand(:, col);
    non_zero_values = column_values(column_values ~= 0);
    
    % To remove duplicate
    unique_values = unique(non_zero_values);
    
    % Assign unique values back to the column
    PressCand(:, col) = zeros(size(PressCand, 1), 1);
    PressCand(1:length(unique_values), col) = unique_values;
end

% Find rows with any non-zero value in any of the columns
nonzero_rows = any(PressCand, 2); % matlab syntax. works well.

% update the matrix
PressCand0 = PressCand(nonzero_rows, 1:4);


%%
a0vec = PressCand0 (:,1);
b0vec = PressCand0 (:,2);
c0vec = PressCand0 (:,3);
d0vec = PressCand0 (:,4);

a1vec = a0vec;

for i = 1:size(a0vec,1)-1
    if a0vec (i+1)>0
        difference = a0vec(i+1,1) - a0vec(i,1);
        if difference >2
            num_values_needed = floor(difference/2);
            for_padding_value =[];
            for_padding_value = linspace (a0vec(i,1), a0vec (i+1,1), num_values_needed+2);
            for_padding_value = for_padding_value';
            addrow_avec = [];
            addrow_avec(:,1) = for_padding_value(2:end-1,1);
            a1vec(size(a1vec,1)+1:size(a1vec,1)+size(addrow_avec,1)) = addrow_avec(:,1);
        end
    end
end

b1vec = b0vec;

for i = 1:size(b0vec,1)-1
    if b0vec (i+1)>0
        difference = b0vec(i+1,1) - b0vec(i,1);
        if difference >2
            num_values_needed = floor(difference/2);
            for_padding_value =[];
            for_padding_value = linspace (b0vec(i,1), b0vec (i+1,1), num_values_needed+2);
            for_padding_value = for_padding_value';
            addrow_bvec = [];
            addrow_bvec(:,1) = for_padding_value(2:end-1,1);
            b1vec(size(b1vec,1)+1:size(b1vec,1)+size(addrow_bvec,1)) = addrow_bvec(:,1);
        end
    end
end

c1vec = c0vec;

for i = 1:size(c0vec,1)-1
    if c0vec (i+1)>0
        difference = c0vec(i+1,1) - c0vec(i,1);
        if difference >2
            num_values_needed = floor(difference/2);
            for_padding_value =[];
            for_padding_value = linspace (c0vec(i,1), c0vec (i+1,1), num_values_needed+2);
            for_padding_value = for_padding_value';
            addrow_cvec = [];
            addrow_cvec(:,1) = for_padding_value(2:end-1,1);
            c1vec(size(c1vec,1)+1:size(c1vec,1)+size(addrow_cvec,1)) = addrow_cvec(:,1);
        end
    end
end

d1vec = d0vec;

for i = 1:size(d0vec,1)-1
    if d0vec (i+1)>0
        difference = d0vec(i+1,1) - d0vec(i,1);
        if difference >2
            num_values_needed = floor(difference/2);
            for_padding_value =[];
            for_padding_value = linspace (d0vec(i,1), d0vec (i+1,1), num_values_needed+2);
            for_padding_value = for_padding_value';
            addrow_dvec = [];
            addrow_dvec(:,1) = for_padding_value(2:end-1,1);
            d1vec(size(d1vec,1)+1:size(d1vec,1)+size(addrow_dvec,1)) = addrow_dvec(:,1);
        end
    end
end

a2vec = round (nonzeros(a1vec));
a2vec = sortrows (a2vec);
size_a2vec = size(a2vec,1);

b2vec = round (nonzeros(b1vec));
b2vec = sortrows (b2vec);
size_b2vec = size(b2vec,1);

c2vec = round (nonzeros(c1vec));
c2vec = sortrows (c2vec);
size_c2vec = size(c2vec,1);

d2vec = round (nonzeros(d1vec));
d2vec = sortrows (d2vec);
size_d2vec = size(d2vec,1);

for_maxrows = [size_a2vec, size_b2vec, size_c2vec, size_d2vec];
maxrows = max(for_maxrows);

addrows_a2vec = []; % Setting these to zero to enable reruns
addrows_b2vec = [];
addrows_c2vec = [];
addrows_d2vec = [];

addrows_a2vec = zeros (maxrows - size_a2vec, 1);
a3vec = cat(1, a2vec, addrows_a2vec);

addrows_b2vec = zeros (maxrows - size_b2vec, 1);
b3vec = cat(1, b2vec, addrows_b2vec);

addrows_c2vec = zeros(maxrows - size_c2vec, 1);
c3vec = cat(1, c2vec, addrows_c2vec);

addrows_d2vec (:,1) = zeros (maxrows - size_d2vec, 1);
d3vec = cat(1, d2vec, addrows_d2vec);

PressCand1 = cat (2, a3vec, b3vec, c3vec, d3vec);

%%
a_vec = PressCand1(:,1);
b_vec = PressCand1(:,2);
c_vec = PressCand1(:,3);
d_vec = PressCand1(:,4);

%%

clearvars comb_matrix**; % This is to clear previous entries
clearvars short_**; % This is to clear previous entries when the program is rerun

comb_matrix0 = zeros(size(PressCand1,1)^size(PressCand1,2),4);
comb_vec = [0 0 0 0];
count = 1;
for i = 1:size(PressCand1,1)
    comb_vec(1) = a_vec(i);
    for j =1:size(PressCand1,1)
        comb_vec(2) = b_vec(j);
        for k = 1:size(PressCand1,1)
            comb_vec(3) = c_vec(k);
            for l =1:size(PressCand1,1)
                comb_vec(4) = d_vec(l);
                comb_matrix0(count,:) = comb_vec;
                count = count + 1;
            end
        end
    end
end

nonzero_rows_com_matrix = all(comb_matrix0(:, 1:4) ~= 0, 2);
comb_matrix = comb_matrix0(nonzero_rows_com_matrix, :);

%%
[uniqueRows, ~, ic] = unique(comb_matrix, 'rows', 'stable'); % To remove duplicate rows
comb_matrix = uniqueRows;

for i = 1: size(comb_matrix,1)
    comb_matrix_rToKeep(i,1) = comb_matrix(i,2)> comb_matrix(i,1) ; % Delete combinations where sys high is lower than syslow
end

comb_matrix1 = comb_matrix(comb_matrix_rToKeep, :);

for i = 1: size(comb_matrix1,1)
    comb_matrix_rToKeep1(i,1) = comb_matrix1(i,4)> comb_matrix1(i,3); % Delete combinations where dia high is lower than dialow
end

comb_matrix1 = comb_matrix1(comb_matrix_rToKeep1, :);

%%
pulsePressure_columns = [18, 19, 23, 24];

for i = 1:size(comb_matrix1,1)
    
    comb_matrix1 (i,5)= round (comb_matrix1(i,3) + 0.4*(comb_matrix1 (i,1)- comb_matrix1(i,3))); %calc MAP low
    comb_matrix1 (i,6)= round (comb_matrix1(i,4) + 0.33*(comb_matrix1 (i,2)- comb_matrix1(i,4))); %calc MAP high
    comb_matrix1 (i,7)= round ((comb_matrix1(i,5) + comb_matrix1 (i,6))/2); % mean calc MAP
    
    comb_matrix1 (i,8)= round(MAPselect_lowP); %  selected MAP low
    comb_matrix1 (i,9)= round(MAPselect_highP); %  selected MAP high
    
    comb_matrix1 (i,10)= (comb_matrix1(i,8) + comb_matrix1(i,9))/2; % mean of selected MAP high and low
    
    comb_matrix1 (i,11) = round(comb_matrix1 (i,5)- comb_matrix1 (i,8)); % diff between calculated mean MAP low and osc amp MAP low
    comb_matrix1 (i,12) =abs(comb_matrix1 (i,11)); % abs diff low MAP
    
    comb_matrix1 (i,13) = round(comb_matrix1 (i,6)- comb_matrix1 (i,9)); % diff between calculated mean MAP high and osc amp MAP high
    comb_matrix1 (i,14) =abs(comb_matrix1 (i,13)); % abs diff high MAP
    
    comb_matrix1 (i,15) = Multiplier_1PC;
    comb_matrix1 (i,16) = Multiplier_2PC;
    
    comb_matrix1(i,17)= comb_matrix1(i,12)+ comb_matrix1(i,14);
    
    comb_matrix1 (i,18)=  round (comb_matrix1 (i,1)- (comb_matrix1 (i,3)));%pulse pressure low
    comb_matrix1 (i,19)=  round (comb_matrix1 (i,2)- (comb_matrix1 (i,4)));%pulse pressure high
    comb_matrix1 (i,20)=  comb_matrix1 (i,19)- (comb_matrix1 (i,18));% difference in pulse pressure
    comb_matrix1 (i,21)= round((comb_matrix1 (i,20)*100)/comb_matrix1 (i,19));% diff as percent of pulse pressure high (was originally as perecent of PPlow)
    comb_matrix1 (i,22)= abs (comb_matrix1 (i,21));%absolute variability of pulse pressure as percentage
    
    comb_matrix1 (i,23)=  round (comb_matrix1 (i,2)- (comb_matrix1 (i,3)));%pulse pressure cross1
    comb_matrix1 (i,24)=  round (comb_matrix1 (i,1)- (comb_matrix1 (i,4)));%pulse pressure cross2
    comb_matrix1 (i,25)= max(comb_matrix1 (i,pulsePressure_columns))- min(comb_matrix1 (i,pulsePressure_columns));% difference in max and min of 4 pulse pressures
    comb_matrix1 (i,26)= round (comb_matrix1(i,25)*100 /max(comb_matrix1 (i,pulsePressure_columns)));% diff as percent of max pulse pressure in the 4 columns (was originally percent of min)
    
    comb_matrix1 (i,27)=  comb_matrix1(i,2)- comb_matrix1(i,1);
    comb_matrix1 (i,28) =  comb_matrix1(i,4)- comb_matrix1(i,3);
end

%%
comb_matrix1b = comb_matrix1;

%%
%Sort based on column 12

[~, comb_matrix1bSortedCol_12] = sort(comb_matrix1b(:,12));
comb_matrix1bSorted_12 = comb_matrix1b(comb_matrix1bSortedCol_12, :);

%Then sort with column 14
comb_matrix1bSorted_col_12_14 = comb_matrix1bSorted_12;
% Find the unique values in column 12
unique_col_12 = unique(comb_matrix1bSorted_col_12_14(:, 12));

% Initialize the sorted data
comb_matrix1bSorted_12_14 = [];

% Sort based on column 14 for each unique value in column 12
for i = 1:length(unique_col_12)
    idx_sort_12_14 = find(comb_matrix1bSorted_col_12_14(:, 12) == unique_col_12(i));
    comb_matrix1bSorted_12_14 = [comb_matrix1bSorted_12_14; sortrows(comb_matrix1bSorted_col_12_14(idx_sort_12_14, :), 14)];
end
%%
comb_matrix1bSorted_12_14_select = comb_matrix1bSorted_12_14(:,17)==comb_matrix1bSorted_12_14(1,17);% The idea here is to select rows where the total variation of calculated MAPs from selcted MAPs is low
short_comb_matrix1 = comb_matrix1bSorted_12_14(comb_matrix1bSorted_12_14_select,:)  ;

% if choices are few, then set the col 17 limit higher to get more choices

if size(short_comb_matrix1,1)<20
    comb_matrix1bSorted_12_14_select = comb_matrix1bSorted_12_14(:,17)<=comb_matrix1bSorted_12_14(1,17)+1;
end

short_comb_matrix1 = comb_matrix1bSorted_12_14(comb_matrix1bSorted_12_14_select,:);

%%
comb_matrix1_cross = zeros (size(comb_matrix1,1), 28);
comb_matrix1_cross (:,1:4)= comb_matrix1 (:,1:4);
%%

pulsePressure_columns = [18, 19, 23, 24];

for i = 1:size(comb_matrix1_cross,1)
    
    comb_matrix1_cross (i,5)= round (comb_matrix1_cross(i,3) + 0.33*(comb_matrix1_cross (i,2)- comb_matrix1_cross(i,3))); %calc MAP low
    comb_matrix1_cross (i,6)= round (comb_matrix1_cross(i,4) + 0.4*(comb_matrix1_cross (i,1)- comb_matrix1_cross(i,4))); %calc MAP high
    comb_matrix1_cross (i,7)= round ((comb_matrix1_cross(i,5) + comb_matrix1_cross (i,6))/2); % mean calc MAP
    
    comb_matrix1_cross (i,8)=  round(MAPselect_lowP); %MAP low
    comb_matrix1_cross (i,9)=  round(MAPselect_highP); %MAP high
    
    comb_matrix1_cross (i,10)= (comb_matrix1_cross(i,8) + comb_matrix1_cross(i,9))/2; % mean max oscill amp pressure
    
    comb_matrix1_cross (i,11) = round(comb_matrix1_cross (i,5)- comb_matrix1_cross (i,8)); % diff between calculated mean MAP low and osc amp MAP low
    comb_matrix1_cross (i,12) =abs(comb_matrix1_cross (i,11)); % abs diff low MAP
    
    comb_matrix1_cross (i,13) = round(comb_matrix1_cross (i,6)- comb_matrix1_cross (i,9)); % diff between calculated mean MAP high and osc amp MAP high
    comb_matrix1_cross (i,14) =abs(comb_matrix1_cross (i,13)); % abs diff high MAP
    
    comb_matrix1_cross (i,15) = Multiplier_2PC;
    comb_matrix1_cross (i,16) = Multiplier_1PC;
    
    comb_matrix1_cross(i,17)= comb_matrix1_cross(i,12)+ comb_matrix1_cross(i,14);
    
    comb_matrix1_cross (i,18)=  round (comb_matrix1_cross (i,2)- (comb_matrix1_cross (i,3)));%pulse pressure cross1
    comb_matrix1_cross (i,19)=  round (comb_matrix1_cross (i,1)- (comb_matrix1_cross (i,4)));%pulse pressure cross2
    comb_matrix1_cross (i,20)=  comb_matrix1_cross (i,19)- (comb_matrix1_cross (i,18));% difference in pulse pressure
    comb_matrix1_cross (i,21)= round(abs((comb_matrix1_cross (i,20)*100))/max(comb_matrix1_cross(i,18), comb_matrix1_cross(i,19)));% diff as percent of pulse pressure high (was originally percent of PPLow)
    
    comb_matrix1_cross (i,22)= abs(comb_matrix1_cross (i,21));%absolute variability of pulse pressure as percentage
    
    comb_matrix1_cross (i,23)=  round (comb_matrix1_cross (i,1)- (comb_matrix1_cross (i,3)));  %pulse pressure low
    comb_matrix1_cross (i,24)=  round (comb_matrix1_cross (i,2)- (comb_matrix1_cross (i,4))); %pulse pressure high
    comb_matrix1_cross (i,25)= max(comb_matrix1_cross (i,pulsePressure_columns))- min(comb_matrix1_cross (i,pulsePressure_columns));% difference in max and min of 4 pulse pressures
    comb_matrix1_cross (i,26)= round (comb_matrix1_cross(i,25)*100 /max(comb_matrix1_cross (i,pulsePressure_columns)));% diff as percent of max pulse pressure in the 4 columns (_was originally percent of min)
    
    comb_matrix1_cross (i,27)=  comb_matrix1_cross(i,2)- comb_matrix1_cross(i,1);
    comb_matrix1_cross (i,28) =  comb_matrix1_cross(i,4)- comb_matrix1_cross(i,3);
end

%%
comb_matrix1b_cross = comb_matrix1_cross;

%%
%Sort based on column 12

[~, comb_matrix1b_crossSortedCol_12] = sort(comb_matrix1b_cross(:,12));
comb_matrix1b_crossSorted_12 = comb_matrix1b_cross(comb_matrix1b_crossSortedCol_12, :);

%Then sort with column 14
comb_matrix1b_crossSorted_col_12_14 = comb_matrix1b_crossSorted_12;
% Find the unique values in column 12
unique_col_12_cross = unique(comb_matrix1b_crossSorted_col_12_14(:, 12));

% Initialize the sorted data
comb_matrix1b_crossSorted_12_14 = [];

% Sort based on column 14 for each unique value in column 12
for i = 1:length(unique_col_12_cross)
    idx_sort_12_14_cross = find(comb_matrix1b_crossSorted_col_12_14(:, 12) == unique_col_12_cross(i));
    comb_matrix1b_crossSorted_12_14 = [comb_matrix1b_crossSorted_12_14; sortrows(comb_matrix1b_crossSorted_col_12_14(idx_sort_12_14_cross, :), 14)];
end
%%
comb_matrix1b_crossSorted_12_14_select = comb_matrix1b_crossSorted_12_14(:,17)==comb_matrix1b_crossSorted_12_14(1,17);
short_comb_matrix1_cross = comb_matrix1b_crossSorted_12_14(comb_matrix1b_crossSorted_12_14_select,:)  ;

% if choices are few, then set the col 17 limit higher to get more choices

if size(short_comb_matrix1_cross,1)<20
    comb_matrix1b_crossSorted_12_14_select = comb_matrix1b_crossSorted_12_14(:,17)<=comb_matrix1b_crossSorted_12_14(1,17)+1;
end

short_comb_matrix1_cross = comb_matrix1b_crossSorted_12_14(comb_matrix1b_crossSorted_12_14_select,:);

%%
comb_matrix1_cross2 = zeros (size(comb_matrix1,1), 28);
comb_matrix1_cross2 (:,1:4)= comb_matrix1 (:,1:4);

%%

pulsePressure_columns = [18, 19, 23, 24];

for i = 1:size(comb_matrix1_cross2,1)
    
    comb_matrix1_cross2 (i,5)= round (comb_matrix1_cross2(i,4) + 0.3*(comb_matrix1_cross2 (i,1)- comb_matrix1_cross2(i,4))); %calc MAP low
    comb_matrix1_cross2 (i,6)= round (comb_matrix1_cross2(i,3) + 0.4*(comb_matrix1_cross2 (i,2)- comb_matrix1_cross2(i,3))); %calc MAP high
    comb_matrix1_cross2 (i,7)= round ((comb_matrix1_cross2(i,5) + comb_matrix1_cross2 (i,6))/2); % mean calc MAP
    
    comb_matrix1_cross2 (i,8)=  MAPselect_lowP; %MAP low
    comb_matrix1_cross2 (i,9)=  MAPselect_highP; %MAP high
    
    comb_matrix1_cross2 (i,10)= (comb_matrix1_cross2(i,8) + comb_matrix1_cross2(i,9))/2; % mean max oscill amp pressure
    
    comb_matrix1_cross2 (i,11) = round(comb_matrix1_cross2 (i,5)- comb_matrix1_cross2 (i,8)); % diff between calculated mean MAP low and osc amp MAP low
    comb_matrix1_cross2 (i,12) =abs(comb_matrix1_cross2 (i,11)); % abs diff low MAP
    
    comb_matrix1_cross2 (i,13) = round(comb_matrix1_cross2 (i,6)- comb_matrix1_cross2 (i,9)); % diff between calculated mean MAP high and osc amp MAP high
    comb_matrix1_cross2 (i,14) =abs(comb_matrix1_cross2 (i,13)); % abs diff high MAP
    
    comb_matrix1_cross2 (i,15) = Multiplier_3PC;
    comb_matrix1_cross2 (i,16) = Multiplier_1PC;
    
    comb_matrix1_cross2(i,17)= comb_matrix1_cross2(i,12)+ comb_matrix1_cross2(i,14);
    
    comb_matrix1_cross2 (i,18)=  round (comb_matrix1_cross2(i,1)- (comb_matrix1_cross2 (i,4)));%pulse pressure cross21
    comb_matrix1_cross2 (i,19)=  round (comb_matrix1_cross2(i,2)- (comb_matrix1_cross2 (i,3)));%pulse pressure cross22
    comb_matrix1_cross2 (i,20)=  comb_matrix1_cross2 (i,19)- (comb_matrix1_cross2 (i,18));% difference in pulse pressure
    comb_matrix1_cross2 (i,21)= round(abs((comb_matrix1_cross2(i,20)*100)) /max(comb_matrix1_cross2 (i,18), comb_matrix1_cross2 (i,19)));% diff as percent of pulse pressure high (was originally as percent of PPlow)
    
    comb_matrix1_cross2 (i,22)= abs (comb_matrix1_cross2 (i,21));%absolute variability of pulse pressure as percentage
    
    comb_matrix1_cross2 (i,23)=  round (comb_matrix1_cross2 (i,1)- (comb_matrix1_cross2 (i,3))); %pulse pressure low
    comb_matrix1_cross2 (i,24)=  round (comb_matrix1_cross2 (i,2)- (comb_matrix1_cross2 (i,4)));%pulse pressure high
    comb_matrix1_cross2 (i,25)= max(comb_matrix1_cross2 (i,pulsePressure_columns))- min(comb_matrix1_cross2 (i,pulsePressure_columns));% difference in max and min of 4 pulse pressures
    comb_matrix1_cross2 (i,26)= round (comb_matrix1_cross2(i,25)*100 /max(comb_matrix1_cross2 (i,pulsePressure_columns)));% diff as percent of max (THis was originally percent of min pressure) pulse pressure in the 4 columns
    
    comb_matrix1_cross2 (i,27)=  comb_matrix1_cross2(i,2)- comb_matrix1_cross2(i,1); %sys var
    comb_matrix1_cross2 (i,28) =  comb_matrix1_cross2(i,4)- comb_matrix1_cross2(i,3); % dia var
end

%%
comb_matrix1b_cross2 = comb_matrix1_cross2;

%%
%Sort based on column 12

[~, comb_matrix1_cross2SortedCol_12] = sort(comb_matrix1_cross2(:,12));
comb_matrix1_cross2Sorted_12 = comb_matrix1b_cross2(comb_matrix1_cross2SortedCol_12, :);

%Then sort with column 14
comb_matrix1_cross2Sorted_col_12_14 = comb_matrix1_cross2Sorted_12;
% Find the unique values in column 12
unique_col_12_cross2 = unique(comb_matrix1_cross2Sorted_col_12_14(:, 12));

% Initialize the sorted data
comb_matrix1_cross2Sorted_12_14 = [];
% Sort based on column 14 for each unique value in column 12
for i = 1:length(unique_col_12_cross2)
    idx_sort_12_14_cross2 = find(comb_matrix1_cross2Sorted_col_12_14(:, 12) == unique_col_12_cross2(i));
    comb_matrix1_cross2Sorted_12_14 = [comb_matrix1_cross2Sorted_12_14; sortrows(comb_matrix1_cross2Sorted_col_12_14(idx_sort_12_14_cross2, :), 14)];
end
%%
comb_matrix1b_cross2Sorted_12_14_select = comb_matrix1_cross2Sorted_12_14(:,17)==comb_matrix1_cross2Sorted_12_14(1,17);
short_comb_matrix1_cross2 = comb_matrix1_cross2Sorted_12_14(comb_matrix1b_cross2Sorted_12_14_select,:);

% if choices are few, then set the col 17 limit higher to get more choices
if size(short_comb_matrix1_cross2,1)<20
    comb_matrix1b_cross2Sorted_12_14_select = comb_matrix1_cross2Sorted_12_14(:,17)<=comb_matrix1_cross2Sorted_12_14(1,17)+1;
end

short_comb_matrix1_cross2 = comb_matrix1_cross2Sorted_12_14(comb_matrix1b_cross2Sorted_12_14_select,:);

%%
entry1_P = size(short_comb_matrix1,1);
entrySpacer1_P =entry1_P+2;
entry2_P  = entrySpacer1_P +size(short_comb_matrix1_cross,1);
entrySpacer2_P =entry2_P+2;
entry3_P  = entrySpacer2_P +size(short_comb_matrix1_cross2,1);

FinalNumRows_P = size(short_comb_matrix1,1)+ size(short_comb_matrix1_cross,1)+size(short_comb_matrix1_cross2,1);
spacerRows_P= 4;

short_comb_matrix_P_all = zeros(FinalNumRows_P+spacerRows_P, size(short_comb_matrix1,2));
short_comb_matrix_P_all (1:entry1_P, :) = short_comb_matrix1(:,:);
short_comb_matrix_P_all (entrySpacer1_P+1:entry2_P, :) = short_comb_matrix1_cross(:,:);
short_comb_matrix_P_all (entrySpacer2_P+1:entry3_P, :) = short_comb_matrix1_cross2(:,:);

%%
short_comb_matrix1_logical = short_comb_matrix1 (:,27)> short_comb_matrix1 (:,28) | short_comb_matrix1 (:,27)== short_comb_matrix1 (:,28);% avoiding rows where dia var is more than sys var
short_comb_matrix1_select = short_comb_matrix1 (short_comb_matrix1_logical,:);

short_comb_matrix1_cross_logical = short_comb_matrix1_cross (:,27)> short_comb_matrix1_cross (:,28) | short_comb_matrix1_cross (:,27)== short_comb_matrix1_cross (:,28);% avoiding rows where dia var is more than sys var
short_comb_matrix1_cross_select = short_comb_matrix1_cross (short_comb_matrix1_cross_logical,:);

short_comb_matrix1_cross2_logical = short_comb_matrix1_cross2 (:,27)> short_comb_matrix1_cross2 (:,28) | short_comb_matrix1_cross2 (:,27)== short_comb_matrix1_cross2 (:,28);% avoiding rows where dia var is more than sys var
short_comb_matrix1_cross2_select = short_comb_matrix1_cross2 (short_comb_matrix1_cross2_logical,:);

entry1_P_select = size(short_comb_matrix1_select,1);
entrySpacer1_P_select =entry1_P_select+2;
entry2_P_select  = entrySpacer1_P_select +size(short_comb_matrix1_cross_select,1);
entrySpacer2_P_select =entry2_P_select+2;
entry3_P_select  = entrySpacer2_P_select +size(short_comb_matrix1_cross2_select,1);

FinalNumRows_P_select = size(short_comb_matrix1_select,1)+ size(short_comb_matrix1_cross_select,1)+size(short_comb_matrix1_cross2_select,1);
spacerRows_P_select= 4;

short_comb_matrix_P_select_all = zeros(FinalNumRows_P_select+spacerRows_P_select, size(short_comb_matrix1,2));
short_comb_matrix_P_select_all (1:entry1_P_select, :) = short_comb_matrix1_select(:,:);
short_comb_matrix_P_select_all (entrySpacer1_P_select+1:entry2_P_select, :) = short_comb_matrix1_cross_select(:,:);
short_comb_matrix_P_select_all (entrySpacer2_P_select+1:entry3_P_select, :) = short_comb_matrix1_cross2_select(:,:);

short_comb_matrix_P_select1_all = short_comb_matrix_P_select_all;
for i = 1:size(short_comb_matrix_P_select1_all,1)
    
    if short_comb_matrix_P_select1_all(i,28)< 2 % Dia variability must be atleast 4, as per 29 intra arterial data. This was set at 4 earlier. But in 18091701 it caused a lot of trouble
        short_comb_matrix_P_select1_all(i,1:4)=0;
    end
    
    if short_comb_matrix_P_select1_all(i,27)/short_comb_matrix_P_select1_all(i,28)>4 %Ratio of sys var to dia var should not be more than 3 as per 29 intra arterial data set
        short_comb_matrix_P_select1_all(i,1:4)=0;
    end
end

%%
Multiplier_1Q = 0.45;
Multiplier_2Q = 0.36;
Multiplier_3Q = 0.33;

%%
comb_matrix1Q = comb_matrix1;

pulsePressure_columns = [18, 19, 23, 24];

for i = 1:size(comb_matrix1Q,1)
    
    comb_matrix1Q (i,5)= round (comb_matrix1Q(i,3) + Multiplier_1Q*(comb_matrix1Q (i,1)- comb_matrix1Q(i,3))); %calc MAP low
    comb_matrix1Q (i,6)= round (comb_matrix1Q(i,4) + Multiplier_2Q*(comb_matrix1Q (i,2)- comb_matrix1Q(i,4))); %calc MAP high
    comb_matrix1Q (i,7)= round ((comb_matrix1Q(i,5) + comb_matrix1Q (i,6))/2); % mean calc MAP
    
    comb_matrix1Q (i,8)= MAPselect_lowP; %  second max oscill amp pressure
    comb_matrix1Q (i,9)= MAPselect_highP; %  max oscill amp pressure
    
    comb_matrix1Q (i,10)= (comb_matrix1Q(i,8) + comb_matrix1Q(i,9))/2; % mean max oscill amp pressure
    
    comb_matrix1Q (i,11) = round(comb_matrix1Q (i,5)- comb_matrix1Q (i,8)); % diff between calculated mean MAP low and osc amp MAP low
    comb_matrix1Q (i,12) =abs(comb_matrix1Q (i,11)); % abs diff low MAP
    
    comb_matrix1Q (i,13) = round(comb_matrix1Q (i,6)- comb_matrix1Q (i,9)); % diff between calculated mean MAP high and osc amp MAP high
    comb_matrix1Q (i,14) =abs(comb_matrix1Q (i,13)); % abs diff high MAP
    
    comb_matrix1Q (i,15) = Multiplier_1Q;
    comb_matrix1Q (i,16) = Multiplier_2Q;
    
    comb_matrix1Q(i,17)= comb_matrix1Q(i,12)+ comb_matrix1Q(i,14);
    
    comb_matrix1Q (i,18)=  round (comb_matrix1Q (i,1)- (comb_matrix1Q (i,3)));%pulse pressure low
    comb_matrix1Q (i,19)=  round (comb_matrix1Q (i,2)- (comb_matrix1Q (i,4)));%pulse pressure high
    comb_matrix1Q (i,20)=  comb_matrix1Q (i,19)- (comb_matrix1Q (i,18));% difference in pulse pressure
    comb_matrix1Q (i,21)= round((comb_matrix1Q (i,20)*100) /comb_matrix1Q (i,19));% diff as percent of pulse pressure high (was originally perecent of PPLow)
    comb_matrix1Q (i,22)= abs (comb_matrix1Q (i,21));%absolute variability of pulse pressure as percentage
    
    comb_matrix1Q (i,23)=  round (comb_matrix1Q (i,2)- (comb_matrix1Q (i,3)));%pulse pressure cross1
    comb_matrix1Q (i,24)=  round (comb_matrix1Q (i,1)- (comb_matrix1Q (i,4)));%pulse pressure cross2
    comb_matrix1Q (i,25)= max(comb_matrix1Q (i,pulsePressure_columns))- min(comb_matrix1Q (i,pulsePressure_columns));% difference in max and min of 4 pulse pressures
    comb_matrix1Q (i,26)= round (comb_matrix1Q(i,25)*100 /max(comb_matrix1Q (i,pulsePressure_columns)));% diff as percent of max pulse pressure in the 4 columns (was originally percent of minPP)
    
    comb_matrix1Q (i,27)=  comb_matrix1Q(i,2)- comb_matrix1Q(i,1);
    comb_matrix1Q (i,28) =  comb_matrix1Q(i,4)- comb_matrix1Q(i,3);
end

%%
comb_matrix1Qb = comb_matrix1Q;

%%
%Sort based on column 12

[~, comb_matrix1QbSortedCol_12] = sort(comb_matrix1Qb(:,12));
comb_matrix1QbSorted_12 = comb_matrix1Qb(comb_matrix1QbSortedCol_12, :);

%Then sort with column 14
comb_matrix1QbSorted_col_12_14 = comb_matrix1QbSorted_12;
% Find the unique values in column 12
unique_col_12 = unique(comb_matrix1QbSorted_col_12_14(:, 12));

% Initialize the sorted data
comb_matrix1QbSorted_12_14 = [];

% Sort based on column 14 for each unique value in column 12
for i = 1:length(unique_col_12)
    idx_sort_12_14 = find(comb_matrix1QbSorted_col_12_14(:, 12) == unique_col_12(i));
    comb_matrix1QbSorted_12_14 = [comb_matrix1QbSorted_12_14; sortrows(comb_matrix1QbSorted_col_12_14(idx_sort_12_14, :), 14)];
end
%%
comb_matrix1QbSorted_12_14_select = comb_matrix1QbSorted_12_14(:,17)==comb_matrix1QbSorted_12_14(1,17);
short_comb_matrix1Q = comb_matrix1QbSorted_12_14(comb_matrix1QbSorted_12_14_select,:)  ;

if size(short_comb_matrix1Q, 1)<20
    comb_matrix1QbSorted_12_14_select = comb_matrix1QbSorted_12_14(:,17)<= comb_matrix1QbSorted_12_14(1,17)+1;
end

short_comb_matrix1Q = comb_matrix1QbSorted_12_14(comb_matrix1QbSorted_12_14_select,:)  ;

%%
comb_matrix1Q_cross = zeros (size(comb_matrix1Q,1), 28);
comb_matrix1Q_cross (:,1:4)= comb_matrix1Q (:,1:4);
%%
pulsePressure_columns = [18, 19, 23, 24];

for i = 1:size(comb_matrix1Q_cross,1)
    
    comb_matrix1Q_cross (i,5)= round (comb_matrix1Q_cross(i,3) +Multiplier_2Q*(comb_matrix1Q_cross (i,2)- comb_matrix1Q_cross(i,3))); %calc MAP low
    comb_matrix1Q_cross (i,6)= round (comb_matrix1Q_cross(i,4) + Multiplier_1Q*(comb_matrix1Q_cross (i,1)- comb_matrix1Q_cross(i,4))); %calc MAP high
    comb_matrix1Q_cross (i,7)= round ((comb_matrix1Q_cross(i,5) + comb_matrix1Q_cross (i,6))/2); % mean calc MAP
    
    comb_matrix1Q_cross (i,8)=  MAPselect_lowP; %MAP low
    comb_matrix1Q_cross (i,9)=  MAPselect_highP; %MAP high
    
    comb_matrix1Q_cross (i,10)= (comb_matrix1Q_cross(i,8) + comb_matrix1Q_cross(i,9))/2; % mean max oscill amp pressure
    
    comb_matrix1Q_cross (i,11) = round(comb_matrix1Q_cross (i,5)- comb_matrix1Q_cross (i,8)); % diff between calculated mean MAP low and osc amp MAP low
    comb_matrix1Q_cross (i,12) =abs(comb_matrix1Q_cross (i,11)); % abs diff low MAP
    
    comb_matrix1Q_cross (i,13) = round(comb_matrix1Q_cross (i,6)- comb_matrix1Q_cross (i,9)); % diff between calculated mean MAP high and osc amp MAP high
    comb_matrix1Q_cross (i,14) =abs(comb_matrix1Q_cross (i,13)); % abs diff high MAP
    
    comb_matrix1Q_cross (i,15) = Multiplier_2Q;
    comb_matrix1Q_cross (i,16) = Multiplier_1Q;
    
    comb_matrix1Q_cross(i,17)= comb_matrix1Q_cross(i,12)+ comb_matrix1Q_cross(i,14);
    
    comb_matrix1Q_cross (i,18)=  round (comb_matrix1Q_cross (i,2)- (comb_matrix1Q_cross (i,3)));%pulse pressure cross1
    comb_matrix1Q_cross (i,19)=  round (comb_matrix1Q_cross (i,1)- (comb_matrix1Q_cross (i,4)));%pulse pressure cross2
    comb_matrix1Q_cross (i,20)=  comb_matrix1Q_cross (i,19)- (comb_matrix1Q_cross (i,18));% difference in pulse pressure
    comb_matrix1Q_cross (i,21)= round(abs((comb_matrix1Q_cross (i,20)*100)) /max(comb_matrix1Q_cross (i,18), comb_matrix1Q_cross (i,19)));% diff as percent of pulse pressure high (originally it was PPlow)
    
    comb_matrix1Q_cross (i,22)= abs (comb_matrix1Q_cross (i,21));%absolute variability of pulse pressure as percentage
    
    comb_matrix1Q_cross (i,23)=  round (comb_matrix1Q_cross (i,1)- (comb_matrix1Q_cross (i,3)));  %pulse pressure low
    comb_matrix1Q_cross (i,24)=  round (comb_matrix1Q_cross (i,2)- (comb_matrix1Q_cross (i,4))); %pulse pressure high
    comb_matrix1Q_cross (i,25)= max(comb_matrix1Q_cross (i,pulsePressure_columns))- min(comb_matrix1Q_cross (i,pulsePressure_columns));% difference in max and min of 4 pulse pressures
    comb_matrix1Q_cross (i,26)= round (comb_matrix1Q_cross(i,25)*100 /max(comb_matrix1Q_cross (i,pulsePressure_columns)));% diff as percent of min pulse pressure in the 4 columns (originally PPmin)
    
    comb_matrix1Q_cross (i,27)=  comb_matrix1Q_cross(i,2)- comb_matrix1Q_cross(i,1);
    comb_matrix1Q_cross (i,28) =  comb_matrix1Q_cross(i,4)- comb_matrix1Q_cross(i,3);
end

%%
comb_matrix1Qb_cross = comb_matrix1Q_cross;

%%
%Sort based on column 12

[~, comb_matrix1Qb_crossSortedCol_12] = sort(comb_matrix1Qb_cross(:,12));
comb_matrix1Qb_crossSorted_12 = comb_matrix1Qb_cross(comb_matrix1Qb_crossSortedCol_12, :);

%Then sort with column 14
comb_matrix1Qb_crossSorted_col_12_14 = comb_matrix1Qb_crossSorted_12;
% Find the unique values in column 12
unique_col_12_cross = unique(comb_matrix1Qb_crossSorted_col_12_14(:, 12));

% Initialize the sorted data
comb_matrix1Qb_crossSorted_12_14 = [];

% Sort based on column 14 for each unique value in column 12
for i = 1:length(unique_col_12_cross)
    idx_sort_12_14_cross = find(comb_matrix1Qb_crossSorted_col_12_14(:, 12) == unique_col_12_cross(i));
    comb_matrix1Qb_crossSorted_12_14 = [comb_matrix1Qb_crossSorted_12_14; sortrows(comb_matrix1Qb_crossSorted_col_12_14(idx_sort_12_14_cross, :), 14)];
end
%%
comb_matrix1Qb_crossSorted_12_14_select = comb_matrix1Qb_crossSorted_12_14(:,17)==comb_matrix1Qb_crossSorted_12_14(1,17);
short_comb_matrix1Q_cross = comb_matrix1Qb_crossSorted_12_14(comb_matrix1Qb_crossSorted_12_14_select,:)  ;

if size(short_comb_matrix1Q_cross,1)<20
    comb_matrix1Qb_crossSorted_12_14_select = comb_matrix1Qb_crossSorted_12_14(:,17)<=comb_matrix1Qb_crossSorted_12_14(1,17)+1;
end

short_comb_matrix1Q_cross = comb_matrix1Qb_crossSorted_12_14(comb_matrix1Qb_crossSorted_12_14_select,:)  ;

%%
comb_matrix1Q_cross2 = zeros (size(comb_matrix1Q,1), 28);
comb_matrix1Q_cross2 (:,1:4)= comb_matrix1Q (:,1:4);

%%
pulsePressure_columns = [18, 19, 23, 24];

for i = 1:size(comb_matrix1Q_cross2,1)
    
    comb_matrix1Q_cross2 (i,5)= round (comb_matrix1Q_cross2(i,4) + Multiplier_3Q*(comb_matrix1Q_cross2 (i,1)- comb_matrix1Q_cross2(i,4))); %calc MAP low
    comb_matrix1Q_cross2 (i,6)= round (comb_matrix1Q_cross2(i,3) + Multiplier_1Q*(comb_matrix1Q_cross2 (i,2)- comb_matrix1Q_cross2(i,3))); %calc MAP high
    comb_matrix1Q_cross2 (i,7)= round ((comb_matrix1Q_cross2(i,5) + comb_matrix1Q_cross2 (i,6))/2); % mean calc MAP
    
    comb_matrix1Q_cross2 (i,8)=  MAPselect_lowP; %MAP low
    comb_matrix1Q_cross2 (i,9)=  MAPselect_highP; %MAP high
    
    comb_matrix1Q_cross2 (i,10)= (comb_matrix1Q_cross2(i,8) + comb_matrix1Q_cross2(i,9))/2; % mean max oscill amp pressure
    
    comb_matrix1Q_cross2 (i,11) = round(comb_matrix1Q_cross2 (i,5)- comb_matrix1Q_cross2 (i,8)); % diff between calculated mean MAP low and osc amp MAP low
    comb_matrix1Q_cross2 (i,12) =abs(comb_matrix1Q_cross2 (i,11)); % abs diff low MAP
    
    comb_matrix1Q_cross2 (i,13) = round(comb_matrix1Q_cross2 (i,6)- comb_matrix1Q_cross2 (i,9)); % diff between calculated mean MAP high and osc amp MAP high
    comb_matrix1Q_cross2 (i,14) =abs(comb_matrix1Q_cross2 (i,13)); % abs diff high MAP
    
    comb_matrix1Q_cross2 (i,15) = Multiplier_3Q;
    comb_matrix1Q_cross2 (i,16) = Multiplier_1Q;
    
    comb_matrix1Q_cross2(i,17)= comb_matrix1Q_cross2(i,12)+ comb_matrix1Q_cross2(i,14);
    
    comb_matrix1Q_cross2 (i,18)=  round (comb_matrix1Q_cross2 (i,1)- (comb_matrix1Q_cross2 (i,4)));%pulse pressure cross21
    comb_matrix1Q_cross2 (i,19)=  round (comb_matrix1Q_cross2 (i,2)- (comb_matrix1Q_cross2 (i,3)));%pulse pressure cross22
    comb_matrix1Q_cross2 (i,20)=  comb_matrix1Q_cross2 (i,19)- (comb_matrix1Q_cross2 (i,18));% difference in pulse pressure
    
    comb_matrix1Q_cross2 (i,21)= round(abs((comb_matrix1Q_cross2 (i,20)*100)) /max(comb_matrix1Q_cross2 (i,18), comb_matrix1Q_cross2 (i,19)));% diff as percent of pulse pressure high (originally PPlow)
    comb_matrix1Q_cross2 (i,22)= abs (comb_matrix1Q_cross2 (i,21));%absolute variability of pulse pressure as percentage
    
    comb_matrix1Q_cross2 (i,23)=  round (comb_matrix1Q_cross2 (i,1)- (comb_matrix1Q_cross2 (i,3))); %pulse pressure low
    comb_matrix1Q_cross2 (i,24)=  round (comb_matrix1Q_cross2 (i,2)- (comb_matrix1Q_cross2 (i,4)));%pulse pressure high
    comb_matrix1Q_cross2 (i,25)= max(comb_matrix1Q_cross2 (i,pulsePressure_columns))- min(comb_matrix1Q_cross2 (i,pulsePressure_columns));% difference in max and min of 4 pulse pressures
    comb_matrix1Q_cross2 (i,26)= round (comb_matrix1Q_cross2(i,25)*100 /max(comb_matrix1Q_cross2 (i,pulsePressure_columns)));% diff as percent of max pulse pressure in the 4 columns (originally as percent of min)
    
    comb_matrix1Q_cross2 (i,27)=  comb_matrix1Q_cross2(i,2)- comb_matrix1Q_cross2(i,1);
    comb_matrix1Q_cross2 (i,28) =  comb_matrix1Q_cross2(i,4)- comb_matrix1Q_cross2(i,3);
end

%%
comb_matrix1Qb_cross2 = comb_matrix1Q_cross2;

%%
%Sort based on column 12

[~, comb_matrix1Q_cross2SortedCol_12] = sort(comb_matrix1Q_cross2(:,12));
comb_matrix1Q_cross2Sorted_12 = comb_matrix1Qb_cross2(comb_matrix1Q_cross2SortedCol_12, :);

%Then sort with column 14
comb_matrix1Q_cross2Sorted_col_12_14 = comb_matrix1Q_cross2Sorted_12;
% Find the unique values in column 12
unique_col_12_cross2 = unique(comb_matrix1Q_cross2Sorted_col_12_14(:, 12));

% Initialize the sorted data
comb_matrix1Q_cross2Sorted_12_14 = [];

% Sort based on column 14 for each unique value in column 12
for i = 1:length(unique_col_12_cross2)
    idx_sort_12_14_cross2 = find(comb_matrix1Q_cross2Sorted_col_12_14(:, 12) == unique_col_12_cross2(i));
    comb_matrix1Q_cross2Sorted_12_14 = [comb_matrix1Q_cross2Sorted_12_14; sortrows(comb_matrix1Q_cross2Sorted_col_12_14(idx_sort_12_14_cross2, :), 14)];
end
%%
comb_matrix1Qb_cross2Sorted_12_14_select = comb_matrix1Q_cross2Sorted_12_14(:,17)==comb_matrix1Q_cross2Sorted_12_14(1,17);
short_comb_matrix1Q_cross2 = comb_matrix1Q_cross2Sorted_12_14(comb_matrix1Qb_cross2Sorted_12_14_select,:)  ;

if size(short_comb_matrix1Q_cross2,1) < 20
    comb_matrix1Qb_cross2Sorted_12_14_select = comb_matrix1Q_cross2Sorted_12_14(:,17)<=comb_matrix1Q_cross2Sorted_12_14(1,17)+1;
end

short_comb_matrix1Q_cross2 = comb_matrix1Q_cross2Sorted_12_14(comb_matrix1Qb_cross2Sorted_12_14_select,:)  ;

%%
entry1_Q = size(short_comb_matrix1Q,1);
entrySpacer1_Q =entry1_Q+2;
entry2_Q  = entrySpacer1_Q +size(short_comb_matrix1Q_cross,1);
entrySpacer2_Q =entry2_Q+2;
entry3_Q  = entrySpacer2_Q +size(short_comb_matrix1Q_cross2,1);

FinalNumRows_Q = size(short_comb_matrix1Q,1)+ size(short_comb_matrix1Q_cross,1)+size(short_comb_matrix1Q_cross2,1);
spacerRows_Q= 4;

short_comb_matrix_Q_all = zeros(FinalNumRows_Q+spacerRows_Q, size(short_comb_matrix1Q,2));
short_comb_matrix_Q_all (1:entry1_Q, :) = short_comb_matrix1Q(:,:);
short_comb_matrix_Q_all (entrySpacer1_Q+1:entry2_Q, :) = short_comb_matrix1Q_cross(:,:);
short_comb_matrix_Q_all (entrySpacer2_Q+1:entry3_Q, :) = short_comb_matrix1Q_cross2(:,:);

%%
short_comb_matrix1Q_logical = short_comb_matrix1Q (:,27)> short_comb_matrix1Q (:,28) | short_comb_matrix1Q (:,27)== short_comb_matrix1Q (:,28) ;
short_comb_matrix1Q_select = short_comb_matrix1Q (short_comb_matrix1Q_logical,:);

short_comb_matrix1Q_cross_logical = short_comb_matrix1Q_cross (:,27)> short_comb_matrix1Q_cross (:,28) | short_comb_matrix1Q_cross (:,27)== short_comb_matrix1Q_cross (:,28) ;
short_comb_matrix1Q_cross_select = short_comb_matrix1Q_cross (short_comb_matrix1Q_cross_logical,:);

short_comb_matrix1Q_cross2_logical = short_comb_matrix1Q_cross2 (:,27)> short_comb_matrix1Q_cross2 (:,28) | short_comb_matrix1Q_cross2 (:,27)== short_comb_matrix1Q_cross2 (:,28) ;
short_comb_matrix1Q_cross2_select = short_comb_matrix1Q_cross2 (short_comb_matrix1Q_cross2_logical,:);

entry1_Q_select = size(short_comb_matrix1Q_select,1);
entrySpacer1_Q_select =entry1_Q_select+2;
entry2_Q_select  = entrySpacer1_Q_select +size(short_comb_matrix1Q_cross_select,1);
entrySpacer2_Q_select =entry2_Q_select+2;
entry3_Q_select  = entrySpacer2_Q_select +size(short_comb_matrix1Q_cross2_select,1);

FinalNumRows_Q_select = size(short_comb_matrix1Q_select,1)+ size(short_comb_matrix1Q_cross_select,1)+size(short_comb_matrix1Q_cross2_select,1);
spacerRows_Q_select= 4;

short_comb_matrix_Q_select_all = zeros(FinalNumRows_Q_select+spacerRows_Q_select, size(short_comb_matrix1Q,2));
short_comb_matrix_Q_select_all (1:entry1_Q_select, :) = short_comb_matrix1Q_select(:,:);
short_comb_matrix_Q_select_all (entrySpacer1_Q_select+1:entry2_Q_select, :) = short_comb_matrix1Q_cross_select(:,:);
short_comb_matrix_Q_select_all (entrySpacer2_Q_select+1:entry3_Q_select, :) = short_comb_matrix1Q_cross2_select(:,:);

short_comb_matrix_Q_select1_all = short_comb_matrix_Q_select_all;
for i = 1:size(short_comb_matrix_Q_select1_all,1)
    
    if short_comb_matrix_Q_select1_all(i,28)<2 % Dia variability must be atleast 4, as per 29 intra arterial data. But setting this at 4 creates serious trouble in some cases
        short_comb_matrix_Q_select1_all(i,1:4)=0;
    end
    
    if short_comb_matrix_Q_select1_all(i,27)/short_comb_matrix_Q_select1_all(i,28)>4 %Ratio of sys var to dia var should not be more than 3 as per 29 intra arterial data set
        
        short_comb_matrix_Q_select1_all(i,1:4)=0;
    end
end

%%
Multiplier_1R = 0.36;
Multiplier_2R = 0.27;
Multiplier_3R = 0.24;

%%
comb_matrix1R = comb_matrix1;

pulsePressure_columns = [18, 19, 23, 24];

for i = 1:size(comb_matrix1R,1)
    
    comb_matrix1R (i,5)= round (comb_matrix1R(i,3) + Multiplier_1R*(comb_matrix1R (i,1)- comb_matrix1R(i,3))); %calc MAP low
    comb_matrix1R (i,6)= round (comb_matrix1R(i,4) + Multiplier_2R*(comb_matrix1R (i,2)- comb_matrix1R(i,4))); %calc MAP high
    comb_matrix1R (i,7)= round ((comb_matrix1R(i,5) + comb_matrix1R (i,6))/2); % mean calc MAP
    
    comb_matrix1R (i,8)= MAPselect_lowP; %  second max oscill amp pressure
    comb_matrix1R (i,9)= MAPselect_highP; %  max oscill amp pressure
    
    comb_matrix1R (i,10)= (comb_matrix1R(i,8) + comb_matrix1R(i,9))/2; % mean max oscill amp pressure
    
    comb_matrix1R (i,11) = round(comb_matrix1R (i,5)- comb_matrix1R (i,8)); % diff between calculated mean MAP low and osc amp MAP low
    comb_matrix1R (i,12) =abs(comb_matrix1R (i,11)); % abs diff low MAP
    
    comb_matrix1R (i,13) = round(comb_matrix1R (i,6)- comb_matrix1R (i,9)); % diff between calculated mean MAP high and osc amp MAP high
    comb_matrix1R (i,14) =abs(comb_matrix1R (i,13)); % abs diff high MAP
    
    comb_matrix1R (i,15) = Multiplier_1R;
    comb_matrix1R (i,16) = Multiplier_2R;
    
    comb_matrix1R(i,17)= comb_matrix1R(i,12)+ comb_matrix1R(i,14);
    
    comb_matrix1R (i,18)=  round (comb_matrix1R (i,1)- (comb_matrix1R (i,3)));%pulse pressure low
    comb_matrix1R (i,19)=  round (comb_matrix1R (i,2)- (comb_matrix1R (i,4)));%pulse pressure high
    comb_matrix1R (i,20)=  comb_matrix1R (i,19)- (comb_matrix1R (i,18));% difference in pulse pressure
    comb_matrix1R (i,21)= round((comb_matrix1R (i,20)*100) /comb_matrix1R (i,19));% diff as percent of pulse pressure high (originally PPLow)
    comb_matrix1R (i,22)= abs (comb_matrix1R (i,21));%absolute variability of pulse pressure as percentage
    
    comb_matrix1R (i,23)=  round (comb_matrix1R (i,2)- (comb_matrix1R (i,3)));%pulse pressure cross1
    comb_matrix1R (i,24)=  round (comb_matrix1R (i,1)- (comb_matrix1R (i,4)));%pulse pressure cross2 or is it PP high cross
    comb_matrix1R (i,25)= max(comb_matrix1R (i,pulsePressure_columns))- min(comb_matrix1R (i,pulsePressure_columns));% difference in max and min of 4 pulse pressures
    comb_matrix1R (i,26)= round (comb_matrix1R(i,25)*100 /max(comb_matrix1R (i,pulsePressure_columns)));% diff as percent of max pulse pressure in the 4 columns (earlier, as percent of min PP)
    
    comb_matrix1R (i,27)=  comb_matrix1R(i,2)- comb_matrix1R(i,1);
    comb_matrix1R (i,28) =  comb_matrix1R(i,4)- comb_matrix1R(i,3);
end

%%
comb_matrix1Rb = comb_matrix1R;

%%
%Sort based on column 12

[~, comb_matrix1RbSortedCol_12] = sort(comb_matrix1Rb(:,12));
comb_matrix1RbSorted_12 = comb_matrix1Rb(comb_matrix1RbSortedCol_12, :);

%Then sort with column 14
comb_matrix1RbSorted_col_12_14 = comb_matrix1RbSorted_12;
% Find the unique values in column 12
unique_col_12 = unique(comb_matrix1RbSorted_col_12_14(:, 12));

% Initialize the sorted data
comb_matrix1RbSorted_12_14 = [];

% Sort based on column 14 for each unique value in column 12
for i = 1:length(unique_col_12)
    idx_sort_12_14 = find(comb_matrix1RbSorted_col_12_14(:, 12) == unique_col_12(i));
    comb_matrix1RbSorted_12_14 = [comb_matrix1RbSorted_12_14; sortrows(comb_matrix1RbSorted_col_12_14(idx_sort_12_14, :), 14)];
end
%%
comb_matrix1RbSorted_12_14_select = comb_matrix1RbSorted_12_14(:,17)==comb_matrix1RbSorted_12_14(1,17);
short_comb_matrix1R = comb_matrix1RbSorted_12_14(comb_matrix1RbSorted_12_14_select,:)  ;

if size(short_comb_matrix1R,1)<20
    comb_matrix1RbSorted_12_14_select = comb_matrix1RbSorted_12_14(:,17)<=comb_matrix1RbSorted_12_14(1,17)+1;
end

short_comb_matrix1R = comb_matrix1RbSorted_12_14(comb_matrix1RbSorted_12_14_select,:)  ;

%%
comb_matrix1R_cross = zeros (size(comb_matrix1R,1), 28);
comb_matrix1R_cross (:,1:4)= comb_matrix1R (:,1:4);
%%
pulsePressure_columns = [18, 19, 23, 24];

for i = 1:size(comb_matrix1R_cross,1)
    
    comb_matrix1R_cross (i,5)= round (comb_matrix1R_cross(i,3) +Multiplier_2R*(comb_matrix1R_cross (i,2)- comb_matrix1R_cross(i,3))); %calc MAP low
    comb_matrix1R_cross (i,6)= round (comb_matrix1R_cross(i,4) + Multiplier_1R*(comb_matrix1R_cross (i,1)- comb_matrix1R_cross(i,4))); %calc MAP high
    comb_matrix1R_cross (i,7)= round ((comb_matrix1R_cross(i,5) + comb_matrix1R_cross (i,6))/2); % mean calc MAP
    
    comb_matrix1R_cross (i,8)=  MAPselect_lowP; %MAP low
    comb_matrix1R_cross (i,9)=  MAPselect_highP; %MAP high
    
    comb_matrix1R_cross (i,10)= (comb_matrix1R_cross(i,8) + comb_matrix1R_cross(i,9))/2; % mean max oscill amp pressure
    
    comb_matrix1R_cross (i,11) = round(comb_matrix1R_cross (i,5)- comb_matrix1R_cross (i,8)); % diff between calculated mean MAP low and osc amp MAP low
    comb_matrix1R_cross (i,12) =abs(comb_matrix1R_cross (i,11)); % abs diff low MAP
    
    comb_matrix1R_cross (i,13) = round(comb_matrix1R_cross (i,6)- comb_matrix1R_cross (i,9)); % diff between calculated mean MAP high and osc amp MAP high
    comb_matrix1R_cross (i,14) =abs(comb_matrix1R_cross (i,13)); % abs diff high MAP
    
    comb_matrix1R_cross (i,15) = Multiplier_2R;
    comb_matrix1R_cross (i,16) = Multiplier_1R;
    
    comb_matrix1R_cross(i,17)= comb_matrix1R_cross(i,12)+ comb_matrix1R_cross(i,14);
    
    comb_matrix1R_cross (i,18)=  round (comb_matrix1R_cross (i,2)- (comb_matrix1R_cross (i,3)));%pulse pressure cross1
    comb_matrix1R_cross (i,19)=  round (comb_matrix1R_cross (i,1)- (comb_matrix1R_cross (i,4)));%pulse pressure cross2
    comb_matrix1R_cross (i,20)=  comb_matrix1R_cross (i,19)- (comb_matrix1R_cross (i,18));% difference in pulse pressure
    
    comb_matrix1R_cross (i,21)= round(abs((comb_matrix1R_cross (i,20)*100)) /max(comb_matrix1R_cross (i,18), comb_matrix1R_cross (i,19)));% diff as percent of pulse pressure high (earlier it was percent of min)
    comb_matrix1R_cross (i,22)= abs(comb_matrix1R_cross (i,21));%absolute variability of pulse pressure as percentage
    
    comb_matrix1R_cross (i,23)=  round (comb_matrix1R_cross (i,1)- (comb_matrix1R_cross (i,3)));  %pulse pressure low
    comb_matrix1R_cross (i,24)=  round (comb_matrix1R_cross (i,2)- (comb_matrix1R_cross (i,4))); %pulse pressure high
    comb_matrix1R_cross (i,25)= max(comb_matrix1R_cross (i,pulsePressure_columns))- min(comb_matrix1R_cross (i,pulsePressure_columns));% difference in max and min of 4 pulse pressures
    comb_matrix1R_cross (i,26)= round(comb_matrix1R_cross(i,25)*100 /max(comb_matrix1R_cross(i,pulsePressure_columns)));% diff as percent of max pulse pressure in the 4 columns (earlier it was min PP)
    
    comb_matrix1R_cross (i,27)=  comb_matrix1R_cross(i,2)- comb_matrix1R_cross(i,1);
    comb_matrix1R_cross (i,28) =  comb_matrix1R_cross(i,4)- comb_matrix1R_cross(i,3);
end

%%
comb_matrix1Rb_cross = comb_matrix1R_cross;

%%
%Sort based on column 12

[~, comb_matrix1Rb_crossSortedCol_12] = sort(comb_matrix1Rb_cross(:,12));
comb_matrix1Rb_crossSorted_12 = comb_matrix1Rb_cross(comb_matrix1Rb_crossSortedCol_12, :);

%Then sort with column 14
comb_matrix1Rb_crossSorted_col_12_14 = comb_matrix1Rb_crossSorted_12;
% Find the unique values in column 12
unique_col_12_cross = unique(comb_matrix1Rb_crossSorted_col_12_14(:, 12));

% Initialize the sorted data
comb_matrix1Rb_crossSorted_12_14 = [];

% Sort based on column 14 for each unique value in column 12
for i = 1:length(unique_col_12_cross)
    idx_sort_12_14_cross = find(comb_matrix1Rb_crossSorted_col_12_14(:, 12) == unique_col_12_cross(i));
    comb_matrix1Rb_crossSorted_12_14 = [comb_matrix1Rb_crossSorted_12_14; sortrows(comb_matrix1Rb_crossSorted_col_12_14(idx_sort_12_14_cross, :), 14)];
end
%%
comb_matrix1Rb_crossSorted_12_14_select = comb_matrix1Rb_crossSorted_12_14(:,17)==comb_matrix1Rb_crossSorted_12_14(1,17);
short_comb_matrix1R_cross = comb_matrix1Rb_crossSorted_12_14(comb_matrix1Rb_crossSorted_12_14_select,:)  ;

if size(short_comb_matrix1R_cross,1)<20
    comb_matrix1Rb_crossSorted_12_14_select = comb_matrix1Rb_crossSorted_12_14(:,17)<=comb_matrix1Rb_crossSorted_12_14(1,17)+1;
end

short_comb_matrix1R_cross = comb_matrix1Rb_crossSorted_12_14(comb_matrix1Rb_crossSorted_12_14_select,:);

%%
comb_matrix1R_cross2 = zeros (size(comb_matrix1R,1), 28);
comb_matrix1R_cross2 (:,1:4)= comb_matrix1R (:,1:4);

%%

pulsePressure_columns = [18, 19, 23, 24];

for i = 1:size(comb_matrix1R_cross2,1)
    
    comb_matrix1R_cross2 (i,5)= round (comb_matrix1R_cross2(i,4) + Multiplier_3R*(comb_matrix1R_cross2 (i,1)- comb_matrix1R_cross2(i,4))); %calc MAP low
    comb_matrix1R_cross2 (i,6)= round (comb_matrix1R_cross2(i,3) + Multiplier_1R*(comb_matrix1R_cross2 (i,2)- comb_matrix1R_cross2(i,3))); %calc MAP high
    comb_matrix1R_cross2 (i,7)= round ((comb_matrix1R_cross2(i,5) + comb_matrix1R_cross2 (i,6))/2); % mean calc MAP
    
    comb_matrix1R_cross2 (i,8)=  MAPselect_lowP; %MAP low
    comb_matrix1R_cross2 (i,9)=  MAPselect_highP; %MAP high
    
    comb_matrix1R_cross2 (i,10)= (comb_matrix1R_cross2(i,8) + comb_matrix1R_cross2(i,9))/2; % mean max oscill amp pressure
    
    comb_matrix1R_cross2 (i,11) = round(comb_matrix1R_cross2 (i,5)- comb_matrix1R_cross2 (i,8)); % diff between calculated mean MAP low and osc amp MAP low
    comb_matrix1R_cross2 (i,12) =abs(comb_matrix1R_cross2 (i,11)); % abs diff low MAP
    
    comb_matrix1R_cross2 (i,13) = round(comb_matrix1R_cross2 (i,6)- comb_matrix1R_cross2 (i,9)); % diff between calculated mean MAP high and osc amp MAP high
    comb_matrix1R_cross2 (i,14) =abs(comb_matrix1R_cross2 (i,13)); % abs diff high MAP
    
    comb_matrix1R_cross2 (i,15) = Multiplier_3R;
    comb_matrix1R_cross2 (i,16) = Multiplier_1R;
    
    comb_matrix1R_cross2(i,17)= comb_matrix1R_cross2(i,12)+ comb_matrix1R_cross2(i,14);
    
    comb_matrix1R_cross2 (i,18)=  round (comb_matrix1R_cross2 (i,1)- (comb_matrix1R_cross2 (i,4)));%pulse pressure cross21
    comb_matrix1R_cross2 (i,19)=  round (comb_matrix1R_cross2 (i,2)- (comb_matrix1R_cross2 (i,3)));%pulse pressure cross22
    comb_matrix1R_cross2 (i,20)=  comb_matrix1R_cross2 (i,19)- (comb_matrix1R_cross2 (i,18));% difference in pulse pressure
    
    comb_matrix1R_cross2 (i,21)= round(abs((comb_matrix1R_cross2 (i,20)*100)) /max(comb_matrix1R_cross2 (i,18), comb_matrix1R_cross2 (i,19)));% diff as percent of pulse pressure high (earlier it was PPlow)
    comb_matrix1R_cross2 (i,22)= abs (comb_matrix1R_cross2 (i,21));%absolute variability of pulse pressure as percentage
    
    comb_matrix1R_cross2 (i,23)=  round (comb_matrix1R_cross2 (i,1)- (comb_matrix1R_cross2 (i,3))); %pulse pressure for low sys and low dia
    comb_matrix1R_cross2 (i,24)=  round (comb_matrix1R_cross2 (i,2)- (comb_matrix1R_cross2 (i,4)));%pulse pressure for high sys and high dia
    comb_matrix1R_cross2 (i,25)= max(comb_matrix1R_cross2 (i,pulsePressure_columns))- min(comb_matrix1R_cross2 (i,pulsePressure_columns));% difference in max and min of 4 pulse pressures
    comb_matrix1R_cross2 (i,26)= round (comb_matrix1R_cross2(i,25)*100 /max(comb_matrix1R_cross2(i,pulsePressure_columns)));% diff as percent of max pulse pressure in the 4 columns (earlier it was min PP)
    
    comb_matrix1R_cross2 (i,27)=  comb_matrix1R_cross2(i,2)- comb_matrix1R_cross2(i,1);%sys var
    comb_matrix1R_cross2 (i,28) =  comb_matrix1R_cross2(i,4)- comb_matrix1R_cross2(i,3);% dia var
end

%%
comb_matrix1Rb_cross2 = comb_matrix1R_cross2;

%%
%Sort based on column 12

[~, comb_matrix1R_cross2SortedCol_12] = sort(comb_matrix1R_cross2(:,12));
comb_matrix1R_cross2Sorted_12 = comb_matrix1Rb_cross2(comb_matrix1R_cross2SortedCol_12, :);

%Then sort with column 14
comb_matrix1R_cross2Sorted_col_12_14 = comb_matrix1R_cross2Sorted_12;
% Find the unique values in column 12
unique_col_12_cross2 = unique(comb_matrix1R_cross2Sorted_col_12_14(:, 12));

% Initialize the sorted data
comb_matrix1R_cross2Sorted_12_14 = [];

% Sort based on column 14 for each unique value in column 12
for i = 1:length(unique_col_12_cross2)
    idx_sort_12_14_cross2 = find(comb_matrix1R_cross2Sorted_col_12_14(:, 12) == unique_col_12_cross2(i));
    comb_matrix1R_cross2Sorted_12_14 = [comb_matrix1R_cross2Sorted_12_14; sortrows(comb_matrix1R_cross2Sorted_col_12_14(idx_sort_12_14_cross2, :), 14)];
end
%%
comb_matrix1Rb_cross2Sorted_12_14_select = comb_matrix1R_cross2Sorted_12_14(:,17)==comb_matrix1R_cross2Sorted_12_14(1,17);
short_comb_matrix1R_cross2 = comb_matrix1R_cross2Sorted_12_14(comb_matrix1Rb_cross2Sorted_12_14_select,:)  ;

if size(short_comb_matrix1R_cross2,1)<20
    comb_matrix1Rb_cross2Sorted_12_14_select = comb_matrix1R_cross2Sorted_12_14(:,17)<=comb_matrix1R_cross2Sorted_12_14(1,17)+1;
end

short_comb_matrix1R_cross2 = comb_matrix1R_cross2Sorted_12_14(comb_matrix1Rb_cross2Sorted_12_14_select,:);

%%
entry1_R = size(short_comb_matrix1R,1);
entrySpacer1_R =entry1_R+2;
entry2_R  = entrySpacer1_R +size(short_comb_matrix1R_cross,1);
entrySpacer2_R =entry2_R+2;
entry3_R  = entrySpacer2_R +size(short_comb_matrix1R_cross2,1);

FinalNumRows_R = size(short_comb_matrix1R,1)+ size(short_comb_matrix1R_cross,1)+size(short_comb_matrix1R_cross2,1);
spacerRows_R= 4;

short_comb_matrix_R_all = zeros(FinalNumRows_R+spacerRows_R, size(short_comb_matrix1R,2));
short_comb_matrix_R_all (1:entry1_R, :) = short_comb_matrix1R(:,:);
short_comb_matrix_R_all (entrySpacer1_R+1:entry2_R, :) = short_comb_matrix1R_cross(:,:);
short_comb_matrix_R_all (entrySpacer2_R+1:entry3_R, :) = short_comb_matrix1R_cross2(:,:);

%%
short_comb_matrix1R_logical = short_comb_matrix1R (:,27)> short_comb_matrix1R (:,28) | short_comb_matrix1R (:,27)== short_comb_matrix1R (:,28);
short_comb_matrix1R_select = short_comb_matrix1R (short_comb_matrix1R_logical,:);

short_comb_matrix1R_cross_logical = short_comb_matrix1R_cross (:,27)> short_comb_matrix1R_cross (:,28) | short_comb_matrix1R_cross (:,27)== short_comb_matrix1R_cross (:,28) ;
short_comb_matrix1R_cross_select = short_comb_matrix1R_cross (short_comb_matrix1R_cross_logical,:);

short_comb_matrix1R_cross2_logical = short_comb_matrix1R_cross2 (:,27)> short_comb_matrix1R_cross2 (:,28) | short_comb_matrix1R_cross2 (:,27)== short_comb_matrix1R_cross2 (:,28) ;
short_comb_matrix1R_cross2_select = short_comb_matrix1R_cross2 (short_comb_matrix1R_cross2_logical,:);

entry1_R_select = size(short_comb_matrix1R_select,1);
entrySpacer1_R_select =entry1_R_select+2;
entry2_R_select  = entrySpacer1_R_select +size(short_comb_matrix1R_cross_select,1);
entrySpacer2_R_select =entry2_R_select+2;
entry3_R_select  = entrySpacer2_R_select +size(short_comb_matrix1R_cross2_select,1);

FinalNumRows_R_select = size(short_comb_matrix1R_select,1)+ size(short_comb_matrix1R_cross_select,1)+size(short_comb_matrix1R_cross2_select,1);
spacerRows_R_select= 4;

short_comb_matrix_R_select_all = zeros(FinalNumRows_R_select+spacerRows_R_select, size(short_comb_matrix1R,2));
short_comb_matrix_R_select_all (1:entry1_R_select, :) = short_comb_matrix1R_select(:,:);
short_comb_matrix_R_select_all (entrySpacer1_R_select+1:entry2_R_select, :) = short_comb_matrix1R_cross_select(:,:);
short_comb_matrix_R_select_all (entrySpacer2_R_select+1:entry3_R_select, :) = short_comb_matrix1R_cross2_select(:,:);

short_comb_matrix_R_select1_all = short_comb_matrix_R_select_all;

for i = 1:size(short_comb_matrix_R_select1_all,1)
    
    if short_comb_matrix_R_select1_all(i,28)<2 % Dia variability must be atleast 4, as per 29 intra arterial data. But setting this at 4 creates serious trouble in some cases
        short_comb_matrix_R_select1_all(i,1:4)=0;
    end
    
    if short_comb_matrix_R_select1_all(i,27)/short_comb_matrix_R_select1_all(i,28)>4 %Ratio of sys var to dia var should not be more than 4 as per 29 intra arterial data set
        short_comb_matrix_R_select1_all(i,1:4)=0;
    end
end
%%
short_P_sel_NZ = short_comb_matrix_P_select1_all ;

for i = 1: size(short_P_sel_NZ,1)
    if all(short_P_sel_NZ (i,5:8)>0) && all(short_P_sel_NZ (i,1:4)==0)
        short_P_sel_NZ (i, :)= 1;
    end
end

% Logical index to select rows where not all elements are 1
short_P_sel_NZ_logical = any(short_P_sel_NZ ~= 1, 2);
% Select rows from A using the logical index
short_P_sel_NZ1 =  short_P_sel_NZ(short_P_sel_NZ_logical, :);
%
short_P2_sel_NZ1 = []; % Initializing to enable reruns
short_P2_sel_NZ1_logical = [];
%
for i = 1:size(short_P_sel_NZ1,1)
    if short_P_sel_NZ1 (i, 1:4)>0
        short_P2_sel_NZ1_logical (i,1) = short_P_sel_NZ1(i,22)>(PPG_variability_min/2); % choose values with Pulse variability matches PPG var from col 22
        if PPGvar_acrossPlateaus_prctile_pcOfMax >30
            short_P2_sel_NZ1_logical (i,2) = short_P_sel_NZ1(i,22)<(PPGvar_acrossPlateaus_prctile_pcOfMax*1.5);
        else
            short_P2_sel_NZ1_logical (i,2) = short_P_sel_NZ1(i,22)<(PPGvar_acrossPlateaus_prctile_pcOfMax*2);
        end
        short_P2_sel_NZ1_logical2 (i,1)=short_P2_sel_NZ1_logical(i,1)==1 & short_P2_sel_NZ1_logical(i,2)==1;
        short_P2_sel_NZ1a = short_P_sel_NZ1(short_P2_sel_NZ1_logical2, :);
    end
end


short_P2_sel_NZ1 = short_P2_sel_NZ1a;

if size(short_P2_sel_NZ1a,1)<5
    for i = 1:size(short_P_sel_NZ1,1)
        if short_P_sel_NZ1 (i, 1:4)>0
            short_P2_sel_NZ1_logical (i,1) = short_P_sel_NZ1(i,26)>(PPG_variability_min/4);
            if PPGvar_acrossPlateaus_prctile_pcOfMax >30
                short_P2_sel_NZ1_logical (i,2) = short_P_sel_NZ1(i,26)<(PPGvar_acrossPlateaus_prctile_pcOfMax*2);
            else
                short_P2_sel_NZ1_logical (i,2) = short_P_sel_NZ1(i,26)< (PPGvar_acrossPlateaus_prctile_pcOfMax*3);
                short_P2_sel_NZ1_logical2 (i,1)=short_P2_sel_NZ1_logical(i,1)==1  &short_P2_sel_NZ1_logical(i,2)==1;
                short_P2_sel_NZ1b = short_P_sel_NZ1(short_P2_sel_NZ1_logical2, :);
            end
        end
    end
    if exist('short_P2_sel_NZ1b', 'var')
        short_P2_sel_NZ1 = cat (1, short_P2_sel_NZ1a, short_P2_sel_NZ1b);
    else
        short_P2_sel_NZ1 = short_P2_sel_NZ1a;
    end
end

if isempty(short_P2_sel_NZ1)
    for i = 1:size(short_P_sel_NZ1,1)
        if short_P_sel_NZ1 (i, 1:4)>0
            short_P2_sel_NZ1_logical3 (i,1) = short_P_sel_NZ1(i,22)>(PPG_variability_min/2); % choose values with Pulse variability matches PPG var from col 22
            short_P2_sel_NZ1 = short_P_sel_NZ1(short_P2_sel_NZ1_logical3, :);
        end
    end
end
%%
if size(short_P2_sel_NZ1,1)>100
    while size(short_P2_sel_NZ1,1)>100
        short_P2_sel_NZ1_logical4 = [];
        Threshold_col_22 = round(mean(short_P2_sel_NZ1(:,22)));
        short_P2_sel_NZ1_logical4 = short_P2_sel_NZ1(:,22)<Threshold_col_22;
        short_P2_sel_NZ1(~short_P2_sel_NZ1_logical4, :)=[];
        continue
    end
end
%%
short_Q_sel_NZ = short_comb_matrix_Q_select1_all ;

for i = 1: size(short_Q_sel_NZ,1)
    if all(short_Q_sel_NZ (i,5:8)>0) && all(short_Q_sel_NZ (i,1:4)==0)
        short_Q_sel_NZ (i, :)= 1;
    end
end

% Logical index to select rows where not all elements are 1
short_Q_sel_NZ_logical = any(short_Q_sel_NZ ~= 1, 2);
% Select rows from A using the logical index
short_Q_sel_NZ1 =  short_Q_sel_NZ(short_Q_sel_NZ_logical, :);
%
short_Q2_sel_NZ1 = []; % Initializing to enable reruns
short_Q2_sel_NZ1_logical = [];
%
for i = 1:size(short_Q_sel_NZ1,1)
    if short_Q_sel_NZ1 (i, 1:4)>0
        short_Q2_sel_NZ1_logical (i,1) = short_Q_sel_NZ1(i,22)>(PPG_variability_min/2); % choose values with pulse variability matches PPG var from col 22
        if PPGvar_acrossPlateaus_prctile_pcOfMax >30
            short_Q2_sel_NZ1_logical (i,2) = short_Q_sel_NZ1(i,22)<(PPGvar_acrossPlateaus_prctile_pcOfMax*1.5);
        else
            short_Q2_sel_NZ1_logical (i,2) = short_Q_sel_NZ1(i,22)<(PPGvar_acrossPlateaus_prctile_pcOfMax*2);
        end
        short_Q2_sel_NZ1_logical2 (i,1)=short_Q2_sel_NZ1_logical(i,1)==1 & short_Q2_sel_NZ1_logical(i,2)==1;
        short_Q2_sel_NZ1a = short_Q_sel_NZ1(short_Q2_sel_NZ1_logical2, :);
    end
end

short_Q2_sel_NZ1 = short_Q2_sel_NZ1a;

if size(short_Q2_sel_NZ1a,1)<5
    for i = 1:size(short_Q_sel_NZ1,1)
        if short_Q_sel_NZ1 (i, 1:4)>0
            short_Q2_sel_NZ1_logical (i,1) = short_Q_sel_NZ1(i,26)>(PPG_variability_min/4);
            if PPGvar_acrossPlateaus_prctile_pcOfMax >30
                short_Q2_sel_NZ1_logical (i,2) = short_Q_sel_NZ1(i,26)<(PPGvar_acrossPlateaus_prctile_pcOfMax*2);
            else
                short_Q2_sel_NZ1_logical (i,2) = short_Q_sel_NZ1(i,26)< (PPGvar_acrossPlateaus_prctile_pcOfMax*3);
                short_Q2_sel_NZ1_logical2 (i,1)=short_Q2_sel_NZ1_logical(i,1)==1  &short_Q2_sel_NZ1_logical(i,2)==1;
                short_Q2_sel_NZ1b = short_Q_sel_NZ1(short_Q2_sel_NZ1_logical2, :);
            end
        end
    end
    if exist('short_Q2_sel_NZ1b', 'var')
        short_Q2_sel_NZ1 = cat (1, short_Q2_sel_NZ1a, short_Q2_sel_NZ1b);
    else
        short_Q2_sel_NZ1 = short_Q2_sel_NZ1a;
    end
end

if isempty(short_Q2_sel_NZ1)
    for i = 1:size(short_Q_sel_NZ1,1)
        if short_Q_sel_NZ1 (i, 1:4)>0
            short_Q2_sel_NZ1_logical3 (i,1) = short_Q_sel_NZ1(i,22)>(PPG_variability_min/2); % choose values with pulse variability matches PPG var from col 22
            short_Q2_sel_NZ1 = short_Q_sel_NZ1(short_Q2_sel_NZ1_logical3, :);
        end
    end
end
%%
if size(short_Q2_sel_NZ1,1)>100
    while size(short_Q2_sel_NZ1,1)>100
        short_Q2_sel_NZ1_logical4 = [];
        Threshold_col_22 = round(mean(short_Q2_sel_NZ1(:,22)));
        short_Q2_sel_NZ1_logical4 = short_Q2_sel_NZ1(:,22)<Threshold_col_22;
        short_Q2_sel_NZ1(~short_Q2_sel_NZ1_logical4, :)=[];
        continue
    end
end
%%
short_R_sel_NZ = short_comb_matrix_R_select1_all ;

for i = 1: size(short_R_sel_NZ,1)
    if all(short_R_sel_NZ (i,5:8)>0) && all(short_R_sel_NZ (i,1:4)==0)
        short_R_sel_NZ (i, :)= 1;
    end
end

% Logical index to select rows where not all elements are 1
short_R_sel_NZ_logical = any(short_R_sel_NZ ~= 1, 2);
% Select rows from A using the logical index
short_R_sel_NZ1 =  short_R_sel_NZ(short_R_sel_NZ_logical, :);
%
short_R2_sel_NZ1 = []; % Initializing to enable reruns
short_R2_sel_NZ1_logical = [];
%
for i = 1:size(short_R_sel_NZ1,1)
    if short_R_sel_NZ1 (i, 1:4)>0
        short_R2_sel_NZ1_logical (i,1) = short_R_sel_NZ1(i,22)>(PPG_variability_min/2); % choose values with Rulse variability matches PPG var from col 22
        if PPGvar_acrossPlateaus_prctile_pcOfMax >30
            short_R2_sel_NZ1_logical (i,2) = short_R_sel_NZ1(i,22)<(PPGvar_acrossPlateaus_prctile_pcOfMax*1.5);
        else
            short_R2_sel_NZ1_logical (i,2) = short_R_sel_NZ1(i,22)<(PPGvar_acrossPlateaus_prctile_pcOfMax*2);
        end
        short_R2_sel_NZ1_logical2 (i,1)=short_R2_sel_NZ1_logical(i,1)==1 & short_R2_sel_NZ1_logical(i,2)==1;
        short_R2_sel_NZ1a = short_R_sel_NZ1(short_R2_sel_NZ1_logical2, :);
    end
end

if exist('short_R2_sel_NZ1a', 'var')
    short_R2_sel_NZ1 = short_R2_sel_NZ1a;
    
    if size(short_R2_sel_NZ1a,1)<5
        for i = 1:size(short_R_sel_NZ1,1)
            if short_R_sel_NZ1 (i, 1:4)>0
                short_R2_sel_NZ1_logical (i,1) = short_R_sel_NZ1(i,26)>(PPG_variability_min/4);
                if PPGvar_acrossPlateaus_prctile_pcOfMax >30
                    short_R2_sel_NZ1_logical (i,2) = short_R_sel_NZ1(i,26)<(PPGvar_acrossPlateaus_prctile_pcOfMax*2);
                else
                    short_R2_sel_NZ1_logical (i,2) = short_R_sel_NZ1(i,26)< (PPGvar_acrossPlateaus_prctile_pcOfMax*3);
                    short_R2_sel_NZ1_logical2 (i,1)=short_R2_sel_NZ1_logical(i,1)==1  &short_R2_sel_NZ1_logical(i,2)==1;
                    short_R2_sel_NZ1b = short_R_sel_NZ1(short_R2_sel_NZ1_logical2, :);
                end
            end
        end
        if exist('short_R2_sel_NZ1b', 'var')
            short_R2_sel_NZ1 = cat (1, short_R2_sel_NZ1a, short_R2_sel_NZ1b);
        else
            short_R2_sel_NZ1 = short_R2_sel_NZ1a;
        end
    end
end
if isempty(short_R2_sel_NZ1)
    for i = 1:size(short_R_sel_NZ1,1)
        if short_R_sel_NZ1 (i, 1:4)>0
            short_R2_sel_NZ1_logical3 (i,1) = short_R_sel_NZ1(i,22)>(PPG_variability_min/2); % choose values with Rulse variability matches PPG var from col 22
            short_R2_sel_NZ1 = short_R_sel_NZ1(short_R2_sel_NZ1_logical3, :);
        end
    end
end
%%
if size(short_R2_sel_NZ1,1)>100
    while size(short_R2_sel_NZ1,1)>100
        short_R2_sel_NZ1_logical4 = [];
        Threshold_col_22 = round(mean(short_R2_sel_NZ1(:,22)));
        short_R2_sel_NZ1_logical4 = short_R2_sel_NZ1(:,22)<Threshold_col_22;
        short_R2_sel_NZ1(~short_R2_sel_NZ1_logical4, :)=[];
        continue
    end
end
%%
short_Q2R2_sel_NZ1_appendrow = ones(1, 28);
short_Q2R2_sel_NZ1 = cat (1, short_Q2_sel_NZ1,  short_Q2R2_sel_NZ1_appendrow, short_R2_sel_NZ1);

short_PQR_appendrow = ones(1, 28);
short_PQR_sel_NZ1 = cat (1, short_P2_sel_NZ1,   short_PQR_appendrow,  short_Q2R2_sel_NZ1);

%%
clearvars short2**;
clearvars short3**;
clearvars short4**;
clearvars short5**;
clearvars short6**;
clearvars short8**;
%%
short2_PQR_sel_NZ1 = [];

if ~isempty(short_PQR_sel_NZ1)
    % get ratio of sys var / dia var in column 29. Keep it less than 4
    for i = 1:size(short_PQR_sel_NZ1,1)
        short_PQR_sel_NZ1 (i,29) = (short_PQR_sel_NZ1 (i,27)/short_PQR_sel_NZ1 (i,28));
        short_PQR_sel_NZ1_logical (i,1) = short_PQR_sel_NZ1(i,29) < 3.5; % This was 3.2 earlier. But accounting for cases like Mallika, 24101801, I have increased this to 3.5
        short2_PQR_sel_NZ1 = short_PQR_sel_NZ1(short_PQR_sel_NZ1_logical, :);
    end
end

% Added on 18Sep2025
if sum(sum(short2_PQR_sel_NZ1(:,:)))== size(short2_PQR_sel_NZ1,1)*size(short2_PQR_sel_NZ1,2)
    if ~isempty(short_PQR_sel_NZ1)
        short_PQR_sel_NZ1_logical = [];
    % get ratio of sys var / dia var in column 29. Keep it less than 4
    for i = 1:size(short_PQR_sel_NZ1,1)
        short_PQR_sel_NZ1 (i,29) = (short_PQR_sel_NZ1 (i,27)/short_PQR_sel_NZ1 (i,28));
        short_PQR_sel_NZ1_logical (i,1) = short_PQR_sel_NZ1(i,29) < 4.5; 
        short2_PQR_sel_NZ1 = short_PQR_sel_NZ1(short_PQR_sel_NZ1_logical, :);
    end
    end
end
    
%%
% short list further based on C sys estimates
short3_PQR_sel_NZ1_C = [];

if ~isempty (short2_PQR_sel_NZ1)
    for i = 1:size(short2_PQR_sel_NZ1,1)
        short2_PQR_sel_NZ1_C_logical (i,1) = short2_PQR_sel_NZ1(i,1) > Pressure_selection(1,1) - 6 & short2_PQR_sel_NZ1(i,2) < Pressure_selection(1,2) + 6;
    end
    short3_PQR_sel_NZ1_C = short2_PQR_sel_NZ1(short2_PQR_sel_NZ1_C_logical, :);
end

short4_PQR_sel_NZ1_C = [];

if ~isempty(short3_PQR_sel_NZ1_C)
    for i = 1:size(short3_PQR_sel_NZ1_C,1)
        short3_PQR_sel_NZ1_C_logical (i,1) = short3_PQR_sel_NZ1_C(i,3) >= Pressure_selection(1,3)- 10 & short3_PQR_sel_NZ1_C(i,4) < Pressure_selection(1,4) + 10;
    end
    short4_PQR_sel_NZ1_C = short3_PQR_sel_NZ1_C(short3_PQR_sel_NZ1_C_logical, :);
end

if isempty(short4_PQR_sel_NZ1_C) && ~isempty(short3_PQR_sel_NZ1_C)
    short4_PQR_sel_NZ1_C = short3_PQR_sel_NZ1_C;
elseif isempty(short4_PQR_sel_NZ1_C) &&  ~isempty(short2_PQR_sel_NZ1)
    short4_PQR_sel_NZ1_C = short2_PQR_sel_NZ1;
end

%%
% short list further based on P sys estimates

for i = 1:size(short2_PQR_sel_NZ1,1)
    short2_PQR_sel_NZ1_P_logical (i,1) = short2_PQR_sel_NZ1(i,1) > Pressure_selection(2,1) - 6 & short2_PQR_sel_NZ1(i,2) < Pressure_selection(2,2) + 6;
    short3_PQR_sel_NZ1_P = short2_PQR_sel_NZ1(short2_PQR_sel_NZ1_P_logical, :);
end

% short list further based on P dia estimates
if ~isempty (short3_PQR_sel_NZ1_P)
    for i = 1:size(short3_PQR_sel_NZ1_P,1)
        short3_PQR_sel_NZ1_P_logical (i,1) = short3_PQR_sel_NZ1_P(i,3) > Pressure_selection(2,3) - 10 & short3_PQR_sel_NZ1_P(i,4) < Pressure_selection(2,4) + 10;
        short4_PQR_sel_NZ1_P = short3_PQR_sel_NZ1_P(short3_PQR_sel_NZ1_P_logical, :);
    end
else short4_PQR_sel_NZ1_P = short2_PQR_sel_NZ1;
end

if isempty (short4_PQR_sel_NZ1_P)
    short4_PQR_sel_NZ1_P = short3_PQR_sel_NZ1_P;
end

%% Short list rows where the difference of columns 1, 2 and 4 from the C sys low and high, and Cdiahigh estimates are minimal
% Because C low sys guess is very low (L point, which is at the peripheral diastolic) 
for i=1:size(short4_PQR_sel_NZ1_C,1) % In 10Sep2025 version 1, more weightage is given to dia
    short5_PQR_selAgain_NZ1_C (i, 1)= abs(short4_PQR_sel_NZ1_C (i,1)- Pressure_selection(1,1));
    short5_PQR_selAgain_NZ1_C (i, 2)= abs(short4_PQR_sel_NZ1_C (i,2)- Pressure_selection(1,2));
    short5_PQR_selAgain_NZ1_C (i, 3)= abs(short4_PQR_sel_NZ1_C (i,3)- Pressure_selection(1,3));
    short5_PQR_selAgain_NZ1_C (i, 4)= abs(short4_PQR_sel_NZ1_C (i,4)- Pressure_selection(1,4));
    short5_PQR_selAgain_NZ1_C(i, 5)= sum(short5_PQR_selAgain_NZ1_C(i, 1:4));
end

short4_PQR_sel_NZ1_C (:, 30:34) =   short5_PQR_selAgain_NZ1_C (:,:);
%%
% For central values
% minimum and average differences

PQR_C_minDiff = min (short4_PQR_sel_NZ1_C(:, 34)); % This one may remain unused
PQR_C_avgDiff = mean (short4_PQR_sel_NZ1_C (:, 34));

% Choose rows where the difference is below average difference

for i=1:size(short4_PQR_sel_NZ1_C,1)
    short5_PQR_selAgain_NZ1_C_logical(i, 1)= short5_PQR_selAgain_NZ1_C(i,5)< PQR_C_avgDiff;
end
short6_PQR_selAgain_NZ1_C = short4_PQR_sel_NZ1_C(short5_PQR_selAgain_NZ1_C_logical,:);

if isempty  (short6_PQR_selAgain_NZ1_C)
    short6_PQR_selAgain_NZ1_C =  short4_PQR_sel_NZ1_C;
end

if size(short6_PQR_selAgain_NZ1_C,1)>1 % This was necessary, because if there is only one row, after sorting, the row becomes empty
    short6_PQR_selAgain_NZ1_Csorted = sortrows(short6_PQR_selAgain_NZ1_C, 34);
else    short6_PQR_selAgain_NZ1_Csorted = short6_PQR_selAgain_NZ1_C;
end

%%
%To find unique multipliers in col 15 and 16 from short 6 sorted and pick
%the row with first occurrence

% Extract pairs from columns 15 and 16

multipliersC = [short6_PQR_selAgain_NZ1_Csorted(:, 15), short6_PQR_selAgain_NZ1_Csorted(:, 16)];

% Find unique pairs from C
[unique_multipliersC, ~, idx_C] = unique(multipliersC, 'rows');

% Initialize array to hold the selected rows from C
short8_C = zeros(size(unique_multipliersC, 1), size(short6_PQR_selAgain_NZ1_Csorted, 2));

% Loop through unique pairs and get the first occurrence in C
for i = 1:size(unique_multipliersC, 1)
    row_indexC = find(idx_C == i, 1); % Find the first occurrence
    short8_C(i, :) = short6_PQR_selAgain_NZ1_Csorted(row_indexC, :); % Store the row
end

%%
%%sorting based on column 34 has been rendered null due to the above. Sort
%%again

if size(short8_C,1)>1
    short8_Csorted = sortrows(short8_C, 34);
else short8_Csorted = short8_C;
end

%%
for i = 1: size(short8_Csorted, 1)
    short8_Csorted_straight_logical (i, 1) = (short8_Csorted(i,15)> short8_Csorted (i,16));
end
short8_Csorted_straight = short8_Csorted (short8_Csorted_straight_logical, :);

for i = 1: size(short8_Csorted, 1)
    short8_Csorted_crossed_logical (i, 1) = (short8_Csorted(i,15)< short8_Csorted (i,16));
end
short8_Csorted_crossed = short8_Csorted (short8_Csorted_crossed_logical, :);

%%
SpacerRow1 = ones(1, size(short8_Csorted_straight,2));
SpacerRow0 = zeros(1, size(short8_Csorted_straight,2));
short9_all = cat(1, short8_Csorted_straight, SpacerRow1, short8_Csorted_crossed); %, SpacerRow0, short8_Csorted_new_straight,SpacerRow1, short8_Csorted_new_crossed);

for i = 1: size(short9_all,1)
    if short9_all (i, 1:4)> 1
        short9_all (i, 35) = round(PPG_variability_avg - short9_all (i, 22));
        short9_all (i, 36) = round(PPGvar_acrossPlateaus_pcOfMax - short9_all (i, 26));
        short9_all (i, 37) = round(abs(short9_all (i, 35)) + abs(short9_all (i, 36)));
    else
        short9_all (i, 35:37) = NaN;
    end
end

short9_all_forThreshold = cat(1, short8_Csorted_straight, short8_Csorted_crossed);%, short8_Csorted_new_straight,short8_Csorted_new_crossed);
short9Threshold = max(mean(short9_all_forThreshold(:,30:33)));

for i= 1:size(short9_all,1)
    short9_all_logical(i,1)=any(short9_all(i,30:33)>short9Threshold);
end

short9_all=short9_all(~short9_all_logical,:);

for i = 2:size(short9_all,1)-1
    if short9_all(1,1) > 10
        Table_Results(1,1:34) = short9_all(1,1:34);
    elseif short9_all(i, 1)>10
        if all(short9_all(i-1, 1:4)==1)
            Table_Results(1,1:34) = short9_all(i,1:34);
            break
        end
    end
end

if ~exist('Table_Results', 'var')
    if ~isempty(short8_Csorted_straight)
        Table_Results(1,1:34) = short8_Csorted_straight(1,1:34);
    elseif ~isempty(short8_Csorted_crossed)
        Table_Results(1,1:34) = short8_Csorted_crossed(1,1:34);
    end
end

%% Short list rows where the difference of columns 1, 2 3 and 4 from Presure selection are minimal
% Because C low sys guess is very low (L point, which is at the peripheral diastolic)
for i=1:size(short4_PQR_sel_NZ1_P,1)
    short5_PQR_selAgain_NZ1_P (i, 1)= abs(short4_PQR_sel_NZ1_P (i,1)- Pressure_selection(2,1));
    short5_PQR_selAgain_NZ1_P (i, 2)= abs(short4_PQR_sel_NZ1_P (i,2)- Pressure_selection(2,2));
    short5_PQR_selAgain_NZ1_P (i, 3)= abs(short4_PQR_sel_NZ1_P (i,3)- Pressure_selection(2,3));
    short5_PQR_selAgain_NZ1_P (i, 4)= abs(short4_PQR_sel_NZ1_P (i,4)- Pressure_selection(2,4));
    short5_PQR_selAgain_NZ1_P(i, 5) = sum(short5_PQR_selAgain_NZ1_P(i, 1:4));
end

short4_PQR_sel_NZ1_P (:, 30:34) =   short5_PQR_selAgain_NZ1_P (:,:);
%%
% For central values
% minimum and average differences

PQR_P_minDiff = min (short4_PQR_sel_NZ1_P(:, 34)); % This one may remain unused
PQR_P_avgDiff = mean (short4_PQR_sel_NZ1_P (:, 34));

% Choose rows where the difference is below average difference

for i=1:size(short4_PQR_sel_NZ1_P,1)
    short5_PQR_selAgain_NZ1_P_logical(i, 1)= short5_PQR_selAgain_NZ1_P(i,5)< PQR_P_avgDiff;
end
short6_PQR_selAgain_NZ1_P = short4_PQR_sel_NZ1_P(short5_PQR_selAgain_NZ1_P_logical,:);

if isempty  (short6_PQR_selAgain_NZ1_P)
    short6_PQR_selAgain_NZ1_P =  short4_PQR_sel_NZ1_P;
end

if size(short6_PQR_selAgain_NZ1_P,1)>1 % This was necessary, because if there is only one row, after sorting, the row becomes empty
    short6_PQR_selAgain_NZ1_Psorted = sortrows(short6_PQR_selAgain_NZ1_P, 34);
else    short6_PQR_selAgain_NZ1_Psorted = short6_PQR_selAgain_NZ1_P;
end

%%
%To find unique multipliers in col 15 and 16 from short 6 sorted and pick
%the row with first occurrence

% Extract pairs from columns 15 and 16

multipliersP = [short6_PQR_selAgain_NZ1_Psorted(:, 15), short6_PQR_selAgain_NZ1_Psorted(:, 16)];

% Find unique pairs from C
[unique_multipliersP, ~, idx_P] = unique(multipliersP, 'rows');

% Initialize array to hold the selected rows from C
short8_P = zeros(size(unique_multipliersP, 1), size(short6_PQR_selAgain_NZ1_Psorted, 2));

% Loop through unique pairs and get the first occurrence in C
for i = 1:size(unique_multipliersP, 1)
    row_indexP = find(idx_P == i, 1); % Find the first occurrence
    short8_P(i, :) = short6_PQR_selAgain_NZ1_Psorted(row_indexP, :); % Store the row
end

%%
%%sorting based on column 34 has been rendered null due to the above. Sort
%%again

if size(short8_P,1)>1
    short8_Psorted = sortrows(short8_P, 34);
else short8_Psorted = short8_P;
end

%%
for i = 1: size(short8_Psorted, 1)
    short8_Psorted_straight_logical (i, 1) = (short8_Psorted(i,15)> short8_Psorted (i,16));
end
short8_Psorted_straight = short8_Psorted (short8_Psorted_straight_logical, :);

for i = 1: size(short8_Psorted, 1)
    short8_Psorted_crossed_logical (i, 1) = (short8_Psorted(i,15)< short8_Psorted (i,16));
end
short8_Psorted_crossed = short8_Psorted(short8_Psorted_crossed_logical, :);

%%
SpacerRow1 = ones(1, size(short8_Psorted_straight,2));
SpacerRow0 = zeros(1, size(short8_Psorted_straight,2));
short9_allP = cat(1, short8_Psorted_straight, SpacerRow1, short8_Psorted_crossed); %, SpacerRow0, short8_Csorted_new_straight,SpacerRow1, short8_Csorted_new_crossed);

for i = 1: size (short9_allP,1)
    if short9_allP (i, 1:4)> 1
        short9_allP (i, 35) = round(PPG_variability_avg - short9_allP (i, 22));
        short9_allP (i, 36) = round(PPGvar_acrossPlateaus_pcOfMax - short9_allP (i, 26));
        short9_allP (i, 37) = round(abs(short9_allP (i, 35)) + abs(short9_allP (i, 36)));
    else
        short9_allP (i, 35:37) = NaN;
    end
end

short9_allP_forThreshold = cat(1, short8_Psorted_straight, short8_Psorted_crossed);%, short8_Csorted_new_straight,short8_Csorted_new_crossed);
short9PThreshold = max(mean(short9_allP_forThreshold(:,30:33)));

for i= 1:size(short9_allP,1)
    short9_allP_logical(i,1)= any(any(short9_allP(i,30:33)>short9PThreshold));
end

short9_allP = short9_allP(~short9_allP_logical,:);

if isempty(short9_allP)
   short9_allP = cat(1, short8_Psorted_straight, SpacerRow1, short8_Psorted_crossed);
end

if short9_allP(1,1) > 10
    Table_Results(2,1:34) = short9_allP(1,1:34);
else
    for i = 2:size(short9_allP,1)-1
        if short9_allP(i, 1)>10
            if all(short9_allP(i-1, 1:4)==1)
                Table_Results(2,1:34) = short9_allP(i,1:34);
                break
            end
        end
    end
end
%%
if size(Table_Results,1)==1
    if ~isempty(short8_Psorted_straight)
        Table_Results(2,1:34) = short8_Psorted_straight(1,:);
    elseif ~isempty(short8_Psorted_crossed)
        Table_Results(2,1:34) = short8_Psorted_crossed(1,:);
    end
end

%%
%12Sep2025
%Sort based on difference from Pressure selection specifically for P. Dont worry about MAP.

Peripheral_newP        = P_without_MAP(comb_matrix1,Pressure_selection);
Peripheral_newQ        = P_without_MAP(comb_matrix1Q,Pressure_selection);
Peripheral_newR        = P_without_MAP(comb_matrix1R,Pressure_selection);
Peripheral_newP_cross  = P_without_MAP(comb_matrix1_cross,Pressure_selection);
Peripheral_newQ_cross  = P_without_MAP(comb_matrix1Q_cross,Pressure_selection);
Peripheral_newR_cross  = P_without_MAP(comb_matrix1R_cross,Pressure_selection);
Peripheral_newP_cross2 = P_without_MAP(comb_matrix1_cross2,Pressure_selection);
Peripheral_newQ_cross2 = P_without_MAP(comb_matrix1Q_cross2,Pressure_selection);
Peripheral_newR_cross2 = P_without_MAP(comb_matrix1R_cross2,Pressure_selection);

Central_newP = C_without_MAP(comb_matrix1,Pressure_selection);
Central_newQ = C_without_MAP(comb_matrix1Q,Pressure_selection);
Central_newR = C_without_MAP(comb_matrix1R,Pressure_selection);
Central_newP_cross  = C_without_MAP(comb_matrix1_cross,Pressure_selection);
Central_newQ_cross  = C_without_MAP(comb_matrix1Q_cross,Pressure_selection);
Central_newR_cross  = C_without_MAP(comb_matrix1R_cross,Pressure_selection);
Central_newP_cross2 = C_without_MAP(comb_matrix1_cross2,Pressure_selection);
Central_newQ_cross2 = C_without_MAP(comb_matrix1Q_cross2,Pressure_selection);
Central_newR_cross2 = C_without_MAP(comb_matrix1R_cross2,Pressure_selection);

%%
% Getting values without considering MAP (learning from 18092101 - the one with increasing damping)
Peripheral_newPQR = vertcat(Peripheral_newP, Peripheral_newQ, Peripheral_newR, Peripheral_newP_cross, Peripheral_newQ_cross, Peripheral_newR_cross, Peripheral_newP_cross2, Peripheral_newQ_cross2, Peripheral_newR_cross2);
Central_newPQR = vertcat(Central_newP, Central_newQ, Central_newR, Central_newP_cross, Central_newQ_cross, Central_newR_cross, Central_newP_cross2, Central_newQ_cross2, Central_newR_cross2);

for i = 1:size(Peripheral_newPQR,1)
    Peripheral_newPQR(i,29:32)= Pressure_selection(2, 1:4)- Peripheral_newPQR(i,1:4);
    Peripheral_newPQR(i,33)= sum(Peripheral_newPQR(i, 29:32));
    Peripheral_newPQR(i,34)= sum(abs(Peripheral_newPQR(i, 29:32)));  
end
[~,rI_Pnew_PQR]= min(Peripheral_newPQR(:,34));
Peripheral_new = Peripheral_newPQR(rI_Pnew_PQR, :);

for i = 1:size(Central_newPQR,1)
    Central_newPQR(i,29:32)= Pressure_selection(1, 1:4)- Central_newPQR(i,1:4);
    Central_newPQR(i,33)= sum(Central_newPQR(i, 29:32));
    Central_newPQR(i,34)= sum(abs(Central_newPQR(i, 29:32)));  
end
[~,rI_Cnew_PQR]= min(Central_newPQR(:,34));
Central_new = Central_newPQR(rI_Cnew_PQR, :);

%%
if exist('Central_new', 'var')
    Table_Results(3,1:28) =  Central_new(1, 1:28);
end

if exist('Peripheral_new', 'var')
    Table_Results(4,1:28) =  Peripheral_new(1, 1:28);
end
%%
startForHR = 20;% check figure 12 and mention time value in seconds
stopForHR = 360;

forHRV = pktrfref0_full_cleaned;
forHRV_select = forHRV(forHRV(:,2)>startForHR & forHRV(:,2)<stopForHR, :);
PktoPkinterval = diff(forHRV_select(:,2));

HR=[];
HR(:,1) = round(60./PktoPkinterval(:,1));

SSD_5_95pctile = round(quantile(HR(:,1),[.05 .95])); % for removing outliers
SSD_2_98pctile = round(quantile(HR(:,1),[.02 .98]));
%
HR_mean = round(mean(HR(:,1)));
HR(1:end-1,2) = diff(HR(:,1)); % deviations of successive heart rates
HR(:,3) = HR(:,2).*HR(:,2); % square of successive deviations

HR(:,4) = 1000.*PktoPkinterval(:,1); %intervals
HR(1:end-1,5)= diff(HR(:,4)); % deviations of successive intervals
HR(:,6)= HR(:,5).*HR(:,5); % square of successive deviations

MSSD = round(mean(HR(1:end-1,6))); % Mean square of successive deviations

RMSSD = round(sqrt(MSSD),2);% in milliseconds. This is the mean deviation in pulse interval between successive beats. Typically 20 to 50 milliseconds?
RMSSD_ln = round(log(RMSSD),2); % normal value is 3 to 6

HR_SD = round(std(HR(:,1)));
HR_min_2SD = round (HR_mean - 2*HR_SD);
HR_max_2SD = round (HR_mean + 2*HR_SD);

HR_2_98_percentile= round(quantile(HR(:,1),[.02 .98]));
HR_5_95_percentile= round(quantile(HR(:,1),[.05 .95]));
HR_20_80_percentile= round(quantile(HR(:,1),[.2 .8]));

HR_low = HR_2_98_percentile(1,1);
HR_high = HR_2_98_percentile(1,2);

% Heart rate data

labelHR = {'HR_mean', 'HR_SD','HR low_2 ', 'HR high_98 ', 'MSSD', 'RMSSD', 'RMSSD_ln'};
labelHR = string (labelHR);
resultsHR = [HR_mean, HR_SD, HR_low ,HR_high, MSSD, RMSSD,RMSSD_ln];

Table0_HR = cat(1,labelHR, resultsHR);
Table0_HR = Table0_HR';

%%
%%
% prompt = {'Enter Sphygmo Range):'};
% dlgtitle = 'Input Required';
% dims = [1 50];
% definput = {'400 600 300 400 '};  % Optional default input

% user_input = inputdlg(prompt, dlgtitle, dims, definput);
% 
% if isempty(user_input)
%     disp('User cancelled the input dialog.');
% else
%     % Convert input string to numeric array
%     input_str = user_input{1};
%     Sphygmo_Range = str2num(input_str);  %#ok<ST2NM> str2num allows space/tab-separated values
%     
%     % Check if conversion was successful
%     if isempty(Sphygmo_Range)
%         disp('Input was not a valid list of numbers.');
%     else
%         disp('Sphygmo_Range:');
%         disp(Sphygmo_Range);
%         
%         % Continue with your program using numeric_array
%         % Example: sum of the numbers
%         disp([num2str(sum(Sphygmo_Range))]);
%     end
% end
Sphygmo_Range = [400 600 300 400];

Sphygmo_sys_range = Sphygmo_Range(1,1:2);
Sphygmo_dia_range = Sphygmo_Range(1,3:4);

%%
Pressure_Report(1, 1:6) = Table_Results(1, 1:6);
Pressure_Report(2, 1:6) = Table_Results(2, 1:6);

Pressure_Report(1,7) = Pressure_Report(1,2)- Pressure_Report(1,1);
Pressure_Report(1,8) = Pressure_Report(1,4)- Pressure_Report(1,3);
Pressure_Report(1, 9)= Table_Results(1,15);
Pressure_Report(1, 10)= Table_Results(1,16);

Pressure_Report(2,7) = Pressure_Report(2,2)- Pressure_Report(2,1);
Pressure_Report(2,8) = Pressure_Report(2,4)- Pressure_Report(2,3);
Pressure_Report(2, 9)= Table_Results(2,15);
Pressure_Report(2, 10)= Table_Results(2,16);

Pressure_Report(3,1:8) = Pressure_Report(2,1:8)- Pressure_Report(1,1:8);

if size(Table_Results,1)>=3
    Pressure_Report(4,1:6)= Table_Results (3, 1:6);
    Pressure_Report(4,7) = Pressure_Report(4,2)- Pressure_Report(4,1);
    Pressure_Report(4,8) = Pressure_Report(4,4)- Pressure_Report(4,3);
    Pressure_Report(4, 9)= Table_Results(3,15);
    Pressure_Report(4, 10)= Table_Results(3,16);
end

if size(Table_Results,1)==4
    Pressure_Report(5,1:6)= Table_Results (4, 1:6);
    Pressure_Report(5,7) = Pressure_Report(5,2)- Pressure_Report(5,1);
    Pressure_Report(5,8) = Pressure_Report(5,4)- Pressure_Report(5,3);
    Pressure_Report(5, 9)= Table_Results(4,15);
    Pressure_Report(5, 10)= Table_Results(4,16);
end

Pressure_Report(6,1:8) = Pressure_Report(5,1:8)- Pressure_Report(4,1:8);

Pressure_Report(7,:) = Pressure_Report(1,:)- Pressure_Report(4,:);
Pressure_Report(8,:) = Pressure_Report(2,:)- Pressure_Report(5,:);

disp(Pressure_Report);

for j = 1:4
    if abs(Pressure_Report(7,j))<=3
        CentralPressures(1,j) = Pressure_Report(1,j);
    else
        CentralPressures(1,j)= 0;
    end
    
    if abs(Pressure_Report(8,j))<=3
        PeripheralPressures(1,j) = Pressure_Report(5,j);
    else
        PeripheralPressures(1,j)= 0;
    end
end
     Final_report = vertcat(CentralPressures, PeripheralPressures);
     disp('Final_report');
     disp(Final_report);

%%
Pressure_Report_25 = zeros(1,63);
Pressure_Report_25(1, 1:10)= Pressure_Report(1,1:10);
Pressure_Report_25(1, 12:21)= Pressure_Report(2,1:10);
Pressure_Report_25(1, 23:26)= Sphygmo_Range(1,1:4);

%For Bland Altman plots, mean of test and control
if Pressure_Report_25(1, 23) < 400    
    Pressure_Report_25(1, 28)= round(mean([Pressure_Report_25(1,1), Pressure_Report_25(1,23)])); %mean of mean of IAPsyslow and Csyslow
    Pressure_Report_25(1, 29)= round(mean([Pressure_Report_25(1,2), Pressure_Report_25(1,24)])); %mean of mean of IAPsyshigh and Csyshigh
    Pressure_Report_25(1, 30)= round(mean([Pressure_Report_25(1,3), Pressure_Report_25(1,25)])); %mean of mean of IAPdialow and Cdialow
    Pressure_Report_25(1, 31)= round(mean([Pressure_Report_25(1,4), Pressure_Report_25(1,26)])); %mean of mean of IAPdiahigh and Cdiahigh
    
    Pressure_Report_25(1, 33)= round(mean([Pressure_Report_25(1,12), Pressure_Report_25(1,23)])); %mean of mean of IAPsyslow and Psyslow
    Pressure_Report_25(1, 34)= round(mean([Pressure_Report_25(1,13), Pressure_Report_25(1,24)])); %mean of mean of IAPsyshigh and Psyshigh
    Pressure_Report_25(1, 35)= round(mean([Pressure_Report_25(1,14), Pressure_Report_25(1,25)])); %mean of mean of IAPdialow and Pdialow
    Pressure_Report_25(1, 36)= round(mean([Pressure_Report_25(1,15), Pressure_Report_25(1,26)])); %mean of mean of IAPdiahigh and Pdiahigh
else
    Pressure_Report_25(1,28:31)=NaN;
    Pressure_Report_25(1,33:36)=NaN;
end

%Caution: %The following code gives data as to whether within range or outside range for comparison with sphygmo or oscillometry
%Use different code for Differences of central from IBP for low and high sys, low and high dia

%Caution: %The following code gives data as to whether within range or outside range for comparison with sphygmo or oscillometry
%Use different code for Differences of central from IBP for low and high sys, low and high dia

for j = [23, 24]    % for [38, 39]
    if Pressure_Report_25(1, j) < 400
        if Pressure_Report_25(1, j) <  Pressure_Report_25(1, 1)
            Pressure_Report_25(1, j+15) = Pressure_Report_25(1,1) - Pressure_Report_25(1, j);
        end
        
        if Pressure_Report_25(1, j) >  Pressure_Report_25(1, 2)
            Pressure_Report_25(1, j+15) = Pressure_Report_25(1,2) - Pressure_Report_25(1, j);
        end
    else
        Pressure_Report_25(1, j+15) = NaN;
    end
end

for j = [25, 26]%for [40, 41]
    if Pressure_Report_25(1, j) < 250
        if Pressure_Report_25(1, j) <  Pressure_Report_25(1, 3)
            Pressure_Report_25(1, j+15) = Pressure_Report_25(1,3) - Pressure_Report_25(1, j);
        end
        if Pressure_Report_25(1, j) >  Pressure_Report_25(1, 4)
            Pressure_Report_25(1, j+15) = Pressure_Report_25(1,4) - Pressure_Report_25(1, j);
        end
    else
        Pressure_Report_25(1, j+15) = NaN;
    end
end

for j = [23, 24]    %for [43, 44]
    if Pressure_Report_25(1, j) < 400
        if Pressure_Report_25(1, j) <  Pressure_Report_25(1, 12)
            Pressure_Report_25(1, j+20) = Pressure_Report_25(1,12) - Pressure_Report_25(1, j);
        end
        
        if Pressure_Report_25(1, j) >  Pressure_Report_25(1, 13)
            Pressure_Report_25(1, j+20) = Pressure_Report_25(1,13) - Pressure_Report_25(1, j);
        end
    else
        Pressure_Report_25(1, j+20) = NaN;
    end
end

for j = [25, 26]%for [45, 46]
    if Pressure_Report_25(1, j) < 250
        if Pressure_Report_25(1, j) <  Pressure_Report_25(1, 14)
            Pressure_Report_25(1, j+20) = Pressure_Report_25(1,14) - Pressure_Report_25(1, j);
        end
        if Pressure_Report_25(1, j) >  Pressure_Report_25(1, 15)
            Pressure_Report_25(1, j+20) = Pressure_Report_25(1,15) - Pressure_Report_25(1, j);
        end
    else
        Pressure_Report_25(1, j+20) = NaN;
    end
end

%For Bland Altman plots of means of low and high sys
Pressure_Report_25(1, 48)= round(mean(Pressure_Report_25(1,1:2))); %mean of Csys
Pressure_Report_25(1, 49)= round(mean(Pressure_Report_25(1,3:4))); %mean of Cdia
Pressure_Report_25(1, 50)= round(mean(Pressure_Report_25(1,12:13))); %mean of Psys
Pressure_Report_25(1, 51)= round(mean(Pressure_Report_25(1,14:15))); %mean of Pdia

if Pressure_Report_25(1,23)< 400
    Pressure_Report_25(1, 52)= round(mean(Pressure_Report_25(1,23:24))); %mean of IAP sys
    Pressure_Report_25(1, 53)= round(mean(Pressure_Report_25(1,25:26))); %mean of IAP dia    
    Pressure_Report_25(1, 55)= round(mean([Pressure_Report_25(1,48), Pressure_Report_25(1,52)])); %mean of mean of IAPsys and Csys
    Pressure_Report_25(1, 56)= round(mean([Pressure_Report_25(1,49), Pressure_Report_25(1,53)])); %mean of mean of IAPdia and Cdia
    Pressure_Report_25(1, 57)= round(mean([Pressure_Report_25(1,50), Pressure_Report_25(1,52)])); %mean of mean of IAPsys and Psys
    Pressure_Report_25(1, 58)= round(mean([Pressure_Report_25(1,51), Pressure_Report_25(1,53)])); %mean of mean of IAPdia and Pdia
else
    Pressure_Report_25(1, 52:58)=NaN;
end

%Differences of mean
%For Reference and C  
%  Caution: earlier, when it had to be seen if the sphygmo falls within range the difference was ref - CMCNIBP (this very same section)
if Pressure_Report_25(1,23)< 400
    Pressure_Report_25(1, 60)= Pressure_Report_25(1, 48)-Pressure_Report_25(1, 52);%changed to C - reference. It was Reference - C earlier
    Pressure_Report_25(1, 61)= Pressure_Report_25(1, 49)-Pressure_Report_25(1, 53);
    
    %For IAP and P?
    Pressure_Report_25(1, 62)= Pressure_Report_25(1, 50)-Pressure_Report_25(1, 52);
    Pressure_Report_25(1, 63)= Pressure_Report_25(1, 51)-Pressure_Report_25(1, 53);
else
    Pressure_Report_25(1, 60:63)=NaN;
end

HRData = Table0_HR(1:4,2)';
Pressure_Report_25(1, 64:67)= str2double(HRData); %HR mean, sd, low and high

%%
%figure (305)

%ylim ([30, 220]);
%yticks ([30:5:220]);

%set(gca,'XMinorTick','on','YMinorTick','on')

%line([1, 2], [Pressure_Report_25(1,1), Pressure_Report_25(1,1)], 'Color', 'b' ,'LineStyle', '-'); %   C sys low
%line([1, 2], [Pressure_Report_25(1,2), Pressure_Report_25(1,2)], 'Color', 'b' , 'LineStyle', '-'); % C sys high
%line([1, 2], [Pressure_Report_25(1,3), Pressure_Report_25(1,3)], 'Color', 'b'  ,'LineStyle', '-'); %  C dia low from
%line([1, 2], [Pressure_Report_25(1,4), Pressure_Report_25(1,4)],'Color', 'b' , 'LineStyle', '-'); % C dia high

%line([1, 1.4], [HR_low,  HR_low], 'Color', 'k' , 'LineStyle', '-.'); % C mean high calc
%line([1, 1.4], [HR_high,  HR_high], 'Color', 'k' , 'LineStyle', '-.'); % C mean high calc

%line([3, 4],[Pressure_Report_25(1,23), Pressure_Report_25(1,23)], 'Color', 'r' ,'LineStyle', '-');
%line([3, 4],[Pressure_Report_25(1,24), Pressure_Report_25(1,24)], 'Color', 'r' ,'LineStyle', '-');
%line([3, 4],[Pressure_Report_25(1,25), Pressure_Report_25(1,25)], 'Color', 'r' ,'LineStyle', '-');
%line([3, 4],[Pressure_Report_25(1,26), Pressure_Report_25(1,26)], 'Color', 'r' ,'LineStyle', '-');

%line([2, 3],[Pressure_Report_25(1,12), Pressure_Report_25(1,12)], 'Color', DarkGreen ,'LineStyle', '-');
%line([2, 3],[Pressure_Report_25(1,13), Pressure_Report_25(1,13)], 'Color', DarkGreen ,'LineStyle', '-');
%line([2, 3],[Pressure_Report_25(1,14), Pressure_Report_25(1,14)], 'Color', DarkGreen ,'LineStyle', '-');
%line([2, 3],[Pressure_Report_25(1,15), Pressure_Report_25(1,15)], 'Color', DarkGreen ,'LineStyle', '-');

%grid on
%hold off
%title (expt_id);

%saveas(gcf,[expt_id 'fig305.fig']);

%%
Pressure_Report_35(1, 1:27)= Pressure_Report_25(1,1:27);
Pressure_Report_35(1, 28:39)= Pressure_Report_25(1,38:49);
Pressure_Report_35(1,40)= round(mean(Pressure_Report_35(1,5:6)));
Pressure_Report_35(1,43:44)= Pressure_Report_25(1,50:51);
Pressure_Report_35(1,45)= round(mean(Pressure_Report_35(1,16:17)));
Pressure_Report_35(1, 48:51)= Pressure_Report_25(1, 64:67); %HR mean, sd, low and high

%%
Pressure_Report_65(1,1:8)=Pressure_Report_35(1,1:8);
Pressure_Report_65(1,9:16)= Pressure_Report_35(1,12:19);
Pressure_Report_65(1,17:19)= Pressure_Report_35(1,38:40);
Pressure_Report_65(1,20:22)= Pressure_Report_35(1,43:45);
Pressure_Report_65(1,23:26)= Pressure_Report_35(1,48:51); %HR mean, sd, low and high

C_cutoffs =[130,80,98, 60];
P_cutoffs =[140,80,98, 70];

for i = 1:size(Pressure_Report_65,1)
    Pressure_Report_65(i,27)= C_cutoffs(1,1) - Pressure_Report_65(i,17);
    Pressure_Report_65(i,28)= C_cutoffs(1,2) - Pressure_Report_65(i,18);
    Pressure_Report_65(i,29)= C_cutoffs (1,3) - Pressure_Report_65(i,19);
    Pressure_Report_65(i,30)= Pressure_Report_65(i,17)- Pressure_Report_65(i,18);%pulse pressure C
    Pressure_Report_65(i,31)= C_cutoffs(1,4) - Pressure_Report_65(i,30);%pulse pressure C (56 was mean  + SD for nonhypertensives in this group
    
    if all(Pressure_Report_65(i,27:29)>0) || all(Pressure_Report_65(i,27:29)<=0)
        if Pressure_Report_65(i,31) < -4 %if Pulse pressure is too wide, take that into account as well
            Pressure_Report_65(i,32)= (0.2*Pressure_Report_65(i,27))+(0.3*Pressure_Report_65(i,28))+(0.45*Pressure_Report_65(i,29))+ (0.05*Pressure_Report_65(i,31));
        else
            Pressure_Report_65(i,32)= (0.2*Pressure_Report_65(i,27))+(0.3*Pressure_Report_65(i,28))+(0.5*Pressure_Report_65(i,29));
        end
    elseif Pressure_Report_65(i,27)<=0 && Pressure_Report_65(i,28)>0 %as in ISH; dont calculate average delta with dia; Use pulse pressure delta instead
        Pressure_Report_65(i,32)= (0.5*Pressure_Report_65(i,27))+(0.4*Pressure_Report_65(i,29))+(0.1*Pressure_Report_65(i,31));%giving more weightage to pulse pressure than before
    elseif Pressure_Report_65(i,27)>0 && Pressure_Report_65(i,28)<=0
        Pressure_Report_65(i,32)= (0.5*Pressure_Report_65(i,28))+(0.5*Pressure_Report_65(i,29));%using dia and MPressure_Report_65P for IDH
    end
    
    Pressure_Report_65(i,33)= P_cutoffs(1,1) - Pressure_Report_65(i,20);%systolic difference from cut off
    Pressure_Report_65(i,34)= P_cutoffs(1,2) - Pressure_Report_65(i,21); %diastolic difference from cut off
    Pressure_Report_65(i,35)= P_cutoffs(1,3) - Pressure_Report_65(i,22); %MPressure_Report_65P difference from cut off
    
    Pressure_Report_65(i,36)= Pressure_Report_65(i,20)- Pressure_Report_65(i,21);%pulse pressure P
    Pressure_Report_65(i,37)= P_cutoffs(1,4) - Pressure_Report_65(i,36);%pulse pressure delta
    
    if all(Pressure_Report_65(i,33:35)>0) || all(Pressure_Report_65(i,33:35)<=0)
        if Pressure_Report_65(i,37) < -4 %if Pulse pressure is too wide, take that into account as well
            Pressure_Report_65(i,38)= (0.2*Pressure_Report_65(i,33))+(0.3*Pressure_Report_65(i,34))+(0.45*Pressure_Report_65(i,35))+ (0.05*Pressure_Report_65(i,37));
        else
            Pressure_Report_65(i,38)= (0.2*Pressure_Report_65(i,33))+(0.3*Pressure_Report_65(i,34))+(0.5*Pressure_Report_65(i,35));
        end
    elseif Pressure_Report_65(i,33)<=0 && Pressure_Report_65(i,34)>0 %as in ISH; dont calculate average delta with dia; Use pulse pressure delta instead
        Pressure_Report_65(i,38)= (0.5*Pressure_Report_65(i,33))+(0.4*Pressure_Report_65(i,35))+(0.1*Pressure_Report_65(i,37));%giving more weightage to pulse pressure than the earlier statement
    elseif Pressure_Report_65(i,33)>0 && Pressure_Report_65(i,34)<=0
        Pressure_Report_65(i,38)= (0.5*Pressure_Report_65(i,34))+(0.5*Pressure_Report_65(i,35));%using dia and MPressure_Report_65P for IDH
    end
    
    if any(Pressure_Report_65(i,27:29)<=0)
        if Pressure_Report_65(i, 32)< -4
            Pressure_Report_65(i,39)=3; %Hypertension           
            
        elseif Pressure_Report_65(i, 32)>= -4 && Pressure_Report_65(i, 32)<=0 && Pressure_Report_65(i, 19)> C_cutoffs (1,3)
            Pressure_Report_65(i,39)=2; %Borderline hypertension
            
        elseif  Pressure_Report_65(i, 32)>= -4 && Pressure_Report_65(i, 32)<=0 && Pressure_Report_65(i, 19)<=C_cutoffs (1,3)
            Pressure_Report_65(i,39)=1; %High Normal
          
        elseif Pressure_Report_65(i, 32)>=0 && Pressure_Report_65(i, 32)<=4
            Pressure_Report_65(i,39)=1; % High normal
           
        elseif Pressure_Report_65(i, 32)>4
            Pressure_Report_65(i,39)=0; % normal           
        end
        
    elseif all(Pressure_Report_65(i,27:29)>0)
        if Pressure_Report_65(i, 32)<= 4
            Pressure_Report_65(i,39)=1; % High normal           
        else
            Pressure_Report_65(i,39)=0; % normal          
        end
    end
    
    if any(Pressure_Report_65(i,33:35)<=0)
        if Pressure_Report_65(i, 38)< -4
            Pressure_Report_65(i,41)=3; %Hypertension            
            
        elseif Pressure_Report_65(i, 38)>= -4 && Pressure_Report_65(i, 38)<=0 && Pressure_Report_65(i,22)> P_cutoffs (1,3)
            Pressure_Report_65(i,41)=2; %Borderline hypertension
            
        elseif Pressure_Report_65(i, 38)>= -4 && Pressure_Report_65(i, 38)<=0 && Pressure_Report_65(i,22)<= P_cutoffs (1,3)
            Pressure_Report_65(i,41)=1;
           
        elseif Pressure_Report_65(i, 38)>=0 && Pressure_Report_65(i, 38)<=4
            Pressure_Report_65(i,41)=1; % High normal
          
        elseif Pressure_Report_65(i, 38)>4
            Pressure_Report_65(i,41)=0; % normal
           
        end
    elseif all(Pressure_Report_65(i,33:35)>0)
        if Pressure_Report_65(i, 38)<= 4
            Pressure_Report_65(i,41)=1; % High normal         
        else
            Pressure_Report_65(i,41)=0; % normal           
        end
    end       
end

for i = 1:size(Pressure_Report_65,1)
    if Pressure_Report_65(i, 27)<=0 &&  Pressure_Report_65(i, 28)>0 % for central
        Pressure_Report_65(i,40)=1;%ISH
    elseif Pressure_Report_65(i, 27)>0 &&  Pressure_Report_65(i, 28)<=0
        Pressure_Report_65(i,40)=2;%IDH
    elseif Pressure_Report_65(i, 27)<=0 &&  Pressure_Report_65(i, 28)<=0
        Pressure_Report_65(i,40)=3;%EH
    else
        Pressure_Report_65(i,40)=0;%Normal
    end
    
    if Pressure_Report_65(i, 33)<=0 && Pressure_Report_65(i, 34)>0 % for peripheral
        Pressure_Report_65(i,42)=1;%ISH
    elseif Pressure_Report_65(i, 33)>0 && Pressure_Report_65(i, 34)<=0
        Pressure_Report_65(i,42)=2;%IDH
    elseif Pressure_Report_65(i, 33)<=0 && Pressure_Report_65(i, 34)<=0
        Pressure_Report_65(i,42)=3;%EH
    else
        Pressure_Report_65(i,42)=0;%Normal
    end
end

%%
Pressure_Report_26 = zeros(1,63);
Pressure_Report_26(1, 1:10)= Pressure_Report(4,1:10);
Pressure_Report_26(1, 12:21)= Pressure_Report(5,1:10);
Pressure_Report_26(1, 23:26)= Sphygmo_Range(1,1:4);

%For Bland Altman plots, mean of test and control
if Pressure_Report_26(1, 23) < 400    
    Pressure_Report_26(1, 28)= round(mean([Pressure_Report_26(1,1), Pressure_Report_26(1,23)])); %mean of mean of IAPsyslow and Csyslow
    Pressure_Report_26(1, 29)= round(mean([Pressure_Report_26(1,2), Pressure_Report_26(1,24)])); %mean of mean of IAPsyshigh and Csyshigh
    Pressure_Report_26(1, 30)= round(mean([Pressure_Report_26(1,3), Pressure_Report_26(1,25)])); %mean of mean of IAPdialow and Cdialow
    Pressure_Report_26(1, 31)= round(mean([Pressure_Report_26(1,4), Pressure_Report_26(1,26)])); %mean of mean of IAPdiahigh and Cdiahigh
    
    Pressure_Report_26(1, 33)= round(mean([Pressure_Report_26(1,12), Pressure_Report_26(1,23)])); %mean of mean of IAPsyslow and Psyslow
    Pressure_Report_26(1, 34)= round(mean([Pressure_Report_26(1,13), Pressure_Report_26(1,24)])); %mean of mean of IAPsyshigh and Psyshigh
    Pressure_Report_26(1, 35)= round(mean([Pressure_Report_26(1,14), Pressure_Report_26(1,25)])); %mean of mean of IAPdialow and Pdialow
    Pressure_Report_26(1, 36)= round(mean([Pressure_Report_26(1,15), Pressure_Report_26(1,26)])); %mean of mean of IAPdiahigh and Pdiahigh
else
    Pressure_Report_26(1,28:31)=NaN;
    Pressure_Report_26(1,33:36)=NaN;
end
%Caution: %The following code gives data as to whether within range or outside range for comparison with sphygmo or oscillometry
%Use different code for Differences of central from IBP for low and high sys, low and high dia

for j = [23, 24]    % for [38, 39]
    if Pressure_Report_26(1, j) < 400
        if Pressure_Report_26(1, j) <  Pressure_Report_26(1, 1)
            Pressure_Report_26(1, j+15) = Pressure_Report_26(1,1) - Pressure_Report_26 (1, j);
        end
        
        if Pressure_Report_26(1, j) >  Pressure_Report_26(1, 2)
            Pressure_Report_26(1, j+15) = Pressure_Report_26(1,2) - Pressure_Report_26 (1, j);
        end
    else
        Pressure_Report_26(1, j+15) = NaN;
    end
end

for j = [25, 26]%for [40, 41]
    if Pressure_Report_26(1, j) < 250
        if Pressure_Report_26(1, j) <  Pressure_Report_26(1, 3)
            Pressure_Report_26(1, j+15) = Pressure_Report_26 (1,3) - Pressure_Report_26 (1, j);
        end
        if Pressure_Report_26(1, j) >  Pressure_Report_26(1, 4)
            Pressure_Report_26(1, j+15) = Pressure_Report_26(1,4) - Pressure_Report_26 (1, j);
        end
    else
        Pressure_Report_26(1, j+15) = NaN;
    end
end

for j = [23, 24]    %for [43, 44]
    if Pressure_Report_26(1, j) < 400
        if Pressure_Report_26(1, j) <  Pressure_Report_26(1, 12)
            Pressure_Report_26(1, j+20) = Pressure_Report_26(1,12) - Pressure_Report_26(1, j);
        end
        
        if Pressure_Report_26(1, j) >  Pressure_Report_26(1, 13)
            Pressure_Report_26(1, j+20) = Pressure_Report_26(1,13) - Pressure_Report_26(1, j);
        end
    else
        Pressure_Report_26(1, j+20) = NaN;
    end
end

for j = [25, 26]%for [45, 46]
    if Pressure_Report_26(1, j) < 250
        if Pressure_Report_26(1, j) <  Pressure_Report_26(1, 14)
            Pressure_Report_26(1, j+20) = Pressure_Report_26(1,14) - Pressure_Report_26(1, j);
        end
        if Pressure_Report_26(1, j) >  Pressure_Report_26(1, 15)
            Pressure_Report_26(1, j+20) = Pressure_Report_26(1,15) - Pressure_Report_26(1, j);
        end
    else
        Pressure_Report_26(1, j+20) = NaN;
    end
end


%For Bland Altman plots of means of low and high sys
Pressure_Report_26(1, 48)= round(mean(Pressure_Report_26(1,1:2))); %mean of Csys
Pressure_Report_26(1, 49)= round(mean(Pressure_Report_26(1,3:4))); %mean of Cdia
Pressure_Report_26(1, 50)= round(mean(Pressure_Report_26(1,12:13))); %mean of Psys
Pressure_Report_26(1, 51)= round(mean(Pressure_Report_26(1,14:15))); %mean of Pdia

if Pressure_Report_26(1,23)< 400
    Pressure_Report_26(1, 52)= round(mean(Pressure_Report_26(1,23:24))); %mean of IAP sys
    Pressure_Report_26(1, 53)= round(mean(Pressure_Report_26(1,25:26))); %mean of IAP dia    
    Pressure_Report_26(1, 55)= round(mean([Pressure_Report_26(1,48), Pressure_Report_26(1,52)])); %mean of mean of IAPsys and Csys
    Pressure_Report_26(1, 56)= round(mean([Pressure_Report_26(1,49), Pressure_Report_26(1,53)])); %mean of mean of IAPdia and Cdia
    Pressure_Report_26(1, 57)= round(mean([Pressure_Report_26(1,50), Pressure_Report_26(1,52)])); %mean of mean of IAPsys and Psys
    Pressure_Report_26(1, 58)= round(mean([Pressure_Report_26(1,51), Pressure_Report_26(1,53)])); %mean of mean of IAPdia and Pdia
else
    Pressure_Report_26(1, 52:58)=NaN;
end

%Differences of mean
%For Reference and C  
%  Caution: earlier, when it had to be seen if the sphygmo falls within range the difference was ref - CMCNIBP (this very same section)
if Pressure_Report_26(1,23)< 400
    Pressure_Report_26(1, 60)= Pressure_Report_26(1, 48)-Pressure_Report_26(1, 52);%changed to C - reference. It was Reference - C earlier
    Pressure_Report_26(1, 61)= Pressure_Report_26(1, 49)-Pressure_Report_26(1, 53);
    
    %For IAP and P?
    Pressure_Report_26(1, 62)= Pressure_Report_26(1, 50)-Pressure_Report_26(1, 52);
    Pressure_Report_26(1, 63)= Pressure_Report_26(1, 51)-Pressure_Report_26(1, 53);
else
    Pressure_Report_26(1, 60:63)=NaN;
end

HRData = Table0_HR(1:4,2)';
Pressure_Report_26(1, 64:67)= str2double(HRData); %HR mean, sd, low and high

%%
%figure (306)

%ylim ([30, 220]);
%yticks ([30:5:220]);

%set(gca,'XMinorTick','on','YMinorTick','on')

%line([1, 2], [Pressure_Report_26(1,1), Pressure_Report_26(1,1)], 'Color', 'b' ,'LineStyle', '-'); %   C sys low
%line([1, 2], [Pressure_Report_26(1,2), Pressure_Report_26(1,2)], 'Color', 'b' , 'LineStyle', '-'); % C sys high
%line([1, 2], [Pressure_Report_26(1,3), Pressure_Report_26(1,3)], 'Color', 'b'  ,'LineStyle', '-'); %  C dia low from
%line([1, 2], [Pressure_Report_26(1,4), Pressure_Report_26(1,4)],'Color', 'b' , 'LineStyle', '-'); % C dia high

%line([1, 1.4], [HR_low,  HR_low], 'Color', 'k' , 'LineStyle', '-.'); % C mean high calc
%line([1, 1.4], [HR_high,  HR_high], 'Color', 'k' , 'LineStyle', '-.'); % C mean high calc

%line([3, 4],[Pressure_Report_26(1,23), Pressure_Report_26(1,23)], 'Color', 'r' ,'LineStyle', '-');
%line([3, 4],[Pressure_Report_26(1,24), Pressure_Report_26(1,24)], 'Color', 'r' ,'LineStyle', '-');
%line([3, 4],[Pressure_Report_26(1,25), Pressure_Report_26(1,25)], 'Color', 'r' ,'LineStyle', '-');
%line([3, 4],[Pressure_Report_26(1,26), Pressure_Report_26(1,26)], 'Color', 'r' ,'LineStyle', '-');

%line([2, 3],[Pressure_Report_26(1,12), Pressure_Report_26(1,12)], 'Color', DarkGreen ,'LineStyle', '-');
%line([2, 3],[Pressure_Report_26(1,13), Pressure_Report_26(1,13)], 'Color', DarkGreen ,'LineStyle', '-');
%line([2, 3],[Pressure_Report_26(1,14), Pressure_Report_26(1,14)], 'Color', DarkGreen ,'LineStyle', '-');
%line([2, 3],[Pressure_Report_26(1,15), Pressure_Report_26(1,15)], 'Color', DarkGreen ,'LineStyle', '-');

%grid on
%hold off
%title (expt_id);

%saveas(gcf,[expt_id 'fig306.fig']);

%%
Pressure_Report_27(1, 1:11)= Pressure_Report_25(1, 1:11);%Take central values from 25 (considering MAP)
% Be careful in choice of peripheral
PR25_OR_26(1,1)= Pressure_Report_25(1,12) >= Pressure_Report_25(1,1); % Is Psys from 25 better or 26 better?
PR25_OR_26(1,2)= Pressure_Report_25(1,13) >= Pressure_Report_25(1,2);
PR25_OR_26(2,1)= Pressure_Report_26(1,12) >= Pressure_Report_25(1,1);
PR25_OR_26(2,2)= Pressure_Report_26(1,13) >= Pressure_Report_25(1,2);

PR25_OR_26(1,3)= Pressure_Report_25(1,14) <= Pressure_Report_25(1,3)+4; % Is Pdia from 25 better or 26 better?
PR25_OR_26(1,4)= Pressure_Report_25(1,15) <= Pressure_Report_25(1,4)+4;
PR25_OR_26(2,3)= Pressure_Report_26(1,14) <= Pressure_Report_25(1,3)+4;
PR25_OR_26(2,4)= Pressure_Report_26(1,15) <= Pressure_Report_25(1,4)+4;

for j = 1:2
    sumPR25_OR_26(j,1)= PR25_OR_26(j,1)+ PR25_OR_26(j,2);
    sumPR25_OR_26(j,2)= PR25_OR_26(j,3)+ PR25_OR_26(j,4);
    sumPR25_OR_26(j,3)= sumPR25_OR_26(j,1)+ sumPR25_OR_26(j,2);
end

if sumPR25_OR_26(1,3)>= sumPR25_OR_26(2,3)
    Pressure_Report_27(1, 12:27)= Pressure_Report_25(1, 12:27);
else
    Pressure_Report_27(1, 12:27)= Pressure_Report_26(1, 12:27);
end

disp('sumPR25_OR_26');
disp(sumPR25_OR_26);

%For Bland Altman plots, mean of test and control
if Pressure_Report_27(1, 23) < 400    
    Pressure_Report_27(1, 28)= round(mean([Pressure_Report_27(1,1), Pressure_Report_27(1,23)])); %mean of mean of IAPsyslow and Csyslow
    Pressure_Report_27(1, 29)= round(mean([Pressure_Report_27(1,2), Pressure_Report_27(1,24)])); %mean of mean of IAPsyshigh and Csyshigh
    Pressure_Report_27(1, 30)= round(mean([Pressure_Report_27(1,3), Pressure_Report_27(1,25)])); %mean of mean of IAPdialow and Cdialow
    Pressure_Report_27(1, 31)= round(mean([Pressure_Report_27(1,4), Pressure_Report_27(1,26)])); %mean of mean of IAPdiahigh and Cdiahigh
    
    Pressure_Report_27(1, 33)= round(mean([Pressure_Report_27(1,12), Pressure_Report_27(1,23)])); %mean of mean of IAPsyslow and Psyslow
    Pressure_Report_27(1, 34)= round(mean([Pressure_Report_27(1,13), Pressure_Report_27(1,24)])); %mean of mean of IAPsyshigh and Psyshigh
    Pressure_Report_27(1, 35)= round(mean([Pressure_Report_27(1,14), Pressure_Report_27(1,25)])); %mean of mean of IAPdialow and Pdialow
    Pressure_Report_27(1, 36)= round(mean([Pressure_Report_27(1,15), Pressure_Report_27(1,26)])); %mean of mean of IAPdiahigh and Pdiahigh
else
    Pressure_Report_27(1,28:31)=NaN;
    Pressure_Report_27(1,33:36)=NaN;
end

%Caution: %The following code gives data as to whether within range or outside range for comparison with sphygmo or oscillometry
%Use different code for Differences of central from IBP for low and high sys, low and high dia

for j = [23, 24]    % for [38, 39]
    if Pressure_Report_27(1, j) < 400
        if Pressure_Report_27(1, j) <  Pressure_Report_27(1, 1)
            Pressure_Report_27(1, j+15) = Pressure_Report_27(1,1) - Pressure_Report_27 (1, j);
        end
        
        if Pressure_Report_27(1, j) >  Pressure_Report_27(1, 2)
            Pressure_Report_27(1, j+15) = Pressure_Report_27(1,2) - Pressure_Report_27 (1, j);
        end
    else
        Pressure_Report_27(1, j+15) = NaN;
    end
end

for j = [25, 26]%for [40, 41]
    if Pressure_Report_27(1, j) < 250
        if Pressure_Report_27(1, j) <  Pressure_Report_27(1, 3)
            Pressure_Report_27(1, j+15) = Pressure_Report_27 (1,3) - Pressure_Report_27 (1, j);
        end
        if Pressure_Report_27(1, j) >  Pressure_Report_27(1, 4)
            Pressure_Report_27(1, j+15) = Pressure_Report_27(1,4) - Pressure_Report_27 (1, j);
        end
    else
        Pressure_Report_27(1, j+15) = NaN;
    end
end

for j = [23, 24]    %for [43, 44]
    if Pressure_Report_27(1, j) < 400
        if Pressure_Report_27(1, j) <  Pressure_Report_27(1, 12)
            Pressure_Report_27(1, j+20) = Pressure_Report_27(1,12) - Pressure_Report_27(1, j);
        end
        
        if Pressure_Report_27(1, j) >  Pressure_Report_27(1, 13)
            Pressure_Report_27(1, j+20) = Pressure_Report_27(1,13) - Pressure_Report_27(1, j);
        end
    else
        Pressure_Report_27(1, j+20) = NaN;
    end
end

for j = [25, 26]%for [45, 46]
    if Pressure_Report_27(1, j) < 250
        if Pressure_Report_27(1, j) <  Pressure_Report_27(1, 14)
            Pressure_Report_27(1, j+20) = Pressure_Report_27(1,14) - Pressure_Report_27(1, j);
        end
        if Pressure_Report_27(1, j) >  Pressure_Report_27(1, 15)
            Pressure_Report_27(1, j+20) = Pressure_Report_27(1,15) - Pressure_Report_27(1, j);
        end
    else
        Pressure_Report_27(1, j+20) = NaN;
    end
end
%For Bland Altman plots of means of low and high sys
Pressure_Report_27(1, 48)= round(mean(Pressure_Report_27(1,1:2))); %mean of Csys
Pressure_Report_27(1, 49)= round(mean(Pressure_Report_27(1,3:4))); %mean of Cdia
Pressure_Report_27(1, 50)= round(mean(Pressure_Report_27(1,12:13))); %mean of Psys
Pressure_Report_27(1, 51)= round(mean(Pressure_Report_27(1,14:15))); %mean of Pdia

if Pressure_Report_27(1,23)< 400
    Pressure_Report_27(1, 52)= round(mean(Pressure_Report_27(1,23:24))); %mean of IAP sys
    Pressure_Report_27(1, 53)= round(mean(Pressure_Report_27(1,25:26))); %mean of IAP dia    
    Pressure_Report_27(1, 55)= round(mean([Pressure_Report_27(1,48), Pressure_Report_27(1,52)])); %mean of mean of IAPsys and Csys
    Pressure_Report_27(1, 56)= round(mean([Pressure_Report_27(1,49), Pressure_Report_27(1,53)])); %mean of mean of IAPdia and Cdia
    Pressure_Report_27(1, 57)= round(mean([Pressure_Report_27(1,50), Pressure_Report_27(1,52)])); %mean of mean of IAPsys and Psys
    Pressure_Report_27(1, 58)= round(mean([Pressure_Report_27(1,51), Pressure_Report_27(1,53)])); %mean of mean of IAPdia and Pdia
else
    Pressure_Report_27(1, 52:58)=NaN;
end

%Differences of mean
%For Reference and C  
%  Caution: earlier, when it had to be seen if the sphygmo falls within range the difference was ref - CMCNIBP (this very same section)
if Pressure_Report_27(1,23)< 400
    Pressure_Report_27(1, 60)= Pressure_Report_27(1, 48)-Pressure_Report_27(1, 52);%changed to C - reference. It was Reference - C earlier
    Pressure_Report_27(1, 61)= Pressure_Report_27(1, 49)-Pressure_Report_27(1, 53);
    
    %For Reference and P?
    Pressure_Report_27(1, 62)= Pressure_Report_27(1, 50)-Pressure_Report_27(1, 52);
    Pressure_Report_27(1, 63)= Pressure_Report_27(1, 51)-Pressure_Report_27(1, 53);
else
    Pressure_Report_27(1, 60:63)=NaN;
end

HRData = Table0_HR(1:4,2)';
Pressure_Report_27(1, 64:67)= str2double(HRData); %HR mean, sd, low and high

%%
%figure (307)

%ylim ([30, 220]);
%yticks ([30:5:220]);

%set(gca,'XMinorTick','on','YMinorTick','on')

%line([1, 2], [Pressure_Report_27(1,1), Pressure_Report_27(1,1)], 'Color', 'b' ,'LineStyle', '-'); %   C sys low
%line([1, 2], [Pressure_Report_27(1,2), Pressure_Report_27(1,2)], 'Color', 'b' , 'LineStyle', '-'); % C sys high
%line([1, 2], [Pressure_Report_27(1,3), Pressure_Report_27(1,3)], 'Color', 'b'  ,'LineStyle', '-'); %  C dia low from
%line([1, 2], [Pressure_Report_27(1,4), Pressure_Report_27(1,4)],'Color', 'b' , 'LineStyle', '-'); % C dia high

%line([1, 1.4], [HR_low,  HR_low], 'Color', 'k' , 'LineStyle', '-.'); % C mean high calc
%line([1, 1.4], [HR_high,  HR_high], 'Color', 'k' , 'LineStyle', '-.'); % C mean high calc

%line([3, 4],[Pressure_Report_27(1,23), Pressure_Report_27(1,23)], 'Color', 'r' ,'LineStyle', '-');
%line([3, 4],[Pressure_Report_27(1,24), Pressure_Report_27(1,24)], 'Color', 'r' ,'LineStyle', '-');
%line([3, 4],[Pressure_Report_27(1,25), Pressure_Report_27(1,25)], 'Color', 'r' ,'LineStyle', '-');
%line([3, 4],[Pressure_Report_27(1,26), Pressure_Report_27(1,26)], 'Color', 'r' ,'LineStyle', '-');

%line([2, 3],[Pressure_Report_27(1,12), Pressure_Report_27(1,12)], 'Color', DarkGreen ,'LineStyle', '-');
%line([2, 3],[Pressure_Report_27(1,13), Pressure_Report_27(1,13)], 'Color', DarkGreen ,'LineStyle', '-');
%line([2, 3],[Pressure_Report_27(1,14), Pressure_Report_27(1,14)], 'Color', DarkGreen ,'LineStyle', '-');
%line([2, 3],[Pressure_Report_27(1,15), Pressure_Report_27(1,15)], 'Color', DarkGreen ,'LineStyle', '-');

%grid on
%hold off
%title (expt_id);

%saveas(gcf,[expt_id 'fig307.fig']);

%%
Pressure_Report_36(1, 1:27)= Pressure_Report_26(1,1:27);
Pressure_Report_36(1, 28:39)= Pressure_Report_26(1,38:49);
Pressure_Report_36(1,40)= round(mean(Pressure_Report_36(1,5:6)));
Pressure_Report_36(1,43:44)= Pressure_Report_26(1,50:51);
Pressure_Report_36(1,45)= round(mean(Pressure_Report_36(1,16:17)));
Pressure_Report_36(1, 48:51)= Pressure_Report_26(1, 64:67); %HR mean, sd, low and high

%%
Pressure_Report_66(1,1:8)=Pressure_Report_36(1,1:8);
Pressure_Report_66(1,9:16)= Pressure_Report_36(1,12:19);
Pressure_Report_66(1,17:19)= Pressure_Report_36(1,38:40);
Pressure_Report_66(1,20:22)= Pressure_Report_36(1,43:45);
Pressure_Report_66(1,23:26)= Pressure_Report_36(1,48:51); %HR mean, sd, low and high

C_cutoffs =[130,80,98, 60];
P_cutoffs =[140,80,98, 70];

for i = 1:size(Pressure_Report_66,1)
    Pressure_Report_66(i,27)= C_cutoffs(1,1) - Pressure_Report_66(i,17);
    Pressure_Report_66(i,28)= C_cutoffs(1,2) - Pressure_Report_66(i,18);
    Pressure_Report_66(i,29)= C_cutoffs (1,3) - Pressure_Report_66(i,19);
    Pressure_Report_66(i,30)= Pressure_Report_66(i,17)- Pressure_Report_66(i,18);%pulse pressure C
    Pressure_Report_66(i,31)= C_cutoffs(1,4) - Pressure_Report_66(i,30);%pulse pressure C (56 was mean  + SD for nonhypertensives in this group
    
    if all(Pressure_Report_66(i,27:29)>0) || all(Pressure_Report_66(i,27:29)<=0)
        if Pressure_Report_66(i,31) < -4 %if Pulse pressure is too wide, take that into account as well
            Pressure_Report_66(i,32)= (0.2*Pressure_Report_66(i,27))+(0.3*Pressure_Report_66(i,28))+(0.45*Pressure_Report_66(i,29))+ (0.05*Pressure_Report_66(i,31));
        else
            Pressure_Report_66(i,32)= (0.2*Pressure_Report_66(i,27))+(0.3*Pressure_Report_66(i,28))+(0.5*Pressure_Report_66(i,29));
        end
    elseif Pressure_Report_66(i,27)<=0 && Pressure_Report_66(i,28)>0 %as in ISH; dont calculate average delta with dia; Use pulse pressure delta instead
        Pressure_Report_66(i,32)= (0.5*Pressure_Report_66(i,27))+(0.4*Pressure_Report_66(i,29))+(0.1*Pressure_Report_66(i,31));%giving more weightage to pulse pressure than before
    elseif Pressure_Report_66(i,27)>0 && Pressure_Report_66(i,28)<=0
        Pressure_Report_66(i,32)= (0.5*Pressure_Report_66(i,28))+(0.5*Pressure_Report_66(i,29));%using dia and MPressure_Report_66P for IDH
    end
    
    Pressure_Report_66(i,33)= P_cutoffs(1,1) - Pressure_Report_66(i,20);%systolic difference from cut off
    Pressure_Report_66(i,34)= P_cutoffs(1,2) - Pressure_Report_66(i,21); %diastolic difference from cut off
    Pressure_Report_66(i,35)= P_cutoffs(1,3) - Pressure_Report_66(i,22); %MPressure_Report_66P difference from cut off
    
    Pressure_Report_66(i,36)= Pressure_Report_66(i,20)- Pressure_Report_66(i,21);%pulse pressure P
    Pressure_Report_66(i,37)= P_cutoffs(1,4) - Pressure_Report_66(i,36);%pulse pressure delta
    
    if all(Pressure_Report_66(i,33:35)>0) || all(Pressure_Report_66(i,33:35)<=0)
        if Pressure_Report_66(i,37) < -4 %if Pulse pressure is too wide, take that into account as well
            Pressure_Report_66(i,38)= (0.2*Pressure_Report_66(i,33))+(0.3*Pressure_Report_66(i,34))+(0.45*Pressure_Report_66(i,35))+ (0.05*Pressure_Report_66(i,37));
        else
            Pressure_Report_66(i,38)= (0.2*Pressure_Report_66(i,33))+(0.3*Pressure_Report_66(i,34))+(0.5*Pressure_Report_66(i,35));
        end
    elseif Pressure_Report_66(i,33)<=0 && Pressure_Report_66(i,34)>0 %as in ISH; dont calculate average delta with dia; Use pulse pressure delta instead
        Pressure_Report_66(i,38)= (0.5*Pressure_Report_66(i,33))+(0.4*Pressure_Report_66(i,35))+(0.1*Pressure_Report_66(i,37));%giving more weightage to pulse pressure than the earlier statement
    elseif Pressure_Report_66(i,33)>0 && Pressure_Report_66(i,34)<=0
        Pressure_Report_66(i,38)= (0.5*Pressure_Report_66(i,34))+(0.5*Pressure_Report_66(i,35));%using dia and MPressure_Report_66P for IDH
    end
    
    if any(Pressure_Report_66(i,27:29)<=0)
        if Pressure_Report_66(i, 32)< -4
            Pressure_Report_66(i,39)=3; %Hypertension           
            
        elseif Pressure_Report_66(i, 32)>= -4 && Pressure_Report_66(i, 32)<=0 && Pressure_Report_66(i, 19)> C_cutoffs (1,3)
            Pressure_Report_66(i,39)=2; %Borderline hypertension
            
        elseif  Pressure_Report_66(i, 32)>= -4 && Pressure_Report_66(i, 32)<=0 && Pressure_Report_66(i, 19)<=C_cutoffs (1,3)
            Pressure_Report_66(i,39)=1; %High Normal
          
        elseif Pressure_Report_66(i, 32)>=0 && Pressure_Report_66(i, 32)<=4
            Pressure_Report_66(i,39)=1; % High normal
           
        elseif Pressure_Report_66(i, 32)>4
            Pressure_Report_66(i,39)=0; % normal           
        end
        
    elseif all(Pressure_Report_66(i,27:29)>0)
        if Pressure_Report_66(i, 32)<= 4
            Pressure_Report_66(i,39)=1; % High normal           
        else
            Pressure_Report_66(i,39)=0; % normal          
        end
    end
    
    if any(Pressure_Report_66(i,33:35)<=0)
        if Pressure_Report_66(i, 38)< -4
            Pressure_Report_66(i,41)=3; %Hypertension            
            
        elseif Pressure_Report_66(i, 38)>= -4 && Pressure_Report_66(i, 38)<=0 && Pressure_Report_66(i,22)> P_cutoffs (1,3)
            Pressure_Report_66(i,41)=2; %Borderline hypertension
            
        elseif Pressure_Report_66(i, 38)>= -4 && Pressure_Report_66(i, 38)<=0 && Pressure_Report_66(i,22)<= P_cutoffs (1,3)
            Pressure_Report_66(i,41)=1;
           
        elseif Pressure_Report_66(i, 38)>=0 && Pressure_Report_66(i, 38)<=4
            Pressure_Report_66(i,41)=1; % High normal
          
        elseif Pressure_Report_66(i, 38)>4
            Pressure_Report_66(i,41)=0; % normal
           
        end
    elseif all(Pressure_Report_66(i,33:35)>0)
        if Pressure_Report_66(i, 38)<= 4
            Pressure_Report_66(i,41)=1; % High normal         
        else
            Pressure_Report_66(i,41)=0; % normal           
        end
    end       
end

for i = 1:size(Pressure_Report_66,1)
    if Pressure_Report_66(i, 27)<=0 &&  Pressure_Report_66(i, 28)>0 % for central
        Pressure_Report_66(i,40)=1;%ISH
    elseif Pressure_Report_66(i, 27)>0 &&  Pressure_Report_66(i, 28)<=0
        Pressure_Report_66(i,40)=2;%IDH
    elseif Pressure_Report_66(i, 27)<=0 &&  Pressure_Report_66(i, 28)<=0
        Pressure_Report_66(i,40)=3;%EH
    else
        Pressure_Report_66(i,40)=0;%Normal
    end
    
    if Pressure_Report_66(i, 33)<=0 && Pressure_Report_66(i, 34)>0 % for peripheral
        Pressure_Report_66(i,42)=1;%ISH
    elseif Pressure_Report_66(i, 33)>0 && Pressure_Report_66(i, 34)<=0
        Pressure_Report_66(i,42)=2;%IDH
    elseif Pressure_Report_66(i, 33)<=0 && Pressure_Report_66(i, 34)<=0
        Pressure_Report_66(i,42)=3;%EH
    else
        Pressure_Report_66(i,42)=0;%Normal
    end
end

%%
Pressure_Report_37(1, 1:27)= Pressure_Report_27(1,1:27);
Pressure_Report_37(1, 28:39)= Pressure_Report_27(1,38:49);
Pressure_Report_37(1,40)= round(mean(Pressure_Report_37(1,5:6)));
Pressure_Report_37(1,43:44)= Pressure_Report_27(1,50:51);
Pressure_Report_37(1,45)= round(mean(Pressure_Report_37(1,16:17)));
Pressure_Report_37(1, 48:51)= Pressure_Report_27(1, 64:67); %HR mean, sd, low and high

%%
Pressure_Report_67(1,1:8)=Pressure_Report_37(1,1:8);% central
Pressure_Report_67(1,9:16)= Pressure_Report_37(1,12:19);%peripheral

Pressure_Report_67(1,17:19)= Pressure_Report_37(1,38:40); % means centra;sys dia and MPressure_Report_67P
Pressure_Report_67(1,20)= Pressure_Report_37(1,17)- Pressure_Report_37(1,17) ; % PP central

Pressure_Report_67(1,21:23)= Pressure_Report_37(1,43:45); % means peripheral
Pressure_Report_67(1,24:27)= Pressure_Report_37(1,48:51); %HR mean, sd, low and high

Mean_forC_cutoffs = [111,69,84,42]; % These were generated from 77/84 naive (excluding HT from sphygmo)from data of the 100 dataset
SD_forC_cutoffs =    [10,9,8,10] ;

%Diagnosis for central
    for j = [17,18,19,20] % get into 28, 29, 30, 31 for C sys, Cdia, MPressure_Report_67P and C PP
        if Pressure_Report_67(1, j)<=  round(Mean_forC_cutoffs(1,j-16)+ 0.5*(SD_forC_cutoffs(1, j-16)))
            Pressure_Report_67(1,j+11) = 0;
            
        elseif Pressure_Report_67(1,j)> round(Mean_forC_cutoffs(1,j-16)+ 0.5*(SD_forC_cutoffs(1, j-16))) && Pressure_Report_67(1, j)<= round(Mean_forC_cutoffs(1,j-16)+ SD_forC_cutoffs(1, j-16))
            Pressure_Report_67(1,j+11) = 1;
            
        elseif Pressure_Report_67(1,j)> round(Mean_forC_cutoffs(1,j-16)+ SD_forC_cutoffs(1, j-16)) && Pressure_Report_67(1, j)<= round(Mean_forC_cutoffs(1,j-16)+ 1.5*(SD_forC_cutoffs(1, j-16)))
            Pressure_Report_67(1,j+11) = 2;
            
        elseif Pressure_Report_67(1,j)> round(Mean_forC_cutoffs(1,j-16)+ 1.5*(SD_forC_cutoffs(1, j-16))) && Pressure_Report_67(1, j)<= round(Mean_forC_cutoffs(1,j-16)+ 2*(SD_forC_cutoffs(1, j-16)))
            Pressure_Report_67(1,j+11) = 3;
            
        elseif Pressure_Report_67(1,j)> round(Mean_forC_cutoffs(1,j-16)+ 2*(SD_forC_cutoffs(1, j-16))) && Pressure_Report_67(1,j)<= round(Mean_forC_cutoffs(1,j-16)+ 2.5*(SD_forC_cutoffs(1, j-16)))
            Pressure_Report_67(1,j+11) = 4;
        elseif Pressure_Report_67(1,j)> round(Mean_forC_cutoffs(1,j-16)+ 2.5*(SD_forC_cutoffs(1, j-16)))
            Pressure_Report_67(1,j+11) = 5;
        end
    end

    Pressure_Report_67 (1,32)= sum(Pressure_Report_67(1,28:31)); %sum of sys and PP scores    
  
    %classification into HT or NT
    if  Pressure_Report_67(1,32)>9
        Pressure_Report_67(1,33)=1;
    elseif (Pressure_Report_67(1,28)+ Pressure_Report_67(1,31))>6 % if PP is high and sys slightly high
        Pressure_Report_67(1,33)=1;
    elseif  Pressure_Report_67(1,32)>6 % if total score more than 6
        if (Pressure_Report_67(1,29) + Pressure_Report_67(1,30))>5 || Pressure_Report_67(1,31)>4 %if dia and MPressure_Report_67P scores together more than 4
            Pressure_Report_67(1,33)=1;
        end
    else
        Pressure_Report_67(1,33)=0;

    %typing the BP profile
    if Pressure_Report_67(1,33)==1
        if  Pressure_Report_67(1,28)>3 && Pressure_Report_67(1,29)<=3% If diagnosis is HT, and dia is low, as well as MPressure_Report_67P, and PP is not too high
            Pressure_Report_67(1,34)=1; % ISH
        elseif Pressure_Report_67(1,28)<=3 && Pressure_Report_67(1,29)> 3 
            Pressure_Report_67(1,34)=2; % IDH
        elseif Pressure_Report_67(1,28)>3 && Pressure_Report_67(1,29)>3
            Pressure_Report_67(1,34)=3; % Essential HT
        elseif (Pressure_Report_67(1,28)<=3 && Pressure_Report_67(1,31)>4) && Pressure_Report_67(1,28)<3 && Pressure_Report_67(1,29)<3
            Pressure_Report_67(1,34)=-1; % looks like normotensive,but very low compliance and high PP, may be HT. In this, sphygmo dia may be near MPressure_Report_67P
        else
            Pressure_Report_67(1,34)=0;
        end
    end
    
    if  Pressure_Report_67(1,31)>3
        Pressure_Report_67(1,35)=-1; % wide PP
    end
    end

%%
NameFile = string(date);
today_date =  datetime('today');
save(NameFile, 'today_date', 'expt_id', 'Table0_HR', 'Pressure_Report', 'Pressure_Report_25','Pressure_Report_35','Pressure_Report_65','Pressure_Report_26','Pressure_Report_36','Pressure_Report_66','Pressure_Report_27','Pressure_Report_37','Pressure_Report_67','short9_all', 'Sys_Dia_matrix', 'Pressure_selection', 'LSP', 'HSP', 'SysEarlyArray', 'DiaEarlyArray', 'results_PPGvar', 'PSysDiaMay2025','PPGdelta', 'Sphygmo_Range');

toc
