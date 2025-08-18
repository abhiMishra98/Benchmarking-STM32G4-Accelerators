z = tf("z",1/48000);
alpha = 0.1;
g = alpha / (1 - (1 - alpha)*z^-1)

step(g)

figure;
bode(g);
grid on;


t = 0:1/48000:0.01
x = sin(2*pi*1000*t)

figure
lsim(g,x,t)


























