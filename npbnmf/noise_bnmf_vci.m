%% Get job number
j = getenv('SGE_TASK_ID')

%done = readtable("/ifs/scratch/msph/ehs/eag2186/npbnmf/noise_done.csv");
%done = table2array(done(:,2));

%if any(done == str2num(j))
%    exit()
%end

% Import the data
simdata1 = readtable(strcat("/ifs/scratch/msph/ehs/eag2186/Data/noise_csv/noise_sim", num2str(j), ".csv"));
patterns = readtable(strcat("/ifs/scratch/msph/ehs/eag2186/Data/noise_csv/noise_patterns_", num2str(j), ".csv"));
scores   = readtable(strcat("/ifs/scratch/msph/ehs/eag2186/Data/noise_csv/noise_scores_",   num2str(j), ".csv"));

%% Convert to output type
simdata1 = table2array(simdata1);
patterns = table2array(patterns);
scores   = table2array(scores);

[EWA0, EH0, varH0, alphaH0, betaH0, alphaW0, betaW0, ...
    alphaA0, betaA0, varWA0, finalscore0, final_iter0, init_seed_struct] = BN2MF(simdata1);

% Normalize  truth, too
patterns_denom = sum(patterns, 2);
patterns_scaled = patterns ./ patterns_denom;
patterns_denom_diag = diag(patterns_denom);
scores_scaled = scores * patterns_denom_diag;
        
% Rearrange solution matrices to match truth
[e,Pi] = factor_correspondence(patterns',EH0');
EH = (EH0' * Pi)';
EWA = EWA0 * Pi;

alphaW = alphaW0 * Pi;
betaW  = betaW0  * Pi;

alphaH = (alphaH0' * Pi)';
betaH  = (betaH0'  * Pi)';

alphaA = alphaA0 * Pi;
betaA  = betaA0  * Pi;

% Scale is inverse rate
% theta is inverse beta
thetaA = 1 ./ betaA;
thetaW = 1 ./ betaW;
thetaH = 1 ./ betaH;

draws = 1000;

% Take alphas and thetas
% Take 1000 draws from distributions for W, A, & H
% This creates an empirical distribution for each
W_dist = zeros(1000,   4,  draws);
A_dist = zeros(1,      4,  draws);
H_dist = zeros(4,      50, draws);
WA_dist = zeros(1000,  4,  draws);
A_dist_diag = zeros(4, 4,  draws);

for i = 1:draws
    W_dist(:,:,i) = gamrnd(alphaW, thetaW);
    A_dist(:,:,i) = gamrnd(alphaA, thetaA);
    H_dist(:,:,i) = gamrnd(alphaH, thetaH);

    A_dist_diag(:,:,i) = diag(A_dist(:,:,i));
    WA_dist(:,:,i)     = W_dist(:,:,i) * A_dist_diag(:,:,i);
end

% Normalize all H matrices to L1 norm across chemicals
H_denom  = sum(H_dist, 2);
H_scaled = H_dist ./ H_denom;

H_denom_diag = zeros(4, 4, draws);
for i = 1:draws
    H_denom_diag(:, :, i) = diag(H_denom(:,:,i));
end

% Scale all WA matrices by corresponding normalization constant
% This creates a scaled empirical distribution for scores
WA_scaled = zeros(1000, 4, draws);

for i = 1:draws
    WA_scaled(:,:,i) = WA_dist(:,:,i) * H_denom_diag(:,:,i);
end

% Create CI
upper_ci = quantile(WA_scaled, 0.975, 3);
lower_ci = quantile(WA_scaled, 0.025, 3);

prop = sum(sum(scores_scaled <= upper_ci & scores_scaled >= lower_ci)) / (1000*4);
prop
save_prop = [str2num(j), prop];
save_prop

% Save matrices
save(strcat("/ifs/scratch/msph/ehs/eag2186/npbnmf/t0_bnmf_noise_vci_out/t0_noise_EWA_",    num2str(j), ".mat"), 'EWA');
save(strcat("/ifs/scratch/msph/ehs/eag2186/npbnmf/t0_bnmf_noise_vci_out/t0_noise_EH_",     num2str(j), ".mat"), 'EH');

save(strcat("/ifs/scratch/msph/ehs/eag2186/npbnmf/t0_bnmf_noise_vci_out/t0_noise_upperWA_",  num2str(j), ".mat"), 'upper_ci');
save(strcat("/ifs/scratch/msph/ehs/eag2186/npbnmf/t0_bnmf_noise_vci_out/t0_noise_lowerWA_",  num2str(j), ".mat"), 'lower_ci');

save(strcat("/ifs/scratch/msph/ehs/eag2186/npbnmf/prop_out_noise_t0/t0_noise_save_prop",  num2str(j), ".mat"), 'save_prop');


