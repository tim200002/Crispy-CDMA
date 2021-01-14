classdef RepetitionDecoder < ChannelDecoder
% REPETITIONDECODER is able to decode repetiton codes

    methods
        function obj = RepetitionDecoder(nRepetitions)
            obj@ChannelDecoder(nRepetitions, 1); % nRepetitions equals number of codeword bits
        end
        
        function decoded = step(obj, signal)
        % STEP decodes the repetition encoded binary Signal object "signal"
        
            ordered = signal.divideInBitBlocks(obj.nBitsCodeword, 'matrix', false);            
            means = mean(ordered, 2); % columnwise
            remainingMean = sum(signal.selectFromBitToBitAsBitvector(numel(ordered) + 1, signal.lengthInBits)) / mod(signal.lengthInBits, obj.nBitsCodeword); % hint: [] * Nan = []
            thresholded = uint8([means; remainingMean] > 0.5); % concat mean of remaining bits
            decoded = Signal(thresholded, signal.fs, 'Bits', signal.details);
        end
    end
end