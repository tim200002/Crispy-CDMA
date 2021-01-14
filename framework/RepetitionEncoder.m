classdef RepetitionEncoder < ChannelEncoder
% REPETITIONENCODER is able to encode binary Signal objects with repetition
% codes

    methods
        function obj = RepetitionEncoder(nRepetitions)
            obj@ChannelEncoder(nRepetitions, 1); % nRepetitions equals number of codeword bits
        end
        
        function coded = step(obj, signal)
        % STEP encodes the binary Signal object "signal" with a repetition
        % code
        
            bitvec = signal.selectFromBitToBitAsBitvector(1, signal.lengthInBits);
            coded = repelem(bitvec, obj.nBitsCodeword);
            coded = Signal(coded, signal.fs, 'Bits', signal.details);
        end
        
        function decod = getDecoder(obj)            
        % GETDECODER returns a RepetitionDecoder object "decod" whose 
        % parameters fit to the RepetitionEncoder "obj"
        
            decod = RepetitionDecoder(obj.nBitsCodeword);
        end
        
        function dHamming = getMinimumHammingDist(obj)
        % GETMINIMUMHAMMINGDIST returns the minimum Hamming distance for
        % the repetition code
        
            dHamming = obj.nBitsCodeword; % = nBitsRepetitions
        end
    end
end