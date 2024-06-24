clear; clc;

irFile = './files/IR/3000CStreetGarageStairwell.wav'

[timeResponse,Fs]=audioread(irFile);
t=(0:length(timeResponse)-1)/Fs;
L = length(timeResponse)-1;

figure(1)
plot(t, timeResponse)
title("Señal: '"+irFile+"' (dominio del tiempo)");
xlabel("Tiempo [s]");
ylabel("Amplitud");
hold on;

responseFFT = fft(timeResponse);

csvwrite('./files/csv/ir_stairwell_44k.csv', timeResponse(1:32768));
