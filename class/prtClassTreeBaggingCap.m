classdef prtClassTreeBaggingCap < prtClass
    % prtClassTreeBaggingCap  Tree bagging central axis projection classifier
    %
    %    CLASSIFIER = prtClassTreeBaggingCap Tree bagging central axis
    %    projection classifier.  This classifier is based on the "Random
    %    Forest" classifier described in 
    %
    %    Breiman, Leo (2001). "Random Forests". Machine Learning 45
    %
    %    CLASSIFIER = prtClassTreeBaggingCap(PROPERTY1, VALUE1, ...) constructs a
    %    prtClassTreeBaggingCap object CLASSIFIER with properties as specified by
    %    PROPERTY/VALUE pairs.
    %
    %    A prtClassTreeBaggingCap object inherits all properties from the abstract class
    %    prtClass. In addition is has the following properties:
    %
    %    nTrees                       - The number of trees
    %    nFeatures                    - The number of features
    %    featureSelectWithReplacement - Flag indicating whether or not to
    %                                   do feature selection with 
    %                                   replacement
    %    bootStrapDataAtRoots         - Flag indicating whether or not
    %                                   to bootstrap at roots
    %    useMex                       - flag indicating wheter or not to
    %                                   use the Mex file for speedup.
    %
    %  For more information on random tree classifiers, see:
    %   http://en.wikipedia.org/wiki/Random_forest
    %   http://www.stat.berkeley.edu/~breiman/RandomForests/cc_home.htm
    %
    %    A prtClassTreeBaggingCap  object inherits the TRAIN, RUN, 
    %    CROSSVALIDATE and KFOLDS methods from prtAction. It also inherits 
    %    the PLOT method from prtClass.
    %
    %    Example:
    %
    %     TestDataSet = prtDataGenUniModal;      % Create some test and
    %     TrainingDataSet = prtDataGenUniModal;  % training data
    %     classifier = classifier.train(TrainingDataSet);    % Train
    %     classified = run(classifier, TestDataSet);         % Test
    %     classifier.plot;
    %
    %    See also prtClass, prtClassLogisticDiscriminant, prtClassBagging,
    %    prtClassMap, prtClassCap, prtClassBinaryToMaryOneVsAll, prtClassDlrt,
    %    prtClassPlsda, prtClassFld, prtClassRvm, prtClassGlrt,  prtClass
    
    
    properties (SetAccess=private)
    
        name = 'Tree Bagging Central Axis Projection'  %Tree Bagging Central Axis Projection
        nameAbbreviation = 'TBCAP'  % TBCAP
       
        isNativeMary = true;    % False
        
        % Array of Central Axis Projection Trees
        root = [];
    end
    
    properties
        
        nTrees = 100; % The number of trees
        
        nFeatures = 2;  % The number of features at each node
        
        featureSelectWithReplacement = true;  % Flag indicating whether or not to do feature selection with replacement
        
        bootStrapDataAtRoots = true; % Flag indicating whether or not to boostrap at roots
        
        useMex = true;     % Flag indicating whether or not to use the Mex file
    end
    properties (Hidden = true)
        eml = true;
        Memory = struct('nAppend',1000); % Used in prtUtilRecursiveCapTree
    end
    
    methods
        function Obj = set.nTrees(Obj,val)
            assert(isscalar(val) && isnumeric(val) && val > 0 && val == round(val),'prt:prtClassTreeBaggingCap:nTrees','nTrees must be a scalar integer greater than 0, but value provided is %s',mat2str(val));
            Obj.nTrees = val;
        end
        function Obj = set.nFeatures(Obj,val)
            assert(isscalar(val) && isnumeric(val) && val > 0 && val == round(val),'prt:prtClassTreeBaggingCap:nFeatures','nFeatures must be a scalar integer greater than 0, but value provided is %s',mat2str(val));
            Obj.nFeatures = val;
        end
        function Obj = set.featureSelectWithReplacement(Obj,val)
            assert(isscalar(val) && islogical(val),'prt:prtClassTreeBaggingCap:featureSelectWithReplacement','featureSelectWithReplacement must be a logical value, but value provided is a %s',class(val));
            Obj.featureSelectWithReplacement = val;
        end
        function Obj = set.bootStrapDataAtRoots(Obj,val)
            assert(isscalar(val) && islogical(val),'prt:prtClassTreeBaggingCap:bootStrapDataAtRoots','bootStrapDataAtRoots must be a logical value, but value provided is a %s',class(val));
            Obj.bootStrapDataAtRoots = val;
        end
        function Obj = set.useMex(Obj,val)
            assert(isscalar(val) && islogical(val),'prt:prtClassTreeBaggingCap:useMex','useMex must be a logical value, but value provided is a %s',class(val));
            Obj.useMex = val;
        end
        
        function Obj = prtClassTreeBaggingCap(varargin)
            Obj = prtUtilAssignStringValuePairs(Obj,varargin{:});
        end
    end
    
    methods (Access=protected, Hidden = true)
        function Obj = trainAction(Obj,DataSet)
            
            for i = 1:Obj.nTrees
                treeRoot(i) = generateCAPTree(Obj,DataSet);  %#ok<AGROW>
                
                if i == 1
                    treeRoot = repmat(treeRoot,Obj.nTrees,1);
                end
                
                len = length(find(~isnan(treeRoot(i).W(1,:))));
                treeRoot(i).W = treeRoot(i).W(:,1:len);   %#ok<AGROW>
                treeRoot(i).threshold = treeRoot(i).threshold(:,1:len);  %#ok<AGROW>
                treeRoot(i).featureIndices = treeRoot(i).featureIndices(:,1:len);  %#ok<AGROW>
                treeRoot(i).treeIndices = treeRoot(i).treeIndices(:,1:len);  %#ok<AGROW>
                treeRoot(i).terminalVote = treeRoot(i).terminalVote(:,1:len);  %#ok<AGROW>
            end
            
            if Obj.eml
                wSizes = cellfun(@(x)size(x),{treeRoot.W},'uniformOutput',false);
                wSizes = cat(1,wSizes{:});
                maxWSize = max(wSizes,[],1);
                maxWSize = maxWSize(2);
                for i = 1:length(treeRoot)
                    f = fieldnames(treeRoot);
                    for j = 1:length(f)
                        treeRoot(i).(f{j}) = cat(2,treeRoot(i).(f{j}),nan(size(treeRoot(i).(f{j}),1),maxWSize-size(treeRoot(i).(f{j}),2))); %#ok<AGROW>
                    end
                end
            end
            
            Obj.root = treeRoot;
            
        end
        
        function tree = generateCAPTree(Obj,DataSet)
            %tree = generateCAPTree(Obj,DataSet)
            
            tree.W = [];
            tree.threshold = [];
            tree.featureIndices = [];
            tree.treeIndices = [];
            tree.terminalVote = [];
            tree.maxReservedLen = 0;
            
            tree.father = 0;
            if Obj.bootStrapDataAtRoots
                DataSet = DataSet.bootstrapByClass();
            end
            
            tree = prtUtilRecursiveCapTree(Obj, tree, DataSet.getObservations, logical(DataSet.getTargetsAsBinaryMatrix), 1);
        end
        
        function ClassifierResults = runAction(Obj,PrtDataSet)
            
            Yout = zeros(PrtDataSet.nObservations,Obj.dataSetSummary.nClasses);
            x = PrtDataSet.getObservations;
            theRoot = Obj.root;
            
            if Obj.useMex
                for iTree = 1:Obj.nTrees
                    Yout = Yout + prtUtilEvalCapTreeMex(theRoot(iTree), x, Obj.dataSetSummary.nClasses);
                end
            else
                for jSample = 1:PrtDataSet.nObservations
                    for iTree = 1:Obj.nTrees
                        Yout(jSample,:) = Yout(jSample,:) + prtUtilEvalCAPtree(theRoot(iTree),x(jSample,:),Obj.dataSetSummary.nClasses);
                    end
                end
            end
            
            ClassifierResults = prtDataSetClass(Yout/length(theRoot));
        end
    end
end
