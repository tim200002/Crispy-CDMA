classdef Header
    properties
        lengthInBits
    end
    
    methods
        function obj = Header(lengthInBits)
            obj.lengthInBits = lengthInBits;
        end
        
        function retSignal = addHeader(obj, signal)
            signalLength = signal.length;
            bitVector = de2bi(signalLength).';
            
            if length(bitVector) > obj.lengthInBits
                error('lengthInBits is to short for signal Length');
            end
            %Map Bits from 0,1 to -1,1
            bitVector = 2*bitVector-1;

            retSignal =Signal([bitVector; signal.data], signal.fs);   
        end
        
        function [retSignal, retLength] = removeHeaderAndGetLength(obj, signal)
            header = signal.data(1:obj.lengthInBits);
            retSignal = Signal(signal.data(obj.lengthInBits+1:end), signal.fs);
            
            headerToBits = [];
            for i=1:length(header)
                if(header(i)>0)
                    headerToBits = [headerToBits 1];
                else
                     headerToBits = [headerToBits 0];
                end
            end
            retLength = bi2de(headerToBits);
        end
    
    end
end