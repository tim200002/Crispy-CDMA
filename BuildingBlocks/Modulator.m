classdef Modulator
    properties
        samplesPerSymbol=16
        fc
    end
    methods
        function obj =Modulator(fc, samplesPerSymbol)
            obj.samplesPerSymbol=samplesPerSymbol;
            obj.fc=fc;
        end
        function retSignal = step(obj, signal)
            pulseShapedSignal = obj.pulseShapeSignal(signal);
            mixedSignal = obj.mixSignal(pulseShapedSignal);
            pilotedSignal = obj.addPilot(mixedSignal);
            retSignal = pilotedSignal;
        end
        
        function retSignal= pulseShapeSignal(obj, signal)
            pulseShaper = Pulseshaper(Impulsetype.RaisedCosine, 16);
            retSignal = pulseShaper.step(signal);
        end
        
        function retSignal = mixSignal(obj, signal)
            mixer = Mixer(Mixertype.Cosine, obj.fc);
            retSignal = mixer.step(signal);
        end
        function retSignal = addPilot(obj, signal)
            pilotInserter = PilotInserter(obj.fc);
            retSignal = pilotInserter.step(signal);
        end
        
    end
end