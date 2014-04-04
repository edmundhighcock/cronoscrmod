function no_results = cronos_eqdsk(data, tavg)
%CREATES A EFIT EQDSK G FILE AND MATLABSTRUCTURE FROM CRONOS DATA.EQUI DATA. USED FOR CREATING 
%GEOMETRY INPUT FILES FOR GENE. ALSO CREATES CONVENIENT MATLAB STRUCTURE WITH KEY INFORMATION
%
%A CRONOS DATA FILE NEEDS TO BE IN THE BACKGROUND WHEN RUNNING THIS ROUTINE
%J.Citrin 20.05.2013


%%%%%%%%%%%%INPUT PARAMETERS%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fname='JET75225_Ptotred'; %choose a name for the output geometry file
%tavg=[46 47]; %choose a time window for averaging of CRONOS data
printflag=0; %flag to plot or not (=1) or not to plot (anything else) a figure of the 2D flux surfaces
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


bleed=0.02; %space around limits of R,Z points to define the rectangular grid

ind=round(interp1(data.gene.temps,1:length(data.gene.temps),tavg)); ind=ind(1):ind(2); %find the indexes in data.gene.temps of the desired time window
x=linspace(0,1,101); 

%obtain R,Z, and psi from data.equi. Note that the normalized radial coordinate below is from equi.rhoRZ./equi.rhoRZ(end) and not the uniform x!
R=squeeze(mean(data.equi.R(ind,:,:))); R=double(R); 
Z=squeeze(mean(data.equi.Z(ind,:,:))); Z=double(Z);
psiequi=-mean(data.equi.psiRZ(ind,:)); psiequi=(double(psiequi)); %the minus sign is there since eqdsk expects flipped psi profiles
resotheta=length(R(1,:)); %finds the theta resolution from the CRONOS simulation

%JC 15.5.13
%TO BE CONSISTENT WITH THE CHEASE EQDSK DATA, PSIEQUI IS SHIFTED SUCH THAT PSIEQUI(1)=0
%FEEL FREE TO CHANGE THIS, IT IS TRIVIAL TO DO SO
psiequi=psiequi-psiequi(1);
psiequi=psiequi-psiequi(end);
xrho=mean(data.equi.rhoRZ(ind,:)); xrho=xrho./xrho(end);
psix=interp1(xrho,psiequi,x);
rho1=mean(data.equi.rhomax(ind));

%set the resolution of the rectangular box (for now kept the same as the theta resolution from cronos)
resoR=resotheta; 
resoZ=resotheta;
resopsi=resotheta;

%resoR=100; 
%resoZ=100;
%resopsi=65;

%interpolate equi.psi onto the uniform toroidal flux grid and create 
%the normalized poloidal flux coordinate to interpolate the q, P, P', F, FF' profiles
xrho=mean(data.equi.rhoRZ(ind,:)); xrho=xrho./xrho(end); xrho=double(xrho);
psix=interp1(xrho,psiequi,x);
psinormx=(psix-psix(1))./(psix(end)-psix(1));
dvdrho=mean(data.equi.vpr(ind,:));
%create desired uniform normalized poloidal flux grid
xpsi=linspace(0,1,resopsi);


%define boundaries of rectangular grid
maxR=max(max(R))+bleed;
minR=min(min(R))-bleed;
maxZ=max(max(Z))+bleed;
minZ=min(min(Z))-bleed;

maxxZ = max([maxZ, -minZ]);
maxZ = maxxZ;
minZ = -maxxZ;

%create rectangular grid
xR=linspace(minR,maxR,resoR); 
% EGH Z is defined from - to plus, and it must also be symmetric
yR=linspace(minZ,maxZ,resoZ);
[xnodes,ynodes] = meshgrid(xR,yR); %xnodes, ynodes are matrices defining the x and y (R and Z) coordinates

%Create a 2D array for psi corresponding to x,theta (is a flux function, so same at every theta and tmp is discarded)
%This 2D array, which fits the x,theta arrays of R,Z, are interpolated onto the rectangular grid with coordinates xnodes,ynodes
[psibig,tmp]=meshgrid(psiequi,1:resotheta); psibig=psibig';
zefit1 = griddata(R,Z,psibig,xnodes,ynodes,'cubic');

%define psi quantities for all points in rectangular grid that lay outside of separatrix (became NaN in interpolation)
zefit1(isnan(zefit1))=psiequi(end)*1.05;

%grab necessary profiles and interpolate onto normalized poloidal flux grid
qraw=mean(data.equi.q(ind,:)); qraw=double(qraw);
s=mean(data.equi.shear(ind,:)); 
F=mean(data.equi.F(ind,:));
P=mean(data.prof.ptot(ind,:));
%FFprime=gradient(F,-psiequi); %the minus sign on psiequi defines the gradient to the ORIGINAL psi (i.e. the unflipped one)
% EGH Bugfix
% F and P are on grids of x not rho, so need to take gradient wrt psix
FFprime=gradient(F,psix); %the minus sign on psiequi defines the gradient to the ORIGINAL psi (i.e. the unflipped one)
Pprime=gradient(P,psix);

q=interp1(psinormx,qraw,xpsi);
F=interp1(psinormx,F,xpsi);
FFprime=interp1(psinormx,FFprime,xpsi).*F; %FFprime(1) = 0.0; 
%FFprime(1)=(FFprime(1)+FFprime(2))/2.0; 
%FFprime(1) = FFprime(2);
P=interp1(psinormx,P,xpsi);
Pprime=interp1(psinormx,Pprime,xpsi); %Pprime(1) = 0.0; 
Pprime(1)=(Pprime(1)+Pprime(2))/2.0; 
%Pprime(1)=Pprime(2);
Pprime(1) = 0.0;

%define header quantities for eqdsk file
boxw=maxR-minR; 
boxh=maxZ-minZ; 
rmaj=(maxR+minR)/2; 
rleft=minR;

zmid=(maxZ+minZ)/2; 
zmaxis=Z(1,1);


%ZMID AND ZMAXIS SWITCHED TO ZERO TO BE CONSISTENT WITH THE CHEASE EQDSK INFO
%zmid=0; 
%zmaxis=0;


%IT IS RECOMMENDED TO LEAVE RMAXIS AS IS, SINCE THIS PROVIDES INFORMATION ON THE SHAFRANOV SHIFT
rmaxis1=R(1,1);  
psiAxis=psiequi(1); 
%psiSep=psi(end)/1.05; %TEMP FIX
psiSep=psiequi(end);
B=mean(data.geo.b0(ind));
Ip=mean(data.gene.ip(ind))/1e6;
Ip=mean(data.gene.ip(ind));

fid1 = fopen(fname, 'w');

%write header quantities
fprintf(fid1, '     JET    EFIT  TRACER                           %d  %d  %d\n',0,resoR,resoZ);
fprintf(fid1,'% 16.9E% 16.9E% 16.9E% 16.9E% 16.9E\n% 16.9E% 16.9E% 16.9E% 16.9E% 16.9E\n% 16.9E% 16.9E% 16.9E% 16.9E% 16.9E\n% 16.9E% 16.9E% 16.9E% 16.9E% 16.9E\n',...
boxw,boxh,rmaj,rleft,zmid,rmaxis1,zmaxis,psiAxis,psiSep,B,Ip,psiAxis,0,rmaxis1,0,zmaxis,0,psiSep,0,0);;

%write F, FF', P, P' quantities 
for k=1:resopsi
	fprintf(fid1,'% 16.9E',F(k));
	if mod(k,5)==0
		fprintf(fid1,'\n');
	end
end

for k=1:resopsi
	fprintf(fid1,'% 16.9E',P(k));
	if mod(k,5)==0
		fprintf(fid1,'\n');
	end
end

for k=1:resopsi
	fprintf(fid1,'% 16.9E',FFprime(k));
	if mod(k,5)==0
		fprintf(fid1,'\n');
	end
end

for k=1:resopsi
	fprintf(fid1,'% 16.9E',Pprime(k));
	if mod(k,5)==0
		fprintf(fid1,'\n');
	end
end

%write poloidal flux onto rectangular grid
for j=1:resoZ
	for k=1:resoR
		fprintf(fid1,'% 16.9E',zefit1(j,k));
		if mod(k,5)==0
			fprintf(fid1,'\n');
		end
	end
end

%write the q-profile
for k=1:resopsi
	fprintf(fid1,'% 16.9E',q(k));
	if mod(k,5)==0
		fprintf(fid1,'\n');
	end
end

fprintf(fid1, ' %d %d \n', resotheta-1, 1);
j = 1
for k=1:(resotheta-1)
	fprintf(fid1, '% 16.9E', R(end, k));
	if mod(j,5)==0
		fprintf(fid1, '\n');
	end
	j = j + 1;
	fprintf(fid1, '% 16.9E', Z(end, k));
	if mod(j,5)==0
		fprintf(fid1, '\n');
	end
	j = j + 1;
end
	if mod(j-1,5)~=0
		fprintf(fid1, '\n');
	end

fprintf(fid1, ' %16.9E  %16.9E \n', 0.0, 0.0);
	


fclose(fid1);


%%%PLOT FLUX SURFACES FROM JUST MADE EQDSK FILE

fid=fopen(fname);
fseek(fid, 60, 'bof');
p=fscanf(fid,'%f');
fclose(fid);
pars=p(1:20);
p(1:20)=[];
p(1:resopsi*4)=[];
xefit=linspace(0,1,resopsi);
qefit=p(resoR*resoZ+1:end);
for j=1:resoZ
	for k=1:resoR
		psiefit(j,k)=p(resoR*(j-1)+k,1);
			
	end
end

%2D poloidal flux on R,Z grid
eval([fname,'.psi2D=psiefit;']);

%poloidal flux on the magnetic axis and the last-closed-flux surface 
eval([fname,'.psiaxis=psiequi(1);']);
eval([fname,'.psiedge=psiequi(end);']);

%major radius
eval([fname,'.r0=rmaj;']);

%radius of the magnetic axis (difference between raxis and r0 is the Shafranov shift)
eval([fname,'.raxis=rmaxis1;']);

%z location of the geometric and magnetic axis center. If they are not the same it just means that the magnetic geometry is not up-down symmetric (which is common)
eval([fname,'.zmid=zmid;']);
eval([fname,'.zaxis=zmaxis;']);

%R and Z grids for the 2D psi
eval([fname,'.rmesh=xnodes(1,:)'';']);
eval([fname,'.zmesh=ynodes(:,1);']);

%Normalized toroidal flux coordinate grid
eval([fname,'.rhonorm=linspace(0,1,101);']);

%Toroidal flux on the last-closed-flux surface
eval([fname,'.rhoedge=rho1;']);

%1D psi on the toroidal flux grid
eval([fname,'.psi1D=psix;']);

%dvdrho on the toroidal flux grid
eval([fname,'.dvdrho=dvdrho;']);

eval(['save(''',fname,''');']);

%quick automatic contour plot of 2D flux surfaces
if printflag==1
	figure; contour(xnodes,ynodes,psiefit,40); axis equal
end
