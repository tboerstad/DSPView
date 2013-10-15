function [S, S_C] = strainEstimator(V, C, PARAMETERS, CONSTANTS)
% STRAINESTIMATOR Estimates axial strain from two axial velocity estimates. 
%   [S, S_C] = STRAINESTIMATOR(V, C, PARAMETERS, CONSTANTS) returns a 
%   matrix S of estimates of axial strain values. Two axial velocity 
%   estimates are used in each strain estimate.
%   S_C represents the correlation coefficients of the strain estimates, 
%   based on the correlation coefficients C of the velocity estimates. 
%   PARAMETERS contains parameters, dx axial distance between samples.
%   CONSTANTS contains constants (Fs, PRF, c) from the ultrasound recording. 
%
%   See also strainEstimatorLSQ, VELOCITYESTIMATOR, StrainEstimatorParams, ImagingParams 

T_s        = 1/CONSTANTS.fs;
T_PR       = 1/CONSTANTS.PRF;
c_0        = CONSTANTS.c;
delta_m    = PARAMETERS.dx;
kappa      = 2*T_PR/(c_0*T_s);

% Filter kernel
h            = zeros(delta_m + 1,1);
h(1)         = kappa/delta_m;
h(delta_m+1) = -kappa/delta_m;

h_c            = zeros(delta_m + 1, 1);
h_c(1)         = 1/2;
h_c(delta_m+1) = 1/2;

S = conv2(V, h, 'valid');
S_C = conv2(C, h_c, 'valid');
