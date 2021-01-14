classdef (Abstract) ChannelEncoder < handle
% CHANNELENCODER is an abstract class for channel encoders

    properties
        nBitsCodeword % number of bits of a codeword (both information bits and redundancy bits)
        nBitsInfo % number of information bits in a codeword, nBitsInfo <= nBitsCodeword
    end
    
    methods
        function obj = ChannelEncoder(nBitsCodeword, nBitsInfo)
            obj.nBitsCodeword = nBitsCodeword;
            obj.nBitsInfo = nBitsInfo;
        end
        
        function codebook = getCodebook(obj)
            % GETCODEBOOK returns the codebook of the channel code as 
            % matrix with dimensions 2^obj.nBitsInfo x obj.nBitsCodeword
            
            vec = dec2bin(0:((2^obj.nBitsInfo) - 1), obj.nBitsInfo) - '0';
            vec = vec';
            vec = vec(:);
            vecsi = Signal(vec, 1, 'Bits');
            
            coded = obj.step(vecsi);
            
            codebook = reshape(coded.selectFromBitToBitAsBitvector(1, coded.lengthInBits), obj.nBitsCodeword, 2^obj.nBitsInfo)';
        end
        
        function coderate = getCoderate(obj)
        % GETCODERATE returns the code rate of the channel code
        
            coderate = obj.nBitsInfo / obj.nBitsCodeword;
        end
    end
    
    methods (Abstract)
        coded = step(obj, signal)
        dHamming = getMinimumHammingDist(obj)
        decod = getDecoder(obj)
    end
end