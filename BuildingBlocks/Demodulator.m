classdef Demodulator
    properties
        samplesPerSymbol=16
        fc
    end
    methods
        function obj =Demodulator(fc, samplesPerSymbol)
            obj.samplesPerSymbol=samplesPerSymbol;
            obj.fc=fc;
        end
        function retSignal = step(obj, signal)
            removedPilotSignal = obj.removePilot(signal);
            demixedSignal = obj.mixSignal(removedPilotSignal);
            filteredSignal = obj.filterSignal(demixedSignal);
            timeDiscreteSignal = obj.readSymbolValues(filteredSignal);
            retSignal=timeDiscreteSignal;
        end
        
       
        
        function retSignal = mixSignal(obj, signal)
            mixer = Mixer(Mixertype.Cosine, obj.fc);
            retSignal = mixer.step(signal);
        end
        function retSignal = filterSignal(obj, signal)
            load('filter.mat');
            filter = Filter(32e3, Num);
            retSignal = filter.step(signal);
        end
        function retSignal = removePilot(obj, signal)
            %Find Position of Pilot
            synchronizer = Synchronizer(obj.fc);
            pilotIndex = synchronizer.step(signal);
            %Remove Pilot:
            retSignal = Signal(signal.data(pilotIndex:end), signal.fs);
        end
        
        function retSignal= readSymbolValues(obj, signal)
           symbolIndex = [1: obj.samplesPerSymbol: signal.length];
           retSignal = Signal(signal.data(symbolIndex)*2, signal.fs/16);
        end
        
    end
end