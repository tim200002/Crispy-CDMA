classdef DAConverter < handle
% DACONVERTER is a class for conversion of quantized and sampled Signal 
% objects to pseudo analog Signal objects

    properties
        fs {mustBePositive} = 48000 % sample rate
        bitdepth  {mustBePositive} = 8
        sam Sampler
        qua Quantizer
    end
    methods
        function obj = DAConverter(sampleRate, bitDepth, varargin)
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
        
        function analogsig = step(obj, signal)
        % STEP performs the digital to analog conversion of the Signal
        % object "signal" and outputs the Signal object "analogsig"
            
            valuecont = obj.qua.invPCM(signal);
            [ups, downs] = rat(obj.fs / valuecont.fs);
            if obj.sam.upsampleFactor ~= ups || obj.sam.downsampleFactor ~= downs
                obj.sam = Sampler(ups, downs); % fit Sampler properties to signal.fs, if neccessary
            end
            analogsig = obj.sam.step(valuecont);
        end
    end
end