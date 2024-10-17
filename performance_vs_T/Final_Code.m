%general code for risk sensitive

clear all

% All inputs in the following file..
inputs
%bound
 
fin_T=50;

x_arr=2:6:fin_T;

size_x = size(x_arr);
sz_x_arr = size_x(2);

rew_obt(1:sz_x_arr) = 0;
cost_obt(1:sz_x_arr) =0;
B_arr(1:sz_x_arr) = B;
sample =50000;

cur_step =1;

for ter_t = 2:6:fin_T

    T= ter_t;

    % All initializations other than D_mat in the following file
    Initialize
    
    
    
    
    % Randomly choose D_mat
    D_mat=rand(N_s,N_a,T);
    for t=1:T
    for s=1:N_s
    
            p = rand(1,N_a);  
            p (N_s-s+2:N_a) = 0;
    
            pi =  p / sum(p);
            D_mat(s, :,t) = pi;
    
    end
    end
    
    
    Rand_init_cnt = 1; 
    infeasible_cnt = 1;
    
    Max_sofar = 0; %16.59;
    Max_D_mat = D_mat;
    eps_policy = 0.01;
    eps_q_factors = 1;
    prv_max = 0; 
    
    conseq_cnt = 1;
    mini_exp_success_cnt =   0;
    
    for k = 1:sample
    
    
    % Update Q and mu factors for given D_mat 
    UpdateQandMu_mats
    
    
    % Updating the best sofar (one which satisfies the constraint)
    [rew_lin, cost_lin, rew_exp, cost_exp] = ComputeExpectedUtil (D_mat, Q_rl, Q_cl, Q_r, Q_c, a_init);
    if Max_sofar < rew_exp && cost_exp <= B 
    % Store the value it better than previous best
    Max_sofar = rew_exp ;
    Max_cost = cost_exp;
    Max_D_mat = D_mat ; 
    Max_conseq_cnt = conseq_cnt;
    end
    
    
    if 1 == 0
    
    %%%%% Only for Observations %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    [rew_lin, cost_lin, rew_exp, cost_exp] = ComputeExpectedUtil (D_mat, Q_rl, Q_cl, Q_r, Q_c, a_init);
              
    fprintf ('k=%3d Risk MDP   under the same policy  (log(Rew)/gam, log(Cost)/gam)  = (%f %f)  Max sofar = %f  Rand_init_cnt  = %d infeasible_cnt = %d **********  \n', ...
              k,  -log(rew_exp)/gamma,   log(cost_exp)/gamma,  -1/gamma *log (Max_sofar), Rand_init_cnt, infeasible_cnt );
    
    %%%%% Only for Observations %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    end
    
    tmp = rand + 0.2*le(conseq_cnt, 150);
    
    if tmp < 20/k*exp(-0000000.1* (conseq_cnt)^(0.3)) 
         
       % Generate Random D_Matrix
       [rew_lin, cost_lin, rew_exp, cost_exp] = ComputeExpectedUtil (D_mat, Q_rl, Q_cl, Q_r, Q_c, a_init);
       Gen_Rand_Dmat
       Rand_init_cnt = Rand_init_cnt + 1;
    
    else
    
       % Try to improve by solving wrt to quantities of previous round
       d_temp = solveLPP(Q_r,Q_c,  B,mu_r,mu_c,N_s,N_a,T);
    
       if isempty(d_temp) 
    
           %disp ('mini experiment ..... ')  % To push towards the
           %original limit in exactly mini_mag steps.
           mini_mag = 200;   
           for l = 0:4:mini_mag
               d_temp = solveLPP(Q_r,Q_c,  B* exp (0.01*  (mini_mag-l) ),mu_r,mu_c,N_s,N_a,T);
               if isempty (d_temp) 
                   fprintf ('fail at l = %d \n', l)
                   break;
               end
    
               % Update the Q mu factors and try to improve the D_mat
               % alongside pushing towards the original limit
               UpdateQandMu_mats
                ofs = 0;
                eps_policy= .5;
                for t=1:T-1 
                    temp = d_temp(ofs+(1:N_s*N_a));
                    ofs= ofs+ N_s*N_a;
                    
                    
                    for st=1:N_s
                        D_mat(st, :,t)=(1-  eps_policy) *D_mat(st, :,t)+ eps_policy* temp((st-1)*N_a +1 : st* N_a)' ;
                    end    
                
                end
               [rew_lin, cost_lin, rew_exp, cost_exp] = ComputeExpectedUtil (D_mat, Q_rl, Q_cl, Q_r, Q_c, a_init);
    
               if cost_exp <= B 
                   break;
               end
               %fprintf (' Linear_MDP under the same policy  (Rew, Cost)                    = (%f %f) \n', rew_lin, cost_lin)
               if mod(l, 100)== 0                       
                   fprintf (' mini -- l = %d   (log(Rew)/gam, log(Cost)/gam)  = (%f %f)  Max sofar = %f   **********  \n', ...
                          l, -log(rew_exp)/gamma,   log(cost_exp)/gamma,  -1/gamma *log (Max_sofar));
               end
    
           end
    
           if  isempty (d_temp)  == 0   
               mini_exp_success_cnt = mini_exp_success_cnt + 1;
               disp ('succ')
           else
               if l > 5
                %fprintf (' fail at l = %d \n', l)
               end
           end
    
       end
    
       % learning better policy  
    
        if  isempty(d_temp) 
            % Generate Random DMatrix
            [rew_lin, cost_lin, rew_exp, cost_exp] = ComputeExpectedUtil (D_mat, Q_rl, Q_cl, Q_r, Q_c, a_init);
            Gen_Rand_Dmat
            infeasible_cnt = infeasible_cnt + 1;
        else
    
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
    

    if 0 %plotting buisness
    color_arr (1, :) = 'bo ';    width_arr (1) = 1;
    color_arr (2, :) = 'k* ';    width_arr (2) = 1;
    color_arr (3, :) = 'r* ';    width_arr (3) = 1;
    color_arr (4, :) = 'b  ';    width_arr (4) = 2;
    color_arr (5, :) = 'k  ';    width_arr (5) = 2;
    color_arr (6, :) = 'r  ';    width_arr (6) = 2;
    
    color_arr (7, :) = 'b--';    width_arr (7) = 2;
    color_arr (8, :) = 'k--';    width_arr (8) = 2;
    color_arr (9, :) =  'r--';    width_arr (9) = 2;
    color_arr (10, :) = 'b-.';    width_arr (10) = 2;
    color_arr (11, :) = 'k-.';    width_arr (11) = 2;
    color_arr (12, :) = 'r-.';    width_arr (12) = 2;
    
    if N_s > 12
    disp('color_arr problem')
    end
    
    if conseq_cnt > 200
       %disp ('good conv');
       if mod(conseq_cnt, 200) == 1
          %  PrintD_mat (D_mat, N_s, N_a, T,k)
           
            
            figure(12);hold off;
            for state = N_s:-1:1
                clear tmpr; 
                for tt = 1:T   
                     tmpr  (tt, :) = D_mat (state, 1:N_s-state+1, tt);
                end
                
                for jj = 1:N_s-state+1
                    plot (tmpr ( :, jj)+3*state, color_arr(jj, :), 'LINEWIDTH', width_arr(jj)) % plot (tmpr+2*state, 'o-', 'LINEWIDTH', 2)
                     hold on; 
                end
            end
            title ('Using  D_mat ');
          
            figure(13); hold off;
            for state = N_s:-1:1
                clear tmpr; 
                for tt = 1:T  
                    tmpr  (tt, :) = Max_D_mat (state, 1:N_s-state+1, tt); 
                end 
                
                for jj = 1:N_s-state+1
                    plot (tmpr (:,jj)+3*state, color_arr(jj, :), 'LINEWIDTH', width_arr(jj)) %plot (tmpr+2*state, 'o-', 'LINEWIDTH', 2)
                    hold on; 
                end
            end
            title ('Using Max_D_mat ');
            
            
            if 1 == 0
            for state = 5:-1:1
                clear tmpr; for tt = 1:T   tmpr  (tt, :) = D_mat (state, 1:6-state+1, tt); end; figure(state); hold off; plot (tmpr, 'o-', 'LINEWIDTH', 2)
            end
            end
             disp ('good conv');
          %   state = 1; clear tmpr; for tt = 1:T   tmpr  (tt, :) = D_mat (state, 1:6-state, tt); end; hold off; plot (tmpr, 'LINEWIDTH', 2)
       end
    end
    end
    
    if mod(k,30)==9  
        fprintf('\n---------------------------------------------------------------------------------------')
        fprintf('\n k = %d  T = %2d  gamma = %f log(B)/gamma - %f  infeasible =%d restart_cnt = %d  conseq_cnt = %d mini_exp_success_cnt = %d \n', ...
            k, T,  gamma, log(B)/gamma, infeasible_cnt, Rand_init_cnt, conseq_cnt, mini_exp_success_cnt);
    
        [rew_lin, cost_lin, rew_exp, cost_exp] = ComputeExpectedUtil (D_mat, Q_rl, Q_cl, Q_r, Q_c, a_init);
    
    
    
        fprintf (' Linear_MDP under the same policy  (Rew, Cost)                    = (%f %f) \n', -rew_lin, cost_lin)
        
        fprintf (' Risk MDP   under the same policy  (log(Rew)/gam, log(Cost)/gam)  = (%f %f)  Max sofar = %f   **********  \n', ...
                -log(rew_exp)/gamma,   log(cost_exp)/gamma,  -1/gamma *log (Max_sofar));
    
        if   Max_sofar > 0
            % When we attempt to initialize randomly in between
        
            fprintf ('@@@@@@@@@@@ Max_sofar = %f   Max cost = %f  max_conseq_cnt = %d  and Max_D_mat is \n ', ...
                -1/gamma *log (Max_sofar),  1/gamma*log (Max_cost),  Max_conseq_cnt  );
    
            if (prv_max < Max_cost) || (mod(k, 3000) == 9)
              %  PrintD_mat (Max_D_mat, N_s, N_a, T,k)
            end
            prv_max = Max_cost;
            fprintf ('  @@@@@@@@@@@@ \n');
        end
    
    
        
        %PrintD_mat (D_mat, N_s, N_a, T, k)
    end
    
    
    end
    
    PrintD_mat (Max_D_mat, N_s, N_a, T,k)

rew_obt(cur_step) =  -1/gamma *log (Max_sofar);
cost_obt(cur_step) = 1/gamma*log (Max_cost);

cur_step = cur_step +1;

end

figure(1)
plot(2:6:fin_T,rew_obt)
hold on
plot(2:6:fin_T,cost_obt)
hold on
plot(2:6:fin_T,B_arr)
hold off






function PrintD_mat (DD_mat, N_s, N_a, T, ii)

       if ii < 100
            return;
       end

        for s=1:N_s
            for tim = 1:T-1
                for a=1:N_a
                    if a > N_s-s+1
                        fprintf ('      ', DD_mat (s, a, tim)); 
                    else

                    if DD_mat (s, a, tim) == 0
                        fprintf ('0     ', DD_mat (s, a, tim)); 
                    else
                        if  DD_mat (s, a, tim) == 1
                            fprintf ('1     ', DD_mat (s, a, tim));
                        else
                        
                            fprintf ('%-3.2f  ', abs(DD_mat (s, a, tim))); 
                        end
                    end
                    end
                end
                fprintf('; ')
                if mod (tim, 4) == 0
                    fprintf ('\n')
                end
            end
            fprintf('\n \n ')
        end
%        fprintf('\n i = %d \n', ii)

        if mod (ii, 60)== 9
            pause (2);
        end
end


function  [rew_lin, cost_lin, rew_exp, cost_exp] = ComputeExpectedUtil (DD_mat, QQ_rl, QQ_cl, QQ_r, QQ_c, aa_init)

    temp_cost = sum((DD_mat(:,:,1).*QQ_c(:,:,1))');
    temp_rew = sum((DD_mat(:,:,1).*QQ_r(:,:,1))');
    
    temp_cost_l = sum((DD_mat(:,:,1).*QQ_cl(:,:,1))');
    temp_rew_l = sum((DD_mat(:,:,1).*QQ_rl(:,:,1))');
    
    rew_lin = aa_init*temp_rew_l';
    cost_lin = aa_init*temp_cost_l';
    rew_exp = aa_init*temp_rew';
    cost_exp = aa_init*temp_cost';
end


function [x] = solveLPP(Q_rew,Q_cos,B,mu_r,mu_c,N_s,N_a,T)  
 n=(T-1)*N_s*N_a;

 
 f_r=zeros(1,n);
 f_c=zeros(T-1,n);
 
 ofs =0;

 ub=ones(1,n)';

 for t=1:T-1

 f_r_mat = mu_r(t,:)'.*Q_rew(:,:,t);
 f_c_mat = mu_c(t,:)'.*Q_cos(:,:,t);
 
 
  %stacking rows side by side
 for s=1:N_s
     f_r(ofs + ((s-1)*N_a +1 : s* N_a)) =  -f_r_mat(s,:);
     f_c(t, ofs + ((s-1)*N_a +1 : s* N_a)) =  f_c_mat(s,:);
     ub(ofs +( ((s-1)*N_a + N_s-s+2) : s* N_a) ) = 0;
 end

 ofs = ofs + N_s*N_a;
 end
 

 %prob_satisfy matrix
 Aeq = zeros((T-1)*N_s,n);
 
 ofs_col=0; ofs_row=0;
 for t=1:T-1
 for s=1:N_s
     Aeq(ofs_row+s,ofs_col +((s-1)*N_a +1 : s* N_a))=1;
 end
 ofs_row=ofs_row+N_s;
 ofs_col=ofs_col+N_s*N_a;
 end

 beq=ones(1,(T-1)*N_s)';
    
 lb= zeros(1,n)';

Bound = B*ones(1,T-1);
options = optimoptions('linprog','Display','none');
x = linprog(f_r,f_c,Bound,Aeq,beq,lb,ub,options);

end
 