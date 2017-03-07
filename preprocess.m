function outSentence = preprocess( inSentence, language )
%
%  preprocess
%
%  This function preprocesses the input text according to language-specific rules.
%  Specifically, we separate contractions according to the source language, convert
%  all tokens to lower-case, and separate end-of-sentence punctuation 
%
%  INPUTS:
%       inSentence     : (string) the original sentence to be processed 
%                                 (e.g., a line from the Hansard)
%       language       : (string) either 'e' (English) or 'f' (French) 
%                                 according to the language of inSentence
%
%  OUTPUT:
%       outSentence    : (string) the modified sentence
%
%  Template (c) 2011 Frank Rudzicz 

  global CSC401_A2_DEFNS
  
  % first, convert the input sentence to lower-case and add sentence marks 
  inSentence = [CSC401_A2_DEFNS.SENTSTART ' ' lower( inSentence ) ' ' CSC401_A2_DEFNS.SENTEND];

  % trim whitespaces down 
  inSentence = regexprep( inSentence, '\s+', ' '); 

  % initialize outSentence
  outSentence = inSentence;

  % perform language-agnostic changes
    outSentence = regexprep(outSentence, '(\w+)([.,!?;:*+=<>\(\)''"`\$\%\&\[\]/]|[(.*-.*)])', '$1 $2');
    outSentence = regexprep(outSentence, '([.,!?;:*+=<>\"()]|[\(.*-.*\)])(\w+)', '$1 $2');
    
  switch language
   case 'e'
    outSentence = preprocessEnglish(outSentence);
   case 'f'
    outSentence = preprocessFrench(outSentence);

  end

  % change unpleasant characters to codes that can be keys in dictionaries
  outSentence = convertSymbols( outSentence );
end

function [outSentence] = preprocessEnglish(inSentence)
    outSentence = inSentence;
    cliticRegex = loadEnglishClitics();
	outSentence = regexprep(outSentence, strcat('(\w+)', cliticRegex), '$1 $2', 'ignorecase');
	outSentence = regexprep(outSentence, strcat(cliticRegex, '(\w+)'), '$1 $2', 'ignorecase');
end

function [outSentence] = preprocessFrench(inSentence)
    outSentence = inSentence;
    %two letter consonant-e
    outSentence = regexprep(outSentence, '([cjlmnst]'')(\w+)', '$1 $2');
    %the d' words
    outSentence = regexprep(outSentence, '(d'')((?!(?:abord|ailleurs|accord|habitude)))', '$1 $2');
    %qu'
    outSentence = regexprep(outSentence, '(^|\S)(qu'')(\w+)', '$2 $3'); 
    %puisque, lorsque
    outSentence = regexprep(outSentence, '((puisqu'')|(lorsqu''))(on|il)', '$1 $2');
    
end

function [cliticRegex] = loadEnglishClitics()
    cliticsList = importdata('clitic.english');
    cliticJoin=[sprintf('%s|',cliticsList{1:end-1}),cliticsList{end}];
    cliticRegex = strcat('(', cliticJoin, ')');    
end

