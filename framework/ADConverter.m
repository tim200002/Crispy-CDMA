classdef ADConverter < handle
% ADCONVERTER is a class for conversion of pseudo analog Signal objects to
% quantized and sampled Signal objects

    properties
        fs {mustBePositive} = 48000 % sample rate
        bitdepth  {mustBePositive} = 8
        sam Sampler
        qua Quantizer
    end
    methods
        function obj = ADConverter(sampleRate, bitDepth, varargin)
            % arguments:
            % (1) sampleRate
            % (2) bitDepth
            % (3) (optional) symmetry of quantizer curve {-1;0;1}; see Quantizer
            % (4) (optional) µ for quantizer µ-law: µ >= 0
            obj.fs = sampleRate;
            obj.bitdepth = bitDepth;
            obj.sam = Sampler(3, 2); % 3, 2 is default
            if nargin == 3
                obj.qua = Quantizer(obj.bitdepth, varargin{1});
            elseif nargin == 4
                obj.qua = Quantizer(obj.bitdepth, varargin{1});
                obj.qua.mu = varargin{2};
            else
                obj.qua = Quantizer(obj.bitdepth, -1);
            end
        end
        
        function digitalsig = step(obj, signal)
        % STEP performs the analog to digital conversion of the Signal
        % object "signal" and outputs the Signal object "digitalsig"
        
            [ups, downs] = rat(obj.fs / signal.fs);
            if obj.sam.upsampleFactor ~= ups || obj.sam.downsampleFactor ~= downs
                obj.sam = Sampler(ups, downs); % fit Sampler properties to signal.fs, if neccessary
            end
            sampled = obj.sam.step(signal);
            digitalsig = obj.qua.step(sampled);
        end
    end
end