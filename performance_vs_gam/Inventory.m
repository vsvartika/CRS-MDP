% price of item (shortage cost) >  per order item (order cost)
% Some strange thing happens when the same cost is included in the
% objective as well as constraint  (kind o
% I now made a constraint on the number of orders




Maxinv = N_s-1;

% Poisson demands with rate lam


lam = 9;

fixed_order_cost = 0.2;
per_order_cost = 0.4;  %Cu   

per_item_price =  2.4; %4.2847; 1; %C_s % per_order_cost*2.1;

per_holding_cost = .1;  %Ch


 

P(1:Maxinv+1, 1:Maxinv+1, 1:Maxinv+1) = 0;


rewards (1:Maxinv+1, 1:Maxinv+1) = 0;
cost (1:Maxinv+1, 1:Maxinv+1) = 0; 

for x = 0:Maxinv
    for a = 0:Maxinv-x

        prob = 0; 
        sum_prob_im = 0;
        running_cost = (fixed_order_cost + per_order_cost * a)*gt(a, 0);  % Order cost
        holding_cost = 0;
        short_cost = 0;
        for k=0:10000  
            x_next = x+a-k ;   % k is the amount of demand
            p = 0.7;

            prob_im = p^(k)*(1-p);
            %prob_im =   exp(-lam) * prod(lam ./ (1:k) );
            sum_prob_im = sum_prob_im + prob_im;
            if x_next <= 0
                prob = prob_im + prob;

                % shortage cost
                %running_cost = running_cost + prob_im * (k-x-a)*per_item_price;
                short_cost = short_cost + prob_im * (k-x-a)*per_item_price;
                
            else
                
                P (x+1, a+1, x_next+1) = prob_im;
                
    
                %holding cost
                running_cost = running_cost + prob_im * x *per_holding_cost ;  % holding cost
            end

            
        end
        P (x+1, a+1, 1) = 0;
        
        tmp = 1- sum(P (x+1, a+1, :) );
        P (x+1, a+1, 1)  =  tmp;

 

        rewards (x+1, a+1) = running_cost;
        cost (x+1, a+1) =   short_cost; %a;


        if sum( P(x+1, a+1, :)) ~= 1

           fprintf ('issue with 1-prob_sum =  %e \n',  1- sum( P(x+1, a+1, :)));
        end

    end


end


for i = 1:N_s
    for a = 1:N_a
        sm = sum (P(i,a,:));
        if sm > 0
            P(i,a, :) = P(i, a, :) / sm;
        end
    end
end

  
P
rewards = -rewards 
cost    = (gam_c/gamma)*cost 