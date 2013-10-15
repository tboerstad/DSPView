classdef ImagingSystem < handle
    %IMAGINGSYSTEM Class implementing an ultrasound post-processing system.
    %   IMAGINGSYSTEM is responsible the brain of the operation.
    %   The class keeps control over all settings and parameters, 
    %   and also calls the different algorithms when necessary. 
    
    properties(Access = private)
        
        % Velocity estimator settings
        velEstParams = VelocityEstimatorParams(); % Seperate struct
        velFiltOrder = 0; % TBD TBD
        velFiltFreq  = 2; % Cut off freq (Hz) TBD
        
        % Strain estimator settings
        strainEstParams = StrainEstimatorParams(); % Parameters are kept
                                                   % in a struct. 
        strainEstimator = @strainEstimatorLSQ;     % Function handle of
                                                   % strain estimator. 
        
        % Elastography estimator settings. 
        eFiltOrder = 7;  % Number of strain frames to use for each 
                          % elastogram. 
        eThr       = 0.9; % TBD TBD TBD
        weights    = [];  % TBD TBD TBD
        
        % Imaging parameters
        imParams     = ImagingParams();
        rfFile       = []; % Full path to RF data set
        rfSize       = []; % # of pixels and frames [axial, lateral, 
                           %   noFrames] in RF data set
        
        % RF bandpass filter properties
        rfFiltEn = 0;        % If set to 1, enables RF filtering
        rfFiltGen = @fir1;   % Function handle to FIR filter generator
        rfFiltFreqs = [3 6]; % Passband low and high cutoff freq , in MHz
        rfFiltOrder = 30;    % Number of FIR filter coefficients. 
        rfFiltCoeff = [];    % The FIR filter coefficients. 
        
        % Buffers 
        bufLength     = 30;
        rfBuffer      = [];
        velBuffer     = [];
        cVelBuffer    = [];
        strainBuffer  = [];
        cStrainBuffer = [];
    end
    
    methods     
        % Constructor, handles initial setup based on input RF
        % data file
        function obj = ImagingSystem(fileName)
            openDataFile(obj, fileName)
            readImagingParams(obj)
            initRfBuffer(obj)
        end
        function close(obj)
            if ~isempty(obj.rfFile)
                obj.rfFile.close();
            end
        end
        function openDataFile(obj, fileName)
             [~, ~, ext]=fileparts(fileName);
            switch ext
                case '.rf'
                    msgbox(strcat('Support for .rf files has been', ...
                        'removed due to licensing issues'));
                case '.mat'
                    obj.rfFile = RfFile(fileName);
            end           
        end
        % Fetches metadata from RF data file. 
        function readImagingParams(obj)
            header = obj.rfFile.gvHeader();
            obj.imParams.fs=header.sf;
            obj.imParams.PRF=header.dr;
            obj.rfSize=[header.h, header.w, header.frames];            
        end
        
        %%% Helper functions for the matrix cache %%%
        function initRfBuffer(obj)
            obj.rfBuffer = MatrixBuffer(obj.rfSize, obj.bufLength);
            initVelBuffer(obj);
        end
        function initVelBuffer(obj)
            velSize = [obj.rfSize] - ...
                [obj.velEstParams.yLost, obj.velEstParams.xLost, 0];
            obj.velBuffer    = MatrixBuffer(velSize, obj.bufLength);
            obj.cVelBuffer   = MatrixBuffer(velSize, obj.bufLength);
            initStrainBuffer(obj);
        end
        function initStrainBuffer(obj)
            strainSize = obj.velBuffer.size() - ...
                [obj.strainEstParams.yLost, 0, 0];
            obj.strainBuffer  = MatrixBuffer(strainSize, obj.bufLength);
            obj.cStrainBuffer = MatrixBuffer(strainSize, obj.bufLength);
            initWeights(obj);
        end
        function initWeights(obj)
             obj.weights = zeros(1, obj.rfSize(3));
        end
        function setBufLength(obj, N)
            obj.bufLength = N;
            obj.initRfBuffer();
        end        
        function clearBuffers(obj)
            obj.rfBuffer.clear();
            obj.velBuffer.clear();
            obj.cVelBuffer.clear();
            obj.strainBuffer.clear();
            obj.cStrainBuffer.clear();
            initWeights(obj);
        end
          
        %%% Support functions returning data about the    %%%
        %%% current ImagingSystem configuration           %%%
        function ratio  = aspectRatio(obj)
            ax1=obj.getLateralAxis();
            ax2=obj.getDepthAxis();
            ratio=ax1(end)/ax2(end);
        end
        function N      = noFrames(obj)
            N = obj.rfSize(3);
        end
        function dim    = rfDim(obj)
            dim = obj.rfSize(1:2);
        end
        function ax     = getLateralAxis(obj)
            ax=obj.rfFile.gvLateralAxis('mm');
        end
        function ax     = getDepthAxis(obj)
            ax=obj.rfFile.gvDepthAxis(1540,'mm');            
        end
        function ax     = getFreqAxis(obj)
            [~, ax] = pwelch(zeros(1,obj.rfSize(1)));
            ax = ax*obj.imParams.fs/(1e06*2*pi);
        end
        function ax     = getTimeAxis(obj)
            ax = 0:(obj.rfSize(3)-1);
            ax = ax/obj.imParams.PRF;
        end
        function w      = getWeights(obj, firstFrame, n)
            if obj.eFiltOrder == 0
                w=1;
                return
            end
            w = obj.weights(firstFrame:n);
          %  w = w./max(w);
          %  disp(w);
            % All frames must have a minimum weighting
         %   minWeight = 1/(obj.eFiltOrder+1);
         %   w( w < minWeight) = minWeight;
            
            % No frame should be have more than 20% weight than others
          %  w( w > 1.2 * minWeight) = 1.2 * minWeight;
            
            % Normalize so we do not shift the scale
            w=w./sum(w);
            disp(w);
        end
        
        %%% Setting of parameters for the differen algorithms %%%
        function rfFilt(obj, enable, order, freqs)
            obj.rfFiltEn=enable;
            obj.rfFiltOrder=order;
            obj.rfFiltFreqs=2*freqs./(obj.imParams.fs*1e-06);
            obj.rfFiltCoeff=obj.rfFiltGen(order, obj.rfFiltFreqs);
            obj.clearBuffers();
        end %Note renambe to param
        function velEstParam(obj, rngGate, latGate, twoDimCorrEn, fDem, unwrapEn, ensembleLength, velFiltOrder, velFiltCutOff)
            obj.velEstParams.rangeGate      = rngGate;
            obj.velEstParams.lateralGate    = latGate;
            obj.velEstParams.ensembleLength = ensembleLength;
            obj.velEstParams.twoDimEn       = twoDimCorrEn;
            obj.velEstParams.fDemodulation  = fDem*1e06./obj.imParams.fs;
            obj.velEstParams.unwrapEn       = unwrapEn;
            
            % It is not strictly necessary to clear the buffer if only the
            % velFilter parameters change
            obj.initVelBuffer();
        end
        function strainEstParam(obj, dx, strainAlg)
            obj.strainEstParams.dx = dx;
            switch strainAlg
                case 'Normal'
                    obj.strainEstimator = @strainEstimator;
                case 'Least-Squares'
                    obj.strainEstimator = @strainEstimatorLSQ;
            end
            initStrainBuffer(obj);
        end        
        function elastoParam(obj, eFiltOrder, eThr)
            obj.eFiltOrder=eFiltOrder;
            obj.eThr=eThr;
        end

        %%% Calculations of different images %%%
        function idx = calcRfFrame(obj, n)
            idx = obj.rfBuffer.isInBuf(n);
            if idx % frame in buffer, do nothing
                return
            end
            
            % Get the index into the buffer
            idx = obj.rfBuffer.newIndex(n);
            
            % get frame from file
            rfFrame = double(obj.rfFile.gvFrame(n));
            
            if obj.rfFiltEn
                rfFrame=filter2(obj.rfFiltCoeff', rfFrame);
            end
            obj.rfBuffer.buf(:,:,idx)=hilbert(rfFrame);
        end
        function idx = calcVelFrame(obj, n)
            idx = obj.velBuffer.isInBuf(n);
            if idx % frame in buffer, do nothing
                return
            end
            
            % Get new index
            idx  = obj.velBuffer.newIndex(n);
            idxC = obj.cVelBuffer.newIndex(n); 

            N = obj.velEstParams.ensembleLength;
            X = zeros([obj.rfSize(1:2), N]);
            for i=1:N
                idxRf=obj.calcRfFrame(n-N+i);
               % n-5*N+5*i
                X(:,:,i) = obj.rfBuffer.buf(:,:,idxRf);
            end
            
            [obj.velBuffer.buf(:,:,idx), obj.cVelBuffer.buf(:,:,idxC)] = ...
                velocityEstimator(X, obj.imParams, obj.velEstParams);
        end
        function idx = calcStrainFrame(obj, n)
            idx = obj.strainBuffer.isInBuf(n);
            if idx
                return;
            end
            
            idx  = obj.strainBuffer.newIndex(n);
            cIdx = obj.cStrainBuffer.newIndex(n);
            
            [velFrame, cVelFrame]  = obj.velFrame(n);
            
            [obj.strainBuffer.buf(:,:,idx), obj.cStrainBuffer.buf(:,:,cIdx)] = ...
                obj.strainEstimator(velFrame, cVelFrame, ... 
                obj.strainEstParams, obj.imParams);
            
            obj.weights(n)=sum(sum(abs(obj.strainBuffer.buf(:,:,idx))));   
            
        end
          
        function [frame, varargout] = getFrame(obj, n, modality)
            % User wants quality measure
            if nargout == 2
                switch(modality)
                    case 'vel'
                        [frame, varargout{1}] = velFrame(obj, n);
                    case 'strain'
                        [frame, varargout{1}] = strainFrame(obj, n);
                    case 'absStrain'
                        [frame, varargout{1}] = strainFrame(obj, n);
                        frame=abs(frame);
                    case 'elasto'
                        [frame, varargout{1}] = elastoFrame(obj, n);
                end                
            elseif nargout == 1
                switch(modality)
                    case 'bMode'
                        frame = bModeFrame(obj, n);
                    case 'vel'
                        frame = velFrame(obj, n);
                    case 'strain'
                        frame = strainFrame(obj, n);
                    case 'absStrain'
                        frame = abs(strainFrame(obj, n));
                    case 'elasto'
                        frame = elastoFrame(obj, n);
                    case 'rf'
                        frame = rfFrame(obj,n);
                end
            end
        end
        function [frame, varargout] = strainFrame(obj, n)
            % Needs two RF frames to calculate strain
            if n<2
                dim=obj.strainBuffer.size();
                frame=zeros(dim(1:2));
                if nargout == 2
                    varargout{1} = zeros(dim(1:2));
                end
                return
            end
            idx=obj.calcStrainFrame(n);
            frame=obj.strainBuffer.buf(:,:,idx);
            
            if nargout == 2
                varargout{1} = obj.cStrainBuffer.buf(:,:,idx);
            end
        end
        function frame = rfFrame(obj, n)
            idx=obj.calcRfFrame(n);
            frame=obj.rfBuffer.buf(:,:,idx);
        end
        function frame = bModeFrame(obj, n)
            idx=obj.calcRfFrame(n);
            frame=20*log10(abs(obj.rfBuffer.buf(:,:,idx)));
        end
        function [frame, varargout] = velFrame(obj, n)
            dim          = obj.velBuffer.size();
            % Must fill entire ensemble length and entire low pass filter
            if (n < obj.velEstParams.ensembleLength) || ...
               n < obj.velFiltOrder+2
                frame = zeros(dim(1:2));
                if nargout == 2
                    varargout{1} = zeros(dim(1:2));
                end
                return                
            end
            if obj.velFiltOrder == 0
                w=1;
            else
                f_c = 2*obj.velFiltFreq/(obj.imParams.PRF);
                w = fir1(obj.velFiltOrder,  f_c);
                w = w./sum(w);
            end

            firstFrame = n - obj.velFiltOrder;
            
            frame = zeros(dim(1:2));
            if nargout == 2
                cFrame = zeros(dim(1:2));
            end
            fIdx=1;
            for i=(firstFrame):n
                idx=obj.calcVelFrame(i);
                frame = frame+w(fIdx)*obj.velBuffer.buf(:,:,idx);
                if nargout ==2 
                    cFrame = cFrame + w(fIdx)*obj.cVelBuffer.buf(:,:,idx);
                end
                fIdx=fIdx+1;
            end
            if nargout == 2
                varargout{1} = cFrame;
            end
            
            %%% Let's attempt with averging, uncomment below to not do so
            % Needs two RF frames to calculate velocity
            %if n<2
            %    dim=obj.velBuffer.size();
            %    frame=zeros(dim(1),dim(2));
            %    return
            %end
            %idx = obj.calcVelFrame(n);
            %frame=obj.velBuffer.buf(:,:,idx);
        end
        function [frame, varargout] = elastoFrame(obj, n)
            dim=obj.strainBuffer.size();
            if n < (obj.eFiltOrder + 2)
                frame=zeros(dim(1:2));
                if nargout == 2
                    varargout{1} = zeros(dim(1:2));
                end
                return
            end
            
            firstFrame = n - obj.eFiltOrder;
            for i = firstFrame:n
                [~] = obj.calcStrainFrame(i);
            end
            
            f_c = 2/(obj.imParams.PRF); % WARNING FIXED TO 2 HZ
            w = fir1(obj.eFiltOrder,  f_c);
            w = w./sum(w);
            cFrame = zeros(dim(1:2));
            frame = zeros(dim(1:2));
            fIdx = 1;
            for i=firstFrame:n
                    [currFrame, currCFrame] = obj.strainFrame(i);
                    frame = frame + w(fIdx)*abs(currFrame);
                    cFrame = cFrame + 1/(obj.eFiltOrder+1)*currCFrame;
                fIdx=fIdx+1;
            end
            if nargout == 2
                varargout{1} = cFrame;
            end
            
            c2=cFrame;
            c2(c2>obj.eThr)=1;
            c2(c2<=obj.eThr)=0;
            [tol]=stretchlim(c2.*frame, [0,0.98]);
            frame=frame./tol(2);
            
        end        
    
        %%% Calculations of lines etc %%%
        function x = getLine(obj, n, i, modality)
            switch(modality)
                case 'rfLine'
                    x = rfLine(obj, n, i);
                case 'rfLineFreq'
                    x = rfLineFreq(obj, n, i);
            end
        end           
        function x = rfLine(obj, n, i)
            idx = obj.calcRfFrame(n);
            x = real(obj.rfBuffer.buf(:,i,idx));            
        end
        function Pxx = rfLineFreq(obj, n, i)
            x = rfLine(obj, n, i);
            Pxx = pwelch(x);
            Pxx=10*log10(Pxx);
        end
        
    end
    
end
