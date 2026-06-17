function Power_pv=PVPower_Beckman(Power_rated_pv,G_T_R,Wind_speed)

Ambient_temperature=10;
eta_pv_stc=0.1;
mu_Voc=-0.075;
V_mp=17.5;
T_stc=25;
NOCT=45;
Area_pv=1;
Power_module_pv=0.001;% MW, 认为光伏功率密度是1kw/m2

mu=eta_pv_stc*mu_Voc/V_mp;

eta_pv = eta_pv_stc .* (1 + mu/eta_pv_stc.*(Ambient_temperature-T_stc) ...
    + mu/eta_pv_stc.*(NOCT-20)/800*9.5./(5.7+3.8.*Wind_speed).*(1-eta_pv_stc).*G_T_R);

nHour = size(G_T_R,1);
Power_pv=(repmat(Power_rated_pv',[nHour,1])/1000./eta_pv_stc).*eta_pv.*G_T_R;