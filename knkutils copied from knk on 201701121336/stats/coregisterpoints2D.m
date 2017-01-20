function P2match = coregisterpoints2D(P1,P2)

% function P2match = coregisterpoints2D(P1,P2)
%
% <P1> is the first set of points with dimensions N x 2.
%   The x- and y-coordinates are in the columns.
% <P2> is the second set of points (same format as <P1>).
%   It is assumed there is a one-to-one correspondence between rows of <P1> and <P2>.
%
% Return a new set of points, <P2match>, which is the same as <P2> except that points
% have been allowed to move according to translation, rotation, global scaling, and flips.
% This ensures that all pairwise Euclidean distances are preserved, up to a scale factor.
% The objective is to match <P2> to <P1>, and our metric is the sum of the Euclidean
% distances between the points in <P1> and those in <P2match>.
%
% example:
% P1 = 2 + randn(50,2);
% P2 = .5*P1(:,[2 1]) + 4 + .1*randn(size(P1));
% P2match = coregisterpoints2D(P1,P2);
% figure; hold on;
% scatter(P1(:,1),P1(:,2),'ro');
% scatter(P2(:,1),P2(:,2),'bx');
% scatter(P2match(:,1),P2match(:,2),'bo');
% for p=1:size(P1,1)
%   plot([P1(p,1) P2match(p,1)],[P1(p,2) P2match(p,2)],'k-');
% end

% TODO:
% - make faster by limiting iterations (or do a quick search to figure out which seed is best)?
%    - upper limit of 1000??
% - reduce number of seeds?

% define options
options = optimset('Display','iter','FunValCheck','on','MaxFunEvals',Inf,'MaxIter',Inf,'TolFun',1e-3,'TolX',1e-3);

% define seeds
params0 = [];
for p=[-1 1]
  for q=90:90:360
    params0 = cat(1,params0,[1 p q 1 1]);
  end
end

% prepare
n = size(P1,1);
P1n = [P1'; ones(1,n)];
P2n = [P2'; ones(1,n)];

% what is the base size?
sz = computespread(P1n);
adjustfun = @(a) adjustspread(a,sz/computespread(a));

% try all seeds
resnormbest = Inf;
paramsA = zeros(size(params0,1),5);
resnormA = zeros(1,size(params0,1));
parfor p=1:size(params0,1)
  [params,resnorm,d,exitflag] = ...  % extra sqrt because lsqnonlin squares the error terms for us!
    lsqnonlin(@(a) sqrt(sqrt(sum((P1n-adjustfun(applytr(a,P2n))).^2,1))),params0(p,:),[],[],options);
  assert(exitflag >= 0);
  paramsA(p,:) = params;
  resnormA(p) = resnorm;
end
[d,ix] = min(resnormA);
paramsbest = paramsA(ix,:);

% return output
P2match = adjustfun(applytr(paramsbest,P2n));
P2match = P2match(1:2,:)';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function f = applytr(params,pts)

% function f = applytr(params,pts)
%
% <params> is [a b c d e] where
%   a is the scale factor (constrained to be non-negative),
%   b is the sign multiplier to achieve flips (we force to be 1 or -1),
%   c is the rotation in degrees,
%   d is the x-offset
%   e is the y-offset
% <pts> is 3 x N with the points
%
% return <f> as the transformed <pts> (3 x N).

% prepare
s = abs(params(1));
g = 2*((params(2) > 0) - .5);
r = params(3)/180*pi;
tx = params(4);
ty = params(5);

% compute
T1 = [s 0   0;               % scale and flip
      0 g*s 0;
      0 0   1];
T2 = [cos(r) -sin(r) 0;      % rotate 
      sin(r)  cos(r) 0;
      0       0      1];
T3 = [1 0 tx                 % translate
      0 1 ty
      0 0  1];
f = (T3*T1*T2)*centroidtoorigin(pts);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function f = computespread(pts)

% function f = computespread(pts)
%
% <pts> is 3 x N with the points
%
% compute the mean distance from the centroid.
% this can be thought of as the "spread" of the points.

f = mean(sqrt(sum(zeromean(pts(1:2,:),2).^2,1)));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function pts = centroidtoorigin(pts)

% function pts = centroidtoorigin(pts)
%
% <pts> is 3 x N with the points
%
% set the centroid to the origin.

pts(1:2,:) = zeromean(pts(1:2,:),2);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function pts = adjustspread(pts,sc)

% function pts = adjustspread(pts,sc)
%
% <pts> is 3 x N with the points
% <sc> is a scale factor
%
% zoom the points from their centroid by scale factor <sc>.

center0 = mean(pts(1:2,:),2);
pts(1:2,:) = bsxfun(@plus,bsxfun(@minus,pts(1:2,:),center0) * sc,center0);
