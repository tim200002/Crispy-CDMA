function [compressed, compressRate] = JPEGCompress(signal, compFactor)
% JPEGCOMPRESS returns a JPEG compressed version of Signal object "signal"
% containing an uint8 array representing a JPEG file 
% (incl. header, as it is saved on disk).
% It's universally usable; e.g. for audio signals.
% arguments:
% (1) signal: Signal object containing an uint8 vector
% (2) compFactor: JPEG compression factor should be between 0 and 100
% outputs:
% (1) compressed: Signal object containing an uint8 vector
% (2) compressRate (optional): shrinkage of file size

filename = ['temp' date '.jpg'];
imgWidth = floor(sqrt(signal.length / 3));
selection = signal.selectFromTo(1, imgWidth^2 * 3); % ignores last bytes, that do not fit
ordered = reshape(selection.data, 3, imgWidth, imgWidth); % reshape to quadratic image
ordered = shiftdim(ordered, 1); % now (length x width x 3) uint8 matrix  % view it by: imagesc(ordered)
imwrite(ordered, filename, 'jpg', 'Quality', compFactor, 'Mode', 'lossy'); % create temporary JPEG file
sou = Source(Sourcetype.File, filename);
compressed = sou.step();
compressed.fs = signal.fs;
compressed.details = signal.details;
if nargout == 2 % if compressRate is requested
    fileinfo = imfinfo(char(filename));
    compressRate = fileinfo.FileSize / signal.length;
end
delete(filename); % delete temporary file

end