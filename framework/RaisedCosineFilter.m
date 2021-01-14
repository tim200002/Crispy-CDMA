classdef RaisedCosineFilter < Filter
% RAISEDCOSINEFILTER is a class to apply a raised cosine filter to Signal
% objects

    properties
        rolloff {mustBeGreaterThanOrEqual(rolloff, 0), mustBeLessThanOrEqual(rolloff, 1)}
        samplesPerSymbol
    end
    
    properties (Dependent = true)
        cutoffFreq % property 'cutoff frequency' of raised cosine low pass filter is dependent of samplesPerSymbol
    end
    
    methods
        function obj = RaisedCosineFilter(sampleRate, nSamples, rolloff, samplesPerSymbol)
        % arguments:
        % (1) sampleRate
        % (2) nSamples: length of impulse response or number of filter
        % tabs
        % (3) rolloff: roll-off factor, which determines filter slope 0<=rolloff<1
        % (4) samplesPerSymbol: number of samples between zeros of impulseresponse
        
            impulseresponse = RaisedCosineFilter.generateRaisedCosineFilter(samplesPerSymbol, nSamples, rolloff); % invoke static method
            obj@Filter(sampleRate, impulseresponse); % invoke superclass constructor
            obj.rolloff = rolloff;
            obj.samplesPerSymbol = samplesPerSymbol;
        end
        
        function obj = set.cutoffFreq(obj, newCutoffFreq)
        % SET.CUTOFFFREQ regenerates the raised cosine filter according to
        % the new cutoff frequency
        
            obj.samplesPerSymbol = ceil(obj.fs / 2 / newCutoffFreq);
            obj.data = RaisedCosineFilter.generateRaisedCosineFilter(obj.samplesPerSymbol, obj.length, obj.rolloff); % update impulse response
        end
        
        function cutoffFreq = get.cutoffFreq(obj)
        % GET.CUTOFFFREQ returns the actual cutoff frequency of the filter
        
            cutoffFreq = ceil(obj.fs / 2 / obj.samplesPerSymbol);
        end
    end
    
    methods (Static)
        function impulseResponse = generateRaisedCosineFilter(samplesPerSymbol, nSamples, rolloff)
            % GENERATERAISEDCOSINEFILTER produces a raised cosine low pass filter impulse
            % response, which fits to the input parameters
            % INPUTS:
            % (1) samplesPerSymbol ... number of samples between zeros of impulseresponse
            % (2) nSamples ... number of samples
            % (3) rolloff ... roll-off factor, which determines filter slope 0<=rolloff<1
            %
            % OUTPUTS:
            % (1) impulseResponse ... impulse response of the low pass filter as double vector
            
            time = (-nSamples / 2):(nSamples / 2 - 1);
            impulseResponse = sin(pi * time / samplesPerSymbol) ./ (pi * time / samplesPerSymbol) .* cos(rolloff * pi * time / samplesPerSymbol) ./ (1 - (2 * rolloff * time / samplesPerSymbol) .^ 2);
            impulseResponse(nSamples / 2 + 1) = 1; % peak
            impulseResponse(isnan(impulseResponse)) = 0; % for samples with division by zero
            impulseResponse(~isfinite(impulseResponse)) = 0; % for samples with division by zero
        end
    end
end