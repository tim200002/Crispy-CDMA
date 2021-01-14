classdef Filter < Signal
% FILTER is a class to collect properties and methods that are common for
% filter objects

    properties
        memoryStates % double vector, used to save samples of a previous signal, if persistentMemory = true
        dfiltObj % dfilt.dffir % optional dfilt object to store Signal Processing Toolbox� filters
    end
    
    properties (Access = private)
        persistentMemory logical % set true for blockwise filtering
    end
    
    methods
        function obj = Filter(sampleRate, varargin)
        % arguments:
        % (1) sampleRate
        % (2) vector containing an impulseresponse OR a dfilt.dffir
        % object
        % (3)(optional) logical if memory persistency is applied
            
            details.sourcetype = Sourcetype.Undefined;
            if isa(varargin{1},'dfilt.dffir') % given parameter is a dfilt object e.g. generated by filterDesigner
                impulseResponseVector = varargin{1}.Numerator;
            else % given parameter is a vector containing an impulseresonse 
                impulseResponseVector = varargin{1};
            end
            obj@Signal(impulseResponseVector, sampleRate, Signaltype.Valuecontinuous, details); % superclass constructor
            if nargin == 3 && islogical(varargin{2})
                obj.setPersistentMemory(varargin{2});
            else
                obj.setPersistentMemory(false);
            end
        end
        
        function filteredSignal = step(obj, signal)
        % STEP applies the filter "obj" to the Signal object "signal".
        % The output "filteredSignal" is as long as "signal".
        
            if signal.signaltype ~= Signaltype.Valuecontinuous
                error("Filter.step: input signal not valuecontinuous");
            end
%             if obj.fs ~= signal.fs
%                 error("Filter.step: sample rates do not match");
%             end
            if isempty(obj.dfiltObj)
                if obj.persistentMemory
                    memoryAndSignal = [obj.memoryStates; signal.data]; % concat saved states with signal
                    filteredSignal = conv(memoryAndSignal, obj.data);
                    nSamplesOffset = min(length(memoryAndSignal), obj.length) - 1;
                    from = length(filteredSignal) - nSamplesOffset - signal.length + 1;
                    to = length(filteredSignal) - nSamplesOffset;
                    % select signal.length samples of the convolution
                    % without the endmost nSamplesOffset samples of the filter transient
                    filteredSignal = Signal(filteredSignal(from : to), signal.fs, Signaltype.Valuecontinuous, signal.details);
                    % save nSamplesToSave samples of the signal in memoryStates
                    nSamplesToSave = min(signal.length, obj.length) - 1;
                    obj.memoryStates = signal.data(signal.length - nSamplesToSave + 1 : signal.length);
                else
                    filteredSignal = conv(signal.data, obj.data, 'same'); % returns only the CENTRAL part of the convolution, the same size as signal
                    
                    %selectFrom = ceil(length(obj.data) / 2);
                    %selectTo = length(filteredSignal) - floor(length(obj.data) / 2);
                    %filteredSignal = filteredSignal(selectFrom:selectTo);
                    
                    filteredSignal = Signal(filteredSignal, signal.fs, Signaltype.Valuecontinuous, signal.details);
                end
            else % if obj.dfiltObj contains a dfilt.dffir object, use its filter function
                filteredSignal = Signal(obj.dfiltObj.filter(signal.data), signal.fs, Signaltype.Valuecontinuous, signal.details);
            end
        end
        
        function setPersistentMemory(obj, state)
        % SETPERSISTENTMEMORY sets, whether the filter "obj" uses memory
        % persistence.
        % arguments:
        % (1) Filter object
        % (2) logical
        
            obj.persistentMemory = state;
            if ~isempty(obj.dfiltObj)
                obj.dfiltObj.PersistentMemory = state;
            end
        end
        
        function reset(obj)
        % RESET resets the memory states of the Filter object "obj"
        
            obj.memoryStates = [];
            if ~isempty(obj.dfiltObj)
                obj.dfiltObj.states = 0;
                obj.dfiltObj.reset;
            end
        end
    end
    
    methods (Static)
        function fil = generateLowPass(sampleRate, cutoffFreqPass, cutoffFreqStop)
            % sampleRate: sample rate
            % cutoffFreqPass: Passband Frequency
            % cutoffFreqStop: Stopband Frequency
            
            % Generated by MATLAB(R) 9.2 and the DSP System Toolbox 9.4.
            % Generated on: 22-Jun-2018 12:12:01
            
            % Equiripple Lowpass filter designed using the FIRPM function.
            
            % hard coded from Filter Designer:
            Dpass = 0.057501127785;  % Passband Ripple
            Dstop = 0.0001;          % Stopband Attenuation
            dens  = 20;              % Density Factor
            
            % Calculate the order from the parameters using FIRPMORD. 
            [N, Fo, Ao, W] = firpmord([cutoffFreqPass, cutoffFreqStop]/(sampleRate/2), [1 0], [Dpass, Dstop]);
            
            % Calculate the coefficients using the FIRPM function.
            b  = firpm(N, Fo, Ao, W, {dens});
            Hd = dfilt.dffir(b);
            
            fil = Filter(sampleRate, Hd);
        end
    end
end