function [xCords, yCords] = centerCoords(priSize, secSize)
%CENTERCOORDS Finds coordinates aligning a sub-image to a larger image
%   [XCORDS, YCORDS] = CENTERCOORDS(PRISIZE, SECSIZE) calculates the first
%   the first and last column and row indices to align a sub-matrix to
%   a larger matrix. 
%
%   This is useful, for example, if you want to superimpose a 3x3 image 
%   on top of a 7x7 image.
%
%   Example:
%   [XCORDS, YCORDS] = CENTERCOORDS([7 7], [3 3]) will return 
%   XCORDS = [3 5], which is the starting and ending column-indices 
%   of the largest image where the smaller image should be superimposed.
%   The same goes for YCOORDS, which contains the row-indices. 
%   

offset = ceil((priSize-secSize+1)/2);
xCords = [offset(2), offset(2)+secSize(2)-1];
yCords = [offset(1), offset(1)+secSize(1)-1];


end

