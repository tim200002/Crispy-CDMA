classdef SourceEncoder < handle
% SOURCEENCODER is a class to apply source coding to Signal objects.
% Currently supported methods:
% lossless source coding: Huffman coding
% lossy source coding: JPEG compression

   properties
       method
       JPEGCompressionFactor {mustBeNonnegative}
       huf HuffmanEncoder
   end
   
   methods
       function obj = SourceEncoder(method, varargin)
       % arguments:
       % (1) 'lossless' or 'lossy'
       % (2) a HuffmanEncoder object for lossless method
       % OR
       % (2) (optional) JPEGCompressionFactor between 0 and 100
       
           if strcmpi(method, 'lossless')
               obj.method = method;
               if nargin == 2
                   obj.huf = varargin{1};
               else
                   error("expected instance of HuffmanEncoder class");
               end
           elseif strcmpi(method, 'lossy')
               obj.method = method;
               if nargin == 2
                   obj.JPEGCompressionFactor = varargin{1};
               else
                   obj.JPEGCompressionFactor = 75;
                   warning("JPEG compression factor set to 75");
               end
           else
               error("choose either 'lossy' or 'lossless' as source coding method");
           end
       end
       
       function coded = step(obj, signal)
       % STEP applies the chosen method on the Signal object "signal".
           if strcmpi(obj.method, 'lossless')
               coded = obj.huf.step(signal);
           elseif strcmpi(obj.method, 'lossy')
               coded = JPEGCompress(signal, obj.JPEGCompressionFactor);
           end
       end
       
       function decod = getDecoder(obj)
       % GETDECODER returns the corresponding SourceDecoder object.
           if strcmpi(obj.method, 'lossless')
               decod = SourceDecoder(obj.method, obj.huf.getDecoder);
           elseif strcmpi(obj.method, 'lossy')
               decod = SourceDecoder(obj.method);
           end
       end
   end
end