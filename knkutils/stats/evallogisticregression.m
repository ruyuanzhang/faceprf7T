function y = evallogisticregression(params,X)

% function y = evallogisticregression(params,X)
%
% <params> is a column vector of weights (regressors x 1)
% <X> is a matrix of regressors (points x regressors)
%
% evaluate the logistic regression model at <X>, returning
% a column vector (points x 1).  the values that are returned
% range between 0 and 1.
%
% example:
% params = [4 1]';
% X = (-2:.1:2)';
% X(:,2) = 1;
% y = evallogisticregression(params,X);
% figure; hold on;
% plot(X(:,1),y,'r-');

y = 1./(1+exp(-(X*params)));
