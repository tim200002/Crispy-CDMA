classdef PAMDemapper
    properties
        codeLength %length of the code is minimum and maximum
        symbol_Vector
    end
    methods
        function obj = PAMDemapper(codeLength)
            obj.codeLength=codeLength;
            obj.symbol_Vector = obj.createSymbolVector;
        end
        
        function retSignal = step(obj, signal)
            data = [];
            for i=1:signal.length
                data = [data, findNearestSymbol(obj, signal.data(i))];
            end
            retSignal = Signal(data, signal.fs);
            retSignal.signaltype = Signaltype.Valuecontinuous;
        end
         function retSignal = stepForExactly3Signals(obj, signal)
            data = [];
            for i=1:signal.length
                data = [data, findNearestSymbolForExactly3Signals(obj, signal.data(i))];
            end
            retSignal = Signal(data, signal.fs);
            retSignal.signaltype = Signaltype.Valuecontinuous;
        end
        
        function nearestSymbol = findNearestSymbol(obj,value)
            distanceVector = abs(obj.symbol_Vector-value);
            minIndex = find(distanceVector == min(distanceVector));
            nearestSymbol = minIndex-(obj.codeLength +1); %From index one can easily map down to real value   
        end
       function nearestSymbol = findNearestSymbolForExactly3Signals(obj,value)
            validKeys = [-0.75,-0.25,0.25,0.75];
            map =containers.Map(validKeys,[-3,-1,1,3]);
            distanceVector = abs(validKeys-value);
            minIndex = find(distanceVector == min(distanceVector));
            nearestSymbol =map(validKeys(minIndex)); %From index one can easily map down to real value   
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