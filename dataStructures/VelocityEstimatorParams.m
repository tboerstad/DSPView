classdef VelocityEstimatorParams
%VelocityEstimatorParams Parameters used by strain estimation algorithm. 
%   rangeGate      = number of lateral samples used in each estimate. 
%   lateralGate    = number of depth samples used in each estimate.
%   ensembleLength = number of time samples used in each estimate. 
%   twoDimEn       = If set to 1, enables 2-dimensional velocity estimator
%   unwrapEn       = If set to 1, enables phase unwrapping.  
%   fDemodulation  = used only for 1-dimension velocity estimator, 
%                    this is the fixed demodulation frequency
%
%   See also: VelocityEstimator
    properties
        rangeGate = 20;
        lateralGate = 4;  
        ensembleLength = 2;
        twoDimEn = 1;
        unwrapEn = 1;
        fDemodulation = 0.5;
    end    
    
    methods
        function x = xLost(obj)
            x=obj.lateralGate-1;
        end
        function y = yLost(obj)
            y=obj.rangeGate;
        end
    end
end

