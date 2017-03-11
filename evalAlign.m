%
% evalAlign
%
%  This is simply the script (not the function) that you use to perform your evaluations in 
%  Task 5. 

% some of your definitions
trainDir     = 'data/Hansard/Training/';
testDir      = 'data/Hansard/Testing/';


% Train your language models. This is task 2 which makes use of task 1
LME = lm_train( trainDir, 'e', fn_LME ); %load('traininge3.mat'); 
LMF = lm_train( trainDir, 'f', fn_LMF ); %load('trainingf3.mat'); % 
vocabSize = length(fields(LME.LM.uni));

% Train your alignment model of French, given English 
AMFE_30 =  align_ibm1(trainDir, 30000, 5, 'align30k5Iter.mat'); %load('align30k5Iter.mat');
AMFE_15 = align_ibm1(trainDir, 15000, 5, 'align15k5Iter.mat');%load('align15k5Iter.mat');
AMFE_10 = align_ibm1(trainDir, 10000, 5, 'align10k5Iter.mat');%load('align10k5Iter.mat');%align_ibm1(trainDir, 10000, 5, 'align10k5Iter.mat');
AMFE_1 = align_ibm1(trainDir, 1000, 5, 'align1k5Iter.mat');%load('align1k5Iter.mat');

AMFE_arr = [AMFE_30, AMFE_15, AMFE_10, AMFE_1];

% TODO: a bit more work to grab the English and French sentences. 
%       You can probably reuse your previous code for this  \
googleLines = textread([testDir, filesep, 'Task5.google.e'], '%s','delimiter','\n');
engLines = textread([testDir, filesep, 'Task5.e'], '%s','delimiter','\n');
freLines = textread([testDir, filesep, 'Task5.f'], '%s','delimiter','\n');

alignModelStruct = struct('translation', '', 'n1', 0, 'n2', 0, 'n3', 0);

numSents = length(freLines);
for i = 1:numSents
    
    processFre =  preprocess(freLines{i}, 'f');
    googleSentence = preprocess(googleLines{i}, 'e');
    engSentence = preprocess(engLines{i}, 'e');
    
    sentArr(i) = struct('fre', processFre, 'goog', googleSentence, 'eng', engSentence, 'thirty', alignModelStruct, 'fifteen', alignModelStruct, 'ten', alignModelStruct, 'one', alignModelStruct); 
    
    for j = 1:4 %for each alignment
        AM = AMFE_arr(j).AM;
 
        % Decode the test sentence 'fre'
        engTranslation = decode2(processFre, LME.LM, AM, '', 1, vocabSize );
        
        translatedWords = strsplit(' ', engTranslation );
        
        % TODO: perform some analysis
        % calc BLEU score
        nUnigram = length(translatedWords);
        cUnigram = struct();
        cUnigramTot = 0;
        nBigram = nUnigram - 1;
        cBigram = struct();
        cBigramTot = 0;
        nTrigram = nBigram - 1;
        cTrigram = struct();
        cTrigramTot = 0;

        for k = 1:nUnigram
            kWord = translatedWords{k};
            if ~isempty(regexp(googleSentence, kWord)) || ~isempty(regexp(engSentence, kWord))
                cUnigramTot = cUnigramTot + 1;
                if isfield(cUnigram, kWord)
                    if  cUnigram.(kWord) < 2
                        cUnigram.(kWord)= cUnigram.(kWord) + 1;
                    end
                else
                    [cUnigram(:).(kWord)] = deal(1);
                end
            end
            if k < nUnigram
                k1Word = translatedWords{k+1};
                bi = sprintf('%s %s',kWord, k1Word);
                biField = sprintf('%s%s',kWord, k1Word);
                if ~isempty(regexp(googleSentence, bi)) || ~isempty(regexp(engSentence, bi))
                    cBigramTot = cBigramTot + 1;
                    if isfield(cBigram, biField)
                        if cBigram.(biField) < 2
                            cBigram.(biField)= cBigram.(biField) + 1;
                        end
                    else
                        [cBigram(:).(biField)] = deal(1);
                    end
                end
            end
            if k < nUnigram - 1
                
             k2Word = translatedWords{k+2};
               tri = sprintf('%s %s %s', kWord, k1Word, k2Word);
               triField = sprintf('%s%s%s', kWord,k1Word, k2Word);
               if ~isempty(regexp(googleSentence, tri)) || ~isempty(regexp(engSentence, tri))
                     cTrigramTot = cTrigramTot + 1;
                     if isfield(cTrigram, triField) 
                         if cTrigram.(triField) < 2
                            cTrigram.(triField)= cTrigram.(triField) + 1;
                            
                         end
                    else
                        [cTrigram(:).(triField)] = deal(1);
                    end
               end
            end
        end
                
        pUnigram = cUnigramTot/nUnigram;
        pBigram = cBigramTot/nBigram;
        pTrigram = cTrigramTot/nTrigram;

        nGoog = length(strsplit(' ', googleSentence));
        nEng = length(strsplit(' ', engSentence));
        googdiff = abs(nGoog - nUnigram);
        engdiff = abs(nEng - nUnigram);
        if googdiff < engdiff
            brev = nUnigram/nGoog;
        else
            brev = nUnigram/nEng;
        end

        BP = 0;
        if brev < 1
            BP = 1;
        else
            BP = exp(1-brev);
        end

        BLEU_1 = BP*(pUnigram);
        BLEU_2 = BP*(pUnigram*pBigram)^(1/2);
        BLEU_3 = BP*(pUnigram*pBigram*pTrigram)^(1/3);
        
        if j == 1
           sentArr(i).thirty.translation = engTranslation;
           sentArr(i).thirty.n1 = BLEU_1;
           sentArr(i).thirty.n2 = BLEU_2;
           sentArr(i).thirty.n3 = BLEU_3;
        elseif j == 2
            sentArr(i).fifteen.translation = engTranslation;
           sentArr(i).fifteen.n1 = BLEU_1;
           sentArr(i).fifteen.n2 = BLEU_2;
           sentArr(i).fifteen.n3 = BLEU_3;
        elseif j == 3
            sentArr(i).ten.translation = engTranslation;
           sentArr(i).ten.n1 = BLEU_1;
           sentArr(i).ten.n2 = BLEU_2;
           sentArr(i).ten.n3 = BLEU_3;
        else
            sentArr(i).one.translation = engTranslation;
           sentArr(i).one.n1 = BLEU_1;
           sentArr(i).one.n2 = BLEU_2;
           sentArr(i).one.n3 = BLEU_3;
        end
            
    end
end
 

[status, result] = unix('')