function Y = thresholdAndScale(X, thold, nValues)
%THRESHOLDANDSCALE Thresholds and scales an image. 
%   Y = THRESHOLDANDSCALE(X, THOLD, NVALUES) takes a THOLD = [LOW HIGH],
%   the number of values NVALUES and an input matrix X. Values in X below 
%   LOW or exciding HIGH will be thresholded to LOW and HIGH respectivly, 
%   and then be scaled from 0 to NVALUES-1. The 
%   resulting matrix is returned as Y. 
%
%   Example:
%   If   X = [0 1 2
%             3 4 5]
% 
%   then THRESHOLDANDSCALE(X, [2,4], 3) returns
%        Y = [0 0 0
%             1 2 2]


Y=X;
low=thold(1);
high=thold(2);
Y(Y>high)=high;
Y(Y<low)=low;
Y=floor((nValues-1)*(Y-low)./(high-low));


end

