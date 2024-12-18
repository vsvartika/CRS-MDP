%Code that Implements GRC Algorithm of [1] for various values of Gamma
%(Risk factor)
%
% The MDP is time-homogeneous -- the rewards, costs, state space, action
% space, and transition probabilities do not depend on time (terminal
% reward adn cost are specified seperately)
%
%
%--------INPUTS------------------------------------------------------------
% 
%  Variable             Size                Description
%   init_gam            1x1                 Initial value of risk factor gamma
%   fin_gam             1x1                 Final value of risk factor gamma
%   step_size           1x1                 Step size to create risk factor array
%   x_arr               array               Risk factor array
%   sample              1x1                 Iterations of GRC algorithm for each value of gamma
%   
%  MDP details are managed using <inputs> file
%  Variable             Size                Description
%   N_s                 1x1                 No. of states
%   N_a_arr             1xN_s               Array of no. of actions in each state
%   N_a                 1x1                 Represents Max(N_a_arr)
%   T                   1x1                 Terminal time for MDP
%   bet                 1x1                 Discount factor \in [0,1]
%   gam                 1x1                 Risk factor for reward
%   gam_c               1x1                 Risk factor for cost
%   B_l                 1x1                 The constraint of cost
%   a_init              1xN_s               Initial distribution over states
%   rewards             N_sxN_a             Each row corresponds to reward at a particular state for various action, entries are zero for invalid actions
%   cost                N_sxN_a             Each row corresponds to cost at a particular state for various action, entries are zero for invalid actions
%   P                   N_sxN_axN_s         Entry (s,a,s') represents the probability of going to state s' from state s when a is chosen
%   rew_T               1xN_s               Terminal reward
%   cost_T              1xN_s               Terminal cost
%
%
%--------Various factors required for implementation-----------------------
% Variables             Size                Description
%  D_mat                N_sxN_axT           Policy
%  Q_rl                 N_sxN_axT           Q-factors for reward -- linear
%  Q_cl                 N_sxN_axT           Q-factors for cost -- linear      
%  Q_r                  N_sxN_axT           Q-factors for reward -- risk-senitive
%  Q_c                  N_sxN_axT           Q-factors for cost -- risk-senitive
%  mu_r                 TxN_s               theta factors for reward
%  mu_c                 TxN_s               theta factors for cost
%   
%---------OUTPUTS----------------------------------------------------------
% Variable              Size                Description
%   rew_obt             1xsz_x_array        Array of optimal rewards for all values of gamma
%   cost_obt            1xsz_x_array        Array of MDP cost at optimal policy fo all values of gamma
%
% Plosts
% 1. rew_obt and cost_obt as a function of risk factor gamma
%--------------------------------------------------------------------------
clear

init_gam  = 0.1;
fin_gam   = 20;
step_size = 3;
x_arr     = init_gam:step_size:fin_gam;
sample    = 50000;


size_x = size(x_arr);
sz_x_arr = size_x(2);
rew_obt(1:sz_x_arr) = 0;
cost_obt(1:sz_x_arr) = 0;
cur_step = 1;

for cur_gam = x_arr
   
    inputs
    % All matrices and vectors other than D_mat initialized in the following file
    Initialize
    
    %% Randomly choose D_mat -- the Policy
    D_mat=rand(N_s,N_a,T);
    for t=1:T
    for s=1:N_s    
            p = rand(1,N_a);  
            p(N_s-s+2:N_a) = 0;    
            pi =  p / sum(p);
            D_mat(s, :,t) = pi;    
    end
    end

    %%  
    
    Rand_init_cnt  = 1;             %counts the number of random initialization of D_mat
    infeasible_cnt = 1;             %counts the number of times LP in local improvement step of GRC was infeasible    
    Max_sofar = 0;                  %to track the best objective value seen so far
    Max_D_mat = D_mat;              %policy correspoding to best objective value
    eps_policy = 0.01;              %the weightage given to new policy when updating the policy according to GRC
    eps_q_factors = 1;              %the weightage given to new Q-factors when updating the policy according to GRC
    conseq_cnt = 1;                 %number of times local improvement happend consecutively
    mini_exp_success_cnt =   0;
    
    for k = 1:sample 

    % Update Q and mu factors for given D_mat 
    UpdateQandMu_mats
    
    
    % Updating the best sofar (one which satisfies the constraint)
    [rew_lin, cost_lin, rew_exp, cost_exp] = ComputeExpectedUtil (D_mat, Q_rl, Q_cl, Q_r, Q_c, a_init);
    if Max_sofar < rew_exp && cost_exp <= B  
        Max_sofar = rew_exp ;
        Max_cost  = cost_exp;
        Max_D_mat = D_mat ; 
        Max_conseq_cnt = conseq_cnt;
    end
    
    %% GRC Implementation
    tmp = rand + 0.2*le(conseq_cnt, 150);    

    %% Random Restart with diminishing probability--------------------------
    if tmp < 20/k*exp(-0000000.1* (conseq_cnt)^(0.3)) 
       [rew_lin, cost_lin, rew_exp, cost_exp] = ComputeExpectedUtil (D_mat, Q_rl, Q_cl, Q_r, Q_c, a_init);
       Gen_Rand_Dmat
       Rand_init_cnt = Rand_init_cnt + 1;    
    else 
    %% Local Improvement--------------------------------------------------    
       d_temp = solveLPP(Q_r,Q_c,B,mu_r,mu_c,N_s,N_a,T,N_a_arr);  
   
       if isempty(d_temp) 
            %Generate Random Policy
            [rew_lin, cost_lin, rew_exp, cost_exp] = ComputeExpectedUtil (D_mat, Q_rl, Q_cl, Q_r, Q_c, a_init);
            Gen_Rand_Dmat
            infeasible_cnt = infeasible_cnt + 1;
       else %Update the policy
            conseq_cnt = conseq_cnt+1;
            eps_policy = min(0.01, 1.5/conseq_cnt^(.55));
            ofs = 0;
            for t=1:T-1 
                temp = d_temp(ofs+(1:N_s*N_a));
                ofs= ofs+ N_s*N_a;              
                for st=1:N_s
                    D_mat(st, :,t)=(1-  eps_policy) *D_mat(st, :,t)+ eps_policy* temp((st-1)*N_a +1 : st* N_a)' ;
                end            
            end
       end    
    end

    %% Printing
    if mod(k,30)==9  
        [rew_lin, cost_lin, rew_exp, cost_exp] = ComputeExpectedUtil (D_mat, Q_rl, Q_cl, Q_r, Q_c, a_init);

        fprintf('\n---------------------------------------------------------------------------------------')
        fprintf('\n k = %d  T = %2d  gamma = %f log(B)/gamma - %f  infeasible =%d restart_cnt = %d  conseq_cnt = %d mini_exp_success_cnt = %d \n', ...
                    k, T,  gamma, log(B)/gamma, infeasible_cnt, Rand_init_cnt, conseq_cnt, mini_exp_success_cnt);   
        fprintf (' Linear MDP under the same policy  (Rew, Cost)                    = (%f %f) \n', -rew_lin, cost_lin)        
        fprintf (' Risk MDP   under the same policy  (log(Rew)/gam, log(Cost)/gam)  = (%f %f) \n', -log(rew_exp)/gamma, log(cost_exp)/gamma);      
        fprintf (' Max_sofar = %f   Max cost = %f  max_conseq_cnt = %d  \n ',-1/gamma *log (Max_sofar),  1/gamma*log (Max_cost),  Max_conseq_cnt); 
    end
    
    
    end
rew_obt(cur_step)  =  -1/gamma *log (Max_sofar);
cost_obt(cur_step) =   1/gamma*log (Max_cost);
cur_step = cur_step +1;

end

%% Plotting
figure(1)
plot(x_arr,rew_obt,'b*--','LineWidth',1)
hold on
plot(x_arr,cost_obt,'r*--','LineWidth',1)
title('Optimal Reward and Cost as a function of Risk-factor')
xlabel('Risk factor')
legend('Optimal Reward','Optimal Cost')
hold off


%% Local Functions

function  [rew_lin, cost_lin, rew_exp, cost_exp] = ComputeExpectedUtil (DD_mat, QQ_rl, QQ_cl, QQ_r, QQ_c, aa_init)
%Returns expected linear and risk-sensitive rewards and costs given Q-factors, initial distribution and corresponding policy
    temp_cost = sum(DD_mat(:,:,1).*QQ_c(:,:,1),2);
    temp_rew  = sum(DD_mat(:,:,1).*QQ_r(:,:,1),2);
    
    temp_cost_l = sum(DD_mat(:,:,1).*QQ_cl(:,:,1),2);
    temp_rew_l  = sum(DD_mat(:,:,1).*QQ_rl(:,:,1),2);
    
    rew_lin  = aa_init*temp_rew_l;
    cost_lin = aa_init*temp_cost_l;
    rew_exp  = aa_init*temp_rew;
    cost_exp = aa_init*temp_cost;
end


function [x] = solveLPP(Q_rew,Q_cos,B,mu_r,mu_c,N_s,N_a,T,N_a_arr) 
%Returns the policy solving Linear Program in [1] 
%This function does not format the solution in the policy format
 
n   = (T-1)*N_s*N_a;    %no. of variables -- the policy, d(1,1,1),d(1,2,1)
f_r = zeros(1,n);       %initializing objective function
f_c = zeros(T-1,n);     %initializing constraint function
 
ub=ones(1,n)';          %upper bound on variables
lb= zeros(1,n)';        %lower bound on variables

 
ofs = 0;                %for each t, ofs+1 corresponds to first decision variable
for t=1:T-1  
    f_r_mat = mu_r(t,:)'.*Q_rew(:,:,t);
    f_c_mat = mu_c(t,:)'.*Q_cos(:,:,t);

    %stacking rows side by side
    for s=1:N_s
        l_idx = ofs + (s-1)*N_a + 1;
        r_idx = ofs + s* N_a; 
        f_r(  l_idx:r_idx) = -f_r_mat(s,:);
        f_c(t,l_idx:r_idx) =  f_c_mat(s,:);

        %to ensure invalid action entries have zero probability
        ll_idx = ofs + (s-1)*N_a + N_a_arr(s)+1 ;    
        ub(ll_idx: r_idx) = 0;
    end    
    ofs = ofs + N_s*N_a;
end

Bound = B*ones(1,T-1);

%to ensure that the sum of probability of choosing any action is 1 for all states
Aeq = zeros((T-1)*N_s,n);
ofs_col=0; ofs_row=0;
for t=1:T-1
    for s=1:N_s
        row_idx = ofs_row+s;
        l_idx   = ofs_col + (s-1)*N_a +1;
        r_idx   = ofs_col + s* N_a; 
        Aeq(row_idx, l_idx:r_idx) = 1;
    end
    ofs_row = ofs_row + N_s;
    ofs_col = ofs_col + N_s*N_a;
end
beq=ones(1,(T-1)*N_s)';

options = optimoptions('linprog','Display','none');
x = linprog(f_r,f_c,Bound,Aeq,beq,lb,ub,options);
end
 
