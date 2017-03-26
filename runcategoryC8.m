%%%%% NOTE: THIS IS A QUICK ADAPTATION OF AN OLD SCRIPT THAT RAN CATEGORYC8.
%%%%%       THIS MUST BE CHECKED AND PROBABLY MODIFIED BEFORE ACTUAL USE.

%%% consider rebooting. turn off network, energy saver, software updates, quit applications
%%% do a test run to make sure it will actually work.
%%% can the person actually fixate?

% % check calibration images 
% oldclut = pton([1280 800 0 32],[],'cni_lcd');
% offset = ptviewimage('/research/figures/calibrationimages/*.png',[1 0],0);
% ptoff(oldclut);

%% setup
%ptonparams      = {[1920 1080 120 24],[],0};                                    
ptonparams      = {[],[],0};                                    


offset          = [];
movieflip       = [0 0];  % [1 0] is necessary for flexi mirror to show up right-side up
%   movieflip = [0 0];
frameduration   = 15;  %%15 for 60hz, 30 for 120hz
  % .175 size, 1 ON 1 OFF, omit disc, (1/9.6)/2 will repeat (but up to 2), 3 extra entries, white/black alternation
fixationinfo    = {{.175 [1 1] 1 -(1/9.6)/2 3 1}};  %%OLD [1 0]
fixationsize    = 64;  % 1/12.5*800
%tfun = [];
%tfun = @() assert(StartScan(0.010)==0);
tfunNOEYE = @() fprintf('STIMULUS STARTED.\n');
tfunEYE = @() cat(2,fprintf('STIMULUS STARTED.\n'),Eyelink('Message','SYNCTIME'));
  % BOLDSCREEN (intentionally linear CLUT since the monitor already linearizes itself)

%soafun = @() round(7*(60/frameduration) + 2*(2*(rand-.5))*(60/frameduration));  % 7 +/- 2 is [5,9],
soafun = @() round(7*(120/frameduration) + 2*(2*(rand-.5))*(120/frameduration));  % 7 +/- 2 is [5,9]
skiptrials      = 0;
grayval         = uint8(161);
con             = 100;
trialparams     = {1/2 uint8([255 0 0]) 20 0 -2};  %%OLD last entry 1,

%%%%%%%%%%%%%%%% path stuff

addpath(genpath(strrep(which('runcategoryC8'),'runcategoryC8.m','knkutils')));
stimulusdir = strrep(which('runcategoryC8'),'runcategoryC8.m','stimulusfiles');

%%%%%%%%%%%%%%%%

%% PRE-RUN TO GET PHYSICAL STIMULUS GENERATED.  [to run a test, just edit the filename.]
% Note that when storing these MASTERrun.mat files, the movieflip that is used is in a sense hard-
% coded into the files.  Thus, you cannot mix and match different movieflip types!
images = [];
todos = repmat([66],[1 4]);
for p=1:length(todos)
  filename = sprintf('MASTERrun%02d.mat',p);
  eyefilename = [];
  images = showmulticlass(filename,offset,movieflip,frameduration,fixationinfo,fixationsize,tfunNOEYE, ...
                          ptonparams,soafun,skiptrials,images,todos(p),[],grayval,[],[],con, ...
                          [],[],'5',[],trialparams,eyefilename,[],[],stimulusdir);
  close all;
end

%% FOR TRAINING THE SUBJECT, HERE ARE TWO TEST RUNS WITH EYETRACKING
images = [];
todos = repmat([66],[1 2]);
for p=1:length(todos)
  filenameMASTER = sprintf('MASTERrun%02d.mat',p);
  filename = sprintf('test%02d.mat',p);
  eyefilename = sprintf('testeye%02d.edf',p);
  images = showmulticlass(filename,offset,movieflip,frameduration,fixationinfo,fixationsize,tfunEYE, ...
                          ptonparams,soafun,skiptrials,images,todos(p),[],grayval,[],[],con, ...
                          ['' filenameMASTER],[],'5',[],trialparams,eyefilename,[],[],stimulusdir);
  close all;
end

%% NOW SET UP THE ACTUAL EXPERIMENT
% consider using exactly the same stimulus (frames / trial order) as some other session (see MP20110930).
% use safe mode to guard against triggers!
images = [];
for q=1:3  % 3 sets of 4
  todos = repmat([66],[1 4]);
  for p=1:length(todos)
    filenameMASTER = sprintf('MASTERrun%02d.mat',p);
    filename = sprintf('run%02d.mat',(q-1)*4+p);
    eyefilename = sprintf('eye%02d.edf',(q-1)*4+p);
    images = showmulticlass(filename,offset,movieflip,frameduration,fixationinfo,fixationsize,tfunEYE, ...
                            ptonparams,soafun,skiptrials,images,todos(p),[],grayval,[],[],con, ...
                            ['' filenameMASTER],[],'5',[],trialparams,eyefilename,[],[],stimulusdir);
    close all;
  end
end


% remove path
rmpath(genpath(strrep(which('runcategoryC8'),'runcategoryC8.m','knkutils')));
% % check timing
% a = load('test.mat');
% mean(diff(a.timeframes))*2
