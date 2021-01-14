sig1 = Signal(linspace(-1, 1, 1e4), 1, 'V');
qua = Quantizer(8, -1);
qua.mu = 7;
sig2 = qua.step(sig1);

sig3 = qua.invPCM(sig2);

plot(sig1.data);
hold on;
plot(sig3.data);
hold off;
figure; plot(sig2.data)