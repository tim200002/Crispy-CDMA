classdef (Abstract) ChannelDecoder < handle
% CHANNELDEOCDER is an abstract class for channel decoders

    properties
        nBitsCodeword % number of bits in a codeword
        nBitsInfo % number of information bits in a codeword, nBitsInfo < nBitsCodeword
    end
    
    methods
        function obj = ChannelDecoder(nBitsCodeword, nBitsInfo)
            obj.nBitsCodeword = nBitsCodeword;
            obj.nBitsInfo = nBitsInfo;
        end
    end
    
    methods (Abstract)
        decoded = step(obj, signal)
    end
end