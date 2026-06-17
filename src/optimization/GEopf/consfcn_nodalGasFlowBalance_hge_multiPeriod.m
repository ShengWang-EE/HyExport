function f = consfcn_nodalGasFlowBalance_hge_multiPeriod(PGs,Qd,Qgpp,Qptg, gasFlow,Qd_export,mpc,nGasType,nGPP,nGasLoad,iGd,NK)
%% parameter
nGs = size(mpc.Gsou,1);
nGb = size(mpc.Gbus,1);
nGl = size(mpc.Gline,1);
nPTG = size(mpc.ptg,1);

f = sdpvar(NK,nGb,nGasType);
%%
for k = 1:NK
    for r = 1:nGasType
        % for each type of gas
        PGsbus = mpc.Gsou(:,1) ; 
        Cgs_PGs = sparse(PGsbus, (1:nGs)', 1, nGb, nGs); % connection matrix
        Qdbus = iGd; 
        Cgs_Qd = sparse(Qdbus, (1:nGasLoad)', 1, nGb, nGasLoad); % connection matrix
        f(k,:,r) = Cgs_PGs*(PGs(k,:)' .* mpc.gasCompositionForGasSource(:,r)) - Cgs_Qd * Qd(k,:,r)'; % supply-demand, Mm3/day
        
        % export demand
        if r == 2
            for i = 1:nPTG
                GB = mpc.ptg(i,1); % GB可能有重复的，所以得一个一个减
                f(k,GB,r) = f(k,GB,r) - Qd_export(k,i);
            end
        end

        % gas flow
        for  m = 1:nGl
            fb = mpc.Gline(m,1); tb = mpc.Gline(m,2);
    
            f(k,fb,r) = f(k,fb,r) - gasFlow(k,m,r);
            f(k,tb,r) = f(k,tb,r) + gasFlow(k,m,r);
        end
        % ptg
        if (r == 1) || (r == 2) % is methane or hydrogen
            for i = 1:nPTG
                GB = mpc.ptg(i,1);
                if r == 1 % methane
                    ptgGasType = 1;
                elseif r == 2 % hydrogen
                    ptgGasType = 2;
                end
                f(k,GB,r) = f(k,GB,r) + Qptg(k,i,ptgGasType);
            end
        end
        % gfu
        for i = 1:nGPP
            GB = mpc.GEcon(i,1);
            f(k,GB,r) = f(k,GB,r) - Qgpp(k,i,r);
        end
    end
end
end