%% Code Division Multiple Access Encoder (Symetric)
% This encoder uses  vector codes based one Hadamard Matrice
% signal = raw Signal
% code = Code Numer -> Zeilenummer Hadamard Matrix
% h_l = Hadamard Matrix Größe

function[signalout] = CDMA_Encode(signal, code, h_l)
if code>h_l
    errordlg('The input code number must be equal or less than the Hadamard length','File Error');
end

H=hadamard(h_l);

%Get Code from code Number
H_Code = H(code,:);

signalout = kron(signal,H_Code);

