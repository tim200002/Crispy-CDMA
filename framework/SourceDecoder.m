classdef SourceDecoder < handle
% SOURCEDECODER is a class to decode source coded bianry Signal objects.
% Currently supported methods:
% lossless source coding: Huffman coding
% lossy source coding: JPEG compression

   properties
       method
       huf HuffmanDecoder
   end
   
   methods
       function obj = SourceDecoder(method, varargin)
       % arguments:
       % (1) 'lossless' or 'lossy'
       % (2) (optional) a HuffmanDecoder object for lossless method
       
           if strcmpi(method, 'lossless')
               obj.method = method;
               if nargin == 2
                   obj.huf = varargin{1};
               else
                   error("expected HuffmanDecoder object");
               end
           elseif strcmpi(method, 'lossy')
               obj.method = method;
           else
               error("choose either 'lossy' or 'lossless' as source coding method");
           end
       end
       
       function coded = step(obj, signal)
       % STEP decodes the binary Signal object "signal" with the chosen
       % method.
           if strcmpi(obj.method, 'lossless')
               coded = obj.huf.step(signal);
           elseif strcmpi(obj.method, 'lossy')
               coded = JPEGDecompress(signal);
           end
       end
   end
end