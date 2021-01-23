classdef ImageDeserializer
    %IMAGEDESERIALIZER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        img
        colorResolution
    end
    
    methods
        function obj = ImageDeserializer(colorResolution)
            obj.colorResolution=colorResolution;
            
        end
        
        function image = GetImageFromBitVector(obj, bitStreamVector, size_x, size_y)
            %transform vector back to matrix
            for n = 1:3
                BitMatrix=reshape(bitStreamVector(n,:),[],obj.colorResolution);
                DecMatrix = bi2de(BitMatrix);
                if obj.colorResolution == 4
                    DecMatrix = obj.upscaleImageTo8Bits(DecMatrix);
                end
     
                ColorMat = reshape(DecMatrix,size_x,size_y);
                obj.img(:,:,n) = ColorMat(:,:);
            end
            
            obj.img = uint8(obj.img);
            
            imshow(obj.img);
            image = obj.img;
        end
        
         function  upscaledArray = upscaleImageTo8Bits(obj, array)
            upscaledArray = array * 17;
         end
    end
end

