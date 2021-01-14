classdef BCHEncoder < ChannelEncoder
    % BCHENCODER is a class to encode Signal objects using a BCH encoder
    % with the parameters nBitsCodeword and nBitsInfo
    % uses Communications System Toolbox
    
    properties
        encObject % for BCH system object
    end
    
    methods
        function obj = BCHEncoder(nBitsCodeword, nBitsInfo)
            nBitsCodewordCorrected = 2^(round(log2(nBitsCodeword + 1))) - 1; % correct to next power of 2 -1
            if nBitsCodewordCorrected ~= nBitsCodeword
                warning(['number of codeword bits corrected to ' num2str(nBitsCodewordCorrected)]);
            end
            nCorrectableErrors = bchnumerr(nBitsCodewordCorrected); % returns a matrix with number of correctable errors and number of information bits
            idx = find(nCorrectableErrors(:, 2) == nBitsInfo); % find the number of information bits according to the codeword length
            if isempty(idx) % the number of information bits has to be changed, if it does not occur in the nCorrectableErrors matrix
                [~, idx2] = min(abs(nCorrectableErrors(:, 2) - nBitsInfo));
                nBitsInfoCorrected = nCorrectableErrors(idx2, 2);
                warning(['number of information bits corrected to ' num2str(nBitsInfoCorrected)]);
            else
                nBitsInfoCorrected = nCorrectableErrors(idx, 2);
            end
            obj@ChannelEncoder(nBitsCodewordCorrected, nBitsInfoCorrected);
            obj.encObject = comm.BCHEncoder(nBitsCodewordCorrected, nBitsInfoCorrected);
        end
        
        function coded = step(obj, signal)
        % STEP performs the BCH encoding of the Signal object "signal" and
        % outputs the result as a Signal object "coded"
        
            nMessageWords = floor(signal.lengthInBits / obj.nBitsInfo);
            bitvec = double(signal.selectFromBitToBitAsBitvector(1, nMessageWords * obj.nBitsInfo));
            if length(bitvec) ~= signal.lengthInBits
                warning(['not all (only ' num2str(length(bitvec)) ' of ' num2str(signal.lengthInBits) ' bits) have been encoded']);
            end
            encData = obj.encObject.step(bitvec);
            coded = Signal(encData, signal.fs, 'Bits', signal.details);
            obj.encObject.release();
        end
        
        function decod = getDecoder(obj)
        % GETDECODER returns a BCHDecoder object "decod" whose parameters
        % fit to the BCHEncoder "obj"
        
            decod = BCHDecoder(obj.nBitsCodeword, obj.nBitsInfo);
        end
        
        function dHamming = getMinimumHammingDist(obj)
        % GETMINIMUMHAMMINGDIST returns the minimum Hamming distance for
        % the BCH code used by the BCHEncoder "obj"
        
            dHamming = 2 * bchnumerr(obj.nBitsCodeword, obj.nBitsInfo) + 1;
        end
    end
end