projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(projectRoot);
projectRoot = setupHyExport(projectRoot);
run(fullfile(projectRoot, 'main.m'));
