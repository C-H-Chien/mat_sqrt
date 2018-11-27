function Matrix_Square_Root(A)

TOL=1.e-8;
n = size(A,1);
A_k = eye(n);

%Parameters of DB iterative method
Y_k = A' * A;
Z_k = eye(n);

%Parameters of Meini iterative method
%M_k = 2 * (Z_k + A'*A);
%N_k = Z_k - A'*A;

M_k = 2 * (Z_k + A);
N_k = Z_k - A;

max_iter_num = 2;

for iter = 1 : max_iter_num
    %inv_A_k = Matrix_Inverse(A_k);
    %A_k = 0.5 * (A_k + A * inv_A_k);
    %A_k = 0.5 * (A_k + A * inv(A_k));
    
    %The followings are the  Denman and Beavers (DB) method 
    %based on the matrix sign function iteration.
    Y_k_hat = 0.5 * (Y_k + inv(Z_k));
    Z_k_hat = 0.5 * (Z_k + inv(Y_k));
    Y_k = Y_k_hat;
    Z_k = Z_k_hat;
    
    %The followings are the Meini method
    N_k_hat = -N_k * inv(M_k) * N_k;
    %if(iter < 3)
        %disp('N_k_hat is');
      % disp(N_k_hat);
    %end
    M_k_hat = M_k - 2 * N_k * inv(M_k) * N_k;
    
%     if(iter < 4)
%        disp('N_k_hat');
%        disp(N_k_hat);
%        disp('M_k_hat');
%        disp(M_k_hat);
%        disp('inv(M_k)');
%        disp(inv(M_k));
%        disp('N_k * inv(M_k) is');
%        disp(N_k * inv(M_k));
%     end
    
    M_k = M_k_hat;
    N_k = N_k_hat;
end

disp('The square root of AtA is');
disp(sqrtm(A'*A));
%disp(sqrtm(A));
disp('The DB method for the square root is:');
disp(Y_k);
%disp('Y_k * Y_k is:');
%disp(Y_k * Y_k);
disp('The Meini method for the square root is: ');
disp(0.25 * M_k);
