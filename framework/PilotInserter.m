classdef PilotInserter < handle
% PILOTINSERTER is a module to add pilot sequences to signals

    properties
        pilotSequence Signal                % pilot sequence to search for, no binary signal, but symbol signal
        fc = 8e3                            % carrier frequency of pilot
        PilotMixer Mixer                    % Mixer for Pilot
        PilotBandwidth = 2e3
        PilotPulseshaper Pulseshaper
    end
    
    methods
        function obj = PilotInserter(fc,pilotSequence)
            if nargin >1
                obj.pilotSequence = pilotSequence;
            else
                obj.pilotSequence = Signal(genZadoffChuSequence,obj.PilotBandwidth);
            end
            obj.PilotMixer = Mixer(Mixertype.Complex,fc);
        end
        
        function [outputsignal] = step(obj, signal)
        % STEP returns the Signal object with concatenated pilot sequence
        
            SamplesPerSymbol = round(signal.fs./obj.PilotBandwidth);
            obj.PilotPulseshaper = Pulseshaper(Impulsetype.RootRaisedCosine,SamplesPerSymbol);

            PilotPulseshaped = obj.PilotPulseshaper.step(obj.pilotSequence);
            PilotPassBand = obj.PilotMixer.step(PilotPulseshaped);
            PilotPassBand = PilotPassBand.real;
            PilotPassBand = PilotPassBand.normByMax;
            
            outputsignal = [PilotPassBand ; signal];
        end
    end
end