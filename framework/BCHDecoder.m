classdef BCHDecoder < ChannelDecoder
    % BCHDECODER is a class to decode Signal objects using a BCH decoder
    % with the parameters nBitsCodeword and nBitsInfo
    % uses Communications System Toolbox
    
    properties
        decObject
    end
    
    methods
        function obj = BCHDecoder(nBitsCodeword, nBitsInfo)
            nBitsCodewordCorrected = 2^(round(log2(nBitsCodeword + 1))) - 1; % correct to next power of 2 -1
            if nBitsCodewordCorrected ~= nBitsCodeword
                warning(['number of codeword bits corrected to ' num2str(nBitsCodewordCorrected)]);
            end
            nCorrectableErrors = bchnumerr(nBitsCodewordCorrected);
            idx = find(nCorrectableErrors(:, 2) == nBitsInfo);
            if isempty(idx)
                [~, idx2] = min(abs(nCorrectableErrors(:, 2) - nBitsInfo));
                nBitsInfoCorrected = nCorrectableErrors(idx2, 2);
                warning(['number of information bits corrected to ' num2str(nBitsInfoCorrected)]);
            else
                nBitsInfoCorrected = nCorrectableErrors(idx, 2);
            end
            obj@ChannelDecoder(nBitsCodewordCorrected, nBitsInfoCorrected);
            obj.decObject = comm.BCHDecoder(nBitsCodewordCorrected, nBitsInfoCorrected);
        end
        
        function decoded = step(obj, signal)
        % STEP performs the BCH decoding of the Signal object "signal" and
        % outputs the result as a Signal object "decoded"
        
            nWords = floor(signal.lengthInBits / obj.nBitsCodeword);
%             bitvec = double(signal.selectFromBitToBitAsBitvector(1, nWords * obj.nBitsCodeword));
bitvec = (signal.selectFromBitToBitAsBitvector(1, nWords * obj.nBitsCodeword));
            if length(bitvec) ~= signal.lengthInBits
                warning(['not all (only ' num2str(length(bitvec)) ' of ' num2str(signal.lengthInBits) ' bits) have been decoded']);
            end
            decData = obj.decObject.step(bitvec);
            decoded = Signal(decData, signal.fs, 'Bits', signal.details);
            obj.decObject.release();
        end
    end
end