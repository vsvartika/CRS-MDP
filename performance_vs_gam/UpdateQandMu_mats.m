%% Compute Q-factors and theta-factors for a given policy D_mat
%
%----------Description-----------------------------------------------------
% theta factors are represented using mu
%
% Variable          Size        Description
% mu_r


%updating mu factors
for t=2:T-1
    for s=1:N_s
        tmp_r=0;
        tmp_c=0; 
        for st = 1:N_s
            for a=1:N_s-st+1  % Only actions limited.. Ex: When s = 6, only action 0 is allowed.
                tmp_r = tmp_r + mu_r(t-1,st)*D_mat(st,a,t-1)*P(st,a,s)*exp(gamma*(beta^(t-1)*rewards(st,a)));                   
                tmp_c = tmp_c + mu_c(t-1,st)*D_mat(st,a,t-1)*P(st,a,s)*exp(gamma*(beta^(t-1)*cost(st,a)));
            end 
        end
        mu_r(t,s) =  (1-eps_q_factors)* mu_r(t,s)+  eps_q_factors* tmp_r;
        mu_c(t,s) =  (1-eps_q_factors)* mu_c(t,s)+ eps_q_factors* tmp_c;

    end
end


    

    %updating Q factors

    for st=1:N_s
       Q_r_new(st,:,T) = exp(gamma*(beta^T)*rew_T(st));
       Q_c_new(st,:,T) = exp(gamma*(beta^T)*cost_T(st));
       
       Q_r_new_l(st,:,T) = 0;
       Q_c_new_l(st,:,T) = 0;
        
      
    end


    
    for t=T-1:-1:1

        d=D_mat(:,:,t+1); % for T all Q factors are equated to same value, so will not cause problem.
       

        for st=1:N_s
             for at = 1:N_s-st+1  % Only actions limited.. Ex: When s = 6, only action 0 is allowed.
                tmp=0;
                tmp1=0;

                tmp_l=0;
                tmp1_l=0;

                for s=1:N_s
                    for a=1:N_s-s+1  % Only actions limited.. Ex: When s = 6, only action 0 is allowed.

                        tmp = tmp + P(st,at,s)*d(s,a)*Q_r_new(s,a,t+1); 
                        tmp1 = tmp1+ P(st,at,s)*d(s,a)*Q_c_new(s,a,t+1);

                        tmp_l = tmp_l + P(st,at,s)*d(s,a)*Q_r_new_l(s,a,t+1); 
                        tmp1_l = tmp1_l+ P(st,at,s)*d(s,a)*Q_c_new_l(s,a,t+1);
                        
                    end
                end
               
                Q_r_new(st,at,t) = (1-eps_q_factors)*  Q_r(st,at,t) + eps_q_factors* (exp(gamma*beta^t*rewards(st,at))*tmp);
                Q_c_new(st,at,t) = (1-eps_q_factors)* Q_c(st,at,t)+ eps_q_factors*(exp(gamma*beta^t*cost(st,at))*tmp1);

                Q_r_new_l(st,at,t) = (1-eps_q_factors)* Q_rl(st,at,t)+ eps_q_factors*(beta^t*rewards(st,at)+tmp_l);
                Q_c_new_l(st,at,t) = (1-eps_q_factors)* Q_cl(st,at,t)+ eps_q_factors*(beta^t*cost(st,at)+tmp1_l);

             end  
         end
    end

    max_diff_r = max(max(abs(Q_r - Q_r_new)./Q_r_new )) +  max(max(abs(Q_rl - Q_r_new_l)./Q_r_new_l ));
    max_diff_c = max(max(abs(Q_c - Q_c_new)./ Q_c_new ))+ max(max(abs(Q_cl - Q_c_new_l)./ Q_c_new_l ));

    Q_r = Q_r_new;
    Q_c = Q_c_new;

    Q_rl = Q_r_new_l;
    Q_cl = Q_c_new_l;
