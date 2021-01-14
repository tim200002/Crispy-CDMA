classdef Mixer < handle
% MIXER can be used to multiply a Signal object with different waveforms. 

    properties
        mixertype Mixertype % member of enumeration Mixertype
        fc {mustBePositive} % carrier frequency
        persistentPhase logical % set true for blockwise mixing
        memoryPhase {mustBeNumeric} % stores the current phase, if persistentPhase == true; 0 <= memoryPhase < 2*pi
    end
    
    methods
        function obj = Mixer(mixertype, carrierFrequency, varargin)
            % optional third argument: logical for phase storage
            obj.mixertype = mixertype;
            obj.fc = carrierFrequency;
            obj.memoryPhase = 0;
            if nargin == 3 && islogical(varargin{1})
                obj.persistentPhase = varargin{1};
            else
                obj.persistentPhase = false;
            end
        end
        
        function signalout = step(obj, signalin)
        % STEP mixes the valuecontinuous Signal "signalin" with the
        % specified waveform obeying the correct phase
        
            if signalin.signaltype ~= Signaltype.Valuecontinuous
                error("Mixer.step: Signal input is not value continuous");
            end
            signalLength = signalin.length;
            sampleRate = signalin.fs;
            timeVector = (0:(signalLength-1))' / sampleRate;
            argument = 2 * pi * obj.fc * timeVector + obj.memoryPhase;
            switch obj.mixertype
                case Mixertype.Sine
                    localOscillator = sin(argument);
                case Mixertype.Cosine
                    localOscillator = cos(argument);
                case Mixertype.Complex
                    localOscillator = exp(1i * argument);
                case Mixertype.ComplexConjugate
                    localOscillator = exp(- 1i * argument);
            end
            
            if obj.persistentPhase % save phase
                obj.memoryPhase = mod(signalLength / sampleRate * 2 * pi * obj.fc + obj.memoryPhase, 2 * pi); % this is the first argument of the next block, because timeVector begins with 0
            end
            
            y = signalin.data(:) .* localOscillator;
            signalout = Signal(y, sampleRate, Signaltype.Valuecontinuous, signalin.details);
        end
    end
end