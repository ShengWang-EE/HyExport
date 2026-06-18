function root = setupHyExport(root)
if nargin == 0
    root = fileparts(mfilename('fullpath'));
end

addpath(genpath(fullfile(root, 'src')));
addpath(genpath(fullfile(root, 'scripts')));
addpath(genpath(fullfile(root, 'map')));
addpath(genpath(fullfile(root, 'matpower7.1')));
addpath(genpath(fullfile(root, 'toolbox_user', 'YALMIP-master')));
rmpath(fullfile(root, 'matpower7.1', 'mp-opt-model', '.github', 'osqp'));
configureGurobi();

checkpointDir = fullfile(root, 'results', 'checkpoints');
if exist(checkpointDir, 'dir') ~= 7
    mkdir(checkpointDir);
end
cd(root);
end

function configureGurobi()
if exist('gurobi', 'file') == 3 || exist('gurobi', 'file') == 2
    return;
end

gurobiHome = findGurobiHome();
if isempty(gurobiHome)
    warning('Gurobi installation not found. YALMIP calls that require ''gurobi'' may fail.');
    return;
end

gurobiMatlab = fullfile(gurobiHome, 'matlab');
gurobiBin = fullfile(gurobiHome, 'bin');
addpath(gurobiMatlab, '-begin');
setenv('GUROBI_HOME', gurobiHome);

if isfolder(gurobiBin)
    if ispc
        pathSep = ';';
    else
        pathSep = ':';
    end
    currentPath = getenv('PATH');
    if isempty(currentPath)
        setenv('PATH', gurobiBin);
    elseif ~contains(lower(currentPath), lower(gurobiBin))
        setenv('PATH', [gurobiBin pathSep currentPath]);
    end
end
end

function gurobiHome = findGurobiHome()
gurobiHome = '';

envHome = getenv('GUROBI_HOME');
if isValidGurobiHome(envHome)
    gurobiHome = envHome;
    return;
end

if ispc
    candidates = dir('C:/gurobi*/win64');
else
    candidates = [dir('/Library/gurobi*/macos_universal2'); dir('/Library/gurobi*/mac64')];
end

candidatePaths = cell(numel(candidates), 1);
candidateScores = -inf(numel(candidates), 1);
for i = 1:numel(candidates)
    candidatePaths{i} = fullfile(candidates(i).folder, candidates(i).name);
    token = regexp(candidatePaths{i}, 'gurobi(\d+)', 'tokens', 'once');
    if ~isempty(token)
        candidateScores(i) = str2double(token{1});
    end
end

[~, order] = sort(candidateScores, 'descend');
for i = 1:numel(order)
    candidateNow = candidatePaths{order(i)};
    if isValidGurobiHome(candidateNow)
        gurobiHome = candidateNow;
        return;
    end
end
end

function tf = isValidGurobiHome(pathNow)
tf = ~isempty(pathNow) && isfolder(fullfile(pathNow, 'matlab'));
end
