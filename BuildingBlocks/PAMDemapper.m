classdef PAMDemapper
    properties
        codeLength %length of the code is minimum and maximum
    end
    methods
        function obj = PAMDemapper(codeLength)
            obj.codeLength=codeLength
        end
        
        function retSignal = step(obj, signal)
            data = [];
            for i=1:signal.length
                data = [data, findNearestSymbol(obj, signal.data(i))];
            end
            retSignal = Signal(data, signal.fs);
            retSignal.signaltype = Signaltype.Valuecontinuous;
        end
        
        function nearestSymbol = findNearestSymbol(obj,value)
            symbolVector = obj.createSymbolVector();
            distanceVector = abs(symbolVector-value);
            minIndex = find(distanceVector == min(distanceVector));
            nearestSymbol = minIndex-(obj.codeLength +1); %From index one can easily map down to real value
            
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