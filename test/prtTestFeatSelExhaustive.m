function result = prtTestFeatSelExhaustive

%%
result = true;
%%



%%
% This should not error out.
try
dataSet = prtDataCircles;
featSel = prtFeatSelExhaustive; 
featSel.nFeatures = 1;
featSel = featSel.train(dataSet);
outDataSet = featSel.run(dataSet);
catch
    disp('Error #1, basic feature selection fail')
    result = false;
end

if outDataSet.nFeatures ~=1
    disp('Error #2, wrong # of features')
    result = false;
end

if featSel.isTrained ~= 1
    disp('Error #2a, should be trained')
    result = false;
end


% Check changing the Eval metric
dataSet = prtDataCircles;
featSel = prtFeatSelExhaustive; 
featSel.nFeatures = 1;
try
featSel.EvaluationMetric = @(DS)prtScorePdAtPf(DS, prtClassMAP, .9);
featSel = featSel.train(dataSet);
outDataSet = featSel.run(dataSet);
catch
    disp('Error #3, change eval metric')
    result = false;
end

% check param/value constructor
try
    featSel = prtFeatSelExhaustive('nFeatures',2, 'EvaluationMetric', @(DS)prtScorePdAtPf(DS, prtClassMAP, .9));
catch
    disp('Error #4, param/val constructor fail')
    result = false;
end
%% Stuff that should error
error = true;
% This errors out messily if you don't train first, should error out clean.
dataSet = prtDataSpiral3;
featSel = prtFeatSelExhaustive; 
featSel.nFeatures = 1;

try
    R = featSel.run(dataSet);
    disp('Error# x , run before train')
    error = false;
end

result = result & error;


