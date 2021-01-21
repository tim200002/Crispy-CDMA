classdef Header
    properties
        lengthInBits
        onesLength = 4
    end
    
    methods
        function obj = Header(lengthInBits)
            obj.lengthInBits = lengthInBits;
        end
        
        function retSignal = addHeader(obj, signal)
            signalLength = signal.length;
            
            bitVector = de2bi(signalLength);
            
            a = obj.lengthInBits - length(bitVector);
            
            bitVector = [bitVector zeros(1,a)].';
            
            if length(bitVector) > obj.lengthInBits
                error('lengthInBits is to short for signal Length');
            end
            %Map Bits from 0,1 to -1,1
            bitVector = 2*bitVector-1;
           

            %Header Always starts with 4 ones in a row
            one = ones(1,obj.onesLength).';
            bitVector = [one; bitVector];
            retSignal =Signal([bitVector; signal.data], signal.fs);   
        end
        
        function [retSignal, retLength] = removeHeaderAndGetLength(obj, signal)
           %Create Scale Factor from ones at front
            ones = signal.data(1: obj.onesLength);
            scaleFaktor = 1/mean(ones);
            header =scaleFaktor * signal.data(obj.onesLength+1:obj.lengthInBits + obj.onesLength); %4 because 4 ones added in front
            
                        
            retSignal = Signal(signal.data(obj.lengthInBits+obj.onesLength+1:end)*scaleFaktor, signal.fs);
            

            
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