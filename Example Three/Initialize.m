
%initialization
Q_r =rand(N_s,N_a,T);
Q_c= rand(N_s,N_a,T);



Q_rl =rand(N_s,N_a,T);
Q_cl= rand(N_s,N_a,T);



mu_r =ones(T-1,N_s);
mu_c =ones(T-1,N_s);

mu_r(1,:)=  a_init;
mu_c(1,:)=  a_init;

for s = 1:N_s
    Q_r (s, (N_s-s+2):N_a, : ) = 1; 
    Q_c (s, (N_s-s+2):N_a, : ) = 1; 
    
    Q_rl (s, (N_s-s+2):N_a, : ) = 0; 
    Q_cl (s, (N_s-s+2):N_a, : ) = 0; 
end


Q_r_new = Q_r;
Q_c_new = Q_c;

Q_r_new_l = Q_rl;
Q_c_new_l = Q_cl;

delta = 0.00001;


