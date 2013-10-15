function [cMin, cMax] = autoScale(X, displayType)
%AUTOSCALE Suggests min and max values for color mapping.
%   [CMIN, CMAX] = AUTOSCALE(X, DISPLAYTYPE) returns the suggested minimum
%   value CMIN and maximum value CMAX, based on the input image X
%   and the type of image DISPLAYTYPE: 
%     'bMode'     - Represents an ultrasound B-mode image
%     'vel'       - Represents a velocity image
%     'strain'    - Represents a strain image
%     'absStrain' - Represents a strain magnitude image
%     'elasto'    - Represents an elastogram image 

% If the input matrix is all zeros.
% use default values
if nnz(X) == 0
    switch(displayType)
        case {'strain','vel'}
            cMin = -0.001;
            cMax = 0.001;
        case {'absStrain', 'elasto'}
            cMin = 0;
            cMax = 0.001;
    end
    return
end

% Colormap suggestions are based on three-sigma boundaries
my=mean(X(:));
sig=std(X(:));
a=3;
X(X > my+a*sig)=my;
X(X < my-a*sig)=my;
sig = std(X(:));
cMin = my - a*sig;
cMax = my + a*sig;

% Different modalities look better with different floating point precision.  
switch(displayType)
    case 'bMode'
        cMin = str2double(sprintf('%1.0f',cMin));
        cMax = str2double(sprintf('%1.0f',cMax));
    case {'strain','vel'}
        maxAbs = max([abs(cMin), cMax]);
        cMin = str2double(sprintf('%0.4f', -maxAbs));
        cMax = str2double(sprintf('%0.4f', maxAbs));
    case {'absStrain', 'elasto'}
        cMin = 0;
        cMax = str2double(sprintf('%0.4f', cMax));
end