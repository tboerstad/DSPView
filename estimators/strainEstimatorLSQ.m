function [S, S_C] = strainEstimatorLSQ(V, C, PARAMETERS, CONSTANTS)
%STRAINESTIMATORLSQ Least-squares implementation of strainEstimator. 
%   Similar to the strainEstimator estimator, but instead of using 
%   just two samples, strainEstimatorLSQ uses a total of "PARAMETERS.DX"
%   velocity samples for each strain estimate, using a least-squares 
%   equation
%  
%   PARAMETERS contains parametere (dx), the number of axial samples to use.
%   CONSTANTS contains constants (Fs, PRF, c) from the ultrasound recording. 
%
%   See also strainEstimator, VELOCITYESTIMATOR, StrainEstimatorParams, ImagingParams 

T_s        = 1/CONSTANTS.fs;
T_PR       = 1/CONSTANTS.PRF;
c_0        = CONSTANTS.c;
delta_m    = PARAMETERS.dx;
kappa      = 2*T_PR/(c_0*T_s);

n = delta_m+1;

h   = 12/(n*(n^2-1)) * ( (n:-1:1) - (n+1)/2 )';
h_c = 1/n*ones(n,1);

S   = kappa*conv2(V,h,'valid');
S_C = conv2(C,h_c,'valid');
