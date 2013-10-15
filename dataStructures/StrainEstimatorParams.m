classdef StrainEstimatorParams
%StrainEstimatorParams Parameters used by strain estimation algorithm. 
%   dx = The axial distance over which to calculate strain (in number of
%        samples)
%   
%   See also: StrainEstimator, StrainEstimatorLSQ
    
    properties
        dx = 90;
        method = 'Least-Squares';
    end    
    methods
        function y = yLost(obj)
            y=obj.dx;
        end
    end
end

