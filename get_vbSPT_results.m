function [ diff_mean, diff_std, occupancy, spaths, posterior_tp_mean, posterior_tp_std, bootstrap_tp_mean, bootstrap_tp_std, model_fit ] = get_vbSPT_results( start_path, runinput, modelsize )
% extract states from vbSPT

cd(start_path)
%% Parse input

% if an existing file, generate options structure
if(isstr(runinput) && exist(runinput)==2)
    runinputfile = runinput;
    opt=VB3_getOptions(runinputfile);
    disp(['Read runinput file ' runinputfile])
    % if an option struct, read in the runinputfilename
elseif(isstruct(runinput))
    opt=runinput;
    runinputfile=opt.runinputfile;
    disp(['Read options structure based on runinput file ' runinputfile ])
else
    error(['Not a valid input, aborting']);
end

%% load the vbSPT model

try
    res=load(opt.outputfile);
catch me
    if(~exist(opt.outputfile)) % if there is no vbSPT run for this movie
        diff_mean = [];
        diff_std = [];
        occupancy = [];
        spaths = [];
        posterior_tp_mean = [];
        posterior_tp_std = [];
        bootstrap_tp_mean = [];
        bootstrap_tp_std = [];
        model_fit = [];
        return 
    end
end


%% get diff coeff, occupancy, transition matrix

model_fit = res.dF;
if modelsize == 0
    diff_mean = res.Wbest.est.DdtMean/opt.timestep;
    diff_std = res.Wbest.est.Ddtstd/opt.timestep;
    occupancy = res.Wbest.est.Ptot;
    spaths = res.Wbest.est2.sMaxP;
    posterior_tp_mean = res.Wbest.est.Amean;
    posterior_tp_std = res.Wbest.est.Astd;
    bootstrap_tp_std = 0; %res.bootstrap.Wstd.est.Amean;
    bootstrap_tp_mean = 0; % res.bootstrap.Wmean.est.Amean;
else
    diff_mean = res.WbestN{modelsize}.est.DdtMean/opt.timestep;
    diff_std = res.WbestN{modelsize}.est.Ddtstd/opt.timestep;
    occupancy = res.WbestN{modelsize}.est.Ptot;
    posterior_tp_mean = res.WbestN{modelsize}.est.Amean;
    posterior_tp_std = res.WbestN{modelsize}.est.Astd;
    bootstrap_tp_std = res.bootstrap.WstdN(modelsize).est.Amean;
    bootstrap_tp_mean = res.bootstrap.WmeanN(modelsize).est.Amean;
    if isfield(res.WbestN{modelsize}, 'est2')
        spaths = res.WbestN{modelsize}.est2.sMaxP;
    else
        spaths = [];
    end
end

end