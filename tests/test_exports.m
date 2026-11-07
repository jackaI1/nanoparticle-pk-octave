% Export checks must reject plausible but incorrect observation/prediction rows.
% Each case owns a small copy so the committed results are never edited.

%!function check_export_fixture(changed_column)
%! source=fileparts(fileparts(which('pk_fit')));
%! fixture=tempname(); mkdir(fixture);
%! guard=onCleanup(@() rmdir(fixture,'s'));
%! original_path=path(); path_guard=onCleanup(@() path(original_path));
%! for name={'src','data','scripts','results','figures'}
%!   copyfile(fullfile(source,name{1}),fullfile(fixture,name{1}));
%! end
%! checker=fullfile(fixture,'scripts','check_results.m');
%! run_checker(checker); % The unmodified fixture must pass first.
%! path=fullfile(fixture,'results','fit_residuals.csv');
%! fid=fopen(path,'r'); header=fgetl(fid); fclose(fid);
%! rows=dlmread(path,',',1,0);
%! rows(1,changed_column)=rows(1,changed_column)+0.1;
%! rows(:,5)=rows(:,4)-rows(:,3);
%! rows(:,6)=100*rows(:,5)./rows(:,3);
%! fid=fopen(path,'w'); fprintf(fid,'%s\n',header); fclose(fid);
%! dlmwrite(path,rows,'-append','precision','%.15g','delimiter',',');
%! rejected=false;
%! try
%!   run_checker(checker);
%! catch
%!   rejected=true;
%! end
%! assert(rejected,'An internally consistent but incorrect export was accepted');
%!endfunction

%!function run_checker(path)
%! evalc('run(path)');
%!endfunction

%!test
%! check_export_fixture(3); % Alter an observed concentration, keeping arithmetic consistent.

%!test
%! check_export_fixture(4); % Alter a prediction, keeping arithmetic consistent.
