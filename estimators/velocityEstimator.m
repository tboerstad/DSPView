function [gamma_0_1, C] = velocityEstimator(X, CONSTANTS, PARAMETERS)
% VELOCITYESTIMATOR Estimates velocity from an RF-signal
%   [gamma_0_1, C] = VELOCITYESTIMATOR(X, Constants, Parameters) returns
%   a matrix gamma_0_1 containing axial velocity estimates between two 
%   consecutive axial samples. C is a matrix containing the correlation
%   coefficient for the returned samples. 
%
%   PARAMETERS is a struct of type VelocityEstimatorParams.
%   CONSTANTS  is a struct of type ImagingParams. 
%
%   See also: VelocityEstimatorParams, ImagingParams 

c   = CONSTANTS.c;
fs  = CONSTANTS.fs;
PRF = CONSTANTS.PRF;

twoDimEn = PARAMETERS.twoDimEn;
unwrapEn = PARAMETERS.unwrapEn;
fDem     = PARAMETERS.fDemodulation;
U = PARAMETERS.rangeGate;
V = PARAMETERS.lateralGate;
O = PARAMETERS.ensembleLength;

X_conj = conj(X);



gamma_0_1 = sum(X(1:end-1,:,1:end-1).*X_conj(1:end-1,:,2:end),3);
gamma_0_1 = conv2(gamma_0_1, ones(U,1), 'valid');
gamma_0_1 = conv2(gamma_0_1, ones(1,V), 'valid');

if twoDimEn
    gamma_1_0 = sum(X(1:end-1,:,:).*X_conj(2:end,:,:),3);
    gamma_1_0 = conv2(gamma_1_0, ones(U,1), 'valid');
    gamma_1_0 = conv2(gamma_1_0, ones(1,V), 'valid');
end


C = sum(X(1:end-1,:,:).*X_conj(1:end-1,:,:),3);
C = conv2(C, ones(U,1), 'valid');
C = conv2(C, ones(1,V), 'valid');
C = (O/(O-1))*abs(gamma_0_1)./C;

if unwrapEn
    angle_gamma_0_1=unwrap(angle(gamma_0_1));
else
    angle_gamma_0_1=(angle(gamma_0_1));
end

if twoDimEn
    gamma_0_1=c*PRF/(2*fs) * angle_gamma_0_1./(angle(gamma_1_0));
else
    gamma_0_1=-c*PRF/2 * angle_gamma_0_1./(2*pi*fDem*fs);
end



end
