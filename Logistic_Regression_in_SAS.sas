/*
Logistic Regression in SAS
Logistic Regression is one of the most used technique in the analytics world, and for every propensity modelling, risk modelling etc., this is one of the most important as well as well-accepted steps. The main difference between the logistic regression and the linear regression is that the Dependent variable (or the Y variable) is a continuous variable in linear regression, but is a dichotomous or categorical variable in a logistic regression.

While validating a logistic model, we try to see some of the statistics like Concordance and Discordance, Sensitivity and Specificity, Precision and Recall, Area under the ROC curve. One of the most important aspect is the Precision and Recall. The problem faced by the analysts is how to balance between the two. If we try to increase one of them, the other reduces. A measure that tries to balance both of them is called as F-ratio or F-measure, which is calculated as the Harmonic Mean of precision and recall. However, based on the project requirement, one can calculate an adjusted F-ratio, which calculates the harmonic mean of precision and recall after giving a higher weight on one of them.

The following SAS code is an attempt to simplify the SAS code, and it has been automated for future use. A detailed documentation about the Logistic regression output is given here. The various outputs like parameter estimate, concordance-discordance, classification table etc. will be stored as tables. The html output contains the regular stuffs, along with the ROC curve for the training data as well as the ROC curve of the validation data. The score statement gives the classification table for the validation data, and also scores the validation data which can be used for calculating other validation statistics like Kolmogorov-Smirnov etc.
*/


%let train = TRAINING_DATA;           /* TRAINING DATA */
%let validate = VALIDATION_DATA       /* VALIDATION DATA    */
%let targetvar = Y;                   /* DEPENDENT BINARY VARIABLE */
%let varlist = X1 X2 X3 X4;           /* INDEPENDENT VARIABLES   */
%let binvarlist = X2 X3;              /* LIST OF BINARY INDEPENDENT VARIABLES */


ods graphics on;
ods html;
ods output
parameterestimates = TBL_ParamEst     /* PARAMETER ESTIMATES     */
OddsRatios =TBL_OddRatio              /* ODD RATIOS              */
LackFitPartition = TBL_HLpartition    /* HOSMER-LEMESHOW PARTITIONS    */
LackFitChiSq = TBL_HLstatistic        /* HOSMER-LEMESHOW STATISTIC     */
Association = TBL_Association         /* CONCORDANCE DISCORDANCE ETC   */
FitStatistics = TBL_FitStatistic      /* AIC, -2LOG, SC, ETC           */
GlobalTests = TBL_GlobalTests         /* WALD, LOGLIKELIHOOD, ETC      */
Classification = TBL_Classification   /* CLASSIFICATION TABLE    */
;

proc logistic data= &train. descending outest=LogisticTest outmodel=LogisticModel plots(only)=(roc) PLOTS(MAXPOINTS=NONE);
class      &binvarlist.    /param=reference ref=first;
model &targetvar.(event='1')=
&varlist.
/lackfit ctable selection=stepwise slentry= .05 sls=.05 ridging=none;
score data=&train. out= Scored_Training_Data outroc= ROC_TABLE_TRAINING_Data;
score data=&validate. out= Scored_Validation_Data outroc= ROC_TABLE_VALIDATION_DATA;
run;

ods html close;
ods graphics off;
ods output close;

proc sort data= TBL_ParamEst;
by descending waldchisq;
run;

/* The above code sorts the significant estimates based on the Wald Chi Square */

data TBL_Classification (drop = B);
set TBL_classification;
precision = correctevents/(correctevents + Incorrectevents);
recall = correctevents/(correctevents + Incorrectnonevents);
F_stat1 = harmean(precision,recall);
B = 2;
F_stat2 = (((1 + B*B) * (precision * recall))/((B*B*precision) + recall));
run;

proc sort data= LOG_Classification;
by descending F_Stat;
run;

/* The above code uses the Classification Table and calculates the precision, recall and sorts the table based on the F ratio*/
/* It also calculates the adjusted F ratio where higher weightage is given on Recall */
/* The probability value where the F ratio (or adjusted F ratio) is maximum should be treated as the threshold probability during validation */

data ROC_TABLE_TRAINING_Data(drop = B);
set ROC_TABLE_TRAINING_Data;
precision = _POS_/(_POS_ + _FALPOS_);
recall = _POS_/(_POS_ + _FALNEG_);
F_stat = harmean(precision,recall);
B = 2;
F_stat2 = (((1 + B*B) * (precision * recall))/((B*B*precision) + recall));
run;

proc sort data= ROC_TABLE_TRAINING_Data;
by descending F_Stat;
run;

/* This code should give the same precision and recall value as the above table. Instead of using the classification table, here the ROC table made on the training data is used to calculate precision and recall     */

data prob_threshold;
set ROC_TABLE_TRAINING_Data;
if _n_ = 1 then output;
run;

data _null_;
set prob_threshold;
call symput(“prob_thresh”,compress(_prob_);
run;

/* Saving the threshold value of probability for demarcating between 1 and 0 */

data ROC_TABLE_VALIDATION_DATA (drop = B);
set ROC_TABLE_VALIDATION_DATA;
precision = _POS_/(_POS_ + _FALPOS_);
recall = _POS_/(_POS_ + _FALNEG_);
F_stat = harmean(precision,recall);
B = 2;
F_stat2 = (((1 + B*B) * (precision * recall))/((B*B*precision) + recall));
run;

data Validation_Check;
set ROC_TABLE_VALIDATION_DATA;
if _prob_ ge &prob_thresh. then output;     /* Use the Probability_Threshold from the step above */
run;

proc sort data= Validation_Check;
by _prob_;
run;
/* This part of the code calculates the precision and recall in the validation data at the pre-fixed level of probability threshold value. */
