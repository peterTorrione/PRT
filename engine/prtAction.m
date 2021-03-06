classdef prtAction
    % prtAction - Base class for many PRT components.
    % 
    %  prtAction is an abstract class and cannot be instantiated.
    %
    %   Classification, regression and feature selection techniques are all
    %   sub-classes of prtAction.
    %
    %   All prtAction objects have the following properties:
    %
    %   name                 - Descriptive name for prtAction object
    %   nameAbbreviation     - Shortened name for prtAction object
    %   isTrained            - Indicates whether the current prtAction 
    %                          object has been trained                          
    %   isCrossValidateValid - Flag indicating whether or not
    %                          cross-validation is a valid operation on 
    %                          this prtAction object.
    %   verboseStorage       - Flag to allow or disallow verbose storage
    %   dataSetSummary       - A struct, set during training, containing
    %                          information about the training data set
    %   dataSet              - A prtDataSet, containing the training data,
    %                          only used if verboseStorage is true
    %   userData             - A struct containing user specified data
    %
    %   All prtAction objects have the following methods:
    %
    %   train             - Train the prtAction object using a prtDataSet
    %   run               - Evaluate the prtAction object on a prtDataSet
    %   runOnTrainingData - Evaluate the prtAction object on a prtDataSet
    %                       during training prior to training of other
    %                       prtActions within a prtAlgorithm
    %   crossValidate     - Cross-validate a prtAction object using a 
    %                       labeled prtDataSet and cross-validation keys.
    %   kfolds            - K-folds cross-validate a prtAction object using
    %                       a labeled prtDataSet
    %   optimize          - Optimize the prtAction for a specified
    %                       parameter
    % See Also: prtAction/train, prtAction/run, prtAction/crossValidate,
    % prtAction/kfolds, prtClass, prtRegress, prtFeatSel, prtPreProc,
    % prtDataSetBase
    
    properties (Abstract, SetAccess = private)
        % Descriptive name of prtAction object.
        name
        
        % Shortened name for the prtAction object.
        nameAbbreviation 
    end
    
    properties (Abstract, SetAccess = protected)
        % Specifies if the prtAction requires a labeled dataSet
        isSupervised
        
        % Indicates whether or not cross-validation is a valid operation
        isCrossValidateValid
    end
    
    properties (Hidden = true)
        
        % A tag that can be used to reference a specific action within a
        % prtAlgorithm
        tag = '';
    end
    
    properties (Hidden = true, SetAccess=protected, GetAccess=protected)
        classTrain = 'prtDataSetBase';
        classRun = 'prtDataSetBase';
        classRunRetained = false;
        
        verboseFeatureNamesInternal = false;
        verboseStorageInternal = prtAction.getVerboseStorage();
        showProgressBarInternal = prtAction.getShowProgressBar();
    end
    
    properties (Dependent)
        % Specifies whether or not to store the training prtDataset.
        % If true the training prtDataSet is stored internally prtAction.dataSet.
        verboseStorage
        showProgressBar
        % A logical to specify if modified feature names should be stored
        % even if no feature names were specified for the dataset
        verboseFeatureNames = true;
    end
    
    methods (Hidden = true)
        function dataSet = updateDataSetFeatureNames(obj,dataSet)
            
            if obj.verboseFeatureNames %this is redundant... but I'm not sure why the following code checks this anyway
                if isa(dataSet,'prtDataSetStandard') && (dataSet.hasFeatureNames || obj.verboseFeatureNames)
                    fNames = dataSet.getFeatureNames;
                    fNames = obj.updateFeatureNames(fNames);
                    if ~isempty(fNames) %it's possible that the feature set is *empty*; in which case, don't bother
                        dataSet = dataSet.setFeatureNames(fNames);
                    end
                end
            end
        end
    end
    
    methods (Hidden = true)
        function featureNames = updateFeatureNames(obj,featureNames) %#ok<MANU>
            %Default: do nothing
        end
    end
    
    properties (SetAccess = protected)
        % Indicates if prtAction object has been trained.
        isTrained = false;
        %   Set automatically in prtAction.train().
        
        % Structure that summarizes prtDataSet.
        dataSetSummary = [];
        %   Produced by prtDataSet.summarize() and stored in
        %   prtAction.train(). Used to characterize the dataset for
        %   plotting when prtAction.verboseStorage == false
        
        %  The training prtDataSet, only stored if verboseStorage is true. 
        dataSet = []; 
         %   Only stored if prtAction.verboseStorage == true. Otherwise it
        %   is empty.
        
    end
    
    properties
        % User specified data
        userData = struct;
        %   Some prtActions store additional information from
        %   prtAction.run() as a structure in prtAction.userData()
    end
    
    methods (Abstract, Access = protected, Hidden = true)
        % prtAction.trainAction() - Primary method for training a prtAction
        %   Obj = prtAction.trainAction(Obj,DataSet)
        Obj = trainAction(Obj, DataSet)
        
        % prtAction.runAction() - Primary method for evaluating a prtAction
        %   DataSet = runAction(Obj, DataSet)
        DataSet = runAction(Obj, DataSet)
    end
    methods (Access = protected, Hidden = true)
        function xOut = runActionFast(Obj, xIn, ds) %#ok<STOUT,INUSD>
            error('prt:prtAction:runActionFast','The prtAction (%s) does not have a runActionFast() method. Therefore runFast() cannot be used.',class(Obj));
        end
    end
    
    methods (Hidden)
        function Obj = plus(in1,in2)
            if isa(in2,'prtAlgorithm')
                Obj = in2 - in1; % Use prtAlgorithm (use MINUS to flip left/right)
            elseif isa(in2,'prtAction') && (isa(in2,'prtAction') || all(cellfun(@(x)isa(x,'prtAction'),in2)))
                Obj = prtAlgorithm(in1) + prtAlgorithm(in2);
            else
                error('prt:prtAction:plus','prtAction.plus is only defined for second inputs of type prtAlgorithm or prtAction, but the second input is a %s',class(in2));
            end
        end
        
        
        function Obj = mldivide(in1,in2)
            if isa(in2,'prtAlgorithm')
                Obj = in2 / in1; % Use prtAlgorithm(use MLDIVIDE to flip left/right)
            elseif isa(in2,'prtAction')
                Obj = prtAlgorithm(in1) \ prtAlgorithm(in2);
            else
                error('prt:prtAction:mldivide','prtAction.mldivide is only defined for second inputs of type prtAlgorithm or prtAction, but the second input is a %s',class(in2));
            end
        end
        
        function Obj = mrdivide(in1,in2)
            if isa(in2,'prtAlgorithm')
                Obj = in2 \ in1; % Use prtAlgorithm(use MLDIVIDE to flip left/right)
            elseif isa(in2,'prtAction')
                Obj = prtAlgorithm(in1) / prtAlgorithm(in2);
            else
                error('prt:prtAction:mrdivide','prtAction.mrdivide is only defined for second inputs of type prtAlgorithm or prtAction, but the second input is a %s',class(in2));
            end
        end
        
        function DataSetOut = runOnTrainingData(Obj, DataSetIn)
            % RUNONTRAININGDATA  Run a prtAction object on a prtDataSet
            % object during training of a prtAlgorithm
            %
            %   OUTPUT = OBJ.run(DataSet) runs the prtAction object using
            %   the prtDataSet DataSet. OUTPUT will be a prtDataSet object.
            DataSetOut = preRunProcessing(Obj, DataSetIn);
            DataSetOut = runActionOnTrainingData(Obj, DataSetOut);
            DataSetOut = postRunProcessing(Obj, DataSetIn, DataSetOut);
        end
    end
    methods
        function Obj = train(Obj, DataSet)
            % TRAIN  Train a prtAction object using training a prtDataSet object.
            %
            %   OBJ = OBJ.train(DataSet) trains the prtAction object using
            %   the prtDataSet DataSet
            
            if ~isscalar(Obj)
                error('prt:prtAction:NonScalarAction','train method expects scalar prtAction objects, prtAction provided was of size %s',mat2str(size(Obj)));
            end

            inputClassType = class(DataSet);
            if ~isempty(Obj.classTrain) && ~prtUtilDataSetClassCheck(inputClassType,Obj.classTrain)
                error('prt:prtAction:incompatible','%s.train() requires datasets of type %s but the input is of type %s, which is not a subclass of %s', class(Obj), Obj.classTrain, inputClassType, Obj.classTrain);
            end
            
            if Obj.isSupervised && ~DataSet.isLabeled
                error('prt:prtAction:noLabels','%s is a supervised action and therefore requires that the training dataset is labeled',class(Obj));
            end 
            
            % Default preTrainProcessing() stuff
            Obj.dataSetSummary = summarize(DataSet);
            
            %preTrainProcessing should make sure Obj has the right
            %verboseStorage
            Obj = preTrainProcessing(Obj,DataSet);
            
            if Obj.verboseStorage
                Obj.dataSet = DataSet;
            end
            
            Obj = trainAction(Obj, DataSet);
            Obj.isTrained = true;
            Obj = postTrainProcessing(Obj,DataSet);
        end
        
        function [DataSetOut, extraOutput] = run(Obj, DataSetIn)         
            % RUN  Run a prtAction object on a prtDataSet object.
            %
            %   OUTPUT = OBJ.run(DataSet) runs the prtAction object using
            %   the prtDataSet DataSet. OUTPUT will be a prtDataSet object.
            
            if ~Obj.isTrained
                error('prtAction:run:ActionNotTrained','Attempt to run a prtAction of type %s that was not trained',class(Obj));
            end
                
            inputClassName = class(DataSetIn);
            
            if ~isempty(Obj.classRun) && ~prtUtilDataSetClassCheck(inputClassName,Obj.classRun)
                error('prt:prtAction:incompatible','%s.run() requires datasets of type %s but the input is of type %s, which is not a subclass of %s.',class(Obj), Obj.classRun, inputClassName, Obj.classRun);
            end
            
            if isempty(DataSetIn)
                DataSetOut = DataSetIn;
                return
            end
            
            DataSetOut = preRunProcessing(Obj, DataSetIn);
            switch nargout
                case 1
                   DataSetOut = runAction(Obj, DataSetOut);
                case 2 
                    [DataSetOut, extraOutput] = runAction(Obj, DataSetOut);
            end
            DataSetOut = postRunProcessing(Obj, DataSetIn, DataSetOut);
           
            outputClassName = class(DataSetOut);
            
            if Obj.classRunRetained && ~isequal(outputClassName,inputClassName)
                error('prt:prtAction:incompatible','%s specifies that it retains the class of input datasets however, the class of the output dataset is %s and the class of the input dataset is %s. This may indicate an error with the runAction() method of %s.', class(Obj), Obj.classRun, inputClassName, class(Obj));
            end
        end
        
        function Obj = set.classRun(Obj,val)
            assert(ischar(val),'prt:prtAction:classRun','classRun must be a string.');
            Obj.classRun = val;
        end
        function Obj = set.classTrain(Obj,val)
            assert(ischar(val),'prt:prtAction:classTrain','classTrain must be a string.');
            Obj.classTrain = val;
        end
        function Obj = set.classRunRetained(Obj,val)
            assert(prtUtilIsLogicalScalar(val),'prt:prtAction:classRunRetained','classRunRetained must be a scalar logical.');
            Obj.classRunRetained = val;
        end        
        
        function Obj = set.verboseFeatureNames(Obj,val)
            Obj = Obj.setVerboseFeatureNames(val);
        end
        
        function Obj = set.verboseStorage(Obj,val)
            Obj = Obj.setVerboseStorage(val);
        end
        
        function Obj = set.showProgressBar(Obj,val)
            Obj = Obj.setShowProgressBar(val);
        end
        
        function val = get.verboseStorage(Obj)
            val = Obj.verboseStorageInternal;
        end
        
        function val = get.verboseFeatureNames(Obj)
            val = Obj.verboseFeatureNamesInternal;
        end
        
        function val = get.showProgressBar(Obj)
            val = Obj.showProgressBarInternal;
        end
        
        function [OutputDataSet, TrainedActions] = crossValidate(Obj, DataSet, validationKeys)
            % CROSSVALIDATE  Cross validate prtAction using prtDataSet and cross validation keys.
            %
            %  OUTPUTDATASET = OBJ.crossValidate(DATASET, KEYS) cross
            %  validates the prtAction object OBJ using the prtDataSet
            %  DATASET and the KEYS. DATASET must be a labeled prtDataSet.
            %  KEYS must be a vector of integers with the same number of
            %  elements as DataSet has observations.
            %
            %  The KEYS are are used to parition the input DataSet into
            %  test and training data sets. For each unique key, a test set
            %  will be created out of the corresponding observations of the
            %  prtDataSet. The remaining observations will be used as
            %  training data.
            %
            %  [OUTPUTDATASET, TRAINEDACTIONS] = OBJ.crossValidate(DATASET,
            %  KEYS) outputs the trained prtAction objects TRAINEDACTIONS.
            %  TRAINEDACTIONS will have a length equal to the number of
            %  unique KEYS.
            
            
            if ~Obj.isCrossValidateValid
                %Should this error?
                warning('prtAction:crossValidate','The input object of type %s has isCrossValidateValid set to false; the outputs of cross-validation may be meaningless',class(Obj));
            end
            if ~isvector(validationKeys) || (numel(validationKeys) ~= DataSet.nObservations)
                error('prt:prtAction:crossValidate','validationKeys must be a vector with a length equal to the number of observations in the data set');
            end
            
            uKeys = unique(validationKeys);
            
            actuallyShowProgressBar = Obj.showProgressBar && (length(uKeys) > 1);
            
            if actuallyShowProgressBar
                waitBarObj = prtUtilProgressBar(0,sprintf('Crossvalidating - %s',Obj.name),'autoClose',true);
                
                % cleanupObj = onCleanup(@()close(waitBarObj));
                % % The above would close the waitBar upon completion but
                % % it doesn't play nice when there are many bars in the
                % % same window
            end
            
            isDataSetClass = isa(DataSet,'prtDataSetClass'); % Used below to provide a nicer error message in bad casses.
            if isDataSetClass 
                inputNumberOfClasses = DataSet.nClasses;
            end
            
            for uInd = 1:length(uKeys);
                    
                if actuallyShowProgressBar
                    waitBarObj.update((uInd-1)/length(uKeys));
                end
                
                %get the testing indices:
                if isa(uKeys(uInd),'cell')
                    cTestLogical = strcmp(uKeys(uInd),validationKeys);
                else
                    cTestLogical = uKeys(uInd) == validationKeys;
                end
                
                testDataSet = DataSet.retainObservations(cTestLogical);
                if length(uKeys) == 1  %1-fold, incestuous train and test
                    trainDataSet = testDataSet;
                else
                    trainDataSet = DataSet.removeObservations(cTestLogical);
                end
                %fprintf('Original: %d, Train: %d, Test: %d\n',DataSet.nObservations,trainDataSet.nObservations,testDataSet.nObservations);
                
                if isDataSetClass && trainDataSet.nClasses ~= inputNumberOfClasses
                	warning('prt:prtAction:crossValidateNClasses','Cross validation fold %d yielded a test data set with %d class(es) but the input data set contains %d classes. This may result in errors. It may be possible to resolve this by modifying the cross-validation keys.', uInd, trainDataSet.nClasses, inputNumberOfClasses)
                end
                
                classOut = Obj.train(trainDataSet);
                currResults = classOut.run(testDataSet);
                
                if currResults.nObservations < 1
                    error('prt:prtAction:crossValidate','A cross-validation fold returned a data set with no observations.')
                end
                if uInd == 1
                    nOutputDimensions = length(currResults.getX(1,:));
                end
                if nOutputDimensions ~= length(currResults.getX(1,:));
                    error('prt:prtAction:crossValidate','A cross-validation fold returned a data set with a different number of dimensions than a previous fold.')
                end
                
                if uInd == 1
                    InternalOutputDataSet = currResults;
                    
                    OutputMat = nan(DataSet.nObservations, nOutputDimensions);
                end
                OutputMat(cTestLogical,:) = currResults.getObservations();
                
                %only do this if the output is requested; otherwise this cell of
                %classifiers can get very large, and slow things down.
                if nargout >= 2
                    if uInd == 1
                        % First iteration pre-allocate
                        TrainedActions = repmat(classOut,length(uKeys),1);
                    else
                        TrainedActions(uInd) = classOut;
                    end
                end
            end	
            if actuallyShowProgressBar
                waitBarObj.update(1);
            end
            
            OutputDataSet = DataSet;
            OutputDataSet = OutputDataSet.setObservations(OutputMat);
            %OutputDataSet = OutputDataSet.setFeatureNames(InternalOutputDataSet.getFeatureNames);
        end
        
        function varargout = kfolds(Obj,DataSet,K)
            % KFOLDS  Perform K-folds cross validation of prtAction
            % 
            %    OUTPUTDATASET = Obj.KFOLDS(DATASET, K) performs K-folds
            %    cross validation of the prtAction object OBJ using the
            %    prtDataSet DATASET. DATASET must be a labeled prtDataSet,
            %    and K must be a scalar interger, representing the number
            %    of folds. KFOLDS Generates cross validation keys by
            %    patitioning the dataSet into K groups such that the number
            %    of samples of each uniqut target type is attempted to be
            %    held constant.
            %
            %    [OUTPUTDATASET, TRAINEDACTIONS, CROSSVALKEYS] =
            %    Obj.KFOLDS(DATASET, K)  outputs the trained prtAction
            %    objects TRAINEDACTIONS, and the generated cross-validation
            %    keys CROSSVALKEYS.
            %
            %    To manually set which observations correspond are in 
            %    which fold see crossValidate.
            
            
            assert(isa(DataSet,'prtDataSetBase'),'First input must by a prtDataSet.');
            
            if nargin == 2 || isempty(K)
                K = DataSet.nObservations;
            end
            
            assert(prtUtilIsPositiveScalarInteger(K),'prt:prtAction:kfolds','K must be a positive scalar integer');
            
            nObs = DataSet.nObservations;
            if K > nObs;
                warning('prt:prtAction:kfolds:nFolds','Number of folds (%d) is greater than number of data points (%d); assuming Leave One Out training and testing',K,nObs);
                K = nObs;
            elseif K < 1
                warning('prt:prtAction:kfolds:nFolds','Number of folds (%d) is less than 1 assuming FULL training and testing',K);
                K = 1;
            end
            
            keys = DataSet.getKFoldKeys(K);
            
            outputs = cell(1,min(max(nargout,1),2));
            [outputs{:}] = Obj.crossValidate(DataSet,keys);
            
            varargout = outputs(:);
            if nargout > 2
                varargout = [varargout; {keys}];
            end
        end
        
        function Obj = set(Obj,varargin)
            % set - set the object properties
            %   
            % OBJ = OBJ.set(PARAM, VALUE) sets the parameter PARAM of OBJ
            % to the value VALUE. PARAM must be a string indicating the
            % parameter to be set.
            %
            % OBJ = OBJ.set(PARAM1, VALUE1, PARAM2, VALUE2....) sets all
            % the desired parameters to the specified values.
            
            % ActionObj = get(ActionObj,paramNameStr,paramValue);
            % ActionObj = get(ActionObj,paramNameStr1,paramValue1, paramNameStr2, paramNameValue2, ...); 
            
            Obj = prtUtilAssignStringValuePairs(Obj,varargin{:});
        end
        
        function out = get(Obj,varargin)
            % get - get the object properties
            % 
            % val = obj.get(PARAM) retutns the value of the parameter
            % specified by the string PARAM.
            %
            % vals = obj.get(PARAM1, PARAM2....) returns a structure
            % containing the values of all the parameters specified by the
            % PARAM strings
            
            
            % paramValue = get(ActionObj,paramNameStr);
            % paramStruct = get(ActionObj,paramNameStr1,paramNameStr2,...);
            
            nameStrs = varargin;
            
            assert(iscellstr(nameStrs),'additional input arguments must be property name strings');
            
            % No additional inputs, assume all
            if isempty(nameStrs)
                nameStrs = properties(Obj);
            end
            
            % Only one property requested
            % Return value
            if numel(nameStrs)==1
                out = Obj.(nameStrs{1});
                return
            end

            % Several properties requested
            % Return structure of values
            out = struct;
            for iProp = 1:length(nameStrs)
                out.(nameStrs{iProp}) = Obj.(nameStrs{iProp});
            end
        end
        
    end
    
    methods (Access=protected, Hidden= true)
        function ActionObj = preTrainProcessing(ActionObj,DataSet) %#ok<INUSD>
            % preTrainProcessing - Processing done prior to trainAction()
            %   Called by train(). Can be overloaded by prtActions to
            %   store specific information about the DataSet or Classifier
            %   prior to training.
            %   
            %   ActionObj = preTrainProcessing(ActionObj,DataSet)
        end
        
        function ActionObj = postTrainProcessing(ActionObj,DataSet) %#ok<INUSD>
            % postTrainProcessing - Processing done after trainAction()
            %   Called by train(). Can be overloaded by prtActions to
            %   store specific information about the DataSet or Classifier
            %   prior to training.
            %   
            %   ActionObj = postTrainProcessing(ActionObj,DataSet)
        end
        
        function DataSet = preRunProcessing(ActionObj, DataSet) %#ok<MANU>
            % preRunProcessing - Processing done before runAction()
            %   Called by run(). Can be overloaded by prtActions to
            %   store specific information about the DataSet or Classifier
            %   prior to runAction.
            %   
            %   DataSet = preRunProcessing(ActionObj, DataSet)
        end        
        
        function DataSetOut = postRunProcessing(ActionObj, DataSetIn, DataSetOut)
            % postRunProcessing - Processing done after runAction()
            %   Called by run(). Can be overloaded by prtActions to alter
            %   the results of run() to modify outputs using parameters of
            %   the prtAction.
            %   
            %   DataSet = postRunProcessing(ActionObj, DataSet)
            
            if DataSetIn.nObservations > 0
                if ActionObj.isCrossValidateValid
                    if DataSetIn.isLabeled && ~DataSetOut.isLabeled
                        DataSetOut = DataSetOut.setTargets(DataSetIn.getTargets);
                    end
                    DataSetOut = DataSetOut.copyDescriptionFieldsFrom(DataSetIn);
                end
                DataSetOut = ActionObj.updateDataSetFeatureNames(DataSetOut);
            end
        end
        
        function xIn = preRunProcessingFast(ActionObj, xIn, ds) %#ok<INUSD,MANU>
            % preRunProcessingFast - Processing done before runAction()
            %   Called by runFast(). Can be overloaded by prtActions to
            %   store specific information about the xIn or Classifier
            %   prior to runAction.
            %   
            %   xOut = preRunProcessingFast(ActionObj, xIn, ds)
        end
        
        function xOut = postRunProcessingFast(ActionObj, xIn, xOut, dsIn) %#ok<MANU,INUSD>
            % postRunProcessingFast - Processing done after runAction()
            %   Called by runFast(). Can be overloaded by prtActions to
            %   alter the results of run() to modify outputs using
            %   parameters of the prtAction.
            %   
            %   DataSet = postRunProcessing(ActionObj, DataSet)
        end
        
    end
    methods (Access = protected, Hidden)
        function DataSetOut = runActionOnTrainingData(Obj, DataSetIn)
            % RUNACTIONONTRAININGDATA Run a prtAction object on a prtDataSet object
            %   This method differs from RUN() in that it is called after
            %   train() within prtAlgorithm prior to training of subsequent
            %   actions. By default this method is the same as RUN() but it
            %   can be overloaded by prtActions to enable things such as 
            %   outlier removal.
            %
            %    DataSetOut = runOnTrainingData(Obj DataSetIn);
            
            DataSetOut = runAction(Obj, DataSetIn);
        end
    end
    methods (Hidden = false)
        function [optimizedAction,performance] = optimize(Obj,DataSet,objFn,parameterName,parameterValues)
            % OPTIMIZE Optimize action parameter by exhaustive function maximization.
            %
            %  OPTIMACT = OPTIMIZE(DS, EVALFN, PARAMNAME, PARAMVALS)
            %  returns an optimized prtAction object, with parameter
            %  PARAMNAME set to the optimal value. DS must be a prtDataSet
            %  object. EVALFN must be a function handle that returns a
            %  scalar value that indicates a performance metric for the
            %  prtAction object, for example a prtEval function. PARAMNAME
            %  must be a string that indicates the parameter of the
            %  prtAction that is to be optimized. PARAMVALS must be a
            %  vector of possible values of the parameter that the
            %  prtAction will be evaluated at.
            %
            %  [OPTIMACT, PERF]  = OPTIMIZE(...) returns a vector of
            %  performance values that correspond to each element of
            %  PARAMVALS.
            %
            % Example:
            %
            %  ds = prtDataGenBimodal;  % Load a data set
            %  knn = prtClassKnn;       % Create a classifier
            %  kVec = 3:5:50;          % Create a vector of parameters to
            %                           % optimze over
            %
            % % Optimize over the range of k values, using the area under
            % % the receiver operating curve as the evaluation metric.
            % % Validation is performed by a k-folds cross validation with
            % % 10 folds as specified by the call to prtEvalAuc.
            %           
            % [knnOptimize, percentCorrects] = knn.optimize(ds, @(class,ds)prtEvalAuc(class,ds,10), 'k',kVec);
            % plot(kVec, percentCorrects)

            
            %   objFn = @(act,ds)prtEvalAuc(act,ds,3);
            %   [optimizedAction,performance] = optimize(Obj,DataSet,objFn,parameterName,parameterValues)
            
            if isnumeric(parameterValues) || islogical(parameterValues)
                parameterValues = num2cell(parameterValues);
            end
            performance = nan(length(parameterValues),1);
            
            if Obj.showProgressBar
                h = prtUtilProgressBar(0,sprintf('Optimizing %s.%s',class(Obj),parameterName),'autoClose',true);
            end
            
            for i = 1:length(performance)
                Obj.(parameterName) = parameterValues{i};
                performance(i) = objFn(Obj,DataSet);
                
                if Obj.showProgressBar
                    h.update(i/length(performance));
                end
            end
            if Obj.showProgressBar
                % Force close
                h.update(1);
            end
            
            [maxPerformance,maxPerformanceInd] = max(performance); %#ok<ASGLU>
            Obj.(parameterName) = parameterValues{maxPerformanceInd};
            optimizedAction = train(Obj,DataSet);
            
        end
    end
    methods(Hidden = true)
        function [outputObj, creationString] = gui(obj)
            % GUI Graphical method to set properties of prtAction
            %
            % [outputObj, creationString] = gui(obj)
            % 
            % outputObj - Object with specified parameters
            % creationString - code to recreate gui actions
            %
            % Not all properties are currently able to be set using gui
            %
            % Example:
            %   knn = prtClassKnn;
            %   knn.gui
            
            [outputObj, creationString] = prtUtilObjectGuiSimple(obj);
        end
    end
    
    methods (Hidden = true)
        function [out,varargout] = rt(Obj,in)
            % Train and then run an action on a dataset
            switch nargout
                case 1
                    out = run(train(Obj,in),in);
                otherwise
                    varargout = cell(1,nargout-1);
                    [out,varargout{:}] = run(train(Obj,in),in);
            end
        end
        
        function Obj = setVerboseStorage(Obj,val)
            assert(numel(val)==1 && (islogical(val) || (isnumeric(val) && (val==0 || val==1))),'prtAction:invalidVerboseStorage','verboseStorage must be a logical');
            Obj.verboseStorageInternal = logical(val);
        end
        
        function Obj = setVerboseFeatureNames(Obj,val)
            assert(numel(val)==1 && (islogical(val) || (isnumeric(val) && (val==0 || val==1))),'prtAction:invalidVerboseFeatureNames','verboseFeatureNames must be a logical');
            Obj.verboseFeatureNamesInternal = logical(val);
        end
        
        function Obj = setShowProgressBar(Obj,val)
            if ~prtUtilIsLogicalScalar(val);
                error('prt:prtAction','showProgressBar must be a scalar logical.');
            end
            Obj.showProgressBarInternal = val;
        end
        
        function varargout = export(obj,exportType,varargin)
            % export(obj,fileSpec);
            % S = export(obj,'struct');
            if nargin < 2
                error('prt:prtAction:export','exportType must be specified');
            end
                
            switch lower(exportType)
                case {'struct','structure'}
                    varargout{1} = toStructure(obj);
                    
                case {'yaml'}
                    if nargin < 3
                        error('prt:prtAction:exportYaml','fileName must be specified to export YAML');
                    end
                    file = varargin{1};
                    
                    objStruct = toStructure(obj);
                    
                    prtExternal.yaml.WriteYaml(file,objStruct);
                    
                    varargout = {};
                    
                case {'eml'}
                    if length(varargin) < 2
                        structureName = cat(2,class(obj),'Structure');
                    else
                        structureName = varargin{2};
                    end
                    if length(varargin) < 1
                        file = sprintf('%sCreate',structureName);
                    else
                        file = varargin{1};
                    end
                    
                    [filePath, file, fileExt] = fileparts(file); %#ok<NASGU>
                    
                    if ~isvarname(file)
                        error('prt:prtAction:export','When using EML export, file must be a string that is a valid MATLAB function name (optionally it can also contain a path.)');
                    end
                    
                    fileWithMExt = cat(2,file,'.m');
                    
                    exportStruct = obj.toStructure();

                    exportString = prtUtilStructToStr(exportStruct,structureName);
                    
                    % Add a function declaration name to the beginning
                    exportString = cat(1, {sprintf('function [%s] = %s()',structureName,file)}, {''}, exportString);
                    
                    fid = fopen(fullfile(filePath,fileWithMExt),'w');
                    fprintf(fid,'%s\n',exportString{:});
                    fclose(fid);
    
                otherwise
                    error('prt:prtAction:export','Invalid file formal specified');
            end
        end
        
        function S = toStructure(obj)
            % toStructure(obj)
            % This default prtAction method adds all properties defined in
            % the class of obj into the structure, that are:
            %   GetAccess: public
            %   Hidden: false
            % other prtActions (that are properties, contained in cells,
            %   or fields of structures) are also converted to structures.
            
            MetaInfo = meta.class.fromName(class(obj));
            
            propNames = {};
            for iProperty = 1:length(MetaInfo.Properties)
                if isequal(MetaInfo.Properties{iProperty}.DefiningClass,MetaInfo) && strcmpi(MetaInfo.Properties{iProperty}.GetAccess,'public') && ~MetaInfo.Properties{iProperty}.Hidden
                    propNames{end+1} = MetaInfo.Properties{iProperty}.Name; %#ok<AGROW>
                end
            end
            
            S.class = 'prtAction';
            S.prtActionType = class(obj);
            S.isSupervised = obj.isSupervised;
            S.dataSetSummary = obj.dataSetSummary;
            for iProp = 1:length(propNames)
                cProp = obj.(propNames{iProp});
                for icProp = 1:length(cProp) % Allow for arrays of objects
                    cOut = prtUtilFintPrtActionsAndConvertToStructures(cProp(icProp));
                    if icProp == 1
                        cVal = repmat(cOut,size(cProp));
                    else
                        cVal(icProp) = cOut;
                    end
                end
                S.(propNames{iProp}) = cVal;
            end
            S.userData = obj.userData;
        end
        
        function xOut = runFast(Obj, xIn, ds)         
            % RUNFAST  Run a prtAction object on a matrix.
            %   The specific action must have overloaded the runActionFast
            %   method.
            
            if ~Obj.isTrained
                error('prtAction:runFast:ActionNotTrained','Attempt to run a prtAction of type %s that was not trained',class(Obj));
            end
                
            if isempty(xIn)
                xOut = xIn;
                return
            end
            
            if nargin > 2
                xIn = preRunProcessingFast(Obj, xIn, ds);
                xOut = runActionFast(Obj, xIn, ds);
                xOut = postRunProcessingFast(Obj, xIn, xOut, ds);
            else
                xIn = preRunProcessingFast(Obj, xIn);
                xOut = runActionFast(Obj, xIn);
                xOut = postRunProcessingFast(Obj, xIn, xOut);
            end
        end
    end
    
    methods (Hidden, Static)
        function val = getVerboseStorage()
            val = prtOptionsGet('prtOptionsComputation','verboseStorage');
        end
        function val = getShowProgressBar()
            val = prtOptionsGet('prtOptionsComputation','showProgressBar');
        end        
    end
end