classdef HilbertFilter < Filter
% HILBERTFILTER is a class to apply several Hilbert filter algorithms to
% Signal objects

    methods
        function obj = HilbertFilter
            obj@Filter(1, []); % invoke superclass constructor with default values
        end

        function filteredSignal = step(obj, signal)
        % STEP uses the function 'hilbert' of the Signal Processing Toolbox
        % to apply the Hilbert filter to the Signal object "signal"
        % This method overrides STEP of superclass Filter.
        
            filteredSignal = Signal(imag(hilbert(signal.data)), signal.fs, signal.signaltype, signal.details);
        end
        
        function filteredSignal = step2(obj, signal)
        % STEP2 uses convolution with filter impulse response to apply the
        % Hilbert filter to the Signal object "signal".
        
            if signal.signaltype ~= Signaltype.Valuecontinuous
                error("input signal not valuecontinuous");
            end
            if isempty(obj.data) || signal.length ~= obj.length % generate impulseresponse if not done yet
                obj.data = HilbertFilter.generateHilbertFilter(signal.length);
                obj.fs = signal.fs;
            end
            convoluted = conv(signal.data, obj.data);
            convoluted = convoluted(1: floor(end/2)) + convoluted(ceil(end/2) + 1 : end); % add the shifted half signal
            filteredSignal = Signal(convoluted, signal.fs, signal.signaltype, signal.details);
        end
        
        function filteredSignal = step3(obj, signal)
        % STEP3 applies Hilbert filter in frequency domain and performs 
        % transformation back in time domain
        
            if signal.signaltype ~= Signaltype.Valuecontinuous
                error("input signal not valuecontinuous");
            end
            signalTransformed = (fft(signal.data));
            nSamples = signal.length;
            frequencydomain = 1j * [-ones(1, floor(nSamples / 2)) 0 ones(1, ceil(nSamples / 2) - 1)];
            resultFdomain = signalTransformed(:) .* frequencydomain(:);
            resultTd = ifft(resultFdomain);
            filteredSignal = Signal(resultTd, signal.fs, signal.signaltype, signal.details);
        end

    end
    
    methods (Static)
        function impulseResponse = generateHilbertFilter(nSamples)
            % returns a double vector of the impulse response of a Hilbert
            % filter with nSamples samples
            frequencydomain = 1j * [ones(1, floor(nSamples / 2)) 0 -ones(1, ceil(nSamples / 2) - 1)];
            % first define it in frequency domain, then inverse fourier
            % transform it
            impulseResponse = -real(ifft(frequencydomain));% * sqrt(nSamples);
        end
    end
end