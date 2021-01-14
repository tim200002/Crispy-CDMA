classdef HammingDecoder < ChannelDecoder
% HAMMINGDECODER is a class for decoding Hamming encoded binary signals.
% It uses the Communications System Toolbox.

    properties
        nBitsParity
    end
    
    methods
        function obj = HammingDecoder(nBitsParity)
            obj@ChannelDecoder(2^nBitsParity - 1, 2^nBitsParity - 1 - nBitsParity);
            obj.nBitsParity = nBitsParity;
        end
        
        function decoded = step(obj, signal)
        % STEP performs the Hamming decoding of the binary Signal object
        % "signal" and returns the result as binary Signal object "decoded"
        
            nMessageWords = floor(signal.lengthInBits / obj.nBitsCodeword);
            bitvec = double(signal.selectFromBitToBitAsBitvector(1, nMessageWords * obj.nBitsCodeword));
            if length(bitvec) ~= signal.lengthInBits
                warning("not all (only "+length(bitvec)+" of "+signal.lengthInBits+" bits) have been decoded");
            end
            decData = decode(bitvec, obj.nBitsCodeword, (obj.nBitsCodeword - obj.nBitsParity));
            decoded = Signal(decData, signal.fs, 'Bits', signal.details);
        end
    end
end