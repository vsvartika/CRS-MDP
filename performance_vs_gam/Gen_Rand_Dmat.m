
    
    
    % Updating the best sofar (one which satisfies the constraint)
    if Max_sofar < rew_exp && cost_exp < B*1.0001 
        % Store the value it better than previous best
        Max_sofar = rew_exp ;
        Max_cost = cost_exp;
        Max_D_mat = D_mat ; 
        Max_conseq_cnt = conseq_cnt;
    end


    if 1 == 0
        % Restart randomly ..
        for tt=1:T
            for ss = 1:N_s
                p = rand(1,N_a);  
                p (N_s-ss+2:N_a) = 0;
    
                pi =  p / sum(p);
    
               % pi = floor (pi./ max(pi) );
               D_mat (ss, :,tt) =  pi;
            end
        end
    
    else
    
        % Restart at random corners 
    
        for tt=1:T
            for ss = 1:N_s
                idx = randi(N_a-ss+1);  
                p (1:N_a) = 0;
    
                p (idx) = 1;
                idx = randi(N_a-ss+1); 
                p (idx) = rand * 0.1;
                pi =  p / sum(p);
                 
    
               % pi = floor (pi./ max(pi) );
               D_mat (ss, :,tt) =  pi;
            end
        end
    end


    conseq_cnt = 1;
    
   % prv_d_temp = d_temp - d_temp;

