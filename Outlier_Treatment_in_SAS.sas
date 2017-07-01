/*
A very important step for any type of analysis is the outlier treatment. An outlier is an observation which lies at a distant from the majority of the observations, may be because of some exceptional cases, or due to issues in data storage and management. For a regression model to be robust, it is essential to have a sanity check of the data, to remove the presence of any such anomaly.
A very basic way to remove the ouliers are to delete such extreme observations completely from the data. Another way to handle it is called capping and flooring, where the upper extreme values and the lower extreme values are replaced by a pre-determined threshold. Another common way to do this is to implement both of these together.
When the number of variables are huge, it might not be possible to check the distribution of every variable one by one, instead a rule can be created to treat the outliers. Let us create the following rule:

---For all variables, we will delete the values which are above the 99 percentile or below the 1 percentile. After that, we would cap all the values that lie above 95 percentile to the 95th percentile value, and floor all the values that are less than 5 percentile to the 5th percentile value.

The following SAS code has been automated to implement the above rule and create a outlier-treated dataset. The rule can be modified as per scenario, or as per the analysts' discretion.
*/

libname dataloc "C:/Desktop/Data";  /* MODEL DATASET LOCATION  */
%let inset=Base_Data;               /* MODEL DATASET NAME      */
%let libout=C:/Desktop/Output;
libname outlib "&libout.";          /* OUTPUT LOCATION         */
%let outset=Clean_Data;             /* OUTPUT DATASET          */
%let upper_del_threshold = 99;      /* UPPER LIMIT TO DELETE   */
%let lower_del_threshold = 1;       /* LOWER LIMIT TO DELETE   */
%let upper_cap_threshold = 95;      /* UPPER LIMIT TO CAP      */
%let lower_floor_threshold = 5;     /* LOWER LIMIT TO FLOOR    */
%let varlist = X1 X2 X3;            /* LIST OF VARIABLES       */

data inset1;
set dataloc.&inset.;
run;

proc means data=inset1 StackODSOutput P&upper_del_threshold. P&lower_del_threshold. P&upper_cap_threshold. P&lower_floor_threshold.;
var &varlist;
ods output summary=LongPctls;
run;

data LongPctls;
set LongPctls;
run;

data _null_;
set LongPctls;
call symput(compress("var"||_n_),compress(variable));
call symput(compress("up_del"||_n_),compress(P&upper_del_threshold.));
call symput(compress("low_del"||_n_),compress(P&lower_del_threshold.));
call symput(compress("up_ext"||_n_),compress(P&upper_cap_threshold.));
call symput(compress("low_ext"||_n_),compress(P&lower_floor_threshold.));
call symput(compress("n"),compress(_n_));
run;

%macro dataset;
data outset1;
set inset1;
%do i = 1 %to &n.;

if &&var&i..  gt &&up_del&i.. then delete;
else if &&var&i..  lt &&low_del&i.. then delete;

else if &&var&i..  gt &&up_ext&i.. then &&var&i.. = &&up_ext&i..;
else if &&var&i..  lt &&low_ext&i.. then &&var&i.. = &&low_ext&i..;

%end;
run;
%mend;
%dataset;

data outlib.&outset.;
set outset1;
run;

/*A quick check in the univariate analysis to validate the outlier treatment*/

%macro chck;
%do i = 1 %to &n.;
proc univariate data=inset1;
var &&var&i..;
run;

proc univariate data=outset1;
var &&var&i..;
run;

%end;
%mend;
%chck;
