% Print concrete numerical checks in physical units, failing on regression.
root=fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root,'src'));

% Independent exact solution: an immediate dose in one well-mixed pool.
p=pk_parameters(1); p.dose=10; p.V=2; p.CL=0.4;
s=pk_simulate(p,[0;4]); expected=5*exp(-0.2*4);
difference=abs(s.concentration(2)-expected); tolerance=2e-6;
fprintf('Decay: dose=10 mg, volume=2 L, clearance=0.4 L/h, time=4 h\n');
fprintf('  Expected %.10f mg/L; obtained %.10f mg/L; absolute error %.3g mg/L (limit %.3g)\n', ...
        expected,s.concentration(2),difference,tolerance);
assert(difference<=tolerance,'Worked decay differs from the exact solution');

% Regression reference for a fit, not an independent prediction of patients.
d=pk_load_data(); p=pk_parameters(1); p.dose=d.dose; p.infusion=d.infusion;
f=pk_fit(d.time,d.concentration,p,{'CL','V1'});
rows=pk_fit_residuals(d.time,d.concentration,f);
fprintf('Fit: dose=%.1f mg/m2 over %.1f h; six published rounded group means\n',d.dose,d.infusion);
fprintf('  time_h observed_ug_ml predicted_ug_ml error_ug_ml\n');
fprintf('  %7.1f %14.4f %15.4f %+11.4f\n',rows(:,1:4)');
fprintf('  CL=%.8f L/h/m2; V1=%.8f L/m2; RMSE=%.8f ug/mL\n', ...
        f.params.CL,f.params.V(1),f.rmse);
assert(f.exitflag>0,'Worked fit did not converge');
assert(abs(f.params.CL-0.01204046)<=2e-5);
assert(abs(f.params.V(1)-1.55336)<=0.005);
assert(abs(rows(1,3)-26.5695)<=0.005);
assert(abs(rows(1,4)-0.3695)<=0.005);
assert(abs(f.rmse-0.24535)<=0.005);
fprintf('  Reference limits: CL +/-0.00002 L/h/m2; V1 +/-0.005 L/m2; first prediction, error and RMSE +/-0.005 ug/mL\n');
fprintf('Worked numerical checks passed. Fit differences are in-sample, not clinical accuracy.\n');
