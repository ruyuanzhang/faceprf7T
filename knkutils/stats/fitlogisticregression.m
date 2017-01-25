function params = fitlogisticregression(X,y)

% function params = fitlogisticregression(X,y)
%
% <X> is a matrix of regressors (points x regressors)
% <y> is a vector of 0s and 1s (points x 1)
%
% use lsqnonlin.m to fit a logistic regression model relating X to y.
% the output of the model is as follows:
%   y = 1./(1+exp(-(X*params)))
% the output is interpreted as a probability value (binomial distribution).
%
% return estimated parameters in <params> (regressors x 1).
% note that we use a random initial seed for <params>.
%
% also see glmfit.m from the Statistics Toolbox.
%
% example:
% class0 = randn(100,2);
% class1 = 2+randn(100,2);
% ylabel = [zeros(100,1); ones(100,1)];
% params = fitlogisticregression([cat(1,class0,class1) ones(200,1)],ylabel);
% figure; hold on;
% scatter(class0(:,1),class0(:,2),'bo');
% scatter(class1(:,1),class1(:,2),'ro');
% axis([-3 6 -3 6]);
% axis square;
% [xx,yy] = meshgrid(-3:.1:6,-3:.1:6);
% vals = evallogisticregression(params,[xx(:) yy(:) ones(numel(xx),1)]);
% contour(xx,yy,reshape(vals,size(xx)),.1:.1:.9);
% colormap(jet);

costfun = @(pp) -sum((y .* log(evallogisticregression(pp,X)+eps)) + ...
                     ((1-y) .* log(1-evallogisticregression(pp,X)+eps)));
options = optimset('Display','off','FunValCheck','on','MaxFunEvals',Inf, ...
                   'MaxIter',Inf,'TolFun',1e-6,'TolX',1e-6);  %,'Algorithm','levenberg-marquardt');
params = lsqnonlin(costfun,randn(size(X,2),1),[],[],options);
