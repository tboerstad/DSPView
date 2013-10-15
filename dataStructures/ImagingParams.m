classdef ImagingParams
%ImagingParams Struct with parameters used during an ultrasound scan
%   fs  = Sampling frequency of the RF lines [Hz]
%   PRF = Pulse repetition frequency         [Hz]
%   c   = Speed of sound in recorded medium  [m/s]
    
    properties
        fs=20e06; 
        PRF=49;   
        c=1540;
    end
    
    methods
    end
    
end

