classdef PAMMapper
    properties
        codeLength %length of the code is minimum and maximum
    end
    methods
        function obj = PAMMapper(codeLength)
            obj.codeLength=codeLength;
        end
        function retSignal= step(obj, signal)
            symbolVector = obj.createSymbolVector();
            signal.data = signal.data+obj.codeLength +1; %Verschiebe so, dass man einfach aus symbol Vektro Matrix auslesen kann
            data = [];
            for i=1:signal.length
                data = [data, symbolVector(signal.data(i))];
            end
            retSignal= Signal(data, signal.fs);
            retSignal.signaltype = Signaltype.Valuecontinuous;
        end
        
        function retSignal = stepForExactly3Signals(obj, signal)
            map =containers.Map([-3,-1,1,3],[-0.75,-0.25,0.25,0.75]);
            data = [];
            for i=1:signal.length
                data = [data, map(signal.data(i))];
            end
            retSignal= Signal(data, signal.fs);
            retSignal.signaltype = Signaltype.Valuecontinuous;
        end
        function symbolVector = createSymbolVector(obj)
            symbolVector=[];
            delta = 2/(2*obj.codeLength+1);
            for i=0:2*obj.codeLength
                symbolVector=[symbolVector -1+i*delta];
            end
        end
    end
    
end