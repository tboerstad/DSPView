classdef MatrixBuffer < handle
%MATRIXBUFFER Class implementing an in-memory buffer for matrices. 
%   Working with large matrices can be computationally intensive.
%   Rather than calculating a matrix from scratch each time it is needed,
%   MATRIXBUFFER lets you store a variable number of matrices in a cache.
%   If a matrix has recently been calculated, MATRIXBUFFER will fetch 
%   a cached copy rather than recalculate the matrix. 

    properties
        bufSize = [];   % Capacity in # of matrices. 
        dim = [];       % Number of rows and columns [R, C] in matrix.
        idx2buf = [];   % Binary array, idx2buf(i) is 1 if index i is 
                        % present in cache, 0 if not. 
        buf2idx = [];   % Maps each entry in the cache to a matrix index. 
        buf = [];       % The cached matrix store
        bufCounter = 0; % Help variable keeping count of where to place
                        % the next matrix to be cached. 
    end
    
    methods
        function obj = MatrixBuffer(dimensions, bufSize)
            obj.bufSize = bufSize;
            obj.dim     = dimensions(1:2);
            obj.buf     = zeros([dimensions(1:2), bufSize]);
            obj.idx2buf = zeros(1, dimensions(3));
            obj.buf2idx = zeros(1, bufSize);
        end
        function dim = size(obj)
            dim = [obj.dim, length(obj.idx2buf)];
        end
        function res = isInBuf(obj, i)
            if obj.idx2buf(i) % frame in buffer
                res = obj.idx2buf(i);
            else 
                res = 0;
            end 
        end 
        % Returns an index into the cache to use based on the matrix 
        % index i
        function newIdx = newIndex(obj, i)
            obj.bufCounter=mod(obj.bufCounter,obj.bufSize)+1;
            % invalidate previous entry
            idxPrev = obj.buf2idx(obj.bufCounter);
            if idxPrev
                obj.idx2buf(idxPrev)=0;
            end
            newIdx=obj.bufCounter;
            obj.idx2buf(i)=newIdx;
            obj.buf2idx(newIdx)=i;
        end
        function clear(obj)
            obj.idx2buf     = zeros(1, length(obj.idx2buf));
            obj.buf2idx     = zeros(1, obj.bufSize);
        end
    end
end