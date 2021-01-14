classdef DSBModulator < handle
% DSBMODULATOR can modulate double side band amplitude modulated signals.

    properties
        mix Mixer
    end
    methods
        function obj = DSBModulator(carrierFreq)
            obj.mix = Mixer(Mixertype.Cosine, carrierFreq, true);
        end
        
        function signalout = step(obj, signalin)
        % STEP performs the DSB amplitude modulation of the Signal object
        % "signalin" and outputs it as Signal object "signalout"
        
            signalout = obj.mix.step(signalin);
        end
    end
end