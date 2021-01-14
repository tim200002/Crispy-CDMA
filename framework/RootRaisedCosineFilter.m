classdef RootRaisedCosineFilter < Filter
% RAISEDCOSINEFILTER is a class to apply a root raised cosine filter to 
% valuecontinuous Signal objects

    properties
        rolloff {mustBeGreaterThanOrEqual(rolloff, 0), mustBeLessThanOrEqual(rolloff, 1)}
        samplesPerSymbol
    end
    
    properties (Dependent = true)
        cutoffFreq % property 'cutoff frequency' of root raised cosine low pass filter is dependent of samplesPerSymbol
    end
    
    methods
        function obj = RootRaisedCosineFilter(sampleRate, nSamples, rolloff, samplesPerSymbol)
        % (1) sampleRate
        % (2) nSamples: length of impulse response or number of filter
        % tabs
        % (3) rolloff: roll-off factor, which determines filter slope 0<=rolloff<1
        % (4) samplesPerSymbol: number of samples between zeros of impulseresponse
            
            impulseresponse = RootRaisedCosineFilter.generateRootRaisedCosineFilter(samplesPerSymbol, nSamples, rolloff); % invoke static method
            obj@Filter(sampleRate, impulseresponse); % invoke superclass constructor
            obj.rolloff = rolloff;
            obj.samplesPerSymbol = samplesPerSymbol;
        end
        
        function obj = set.cutoffFreq(obj, newCutoffFreq)
        % SET.CUTOFFFREQ regenerates the filter according to
        % the new cutoff frequency
        
            obj.samplesPerSymbol = ceil(obj.fs / 2 / newCutoffFreq);
            obj.data = RootRaisedCosineFilter.generateRootRaisedCosineFilter(obj.samplesPerSymbol, obj.length, obj.rolloff); % update impulse response
        end
        
        function cutoffFreq = get.cutoffFreq(obj)
        % GET.CUTOFFFREQ returns the actual cutoff frequency of the filter
        
            cutoffFreq = ceil(obj.fs / 2 / obj.samplesPerSymbol);
        end
    end
    
    methods (Static)
        function impulseResponse = generateRootRaisedCosineFilter(samplesPerSymbol, nSamples, rolloff)
            % GENERATEROOTRAISEDCOSINEFILTER produces a root raised cosine low pass filter impulse
            % response, which fits to the input parameters.
            % In general, a root raised cosine is a not ISI free impulse!
            % INPUTS:
            % i samplesPerSymbol ... number of samples between zeros
            % i nSamples ... number of samples of timeSignal
            % i rolloff ... roll-off factor, which determines filter slope 0<=rolloff<1
            % OUTPUTS:
            % o impulseResponse ... impulse response as double vector
            
            time = (-nSamples / 2):(nSamples / 2 - 1);
            
            normedTime = time * pi / samplesPerSymbol;
            impulseResponse = sin(normedTime * (1 - rolloff)) + 4 * rolloff / pi * normedTime .* cos(normedTime * (1 + rolloff));
            impulseResponse = impulseResponse ./ (sqrt(samplesPerSymbol) * normedTime .* (1 - (4 * rolloff * normedTime / pi) .^ 2));
            
            impulseResponse(nSamples / 2 + 1) = (1 - rolloff + 4 * rolloff / pi) / sqrt(samplesPerSymbol); % middle peak
            impulseResponse(~isfinite(impulseResponse)) = rolloff / sqrt(2 * samplesPerSymbol) * ((1 + 2 / pi) * sin(pi / 4 / rolloff) + (1 - 2 / pi) * cos(pi / 4 / rolloff));
        end
    end
end