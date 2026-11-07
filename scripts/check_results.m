% Confirm regenerated results satisfy numerical contracts, allowing platform
% differences in adaptive integration, optimization and graphics rendering.
root=fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root,'src'));
r=@(name) dlmread(fullfile(root,'results',name),',',1,0);
f=r('fits.csv'); assert(isequal(size(f),[3 6]));
assert(f(1,4)<0.01 && f(1,5)<0.5);
assert(all(f(:,4)<1)); assert(all(f(:,5)<4)); assert(all(f(:,6)>0));
e=r('fit_residuals.csv'); assert(isequal(size(e),[18 6]));
assert(max(abs(e(:,5)-(e(:,4)-e(:,3))))<1e-8);
assert(max(abs(e(:,6)-100*e(:,5)./e(:,3)))<1e-7);
% Match every exported row to its source data and an independent simulation
% from the saved fitted parameters; arithmetic consistency alone is not enough.
data=pk_load_data();
for n=1:3
  rows=e(e(:,1)==n,:); assert(isequal(size(rows),[6 6]));
  assert(rows(:,2),data.time,1e-10);
  assert(rows(:,3),data.concentration,1e-10);
  assert(f(n,1)==n);
  p=pk_parameters(n); p.dose=data.dose; p.infusion=data.infusion;
  p.CL=f(n,2); p.V(1)=f(n,3);
  simulated=pk_simulate(p,data.time);
  assert(rows(:,4),simulated.concentration,1e-6);
  assert(f(n,4),sum(log(rows(:,4)./rows(:,3)).^2),1e-8);
  assert(f(n,5),sqrt(mean(rows(:,5).^2)),1e-8);
end
c=r('curves.csv'); assert(all(isfinite(c(:)))); assert(min(min(c(:,2:end)))>=-1e-8);
m=r('mass_balance.csv');
assert(max(abs(sum(m(:,2:5),2)-m(:,6)))<1e-6);
v=r('monte_carlo.csv'); assert(all(v(:,2)<=v(:,3) & v(:,3)<=v(:,4)));
d=r('monte_carlo_draws.csv'); assert(isequal(size(d),[200 3])); assert(all(d(:)>0));
s=r('sensitivity.csv'); assert(isequal(size(s),[100 7])); assert(all(isfinite(s(:))));
figures=dir(fullfile(root,'figures','*.png')); assert(numel(figures)==4);
assert(all([figures.bytes]>5000));
fprintf('Scientific output checks passed: 18 predictions recomputed within 1e-6 ug/mL, 3 fits, mass balance, 200 draws, 4 figures.\n');
