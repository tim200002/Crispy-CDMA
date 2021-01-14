classdef ParityDecoder < ChannelDecoder
% PARITYDECODER can decode parity coded binary Signal objects

    properties
        nBitsParity % number of parity bits
    end
    methods
        function obj = ParityDecoder(nBitsInfo)
            nBitsParity = nBitsInfo * (nBitsInfo - 1) / 2;
            obj@ChannelDecoder(nBitsInfo + nBitsParity, nBitsInfo);
            obj.nBitsParity = nBitsParity;
        end
        
        function [decoded, nOccurrences, nChangedBits] = step(obj, signal)
        % STEP decodes the parity coded Signal object "signal".
        % ignores bits at the end of signal that do not fit into a codeword
        % output arguments:
        % (1) decoded Signal
        % (2) nOccurrences: how often x bits were corrected, whereas x is the number of changed bits in one codeword, see nChangedBits
        % (3) nChangedBits: how many bits are changed in one codeword
            
            ordered = signal.divideInBitBlocks(obj.nBitsCodeword, 'matrix', false);
            if numel(ordered) < signal.lengthInBits
                warning("only "+numel(ordered)+" of "+signal.lengthInBits+" bits processed");
            end
            
            xorselection = nchoosek(1:obj.nBitsInfo, 2);
            
            sums = zeros(size(ordered, 1), obj.nBitsInfo);
            for idx = 1:obj.nBitsInfo % for each information bit
                [indices, ~] = find(xorselection == idx); %   find positions of parity bits, where this (idx) data bit is involved
                parities = ordered(:, sort(indices) + obj.nBitsInfo); % extract parity bits, where this (idx) data bit is involved
                selvec = 1:obj.nBitsInfo; % index selection vector
                selvec(idx) = [];
                sums(:, idx) = sum(xor(ordered(:, selvec), parities), 2); % select info bits, compare (with xor) to parity bits
            end
            decoded = double(ordered(:, 1:obj.nBitsInfo)) + sums > (obj.nBitsInfo / 2); % comparison (with >) yields logical vector
            
            if nargout == 3 % if output of "nOccurrences" and "nChangedBits" is wished
                occurrences = sum(abs(decoded - double(ordered(:, 1:obj.nBitsInfo))), 2); % how much corrections
                numbersOfCorrectedBits = unique(occurrences); % all possibilities of how many corrections are made in a codeword
                numbersOfCorrectedBits = [numbersOfCorrectedBits; numbersOfCorrectedBits(end) + 1]; % for correct "histcounts" functionality
                [nOccurrences, nChangedBits] = histcounts(occurrences, numbersOfCorrectedBits); % count the occurrences of the numbers of corrections
                nOccurrences = nOccurrences';
                nChangedBits = nChangedBits(1:end-1);
                if isempty(nOccurrences) % nothing was corrected
                    nOccurrences = length(occurrences);
                    nChangedBits = 0;
                end
            end
            
            decoded = decoded';
            decoded = Signal(uint8(decoded(:)), signal.fs, 'Bits', signal.details);
        end
    end
end