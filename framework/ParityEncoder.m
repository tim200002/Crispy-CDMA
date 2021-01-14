classdef ParityEncoder < ChannelEncoder
% PARITYENCODER encodes binary Signal objects with a parity check code
% where nBitsInfo bits of the uncoded signal are XOR-ed with each other.
% This is concatenated to the uncoded signal word.

    properties
        nBitsParity % number of parity bits
    end
    methods
        function obj = ParityEncoder(nBitsInfo)
            nBitsInfo = round(nBitsInfo);
            nBitsParity = nBitsInfo * (nBitsInfo - 1) / 2;
            obj@ChannelEncoder(nBitsInfo + nBitsParity, nBitsInfo);
            obj.nBitsParity = nBitsParity;
        end
        
        function coded = step(obj, signal)
        % STEP performs the encoding of the binary Signal object "signal" 
        % with the parity code
        
            ordered = signal.divideInBitBlocks(obj.nBitsInfo, 'matrix', false);
            if numel(ordered) < signal.lengthInBits
                warning("only "+numel(ordered)+" of "+signal.lengthInBits+" bits processed");
            end
            
            xorselection = nchoosek(1:obj.nBitsInfo, 2);
            
            paritybits = xor(ordered(:, xorselection(:, 1)), ordered(:, xorselection(:, 2)));
            
            coded = [ordered paritybits]';
            coded = Signal(coded(:), signal.fs, 'Bits', signal.details);
        end
        
        function decod = getDecoder(obj)
        % GETDECODER returns a ParityDecoder object "decod" whose 
        % parameters fit to the ParityEncoder "obj"
        
            decod = ParityDecoder(obj.nBitsInfo);
        end
        
        function dHamming = getMinimumHammingDist(obj)
        % GETMINIMUMHAMMINGDIST returns the minimum Hamming distance for
        % the parity code used by the ParityEncoder "obj"
        
            dHamming = obj.nBitsInfo;
        end
    end
end