% define
  % [800 600 60 32] [1280 800 0 32] [1600 1200 60 32]
  % '3T2_projector_2010_09_01'
ptonparams = {[1600 1200 60 32],[],-1};
ptonparams = {[1024 768 60 32],[],-1};

% don't change resolution; sqrt the clut
ptonparams = {[],[],-1};

% get utilities on path
%addpath(genpath(strrep(which('calibrate'),'calibrate.m','knkutils')));

% check calibration images 
oldclut = pton(ptonparams{:});
offset = ptviewimage('calibrationimages/*.png',[0 0],0);  % ,1 means cycle
ptoff(oldclut);

% report offset
fprintf('The offset was found to be %s\n',mat2str(offset));
