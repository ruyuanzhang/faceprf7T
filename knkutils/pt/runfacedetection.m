% runfacedetection
% 
% No editing of this script is required.  Just run it.
% Outputs are saved to a .mat file in the current working directory.

% Experiments to choose from:
% #5 is SIMPLEGENDER:    [8 5 1], prime then face (100% contrast); 9x9; judge gender; measure accuracy and RT
% #7 is SIMPLEGENDERALT: [8 5 8], prime then face (10%  contrast); 9x9; judge gender; measure accuracy and RT
% #8 is GENDERCON:       [8 5 8], prime then face (different con); 3x3; judge gender; measure accuracy and RT
% #9 is SPOKES:          [8 5 8], prime then face (100% contrast); judge gender; measure accuracy and RT; 50% size
%                        center and 8 angs * 5 rings = 41 conditions
%                        eccentricities: 0 1 3 5.5 8.5 12
% #10 is SPOKESMED:      same as #9 except 2/3*50% size and just horizontal meridian
% #11 is SPOKESSM:       same as #9 except 1/3*50% size and just horizontal meridian.
% #12 is SPOKESDET:      same as #9 except detect face.  alternative is phase-scrambled face (0% coherence) matched for lum and con.
% #13 is SPOKESSZ:       same as #9 except only at center and various sizes
% #14 is SPOKESWORD:     same as #9 but with word and lexical decision task
% #15 is HORIZONTALR:    [8 5 8], prime then face (100% contrast); judge gender; matched to 6° of faceprf;
%                        center and 7 pos to the right = 8 conditions (linspace(-20,20,15))
% #16 is HORIZONTALL:    " but to the left = 8 conditions
% #17 is DETECTIONR:     like HORIZONTALR but perform detection (phase-scrambled face, 0% coherence)
% #18 is DETECTIONL:     " but to the left = 8 conditions
% #19 is GENDERCUER:     similar to #15 but with cue and non-cue (digits) cases and shorter face duration
% #20 is GENDERCUEL:     " but to the left
% #21 is ODDBALLCUER:    similar to #19 but the task is oddball
% #22 is ODDBALLCUEL:    " but to the left

% history:
% - 2015/09/01 - add experiments 19-22
% - 2015/04/22 - add experiments 15,16,17,18; now press spacebar to start; give text warning when
%                eye-tracking data are being transferred
% - 2014/11/30 - add expt #14
% - 2014/11/28 - finalized #12. version 1.2.
% - 2014/11/27 - implement #12, #13
% - 2014/11/26 - version 1.1.
% - 2014/11/26 - add eyelink and general improvements
% - 2014/11/23 - implement expt #10, #11
% - 2014/11/22 - implement expt #9
% - 2014/11/21 - implement fcon (multiple contrast levels) and experiment #8
% - 2014/11/19 - version 1.0.  remove detectinput (unnecessary baggage);
%                now handle end of movie input in the same way (KbCheck) to avoid missed inputs;
%                now avoid acausal keypresses (i.e. before the actual stimulus frame comes on the screen)
% - 2014/11/18 - institute extra blank frame at the end; we now immediately exit at the last iteration
% - 2014/11/18 - now, we detect responses during the actual movie
% - 2014/11/18 - add stimrecord

% things to implement:

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% setup

% ask about display
heightofscreen = input('What is the height of your screen in inches? ');
viewingdistance = input('What is your viewing distance in inches? ');

% ask about eyetracking
wanteyetrack = input('Are you recording eye-tracking data (0=no, 1=yes)? ');
eyelinkfile = 'run01.edf';  % dummy file name that we will change after we receive the file

% which experiment to run
expttype = input(['Which experiment to run? ']);

% get screen resolution
screennum = max(Screen('Screens'));  % we assume we are operating on screen with maximum number
temp = Screen('Resolution',screennum);
temp = [temp.width temp.height temp.hz temp.pixelSize];
fprintf('Detected %s as the display setting for screen %d.\n',mat2str(temp),screennum);
ptonparams = {temp,[],-1};  % resolution, [], gamma setting

% is the screen big enough?
tfov = 2*atan((heightofscreen/2) / viewingdistance)/pi*180;  % total size of display in vertical direction (deg)
tfovH = tfov * (ptonparams{1}(1)/ptonparams{1}(2));          % total size of display in horizontal direction (deg)
fprintf('Your vertical screen size is %.2f deg.\n',tfov);
fprintf('Your horizontal screen size is %.2f deg.\n',tfovH);
switch expttype
case {5 7 8}
  fovok = tfov >= 21.5;
case {9 10 11 12 13 14}
  fovok = tfov >= 27;
case {15 16 17 18 19 20 21 22}
  % after 66.415% scaling, 283 pt for edge to edge of niko.  that's 4.422 deg for edge to edge.
  % that means you need at least 4.422 + 20 deg = 24.422 deg extent.  let's round up to say 25 deg.
  fovok = tfovH >= 25;
end
if ~fovok
  error('Sorry, your screen size is not big enough.');
end

% get subject initials
subjnum = input('What are your initials? (e.g. KK) ','s');

% get dataset identifier
dataset = input('What dataset should we create (or continue from)? (e.g. data1) ','s');

% calc some stuff
res =  ptonparams{1}(2);       % full vertical display resolution in pixels
resH = ptonparams{1}(1);       % full horizontal display resolution in pixels
cfac = tfov/res;               % conversion factor to take pixels to deg
dfac = 1/cfac;                 % conversion factor to take deg to pixels

% figure out fixation dot size
fixationdeg = 0.1;                               % total diameter in degrees
fixationsize = [round(fixationdeg*dfac/2)*2 0];  % dot diameter (pixels), border width (pixels)

% figure out fixation digit/letter size
fixationsymboldeg = 0.5;                                  % total diameter in degrees
fixationsymbolsize = round(fixationsymboldeg*dfac/2)*2;   % total diameter in pixels

% take the larger of the two [and allow doubling for room for anti-aliasing]
fixationtotalsize = 2*max(fixationsize(1),fixationsymbolsize);   % total size in pixels to use for fixationimage

% constants
grayval = 127;
fixationcolor = [255 255 255;    % regular fixation dot color (white);
                 255   0   0];   % fixation dot color when paused (red)
triggerkey = 115;   % key to start the experiment (115 = spacebar)
onekey = 'f';       % button 1
twokey = 'j';       % button 2
digitkey = 'space'; % button 3
stimulusdir = strrep(which('runfacedetection.m'),'/runfacedetection.m','/');
altstimulusdir = '~/kendrick/stimulusfiles/';    % alternative location
breaktime = 60;    % how long in seconds until a break

% more constants
switch expttype
case {5 7 8 9 10 11 12 13 14 15 16 17 18}
  frameduration = 6;
case {19 20 21 22}
  frameduration = 2;  % probably won't ever want to go below this so leave it at 2, which means 30 Hz
% case 6
%   frameduration = 6;
end

% some more, experiment-specific
switch expttype
case {5 7 8 9 10 11 12 13 15 16 17 18 19 20 21 22}
  stimlabels = [2 1 1 1 1 1 1 1 2 1 1 2 2 2 2 2 2 2 2 1 2 1 1 2 1 1 2 1 2 2 2 2 1 1 1 1 1 2 2 1 1 2 1 1 2 2 1 1 2 2 1 2 1 2 1 1 1 2 1 1 2 2 1 1 2 1 1 2 2 1 1 2 2 2 2 2 2 2 1 1 1 2 2 2 1 2 1 2 2 1 2 1];  % all 92 (1=male, 2=female)
    % totalset = [24 92 31 8 42 21 91 25 55 85 15 50 51 27 30 39 26 2 88 87 29 68 53 49 72 69 67 22 75 57 44 16 19 36 48 10 78 33 7 35 4 61 46 83 38 70 54 77 74 60 28 3 11 80 64 66 40 43 52 79];  % just hard code it!
  totalset = 1:92;   % use all the faces
case {14}
      % REFERENCE:
      %   verbcheck = loadtext('/research/reading/words/C/3words_verb.txt');
      %   ttt = cellfun(@str2double,verbcheck)
      %   mat2str(ttt)  % this is stimlabels
      %   find(ttt==1)
      %   mat2str(sort(picksubset(find(ttt==2),46)))  % this is nonverbs (46 only)
      %   nonverbs = [8 9 10 17 22 26 28 42 43 51 55 58 64 65 66 68 69 71 72 73 76 83 84 86 88 91 93 94 95 99 108 109 112 116 120 121 123 124 125 128 134 137 144 148 149 150];
      %   mat2str(find(ttt==1))  % this is verbs
      %   verbs = [1 2 3 5 6 15 16 18 19 23 27 29 33 35 38 41 44 50 53 57 67 70 77 78 81 82 89 97 102 103 105 106 107 110 111 113 115 117 122 127 131 136 138 143 146 147];
      %   totalset = sort([nonverbs verbs]);  % this is the complete vector of indices to use
      %   mat2str(totalset)
  stimlabels = [1 1 1 2 1 1 0 2 2 2 0 0 2 2 1 1 2 1 1 0 0 2 1 0 2 2 1 2 1 0 2 2 1 0 1 2 0 1 0 0 1 2 2 1 0 0 0 2 2 1 2 0 1 2 2 0 1 2 0 0 0 0 2 2 2 2 1 2 2 1 2 2 2 2 0 2 1 1 2 0 1 1 2 2 2 2 0 2 1 0 2 2 2 2 2 0 1 2 2 2 0 1 1 0 1 1 1 2 2 1 1 2 1 0 1 2 1 0 0 2 2 1 2 2 2 0 1 2 2 2 1 0 0 2 0 1 2 1 2 0 0 2 1 2 2 1 1 2 2 2];  % 0=don't use, 1=verb, 2=non-verb
  stimlabels = (stimlabels==1) + 1;        % now, verbs are button 2 and everything else is button 1
  totalset = [1 2 3 5 6 8 9 10 15 16 17 18 19 22 23 26 27 28 29 33 35 38 41 42 43 44 50 51 53 55 57 58 64 65 66 67 68 69 70 71 72 73 76 77 78 81 82 83 84 86 88 89 91 93 94 95 97 99 102 103 105 106 107 108 109 110 111 112 113 115 116 117 120 121 122 123 124 125 127 128 131 134 136 137 138 143 144 146 147 148 149 150];
end
vstep = 0.671875;  % in deg (vertical)
hstep = 0.609375;  % in deg (horizontal)
origsz = 12.5;  % original vertical size of stimuli (in deg)

% generate locations to test
alllocs = {};
switch expttype
case {5 7}  % 6
  vidx = 4:-1:-4;  % top to bottom
  hidx = -4:4;     % left to right
  %   vidx = [2 0 -2];     % top to bottom
  %   hidx = [-2 0 2];     % left to right
  %   vidx = [0];     % top to bottom
  %   hidx = [0];     % left to right
  for p=1:length(hidx)
    for q=1:length(vidx)
      alllocs{end+1} = [vidx(q)*vstep hidx(p)*hstep];
    end
  end
  angs = linspacecircular(0,2*pi,8);  % 8 angles
  for p=1:length(angs)
    alllocs{end+1} = [sin(angs(p))*8 cos(angs(p))*8];  % 8 deg from the center
  end
case {8}
  vidx = 4:-4:-4;  % top to bottom
  hidx = -4:4:4;     % left to right
  for p=1:length(hidx)
    for q=1:length(vidx)
      alllocs{end+1} = [vidx(q)*vstep hidx(p)*hstep];
    end
  end
case {9 12 14}
  eccs = [0 1 3 5.5 8.5 12];
  angs = linspacecircular(0,2*pi,8);  % 8 angles
  for p=1:length(eccs)
    for q=1:length(angs)
      if p==1 && q>1
        continue;
      end
      alllocs{end+1} = [sin(angs(q))*eccs(p) cos(angs(q))*eccs(p)];
    end
  end
case {13}
  alllocs{end+1} = [0 0];
case {10 11}
  eccs = [0 1 3 5.5 8.5 12];
  angs = linspacecircular(0,2*pi,2);
  for p=1:length(eccs)
    for q=1:length(angs)
      if p==1 && q>1
        continue;
      end
      alllocs{end+1} = [sin(angs(q))*eccs(p) cos(angs(q))*eccs(p)];
    end
  end
case {15 16 17 18 19 20 21 22}
  eccs = linspace(0,20,8);
  if ismember(expttype,[15 17 19 21])
    angs = 0;
  elseif ismember(expttype,[16 18 20 22])
    angs = pi;
  end
  for p=1:length(eccs)
    for q=1:length(angs)
      if p==1 && q>1
        continue;
      end
      alllocs{end+1} = [sin(angs(q))*eccs(p) cos(angs(q))*eccs(p)];
    end
  end
end

% QUEST stuff
getSecsFunction = 'GetSecs';
tGuessFun = @() rand-2;  % random in the range [-2,-1]
tGuessSd = 2;
pThreshold=0.82;
beta=3.5; delta=0.01; gamma=0.5;

% stimulus design
switch expttype
case 5
  timing = [8 5 1];  % 800 ms primer, 500 ms gap, 100 ms face
  pcon = 100;     % contrast multiplier for noise
  fcon = 100;     % contrast multiplier for face
  testtime = 14;  % frame at which test stimulus appears
  fsiz = 1;
% case 6
%   timing = [8 5 1 5 1];  % 200 ms delay, 1000 ms face
%   pcon = 100;      % contrast multiplier for noise
%   ncon = 0;
%   testtime = 16;   % frame at which test stimulus appears
case 7
  timing = [8 5 8];  % 800 ms primer, 500 ms gap, 800 ms face
  pcon = 100;     % contrast multiplier for noise
  fcon = 10;     % contrast multiplier for face
  testtime = 14;  % frame at which test stimulus appears
  fsiz = 1;
case 8
  timing = [8 5 8];  % 800 ms primer, 500 ms gap, 800 ms face
  pcon = 100;     % contrast multiplier for noise
  fcon = [4 6 10 20 40 100];
  testtime = 14;  % frame at which test stimulus appears
  fsiz = 1;
case {9 14}
  timing = [8 5 8];  % 800 ms primer, 500 ms gap, 800 ms face
  pcon = 100;     % contrast multiplier for noise
  fcon = 100;
  testtime = 14;  % frame at which test stimulus appears
  fsiz = 0.5;
case 10
  timing = [8 5 8];  % 800 ms primer, 500 ms gap, 800 ms face
  pcon = 100;     % contrast multiplier for noise
  fcon = 100;
  testtime = 14;  % frame at which test stimulus appears
  fsiz = 0.5*2/3;
case 11
  timing = [8 5 8];  % 800 ms primer, 500 ms gap, 800 ms face
  pcon = 100;     % contrast multiplier for noise
  fcon = 100;
  testtime = 14;  % frame at which test stimulus appears
  fsiz = 0.5*1/3;
case 12
  timing = [8 5 8];  % 800 ms primer, 500 ms gap, 800 ms face
  pcon = 100;     % contrast multiplier for noise
  fcon = 100;     % both the face and the scrambled face are at this contrast
  testtime = 14;  % frame at which test stimulus appears
  fsiz = 0.5;
  validprop = 500/800;  % valid proportion of original stimuli to use in phase-scrambling
case 13
  timing = [8 5 8];  % 800 ms primer, 500 ms gap, 800 ms face
  pcon = 100;     % contrast multiplier for noise
  fcon = 100;
  testtime = 14;  % frame at which test stimulus appears
  fsiz = [0.5*[1/3 2/3 1] 1:.5:5];
case {15 16 17 18}
  % medium size faceprf faces are 26.5/66*(378*2/3)*2   *(12.5/800) = 3.1619 deg
  % to get it at 6 deg, we effectively did: 6/3.1619 = 189.757% enlargement
  % in illustrator, determined 35% scaling of niko faces to match medium size (eye range)
  % so, the net is 189.757% x 35% = 66.415%.
  % this means that if we apply 66.415% to niko faces, this will be in effect 6 deg faces.
  timing = [8 5 8];
  pcon = 100;
  fcon = 100;
  testtime = 14;
  fsiz = 0.66415;
  validprop = 500/800;
case {19 20 21 22}
  letterdur = 15;        % letter indicator lasts for 500 ms
  lettergap = 15;        % 500 ms gap before digits start
  facedur =  6;          % duration of face (6->3->2->1->sub?)
  facedur2 = 6;          % duration of post-face mask
  wantdigits = 1;        % use the fixation digit mechanism
  digitsize = 0.5;       % font size in (0,1) which is relative to fixationtotalsize. 0.5 because we do doubling
    % CUE CASE:
  cuedummy = 30;         % 1 s of dummy digits before the cue comes up
  timing = [3*8 3*5];    % in the cue case, 800ms cue, 500ms gap, and then face after that
    % NON-CUE (DIGIT) CASE:
  mindigitlen = 60;      % in the digit case, at least this much of digiting before the face can even come up
  digitrng = 3*30;       % after mindigitlen, the face can appear after a delay chosen uniformly between 0 s and this
    % continue...
  digitrate = 4;         % each digit is shown for this long, and each gap is this long
  probdigit = 0.2;       % probability of a digit repetition (and we enforce up to a maximum of two in a row)
  digitresp = 1;         % time in seconds that the subject has to respond
  pcon = 100;
  fcon = [1 2];          % this is a dummy coding that gets specially interpreted
  mandatefcon = 100;
  fsiz = 0.66415;
  validprop = 500/800;
  %testtime = [3*8+3*5+1];  THIS WAS MADE OBSOLETE; we will calculate on the fly!
end

% calc resolution of faces
newres = [];
for p=1:length(fsiz)
  newres(p) = round(origsz*fsiz(p)*dfac/2)*2;  % new pixel resolution for the stimuli (ensure even)
  fprintf('We will be resizing the stimuli (originally 800 x 800) to %d x %d.\n',newres(p),newres(p));
  if newres(p) < 80
    error('The desired pixel resolution is too low');
  end
end

% set random number seed
setrandstate;

% calc
outfile = sprintf('expt%02d_%s_%s.mat',expttype,subjnum,dataset);  % output .mat file
if wanteyetrack
  eyelinkfilereal = sprintf('%s_expt%02d_%s_%s.edf',gettimestring,expttype,subjnum,dataset);
end
wantquest = ~ismember(expttype,[5 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22]);  % do we want to use QUEST?

% try to find stimuli
if ismember(expttype,14)
  stimfilename = 'workspace_categoryC9words.mat';
else
  stimfilename = 'workspace_categoryC9.mat';
end
stimfile = fullfile(stimulusdir,stimfilename);
if ~exist(stimfile,'file')
  stimfile = fullfile(altstimulusdir,stimfilename);
end
if ~exist(stimfile,'file')
  error('Cannot find stimulus .mat file');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% prepare data records

% if data already exists, load them so we can start from there
if exist(outfile,'file')

  % load
  fprintf('Loading existing data from %s.\n',outfile);
  load(outfile,'convals','accvals','rtvals','stimrecord','allqs','synctimes','alltodo','datarecord');

  % make backup for safety reasons
  backupfile = fullfile(tempdir,sprintf('%s_backup_%s',gettimestring,outfile));
  fprintf('Making backup of data file at %s.\n',backupfile);
  assert(copyfile(outfile,backupfile));

else

  % report
  fprintf('Existing data were not found, so creating a new data file.\n');

  % do a save to make sure it will work
  save(outfile);

  % init
  convals = cell(1,length(alllocs)*length(fcon)*length(fsiz));
  accvals = cell(1,length(alllocs)*length(fcon)*length(fsiz));
  rtvals  = cell(1,length(alllocs)*length(fcon)*length(fsiz));
  stimrecord = [];

  % init more
  if wantquest
    clear allqs;
    for zz=1:length(alllocs)*length(fcon)*length(fsiz)
      allqs(zz) = QuestCreate(tGuessFun(),tGuessSd,pThreshold,beta,delta,gamma);
        % This adds a few ms per call to QuestUpdate, but otherwise the pdf will underflow after about 1000 trials.
      allqs(zz).normalizePdf = 1;
    end
  else
    allqs = [];
  end

  % init more
  synctimes = [];
  alltodo = {};
  datarecord = [];

end

% ask user how many trials to do
fprintf('You have completed %d trials in this dataset.\n',length(convals{1}));
trialsDesired = input('How many trials do you wish to do now? ');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% deal with stimuli

% what are the current viewing parameters?
disp0 = {expttype ptonparams{1} heightofscreen viewingdistance};

% if we have existing stimuli and nothing changed, then we don't have to prepare the stimuli
if exist('allstim','var') && isequal(disp0,lastdisp)

else

  % record viewing parameters
  lastdisp = disp0;

  % load images
  a1 = load(stimfile,'images');  % images is 800 x 800 x N, uint8

  % extract images (note that allstim is uint8)
  allstim = a1.images{1}(:,:,sort(totalset));
  %%facemask = a1.conimages{4*9+5};  % the middle one
  clear a1;

  % define face mask (ellipsoid)
  facemask = {};
  for p=1:length(newres)
    facemask{p} = makecircleimage(newres(p),newres(p)*.25,[],[],[],[],[],[.7 .825]);
  end

% % BROKEN BECAUSE WE DO THINGS ON THE FLY  
%   % high-pass filter images
%   if ismember(expttype,[1 3])
%     for p=1:length(allstimS)
%       allstimS{p} = imagefilter(allstimS{p},constructbutterfilter(newres(p),-20,5));
%     end
%   end

    % mask0 = makecircleimage(newres,newres*.25,[],[],[],[],[],[.7 .825]);
    % tt=[10 15 20 25 30 40 50 70];
    % for z=1:length(tt)
    %   im0 = imagefilter(mean(allstim(:,:,randintrange(1,40)),3),constructbutterfilter(newres,-tt(z),5));
    %   im0 = round(im0.*mask0);
    %   im0(logical(mask0)) = zeromean(im0(logical(mask0)));
    %   imagesc(im0,[-50 50]); axis image;
    %   pause;
    % end
    % % 20 or 25.

% % BROKEN BECAUSE WE DO THINGS ON THE FLY  
%   % mask images
%   switch expttype
%   case {1 3}
%     for p=1:length(allstimS)
%       allstimS{p} = bsxfun(@times,allstimS{p},facemask{p});
%     end
%   case {5 7 8 9 10 11 12 13}  % 2 6
%     for p=1:length(allstimS)
%       allstimS{p} = bsxfun(@plus,bsxfun(@times,allstimS{p},facemask{p}),grayval*(1-facemask{p}));
%     end
% %     allstim = bsxfun(@plus,bsxfun(@times,allstim,facemask),0*(1-facemask));
%   end

% % BROKEN BECAUSE WE DO THINGS ON THE FLY  
%   % z-score images and scale
%   if ismember(expttype,[1 3])
% 
%     for q=1:length(allstimS)
%       for p=1:size(allstimS{q},3)
%         im0 = allstim{q}(:,:,p);
%         im0(logical(facemask{q})) = calczscore(im0(logical(facemask{q})));
%         allstimS{q}(:,:,p) = im0;
%       end
%       % now, the range is something like -10 to 10
% 
%       % scale images
%       allstimS{q} = allstimS{q}/10;  % now -1 to 1 (but still some values outside this range)
% 
%       % check contrast?
%       % median(sqrt(mean(squish(allstim,2).^2,1)))
%     end
% 
%   end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Psychtoolbox preparation

% record the time
timeofexpt = datestr(now);

% setup PT
oldclut = pton(ptonparams{:});

% get information about the PT setup
win = firstel(Screen('Windows'));
rect = Screen('Rect',win);

% initialize, setup, calibrate, and start eyelink
if wanteyetrack

  assert(EyelinkInit()==1);
  el = EyelinkInitDefaults(win);
  [wwidth,wheight] = Screen('WindowSize',win);  % returns in pixels
  fprintf('Pixel size of window is width: %d, height: %d.\n',wwidth,wheight);
  Eyelink('command','screen_pixel_coords = %ld %ld %ld %ld',0,0,wwidth-1,wheight-1);
  Eyelink('message','DISPLAY_COORDS %ld %ld %ld %ld',0,0,wwidth-1,wheight-1);
  Eyelink('command','calibration_type = HV5');
  Eyelink('command','active_eye = LEFT');
  Eyelink('command','automatic_calibration_pacing=1500');
    % what events (columns) are recorded in EDF:
  Eyelink('command','file_event_filter = LEFT,RIGHT,FIXATION,SACCADE,BLINK,MESSAGE,BUTTON');
    % what samples (columns) are recorded in EDF:
  Eyelink('command','file_sample_data = LEFT,RIGHT,GAZE,HREF,AREA,GAZERES,STATUS');
    % events available for real time:
  Eyelink('command','link_event_filter = LEFT,RIGHT,FIXATION,SACCADE,BLINK,MESSAGE,BUTTON');
    % samples available for real time:
  Eyelink('command','link_sample_data = LEFT,RIGHT,GAZE,GAZERES,AREA,STATUS');
  Eyelink('Openfile',eyelinkfile);
  fprintf('Please perform calibration. When done, the subject should press a button in order to proceed.\n');
  EyelinkDoTrackerSetup(el);
%  EyelinkDoDriftCorrection(el);
  fprintf('Button detected from subject. Starting recording of eyetracking data. Proceeding to stimulus setup.\n');
  Eyelink('StartRecording');
  Eyelink('Message',eyelinkfilereal);  % embed reference information directly in the .edf file

end

%%%%% fixation-dot stuff

% some experiments need the fixation dot shifted
switch expttype
case {15 17 19 21}
  fixationshift = repmat([-round(10*dfac) 0],[1 2]);
case {16 18 20 22}
  fixationshift = repmat([round(10*dfac) 0],[1 2]);
otherwise
  fixationshift = [0 0 0 0];
end

% note: this will serve as a common mechanism for all fixation-related things
fixationrect = CenterRect([0 0 fixationtotalsize fixationtotalsize],rect) + fixationshift;

% FIRST, make some dots for fixationimage and fixationalpha

  % fixationtotalsize x fixationtotalsize x 3 x N; several different uint8 solid colors
fixationimage = zeros([fixationtotalsize fixationtotalsize 3 size(fixationcolor,1)]);
temp = find(makecircleimage(fixationtotalsize,fixationsize(1)/2-fixationsize(2)));  % this tells us where to insert color
for p=1:size(fixationcolor,1)
  temp0 = zeros([fixationtotalsize*fixationtotalsize 3]);  % everything is initially black
  temp0(temp,:) = repmat(fixationcolor(p,:),[length(temp) 1]);  % insert color in the innermost circle
  fixationimage(:,:,:,p) = reshape(temp0,[fixationtotalsize fixationtotalsize 3]);
end
fixationalpha = repmat(255*makecircleimage(fixationtotalsize,fixationsize(1)/2),[1 1 size(fixationcolor,1)]);  % fixationtotalsize x fixationtotalsize x N; double [0,255] alpha values (255 in circle, 0 outside)

% SECOND, make some digits and letters for fixationimage and fixationalpha

if exist('wantdigits','var') && wantdigits

  % make digits and letters (white on gray)
  temp = preparedigits(fixationtotalsize,digitsize,grayval,255);

  % make a black version
  tempB = temp;
  tempB(tempB==255) = 0;
  
  % make pure gray frame
  tempC = repmat(grayval,[sizefull(fixationimage,2) 3]);
  
  % add them in
  fixationimage = cat(4,fixationimage,temp,tempB,tempC);

  % deal with alpha.
  % for the white and black symbols, the symbols are themselves 255 alpha values;
  % for the pure gray frame, this is completely transparent (0 alpha values).
  fixationalpha = cat(3,fixationalpha, ...
                      repmat(255*(permute(temp(:,:,1,:),[1 2 4 3])~=grayval),[1 1 2]), ...
                      zeros(sizefull(fixationimage,2)));
                      
  % so, to summarize, we have this many fixation images:
  %   size(fixationcolor,1) + 10+26 + 10+26 + 1
  
  % what is index of the last (pure gray) fixation image?
  fixationgrayix = size(fixationcolor,1)+10+26+10+26+1;

end

%%%%%

% prepare movierect
movierect = CenterRect([0 0 resH resH],rect);

% prepare window for alpha blending
Screen('BlendFunction',win,GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA);

% init variables, routines, constants
oldPriority = Priority(MaxPriority(win));
HideCursor;
mfi = Screen('GetFlipInterval',win);  % re-use what was found upon initialization!
filtermode = 0;
sound(zeros(1,100),1000);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% start experiment

% draw the background and fixation
Screen('FillRect',win,grayval,rect);
texture = Screen('MakeTexture',win,cat(3,fixationimage(:,:,:,2),fixationalpha(:,:,2)));
Screen('DrawTexture',win,texture,[],fixationrect,[],0);
Screen('Close',texture);
Screen('Flip',win);

% wait for a key press to start
while 1
  [secs,keyCode,deltaSecs] = KbWait(-3,2);
  temp = KbName(keyCode);  % temp(1) is the key char
  if isequal(double(temp(1)),triggerkey)
    break;
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% main section

% define
alltodo{end+1} = permutedim(1:(length(alllocs)*length(fcon)*length(fsiz)*trialsDesired));  % trials to run
lastbreak = GetSecs;  % time of last break

% do it
stime = clock;  % start time
for pp=1:length(alltodo{end})

  % calc
  ppw = mod2(alltodo{end}(pp),length(alllocs));  % what location are we doing?
  fcon0 = mod2(ceil(alltodo{end}(pp)/length(alllocs)),length(fcon));  % what contrast level index?
  ss = mod2(ceil(alltodo{end}(pp)/(length(alllocs)*length(fcon))),length(fsiz));  % what face size index?

  % get the contrast value to test at
  if wantquest
        % WARNING: this is broken because of the contrast levels change...
    conval = QuestQuantile(allqs(ppw));  % Recommended by Pelli (1987), and still our favorite.
    conval = min(0,conval);  % do not let contrast go larger than 10^0=1
  else
%     if expttype==12
%       conval = log10();
%       %log10(0.1);%log10(0.8);  %log10(0.1);  %log10(.5);
% %       if rand > .5
% %         answer = 1;
% %         conval = log10(fcon(fcon0)/100);
% %       else
% %         answer = 2;
% %         conval = log10(fcon2(fcon0)/100);
% %       end
%     else
    
    % in these special cases, we use fcon0 as a hack to specify cue (fcon0==1) and non-cue (fcon0==2) trials.
    % so we have to use mandatefcon to figure out the face contrast.
    if ismember(expttype,[19 20 21 22])
      conval = log10(mandatefcon/100);
    else
      conval = log10(fcon(fcon0)/100);
    end
  end
	
	%%%%% generate stimuli and prepare movie

  switch expttype
  case {5 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22}

    % generate noise
    noiseframes = zeros(newres(ss),newres(ss),1);
    for zz=1:1
      if newres(ss) > 800   % to speed things up
        temp = calczscore(generatepinknoise(800,1,1,1));  % now roughly in -4 to 4
        temp = imresize(temp,[newres(ss) newres(ss)]);
      else
        temp = calczscore(generatepinknoise(newres(ss),1,1,1));  % now roughly in -4 to 4
      end
      noiseframes(:,:,zz) = 127 + temp * (1/4 * 127 * pcon/100);
    end

    % pick face(s)
    stimix =  randintrange(1,size(allstim,3));
    while 1
      stimix2 = randintrange(1,size(allstim,3));
      if stimix2~=stimix
        break;
      end
    end
    
    % define this for the special case of off-center viewing
    switch expttype
    case {15 17 19 21}
      specialoffset = [0 -round(10*dfac)];
    case {16 18 20 22}
      specialoffset = [0  round(10*dfac)];
    otherwise
      specialoffset = [0 0];
    end

    % where are we putting the stimulus?
    csarg = [-round(alllocs{ppw}(1) * dfac) round(alllocs{ppw}(2) * dfac)];
    pos0 = [resH/2+1 - newres(ss)/2 + csarg(1)  resH/2+1 - newres(ss)/2 + csarg(2)] + specialoffset;
    
    % resize face
    face0 = imresize(double(allstim(:,:,stimix)), [newres(ss) newres(ss)]);
    face1 = imresize(double(allstim(:,:,stimix2)),[newres(ss) newres(ss)]);
    
    % handle special phase-scrambling case
    if ismember(expttype,[12 17 18 21 22])
      centralcrop = round(validprop * newres(ss) / 2)*2;  % how big is the valid region?
      face0 = placematrix(zeros(centralcrop,centralcrop),face0,[]);  % crop the face stimulus
      face0scr1 = phasescrambleimage(face0,0);     % phase-scramble
%       face0scr2 = phasescrambleimage(face0,100);   % phase-scramble
      mask0 = logical(placematrix(zeros(centralcrop,centralcrop),facemask{ss},[]));  % crop the mask
      [mean0,std0] = meanandse(face0(mask0),[],1);  % what is the mean and std of pixels of original face (within mask)?
      face0scr1(mask0) = calczscore(face0scr1(mask0)) * std0 + mean0;  % adjust pixels of scr face (within mask) to match
%       face0scr2(mask0) = calczscore(face0scr2(mask0)) * std0 + mean0;  % adjust pixels of scr face (within mask) to match
      if rand > .5
        face0 = face0scr1;
        answer = 1;
      else
        answer = 2;
      end
      face0 = placematrix(zeros(newres(ss),newres(ss)),face0,[]);  % undo the crop
    end
    
    % mask face
    if ~ismember(expttype,[14])
      face0 = face0 .* facemask{ss} + grayval * (1-facemask{ss});
      face1 = face1 .* facemask{ss} + grayval * (1-facemask{ss});
    end
    
    % place on gray background
    face0 = placematrix(grayval*ones(resH,resH),face0,pos0);
    face1 = placematrix(grayval*ones(resH,resH),face1,pos0);
    
    % change contrast of face and we are done
    face0 = uint8((10^conval) * (face0-grayval) + grayval);
    face1 = uint8((10^conval) * (face1-grayval) + grayval);
    
    % construct noise and we are done
    noise0 = uint8(placematrix(grayval*ones(resH,resH),noiseframes .* facemask{ss} + grayval*(1-facemask{ss}),pos0));

    % init movie
    movieframes = uint8([]);
    movieframes(:,:,1) = grayval*ones(resH,resH);
    movieframes(:,:,2) = noise0;
    movieframes(:,:,3) = face0;
    movieframes(:,:,4) = face1;

    % construct movie
    movieseq = [];
    switch expttype
    case {19 20 21 22}
      if fcon0==1  % if cue case
        movieseq(end+(1:letterdur+lettergap+cuedummy)) = 1;  % allow task indicator and dummy period
        movieseq(end+(1:timing(1))) = 2;                     % put up prime
        movieseq(end+(1:timing(2))) = 1;                     % put up gap
        movieseq(end+(1:facedur)) = 3;                       % put up face
        movieseq(end+(1:facedur2)) = 4;                      % put up mask
        movieseq(end+(1:1)) = 1;                             % put up extra last blank
        testtime = letterdur+lettergap+cuedummy+timing(1)+timing(2)+1;  % time (in frames) of face showing
        tofill = cuedummy+sum(timing)+facedur;               % total number of frames to show digits during
      else         % if non-cue (digits) case
        movieseq(end+(1:letterdur+lettergap)) = 1;           % allow task indicator and dummy period
        numblanks = round(mindigitlen + rand*digitrng);      % calc random number of monitor frames
        movieseq(end+(1:numblanks)) = 1;                     % put up gap
        movieseq(end+(1:facedur)) = 3;                       % put up face
        movieseq(end+(1:facedur2)) = 4;                      % put up mask
        movieseq(end+(1:1)) = 1;                             % put up extra last blank
        testtime = letterdur+lettergap+numblanks+1;          % time (in frames) of face showing
        tofill = numblanks+facedur;                          % total number of frames to show digits during
      end
    otherwise
      movieseq(end+(1:timing(1))) = 2;                     % put up prime
      movieseq(end+(1:timing(2))) = 1;                     % put up gap
      movieseq(end+(1:timing(3))) = 3;                     % put up face
      movieseq(end+(1:1)) = 1;                             % put up extra last blank
      testtime = timing(1)+timing(2)+1;
    end
    
    % figure out digit stuff
    if ismember(expttype,[19 20 21 22])

      % init to white-dot fixation images
      digitmov = 1*ones(1,length(movieseq));  % these hold indices that refer to fixationimage

      % deal with task indicator letter
      if fcon0==1  % if cue case
        digitmov(0+(1:letterdur)) = 2+10+3;  % white 'C'
      else         % if digit case
        digitmov(0+(1:letterdur)) = 2+10+4;  % white 'D'
      end
      digitmov(letterdur+(1:lettergap)) = fixationgrayix;  % blank
      
      % calculate number of digits to generate (a full digit AFTER completion of the face ensures bleedover)
      numdigitstogen = ceil(tofill / (2*digitrate)) + 1;
      
      % generate the numbers (vector with integers)
      digitseq = randintrange2(0,9,numdigitstogen,probdigit,1);

      % vector of indices of monitor frames when digit repetitions occurred.
      % can be empty.  for example, [5 10] means that the 5th and 10th monitor frames
      % (relative to when we started to show digits) had digit repetitions.
      % this will be important when checking subject performance.
      digitrepix = find(upsamplematrix(flatten([[0 diff(digitseq)==0]; zeros(1,length(digitseq))]),digitrate,2,[],0));

      % convert digits to fixationimage indices
      digitseq(1:2:end) = 2+1+digitseq(1:2:end);         % change digits to frame indices (white)
      digitseq(2:2:end) = 2+10+26+1+digitseq(2:2:end);   % change digits to frame indices (black)
      
      % record
      digitmov(letterdur+lettergap+(1:(2*digitrate)*numdigitstogen)) = ...  % add gaps in between and upsample
        upsamplematrix(flatten([digitseq; fixationgrayix*ones(1,length(digitseq))]),digitrate,2,[],'nearest');
      
      % extend blanks as necessary until face presentation is complete
      digitmov(letterdur+lettergap+(2*digitrate)*numdigitstogen+1:letterdur+lettergap+tofill) = fixationgrayix;
    
    else
    
      % in the usual case, we just keep a white dot present throughout the trial
      digitmov = 1*ones(1,length(movieseq));
      
    end

    % record
    stimrecord0 = [pp alltodo{end}(pp) stimix ppw fcon0 ss conval stimix2];
  
  case 6

% NOT FINALIZED
%     % generate noise
%     noiseframes = zeros(newres,newres,1);
%     for zz=1:1
%       temp = calczscore(generatepinknoise(newres,1,1,1));  % now roughly in -4 to 4
%       noiseframes(:,:,zz) = 127 + temp * (1/4 * 127 * pcon/100);
%     end
% 
%     % more noise
%     fullnoise = zeros(newres,newres,2);
%     for zz=1:2
%       temp = calczscore(generatepinknoise(newres,1,1,1));  % now roughly in -4 to 4
%       fullnoise(:,:,zz) = 127 + temp * (1/4 * 127 * ncon/100);
%     end
%     
%     % pick face
%     stimix = randintrange(1,size(allstim,3));
%     stimixB = randintrange(1,size(allstim,3));
% 
%     % mix
%     face0 = (10^conval) * (allstim(:,:,stimix)-grayval) + grayval + (fullnoise(:,:,1) .* facemask + grayval*(1-facemask)) - 127;
%     face0B = (10^conval) * (allstim(:,:,stimixB)-grayval) + grayval + (fullnoise(:,:,2) .* facemask + grayval*(1-facemask)) - 127;
%   
%     % where are we putting the stimulus?
%     csarg = [-round(alllocs{ppw}(1) * dfac) round(alllocs{ppw}(2) * dfac)];
%     pos0 = [res/2+1 - newres/2 + csarg(1)  res/2+1 - newres/2 + csarg(2)];
%     
%     % construct face
%     face0 = placematrix(grayval*ones(res,res),face0,pos0);
%     face0B = placematrix(grayval*ones(res,res),face0B,pos0);
%     
%     % construct noise
%     noise0 = placematrix(grayval*ones(res,res),noiseframes .* facemask + grayval*(1-facemask),pos0);
% 
%     % init movie
%     mov = uint8([]);
% 
%     % put up prime
%     mov = cat(3,mov,repmat(noise0,[1 1 timing(1)]));
%     mov = cat(3,mov,grayval*ones(res,res,timing(2)));
%     mov = cat(3,mov,repmat(face0,[1 1 timing(3)]));
%     mov = cat(3,mov,grayval*ones(res,res,timing(4)));
%     mov = cat(3,mov,repmat(face0B,[1 1 timing(5)]));
% 
%     % record
%     stimrecord(:,end+1) = [pp alltodo{end}(pp) stimix stimixB]';

  end

	%%%%% what is the correct answer?

  % what is the answer?
  switch expttype
  case {1 3}
    answer = whtarget;
  case {2 5 7 8 9 10 11 13 15 16 19 20}
    answer = stimlabels(subscript(sort(totalset),{stimix}));
  case {14}
    answer = stimlabels(subscript(sort(totalset),{stimix}));
  case {6}
%     answer = 2-(subscript(sort(totalset),{stimix})== ...
%              subscript(sort(totalset),{stimixB}));
  case {12 17 18 21 22}
    % answer already defined above
  end
  
  % record it
  stimrecord0 = [stimrecord0 answer];

	%%%%% show the movie

  % init
  timeframes = NaN(1,length(movieseq));
  timekeys = {};
  when = 0;
  getoutearly = 0;
  glitchcnt = 0;

  % show the movie
  framecnt = 0;
  alreadypressed = 0;
  for frame=1:length(movieseq)+1
    framecnt = framecnt + 1;
    frame0 = floor(frame);

    % new hack: last frame is bogus.  so get out ASAP.
    if frame0==length(movieseq)+1
      break;
    end

    % get out early?
    if getoutearly
      break;
    end

    % make a texture, draw it at a particular position
    txttemp = movieframes(:,:,movieseq(frame0));
    texture = Screen('MakeTexture',win,txttemp);
    Screen('DrawTexture',win,texture,[],movierect,0,filtermode,1);  % check??
    Screen('Close',texture);
  
    % draw the fixation
    whtodo = digitmov(frame0);
    texture = Screen('MakeTexture',win,cat(3,fixationimage(:,:,:,whtodo),fixationalpha(:,:,whtodo)));
    Screen('DrawTexture',win,texture,[],fixationrect,0,0);
    Screen('Close',texture);

    % give hint to PT that we're done drawing
    Screen('DrawingFinished',win);
  
    % read input until we have to do the flip
    while 1
  
      % if we are in the initial case OR if we have hit the when time, then display the frame
      if when == 0 | GetSecs >= when
      
        % SYNC [beginning of the trial]
        if wanteyetrack && frame==1
          synctimes = [synctimes GetSecs];
          Eyelink('Message','SYNCTIME');
        end
  
        % issue the flip command and record the empirical time
        [VBLTimestamp,StimulusOnsetTime,FlipTimestamp,Missed,Beampos] = Screen('Flip',win,when);
        timeframes(framecnt) = VBLTimestamp;

        % if we missed, report it
        if Missed > 0 & when ~= 0
          glitchcnt = glitchcnt + 1;
          didglitch = 1;
        else
          didglitch = 0;
        end
      
        % get out of this loop
        break;
    
      % otherwise, try to read input
      else
        [keyIsDown,secs,keyCode,deltaSecs] = KbCheck(-3);  % all devices
        if keyIsDown

          % get the name of the key and record it
          kn = KbName(keyCode);
          timekeys = [timekeys; {secs kn}];

          % check if ESCAPE was pressed
          if isequal(kn,'ESCAPE')
            fprintf('Escape key detected.  Exiting prematurely.\n');
            getoutearly = 1;
            break;
          end
          
          % if the subject already made a choice, we don't care about any keypresses.
          % also, we will care about the keypress only if the actual test frame was
          % put on the screen (to avoid acausal behavioral responses).
          if ~alreadypressed && frame0 > testtime

            if isequal(kn(1),onekey)
              cor = answer==1;
              alreadypressed = 1;
            elseif isequal(kn(1),twokey)
              cor = answer==2;
              alreadypressed = 1;
            end
            
            % if the subject pressed one of the special keys, handle it
            if alreadypressed

              % give feedback
              sound(sin((.2*(cor+1))*(1:500)));

              % update QUEST
              if wantquest
                % Add the new datum (actual test intensity and observer response) to the database.
                allqs(ppw) = QuestUpdate(allqs(ppw),conval,cor);
              end

              % record [NOTE: we make the official record later because timeframes(testtime) may not yet be defined]
              buttontime = secs;

            end

          end

        end
      end

    end

    % update when
    if didglitch
      % if there were glitches, proceed from our earlier when time.
      % set the when time to half a frame before the desired frame.
      % notice that the accuracy of the mfi is strongly assumed here.
      when = (when + mfi / 2) + mfi * frameduration - mfi / 2;
    else
      % if there were no glitches, just proceed from the last recorded time
      % and set the when time to half a frame before the desired time.
      % notice that the accuracy of the mfi is only weakly assumed here,
      % since we keep resetting to the empirical VBLTimestamp.
      when = VBLTimestamp + mfi * frameduration - mfi / 2;  % should we be less aggressive??
    end
  
  end

  % if the subject made a response during the movie
  if alreadypressed

    % record
    ix0 = (ss-1)*(length(fcon)*length(alllocs)) + (fcon0-1)*length(alllocs) + ppw;
    convals{ix0} = [convals{ix0} conval];
    accvals{ix0} = [accvals{ix0} cor];
    rtvals{ix0} =  [rtvals{ix0} buttontime-timeframes(testtime)];
  
  end

  % record and report some statistics on the movie showing
  dur = (timeframes(end)-timeframes(1)) * (length(timeframes)/(length(timeframes)-1));  % projected total movie duration
  stimrecord0 = [stimrecord0 dur];
  fprintf('We had %d glitches. Projected total movie duration: %.10f\n',glitchcnt,dur);

% THIS IS NO LONGER NECESSARY SINCE WE INCLUDE A BLANK DUMMY FRAME AT THE END OF THE MOVIE
%   % draw the background and fixation
%   Screen('FillRect',win,grayval,rect);
%   texture = Screen('MakeTexture',win,cat(3,fixationimage(:,:,:,1),fixationalpha));
%   Screen('DrawTexture',win,texture,[],fixationrect,[],0);
%   Screen('Close',texture);
%   Screen('Flip',win);

  % if the subject didn't already make a response, wait for response
  if ~alreadypressed
    getoutearly = 0;
    while 1
      [keyIsDown,secs,keyCode,deltaSecs] = KbCheck(-3);  % all devices
      if keyIsDown

        % get the name of the key
        kn = KbName(keyCode);

        if isequal(kn(1),onekey)
          cor = answer==1;
          alreadypressed = 1;
        elseif isequal(kn(1),twokey)
          cor = answer==2;
          alreadypressed = 1;
        elseif isequal(kn,'ESCAPE')
          getoutearly = 1;
        end

        if getoutearly
          break;
        end
        
        % if the subject pressed one of the special keys, handle it
        if alreadypressed

          % give feedback
          sound(sin((.2*(cor+1))*(1:500)));
    
          % update QUEST
          if wantquest
            % Add the new datum (actual test intensity and observer response) to the database.
            allqs(ppw) = QuestUpdate(allqs(ppw),conval,cor);
          end
  
          % record
          ix0 = (ss-1)*(length(fcon)*length(alllocs)) + (fcon0-1)*length(alllocs) + ppw;
          convals{ix0} = [convals{ix0} conval];
          accvals{ix0} = [accvals{ix0} cor];
          rtvals{ix0} =  [rtvals{ix0} secs-timeframes(testtime)];
  
          % done
          break;

        end
      end
    end

    % if the subject pressed ESCAPE, we have to stop everything
    if getoutearly
      break;
    end

  end
  
  % SYNC [end of the trial]
  if wanteyetrack
    synctimes = [synctimes GetSecs];
    Eyelink('Message','SYNCTIME');
  end
  
  % finally, analyze the performance on the digits (if applicable)
%  timekeys
%  digitrepix
  

% % first we have to expand the multiple-keypresses cases
% timekeysB = {};
% for p=1:size(timekeys,1)
%   if iscell(timekeys{p,2})
%     for pp=1:length(timekeys{p,2})
%       timekeysB{end+1,1} = timekeys{p,1};
%       timekeysB{end,2} = timekeys{p,2}{pp};
%     end
%   else
%     timekeysB(end+1,:) = timekeys(p,:);
%   end
% end

%   
%   if digit repeat, look for +[200 1200]?
%   %%%%%%%%%%%%%%%%%%  # of repetitions, # of hits - # of false alarms
%   repix
%%% getting multiple depresses..
%   timekeys?
%  digitresp
%   save somewhere?
%       digitfirsttime = a2.timeframes(  trialoffset0 + 20 + 1 );     % time of first digit
%       digitlasttime =  a2.timeframes(  trialoffset0 + 20*5 + 11 );  % time of last digit
% 
%       DIGITevent = find(diff(digits0)==0) + 1;               % index of digit repetition (can be [] if no rep)
% 
% 
%       DIGITtime = a2.timeframes( trialoffset0 + 20 + (DIGITevent-1)*10 + 1 );  % time of digit rep (can be [])
%       allbuttons = find(a1.keytimes{p} >= windowbegin+lowpad & ...
%                         a1.keytimes{p} <  windowend  +highpad);  % indices of all buttons detected
% 
% 
%       if ~isempty(allbuttons)
%           behrecord(stimnum,tasknum,stimclasstrialcnt(stimnum,tasknum),:,p,zzzz) = [0 1 NaN];  % not present, correct, no RT
% 

  % record information about this trial
  stimrecord(:,end+1) = stimrecord0';

  % see if subject wants a break
  if GetSecs > lastbreak + breaktime

    % record break time
    lastbreak = GetSecs;
    
    % draw the background and fixation
    Screen('FillRect',win,grayval,rect);
    texture = Screen('MakeTexture',win,cat(3,fixationimage(:,:,:,2),fixationalpha(:,:,2)));
    Screen('DrawTexture',win,texture,[],fixationrect,[],0);
    Screen('Close',texture);
    Screen('Flip',win);

    % wait for a key press to start
    while 1
      [secs,keyCode,deltaSecs] = KbWait(-3,2);
      temp = KbName(keyCode);  % temp(1) is the key char
      if isequal(temp(1),triggerkey)
        break;
      end
    end

  end

end

% report how long things took
durationsecs = etime(clock,stime);
fprintf('You completed %d trials. This took %.2f minutes (%.2f seconds per trial).\n', ...
        length(alltodo{end}),durationsecs/60,durationsecs/length(alltodo{end}));
fprintf('Good work!\n');

% record for fun
datarecord(:,end+1) = [length(alltodo{end}) durationsecs]';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% save results

% save
fprintf('Saving results to %s.\n',outfile);
saveexcept(outfile,{'allstim' 'txttemp' 'movieframes' 'face0' 'face1' 'noise0' 'noiseframes' 'noiseframe' 'im0' 'facemask' 'temp'});

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% clean up

% restore priority and cursor
Priority(oldPriority);
ShowCursor;

% report basic timing information to stdout
fprintf('we had %d glitches!\n',glitchcnt);

% close out eyelink
if wanteyetrack
  fprintf('*** We are now transferring the eye-tracking data.  Do not touch anything!\n');
  Eyelink('StopRecording');
  Eyelink('CloseFile');
  Eyelink('ReceiveFile');
  Eyelink('ShutDown');
  assert(movefile(eyelinkfile,eyelinkfilereal));    % rename the eyetracking file
  fprintf('*** Transfer of eye-tracking data was successful!\n');
end

% unsetup PT
ptoff(oldclut);


















%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% csfirst = [-172 -172 -172 -172 -172 -172 -172 -172 -172;-129 -129 -129 -129 -129 -129 -129 -129 -129;-86 -86 -86 -86 -86 -86 -86 -86 -86;-43 -43 -43 -43 -43 -43 -43 -43 -43;0 0 0 0 0 0 0 0 0;43 43 43 43 43 43 43 43 43;86 86 86 86 86 86 86 86 86;129 129 129 129 129 129 129 129 129;172 172 172 172 172 172 172 172 172];
% cssecond = [-156 -117 -78 -39 0 39 78 117 156;-156 -117 -78 -39 0 39 78 117 156;-156 -117 -78 -39 0 39 78 117 156;-156 -117 -78 -39 0 39 78 117 156;-156 -117 -78 -39 0 39 78 117 156;-156 -117 -78 -39 0 39 78 117 156;-156 -117 -78 -39 0 39 78 117 156;-156 -117 -78 -39 0 39 78 117 156;-156 -117 -78 -39 0 39 78 117 156];
% 
% diff(sort(union(csfirst(:),[])*(12.5/800)))
% diff(sort(union(cssecond(:),[])*(12.5/800)))
% 
% % 0.671875 deg for vertical steps
% % 0.609375 deg for horizontal steps
% 
% 233 is background
%
% 512 pixels for newres
% the mask was 180 pixels wide, 212 pixels tall
% this is 4.401 deg wide, 5.18389 deg tall
% in vertical direction,   +/- 4 steps is +/- 2.6875 deg for the centers.  so max out (compensating for face) is 5.279445 deg.
% in horizontal direction, +/- 4 steps is +/- 2.4375 deg for the centers.  so max out (compensating for face) is 4.638 deg.
% we also put centers out 8 deg.  this means max out is 10.591945 deg (vertical).  this means we need 21.18389 deg screen size.
% or, out 12 deg. this means max out (at 50% size) is 14.59 deg (vertical). this means we need 29.18 deg screen size.
%
% vertical radius of ellipsoid is 12.5 * 1/2 * 1/4 * .825 = 1.2890625 deg
% so, actually need only 27 deg of vertical screen size

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% case 1
%   frameduration = 6;  % each frame is ~100 ms
% case 2
%   frameduration = 6;
% case 3
%   frameduration = 6;
% case 4
%   frameduration = 6;
% 
% 
% 
% 
% 
% case 1
%   blanktime = 0;  % in frames (at beginning of trial)
%   frametime = 2;  % in frames (duration)
%   gaptime = 2;    % in frames (in between frames)
%   pcon = 50;      % contrast multiplier for noise
%   starttime = blanktime+1;
% case 2
%   blanktime = 0;  % in frames (at beginning of trial)
%   frametime = 3;  % in frames (duration)
%   masktime = 0;%round(30/frameduration);  % in frames (duration)
%   pcon = 100;     % contrast multiplier for noise
%   starttime = blanktime+1;
% case 3
%   blanktime = 0;  % in frames (at beginning of trial)
%   frametime = 2;  % in frames (duration)
%   gaptime = 2;    % in frames (in between frames)
%   pcon = 50;     % contrast multiplier for noise
%   basecon = 25;  % hm, not 0 to X.  rather, m (something that is not 0; perceive a face at all locations) to m+delta
%   starttime = blanktime+1;
% case 4
% 
% 
% 
% 
%   case 1
% 
%     % generate noise
%     noiseframes = zeros(res,res,2);
%     for zz=1:2
%       temp = calczscore(generatepinknoise(res,1,1,1));  % now roughly in -4 to 4
%       noiseframes(:,:,zz) = 127 + temp * (1/4 * 127 * pcon/100);
%     end
% 
%     % pick frame to show face
%     whtarget = (rand > .5) + 1;  % 1 means first; 2 means second
%   
%     % pick face
%     stimix = randintrange(1,size(allstim,3));
%   
%     % construct face
%     csarg = [-round((vidx(rri) * vstep) * dfac) round((hidx(cci) * hstep) * dfac)];
%     face0 = placematrix(zeros(res,res),circshift(allstim(:,:,stimix),csarg),[]);
% 
%           %%  mask0 = placematrix(zeros(res,res),circshift(facemask,csarg),[]);
%           %   % add face
%           %   noiseframes(:,:,whtarget) = ...
%           %     (1-mask0) .* noiseframes(:,:,whtarget) + ...
%           %         mask0 .* (noiseframes(:,:,whtarget) + (10^conval)*face0);
% 
%     % add face
%     noiseframes(:,:,whtarget) = noiseframes(:,:,whtarget) + ((10^conval)*127)*face0;
% 
%     % init movie
%     mov = uint8([]);
% 
%     % generate initial blanks
%     mov = cat(3,mov,grayval*ones(res,res,blanktime));
% 
%     % put up first frame
%     mov = cat(3,mov,repmat(noiseframes(:,:,1),[1 1 frametime]));
% 
%     % put up gap
%     mov = cat(3,mov,grayval*ones(res,res,gaptime));
% 
%     % put up second frame
%     mov = cat(3,mov,repmat(noiseframes(:,:,2),[1 1 frametime]));
% 
%   case 2
% 
%     % generate noise (for mask)
%     temp = calczscore(generatepinknoise(res,1,1,1));  % now roughly in -4 to 4
%     noiseframe = 127 + temp * (1/4 * 127 * pcon/100);
% 
%     % pick face
%     stimix = randintrange(1,size(allstim,3));
%     stimixALT = firstel(permutedim(setdiff(1:size(allstim,3),stimix)));
%   
%     % construct face
%     csarg = [-round((vidx(rri) * vstep) * dfac) round((hidx(cci) * hstep) * dfac)];
%     face0 = placematrix(127*ones(res,res),circshift(allstim(:,:,stimix),csarg),[]);
%     face0ALT = placematrix(127*ones(res,res),circshift(allstim(:,:,stimixALT),csarg),[]);
% 
%     % change contrast of face
%     face0 = (10^conval) * (face0-127) + 127;
%     face0ALT = (10^conval) * (face0ALT-127) + 127;
% 
% %     % construct face
% %     csarg = [-round((vidx(rri) * vstep) * dfac) round((hidx(cci) * hstep) * dfac)];
% %     face0 = placematrix(zeros(res,res),circshift(allstim(:,:,stimix),csarg),[]);
% % 
% %     % change contrast of face
% %     face0 = (min(1,10^conval) * 127) * face0 + 127;
% 
%     % init movie
%     mov = uint8([]);
% 
%     % generate initial blanks
%     mov = cat(3,mov,grayval*ones(res,res,blanktime));
% 
%     % put up face
%     mov = cat(3,mov,repmat(face0,[1 1 frametime]));
% 
%     % put up face
%     mov = cat(3,mov,repmat(face0ALT,[1 1 frametime]));
%     
%     % put up mask
%     mov = cat(3,mov,repmat(noiseframe,[1 1 masktime]));
% 
%   case 3
% 
%     % generate noise
%     noiseframes = zeros(res,res,2);
%     for zz=1:2
%       temp = calczscore(generatepinknoise(res,1,1,1));  % now roughly in -4 to 4
%       noiseframes(:,:,zz) = 127 + temp * (1/4 * 127 * pcon/100);
%     end
% 
%     % pick frame to have higher contrast
%     whtarget = (rand > .5) + 1;  % 1 means first; 2 means second
%   
%     % pick faces
%     stimixs = randintrange(1,size(allstim,3),[1 2],1);
%   
%     % construct face
%     csarg = [-round((vidx(rri) * vstep) * dfac) round((hidx(cci) * hstep) * dfac)];
%     face1 = placematrix(zeros(res,res),circshift(allstim(:,:,stimixs(1)),csarg),[]);
%     face2 = placematrix(zeros(res,res),circshift(allstim(:,:,stimixs(2)),csarg),[]);
% 
%     % add face
%     noiseframes(:,:,whtarget) = noiseframes(:,:,whtarget) + ((basecon/100+10^conval)*127)*face1;
%     noiseframes(:,:,setdiff(1:2,whtarget)) = noiseframes(:,:,setdiff(1:2,whtarget)) + ((basecon/100)*127)*face2;
% 
%     % init movie
%     mov = uint8([]);
% 
%     % generate initial blanks
%     mov = cat(3,mov,grayval*ones(res,res,blanktime));
% 
%     % put up first frame
%     mov = cat(3,mov,repmat(noiseframes(:,:,1),[1 1 frametime]));
% 
%     % put up gap
%     mov = cat(3,mov,grayval*ones(res,res,gaptime));
% 
%     % put up second frame
%     mov = cat(3,mov,repmat(noiseframes(:,:,2),[1 1 frametime]));
% 

%     % check pixel range
%     if expttype==12
%       badout = sum(face0(:)<0 | face0(:)>255);
%       fprintf('answer = %d, badout = %.1f%%\n',answer,badout/sum(mask0(:)) * 100);
%     end
