classdef ImageDeserializer
    %IMAGEDESERIALIZER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        img
    end
    
    methods
        function obj = ImageDeserializer()
            
        end
        
        function image = GetImageFromBitVector(obj, bitStreamVector)
            [size_x,size_y, imgBits] = obj.extractLengthInfromation(bitStreamVector);
            %transform vector back to matrix
            for n = 1:3
                BitMatrix=reshape(imgBits(n,:),[],8);
                DecMatrix = bi2de(BitMatrix);
                ColorMat = reshape(DecMatrix,size_x,size_y);
                obj.img(:,:,n) = ColorMat(:,:);
            end
            
            obj.img = uint8(obj.img);
            
            imshow(obj.img);
            image = obj.img;
        end
        
        function [size_x,size_y, imgBits] = extractLengthInfromation(obj,inputBitStreamVector)
            lengt_bi = inputBitStreamVector(1,[end-31:end]);
            size_x = bi2de(lengt_bi);
            size_y = (length(inputBitStreamVector(1,[1:end-32]))/8)/size_x;
            imgBits = inputBitStreamVector([1:3],[1:end-32]);
        end
    end
end

