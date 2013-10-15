classdef RfFile < handle
    %RFFILE Helper class responsible for reading in RF data from a file. 
    %   RFFILE is also responsible for reading in the metadata from the 
    %   ultrasound scan, such as the sampling frequency used. 
    
    properties
            sf    = 20e06; % RF sampling freq
            pitch = 0.0003; % transducer probe pitch
            dr    = 46; % Framerate (PRF)
            c     = 1540; % Speed of sound
            X     = []; % Stores the RF data matrix. 
    end
    
    methods
        function obj = RfFile(fileName)
            load(fileName,'pulse_repetition_frequency', ...
                'transducer_pitch','rf_data_set', ...
               'rf_sampling_frequency');
            obj.X=rf_data_set;
            obj.dr=pulse_repetition_frequency;
            obj.sf=rf_sampling_frequency;
            obj.pitch=transducer_pitch;
            clear pulse_repetition_frequency ...
                transducer_pitch rf_data_set ...
               rf_sampling_frequency;
        end
        % Returns a datastructure containing metadata. 
        function hdr = gvHeader(obj)
            hdr.sf=obj.sf;
            hdr.dr=obj.dr;
            hdr.h=size(obj.X,1);
            hdr.w=size(obj.X,2);
            hdr.frames=size(obj.X,3);
        end
        function frm = gvFrame(obj, idx)
            frm = obj.X(:,:,idx);
        end
        function ax=gvDepthAxis(obj, ~, ~)
           ax = 0:size(obj.X,1)-1; 
           ax=ax./obj.sf;
           ax=ax.*obj.c/2;
           ax=1e3*ax;
        end
        function ax=gvLateralAxis(obj, ~, ~)
            ax=0:obj.pitch:((size(obj.X,2)-1)*obj.pitch);
            ax=ax*1e3;
        end
        function close(obj)
            % dummy function
        end
    end
    
end

