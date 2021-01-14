classdef HammingEncoder < ChannelEncoder
% HAMMINGENCODER is a class for Hamming encoding binary signals.
% It uses the Communications System Toolbox.

    properties
        nBitsParity
    end
    
    methods
        function obj = HammingEncoder(nBitsParity)
            if nBitsParity > 11
                error("number of parity bits too high");
            end
            obj@ChannelEncoder(2^nBitsParity - 1, 2^nBitsParity - 1 - nBitsParity);
            obj.nBitsParity = nBitsParity;
        end
        
        function coded = step(obj, signal)        
        % STEP performs the Hamming encoding of the binary Signal object
        % "signal" and returns the result as binary Signal object "coded"
        
            nMessageWords = floor(signal.lengthInBits / obj.nBitsInfo);
            bitvec = double(signal.selectFromBitToBitAsBitvector(1, nMessageWords * obj.nBitsInfo));
            if length(bitvec) ~= signal.lengthInBits
                warning("not all (only "+length(bitvec)+" of "+signal.lengthInBits+" bits) have been encoded");
            end
            encData = encode(bitvec, obj.nBitsCodeword, obj.nBitsInfo, 'hamming/binary');
            coded = Signal(encData, signal.fs, 'Bits', signal.details);
        end
        
        function decod = getDecoder(obj)
        % GETDECODER returns a HammingDecoder object "decod" whose 
        % parameters fit to the HammingEncoder "obj"
        
            decod = HammingDecoder(obj.nBitsParity);
        end
        
        function dHamming = getMinimumHammingDist(obj)
        % GETMINIMUMHAMMINGDIST returns the constant minimum Hamming 
        % distance for Hamming codes, in general 3
        
            dHamming = 3;
        end
    end
end