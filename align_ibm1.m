function AM = align_ibm1(trainDir, numSentences, maxIter, fn_AM)
%
%  align_ibm1
% 
%  This function implements the training of the IBM-1 word alignment algorithm. 
%  We assume that we are implementing P(foreign|english)
%
%  INPUTS:
%
%       dataDir      : (directory name) The top-level directory containing 
%                                       data from which to train or decode
%                                       e.g., '/u/cs401/A2_SMT/data/Toy/'
%       numSentences : (integer) The maximum number of training sentences to
%                                consider. 
%       maxIter      : (integer) The maximum number of iterations of the EM 
%                                algorithm.
%       fn_AM        : (filename) the location to save the alignment model,
%                                 once trained.
%
%  OUTPUT:
%       AM           : (variable) a specialized alignment model structure
%
%
%  The file fn_AM must contain the data structure called 'AM', which is a 
%  structure of structures where AM.(english_word).(foreign_word) is the
%  computed expectation that foreign_word is produced by english_word
%
%       e.g., LM.house.maison = 0.5       % TODO
% 
% Template (c) 2011 Jackie C.K. Cheung and Frank Rudzicz
  
  global CSC401_A2_DEFNS
  
  AM = struct();
  
  % Read in the training data
  [eng, fre] = read_hansard(trainDir, numSentences);

  % Initialize AM uniformly 
  AM = initialize(eng, fre);

  % Iterate between E and M steps
  for iter=1:maxIter,
    AM = em_step(AM, eng, fre);
  end

  % Save the alignment model
  save( fn_AM, 'AM', '-mat'); 

  end





% --------------------------------------------------------------------------------
% 
%  Support functions
%
% --------------------------------------------------------------------------------

function [eng, fre] = read_hansard(mydir, numSentences)
%
% Read 'numSentences' parallel sentences from texts in the 'dir' directory.
%
% Important: Be sure to preprocess those texts!
%
% Remember that the i^th line in fubar.e corresponds to the i^th line in fubar.f
% You can decide what form variables 'eng' and 'fre' take, although it may be easiest
% if both 'eng' and 'fre' are cell-arrays of cell-arrays, where the i^th element of 
% 'eng', for example, is a cell-array of words that you can produce with
%
%         eng{i} = strsplit(' ', preprocess(english_sentence, 'e'));
%
  %eng = {};
  %fre = {};

  % TODO: your code goes here.
    eng = cell(1, numSentences);
    fre = cell(1, numSentences);
    DDe = dir( [ mydir, filesep, '*', 'e'] );
    DDf = dir( [ mydir, filesep, '*', 'f'] );
    sentencesRead = 0;
    for iFile=1:length(DDe)
        if sentencesRead >= numSentences 
            break;
        end
        linesE = textread([mydir, filesep, DDe(iFile).name], '%s','delimiter','\n');
        linesF = textread([mydir, filesep, DDf(iFile).name], '%s','delimiter','\n');
        numSentsForThisFile = min(numSentences - sentencesRead, length(linesE));
        
        for l=1:numSentsForThisFile
            eng{l} = strsplit(' ', preprocess(linesE{l}, 'e'));
            fre{l} = strsplit(' ', preprocess(linesF{l}, 'f'));
        end
        sentencesRead = sentencesRead + numSentsForThisFile;
    end
    eng = eng(~cellfun('isempty',eng));
    fre = fre(~cellfun('isempty',fre));
end


function AM = initialize(eng, fre)
%
% Initialize alignment model uniformly.
% Only set non-zero probabilities where word pairs appear in corresponding sentences.
%
    AM = struct(); % AM.(english_word).(foreign_word)
    [AM(:).('SENTSTART')] = struct('SENTSTART', 1);
    [AM(:).('SENTEND')] = struct('SENTEND', 1);
    % TODO: your code goes here
    numSents = length(eng);
    for i = 1:numSents
        numEWords = length(eng{i});
        for j = 1:numEWords
            eWord = char(eng{i}(j));
            if strcmp(eWord, 'SENTSTART') || strcmp(eWord, 'SENTEND')
                continue;
            end
            if ~isfield(AM, eWord)
                [AM(:).(eWord)] = struct();
            end
            
            numFwords = length(fre{i});
            for k = 1:numFwords
                fword = char(fre{i}(k));
                if strcmp(fword, 'SENTSTART') || strcmp(fword, 'SENTEND')
                    continue;
                end
                if ~isfield(AM.(eWord), fre{i}(k))
                    [AM.(eWord)(:).(fword)] = deal(1);
                end
            end
        end
    end
    
    fields = fieldnames(AM);
    for i = 1:numel(fields)
        freFields = fieldnames(AM.(fields{i}));
        uni_prob = 1/length(freFields);
        for j = 1:numel(freFields)
            AM.(fields{i}).(freFields{j}) = uni_prob;
        end
        
    end
end

function t = em_step(t, eng, fre)
% 
% One step in the EM algorithm.
%
  
  % TODO: your code goes here
  % possible alignments = le^lf
  % grid = numsentences x possible alignments
  
%   initialize P(f|e)
% for a number of iterations:
% set tcount(f, e) to 0 for all f, e
% set total(e) to 0 for all e
% for each sentence pair (F, E) in training corpus:
%   for each unique word f in F:
%       denom_c = 0
    %   for each unique word e in E:
    %       denom_c += P(f|e) * F.count(f)
    %   for each unique word e in E:
    %       tcount(f, e) += P(f|e) * F.count(f) * E.count(e) / denom_c
    %       total(e) += P(f|e) * F.count(f) * E.count(e) / denom_c
% for each e in domain(total(:)):
%   for each f in domain(tcount(:,e)):
%       P(f|e) = tcount(f, e) / total(e)

  numSents = length(eng);
  denom_c = 0;
  tcount = struct();
  totalE = struct();
  for i = 1:numSents
      fWords = fre{i}(cellfun(@(s)isempty(regexp(s,'SENT.*')),fre{i})); %get rid of START & END
      numF = length(fWords);
      for j = 1:numF  
          denom_c = 0;
          eWords = unique(eng{i}(cellfun(@(s)isempty(regexp(s,'SENT.*')),eng{i})));
          numE = length(eWords);
          fword = char(fWords{j});
          countF = sum(strcmp(fWords, fword),2);
          
          for k = 1:numE
              denom_c = denom_c + (t.(char(eWords{k})).(fword) * countF);
          end
          for k = 1:numE
              eword = char(eWords{k});
              pfe = t.(eword).(fword);
              countE = sum(strcmp(eWords,eword),2);
              %tcount
              tc = pfe * countF * countE/denom_c;
              if isfield(tcount, fword)
                  if isfield(tcount.(fword),eword) 
                      tcount.(fword).(eword) = tcount.(fword).(eword) + tc;
                  else
                      [tcount.(fword)(:).(eword)] = deal(tc);
                  end
              else
                  [tcount(:).(fword)] = struct(eword, tc);
              end
              
              %total 
              if isfield(totalE, eword)
                  totalE.(eword) = totalE.(eword) + tc;
              else
                  [totalE(:).(eword)] = deal(tc);
              end
          end
      end
      
      eFields = fieldnames(totalE);
      for l = 1:length(eFields)
          eword = char(eFields{l});
          fFields = fieldnames(tcount);
          for m = 1:length(fFields)
             fword = char(fFields{m});
             if isfield(tcount.(fword), eword) 
                 t.(eword).(fword) = tcount.(fword).(eword)/totalE.(eword);
             end
          end
      end
  end 
end


