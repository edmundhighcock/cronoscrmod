function no_results = output_ogyropsi(data, tavg)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% The ogyropsi CHEASE output file 
% consists of MKSA quantities on a
% flux surface grid. Not sure yet
% what the spacing of the grid is
% set by.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This file is currently incomplete:
% It outputs zeros for a lot of quantities
% and skips some altogether. It is intended
% to output quantities to compare to a CHEASE
% run which uses an EQDSK file from the same
% Cronos run as input
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% data is the cronos data structure
% and t avg is an a time window given
% as an array of two values... quanitities
% are averaged over that time window.
% e.g. output_ogyropsi(data, [45.2 46]);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

ind=round(interp1(data.gene.temps,1:length(data.gene.temps),tavg)); ind=ind(1):ind(2); %find the indexes in data.gene.temps of the desired time window
npsi = size(data.equi.R, 2);
nchi = size(data.equi.R, 3) - 1; % ogyropsi doesn't have the 2pi point

x=linspace(0,1,npsi); 
% xrho is the values of x on the grid used for some equi quantities like psiRZ
xrho=mean(data.equi.rhoRZ(ind,:)); xrho=xrho./xrho(end); xrho=double(xrho);

outfile = fopen('ogyropsi.dat', 'w');

fprintf(outfile, 'NPSI\n %d\nNCHI\n %d\n', npsi, nchi);
R = squeeze(mean(data.equi.R(ind, :, :)));
Z = squeeze(mean(data.equi.Z(ind, :, :)));
% R and Z are not on the uniform toroidal flux grid
for i=1:(nchi+1)
	R(:,i) = interp1(xrho, R(:,i), x);
	Z(:,i) = interp1(xrho, Z(:,i), x);
end


B=mean(data.geo.b0(ind));
fprintf(outfile, 'R0EXP\n %16.9E\nB0EXP\n %16.9E\n', R(1,1), B);


psiequi=mean(data.equi.psiRZ(ind,:)); psiequi=(double(psiequi)); %the minus sign is there since eqdsk expects flipped psi profiles
psiequi=-psiequi + psiequi(1);
psix=interp1(xrho,psiequi,x);
%fprintf(outfile, 'PSI\n'); fprintf(outfile, form, psix);
write_array(outfile, 'PSI', psix);

chi = linspace(0.0, 2*pi, nchi+1);
chi = chi(1:nchi);
write_array(outfile, 'CHI', chi);

%%% MAJOR AND MINOR RADII
Rgeom = (R(:,1)+R(:,(nchi)/2))/2;
write_array(outfile, 'Rgeom', Rgeom);
ageom = (R(:,1)-R(:,(nchi)/2));
write_array(outfile, 'ageom', ageom);

%%% SAFETY FACTOR
q=mean(data.equi.q(ind,:)); q=double(q);
write_array(outfile, 'q', q);
dqdpsi = gradient(q, psix);
write_array(outfile, 'dqdpsi', dqdpsi);
d2qdpsi2 = gradient(dqdpsi, psix);
write_array(outfile, 'd2qdpsi2', d2qdpsi2);

%%% PRESSURE
p=mean(data.prof.ptot(ind,:));
write_array(outfile, 'p', p);
dpdpsi = gradient(p, psix);
write_array(outfile, 'dpdpsi', dpdpsi);

%%% TOROIDAL FIELD CURRENT FUNCTION
f=mean(data.equi.F(ind,:));
write_array(outfile, 'f', f);
fdfdpsi = gradient(f, psix).*f;
write_array(outfile, 'fdfdpsi', fdfdpsi);

%%% FLUX SURFACE VOLUME 
v=mean(data.equi.volume(ind,:));
% The above gives NaNs.... don't know why
v = q*0.0;
write_array(outfile, 'V', v);


% SQRT TOROIDAL FLUX
rhox = interp1(xrho, mean(data.equi.rhoRZ(ind,:)), x);
write_array(outfile, 'rho_t', rhox);

%%% MAGNETIC SHEAR
shear=mean(data.equi.shear(ind,:)); shear=double(shear);
write_array(outfile, 'shear', shear);
dsheardpsi = gradient(shear, psix);
write_array(outfile, 'dsheardpsi', dsheardpsi);

dummy_array = shear*0.0;
write_array(outfile, 'kappa', dummy_array);
write_array(outfile, 'delta_lower', dummy_array);
write_array(outfile, 'delta_upper', dummy_array);
write_array(outfile, 'dVdpsi', dummy_array);
write_array(outfile, 'dpsidrhotor', dummy_array);
write_array(outfile, 'GDPSI_av', dummy_array);
write_array(outfile, 'radius_av', dummy_array);
write_array(outfile, 'R_av', dummy_array);

%%% ELECTRON PROFILES
te=mean(data.prof.te(ind,:));
write_array(outfile, 'TE', te);
dtedpsi = gradient(te, psix);
write_array(outfile, 'DTEDPSI', dtedpsi);

ne=mean(data.prof.ne(ind,:));
write_array(outfile, 'NE', ne);
dnedpsi = gradient(ne, psix);
write_array(outfile, 'DNEDPSI', dnedpsi);

%%% ION PROFILES
ti=mean(data.prof.ti(ind,:));
write_array(outfile, 'TI', ti);
dtidpsi = gradient(ti, psix);
write_array(outfile, 'DTIDPSI', dtidpsi);

ni=mean(data.prof.ni(ind,:));
write_array(outfile, 'NI', ni);
dnidpsi = gradient(ni, psix);
write_array(outfile, 'DNIDPSI', dnidpsi);

%%% ZEFF
zeff=mean(data.prof.zeff(ind,:));
write_array(outfile, 'ZEFF', zeff);

%%% MAJOR RADIUS OF FLUX SURFACES
write_array(outfile, 'R', R(:, 1:nchi));


%%% HEIGHT Z OF FLUX SURFACES
write_array(outfile, 'Z', Z(:, 1:nchi));

fclose(outfile);

function write_array(outfile, name, array)

form = ' %16.9E %16.9E %16.9E %16.9E %16.9E\n';
fprintf(outfile, '%s\n', name); 
fprintf(outfile, form, array);
if mod(size(array),5) ~= 0
	fprintf(outfile, '\n');
end


