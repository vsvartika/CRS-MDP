%time steps
T= 5;

%discount factor
beta=0.7; 
bet = beta;

%risk factor for reward and cost
gamma = cur_gam;
gam = gamma;
gam_c = 0.1*gam;

%states and actions
N_s = 6;
N_a_arr = N_s:-1:1; %[6, 5, 4, 3, 2, 1];
N_a = N_s;

%rewards, costs and transition probabilities
Inventory

%bound
B_l=6;
B=exp (B_l*gam_c); 
 
%initial distribution
a_init = N_s:-1:1;%a_init (1) = .1;
a_init = a_init/sum(a_init);

%terminal reward and cost
rew_T  = zeros(1,N_s);
cost_T = zeros(1,N_s);
 
