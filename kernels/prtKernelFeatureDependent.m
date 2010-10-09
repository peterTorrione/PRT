classdef prtKernelFeatureDependent < prtKernel
    % prtKernelFeatureDependent provides a super class for kernels that are 
    % functions of the individual feature dimensions of the data set
    %
    % Kernels that sub-class from prtKernelBinary must implement two
    % functions:
    %
    %         kernel = trainKernel(obj,x);
    %         yOut = evalKernel(obj,x);  
    %
    
    methods
        
        function nDims = getExpectedNumKernels(obj,ds)
            nDims = ds.nFeatures;
        end
        
        function gramm = evaluateGramm(obj,ds1,ds2)
            
            if ~isa(ds1,'prtDataSetBase')
                ds1 = prtDataSetStandard(ds1);
            end
            if ~isa(ds2,'prtDataSetBase')
                ds2 = prtDataSetStandard(ds2);
            end
            
            %Note, this can be very slow for some kernels; we can speed
            %this up by forcing kernels to implement something like
            %"evaluateGramm(obj,ds1,ds2)" that they can write to be fast,
            %but for now we haven't done that.  Actually, clever kernels
            %can just overload this function to make it fast.  
            kernelArray = toTrainedKernelArray(obj,ds1,true(ds1.nFeatures,1));
            gramm = nan(ds2.nObservations,length(kernelArray));
            for i = 1:length(kernelArray);
                gramm(:,i) = evalKernel(kernelArray(i),ds2.getObservations);
            end
        end
        
        function trainedKernelArray = toTrainedKernelArray(obj,dsTrain,logical)
            valid = find(logical);
            trainedKernelArray = repmat(obj,length(valid),1);
            for j = 1:length(valid)
                featureIndex = valid(j);
                trainedKernelArray(j) = obj.trainKernel(featureIndex);
            end
        end
        
        function yOut = run(obj,ds2)
            if isa(ds2,'prtDataSetBase')
                data = ds2.getObservations;
            else
                data = ds2;
            end
            %yOut = prtKernelRbf.rbfEvalKernel(obj.kernelCenter,data,obj.sigma);
            yOut = evalKernel(obj,data);
        end
        
    end
    methods (Abstract)
        yOut = evalKernel(obj,x);
        kernel = trainKernel(obj,x);
    end
end