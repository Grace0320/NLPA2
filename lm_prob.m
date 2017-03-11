function logProb = lm_prob(sentence, LM, type, delta, vocabSize)
%
%  lm_prob
% 
%  This function computes the LOG probability of a sentence, given a 
%  language model and whether or not to apply add-delta smoothing
%
%  INPUTS:
%
%       sentence  : (string) The sentence whose probability we wish
%                            to compute
%       LM        : (variable) the LM structure (not the filename)
%       type      : (string) either '' (default) or 'smooth' for add-delta smoothing
%       delta     : (float) smoothing parameter where 0<delta<=1 
%       vocabSize : (integer) the number of words in the vocabulary
%
% Template (c) 2011 Frank Rudzicz

  logProb = -Inf;
  global CSC401_A2_DEFNS

  % some rudimentary parameter checking
  if (nargin < 2)
    disp( 'lm_prob takes at least 2 parameters');
    return;
  elseif nargin == 2
    type = '';
    delta = 0;
    vocabSize = length(fieldnames(LM.uni));
  end
  if (isempty(type))
    delta = 0;
    vocabSize = length(fieldnames(LM.uni));
  elseif strcmp(type, 'smooth')
    if (nargin < 5)  
      disp( 'lm_prob: if you specify smoothing, you need all 5 parameters');
      return;
    end
    if (delta <= 0) or (delta > 1.0)
      disp( 'lm_prob: you must specify 0 < delta <= 1.0');
      return;
    end
  else
    disp( 'type must be either '''' or ''smooth''' );
    return;
  end

  words = strsplit(' ', sentence);

  % TODO: the student implements the following
  
  %get corpus size
  N = 0;
  uni = fieldnames(LM.uni);
  for i = 1:length(uni)
        N = N + LM.uni.(char(uni{i})); 
  end
  %take out SENTSTART since we don't use its uni count
  SS = LM.uni.( CSC401_A2_DEFNS.SENTSTART );
  N = N - SS;
 
  type_is_smooth = strcmp(type, 'smooth');
  sum = 0;

  %calc probability.
  %for each word in sentence
  for i = 2:length(words) %skip sentstart
      w_i = char(words(i));
      w_imin1 = char(words(i-1));
      
      if type_is_smooth
         biCount = 0;
         uniCount = 0;
         if isfield(LM.uni, w_i) %check for unigram
            uniCount =  LM.uni.(w_i);
         end
         if isfield(LM.bi, w_imin1) %check for bigram
            if isfield(LM.bi.(w_imin1), w_i)
                biCount = LM.bi.(w_imin1).(w_i);
            end
         end
         sum = sum + log2((biCount + delta)*(N + (delta*vocabSize))/((uniCount + delta*vocabSize)*(uniCount + delta)));
      else %MLE
        %(bigramcount/unicount)/(unicount/corpus size) simplifies to bigram_count*N/unicount^2  
        if isfield(LM.uni, w_i)
            if isfield(LM.bi, w_imin1)
                if isfield(LM.bi.(w_imin1), w_i)       
                    sum = sum + log2(LM.bi.(w_imin1).(w_i)*N/(LM.uni.(w_1)^2));
                else
                    sum = -Inf;
                    break;
                end
            else
                sum = -Inf;
                break;
            end
        else
            sum = -Inf;
            break;
        end
      end
  end
  logProb = sum;
  % TODO: once upon a time there was a curmudgeonly orangutan named Jub-Jub.
return