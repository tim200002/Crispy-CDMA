classdef CDMADecoder
    properties
        walshMatrix %matrix of wals code
        codeLength
    end
    methods
         function obj = CDMADecoder(codeLength)
             obj.codeLength = codeLength;
             obj.walshMatrix = hadamard(codeLength);
         end
         
         function retSignal = step(obj, signalToBeDecoded, walshIndex)
             walshSequence = obj.walshMatrix(:,walshIndex); %This is the Code for the current index
             
             signalValues = signalToBeDecoded.data;
             data = [];
             
             while ~isempty(signalValues)
                 currentSequence = signalValues(1:obj.codeLength);
                 data = [data, obj.getBitValue(currentSequence, walshSequence)];
                 signalValues = signalValues(obj.codeLength+1:end);
             end
             retSignal = Signal(data,signalToBeDecoded.fs/obj.codeLength);
             retSignal.signaltype = Signaltype.Bits;
             
             
         end
         
         function bitValue = getBitValue(obj,signalArray, walshSequence)
             skalar = dot(signalArray, walshSequence);
             if skalar>0
                 bitValue = 1;
             else
                 bitValue=0;
             end
         end
         
         function matrix = getWalshMatrix(obj)
             matrix=obj.walshMatrix;
         end
    end

end