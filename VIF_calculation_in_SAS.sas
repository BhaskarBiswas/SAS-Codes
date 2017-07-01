/*
In statistics (or econometrics), the variance inflation factor (VIF) calculates incidence and severity of multicollinearity among the independent variables in an ordinary least squares (OLS) regression analysis. In a linear regression analysis, it is important to run the VIF test to remove the multicollinearity among the independent variables. As a rule of thumb, the VIF value should not be more than 2 for better modeling. However, the final decision depends on the analyst’s discretion.

While running the linear regression analysis, one should not remove all the variables which have VIF more than the pre-decided threshold value (in this case, say 5). Instead, the analyst should remove the variable having the highest VIF value, and then re-calculate the VIF values. The process of calculation and removal of variable should continue till the highest VIF comes lower than the threshold level, only variable being removed at a time.
The process is not a difficult one, but might turn to be cumbersome process if the number of independent variables is very high.

The following SAS code is an automated code to solve the problem multiple iterations, and the final datasets gives the list of retained variables as well as removed variables. The SAS code uses proc reg as the only statistical procedure to calculate the VIF automatically. The iterations are used to remove one variable at a time.
*/

libname dataloc “/Desktop/Model";   /* MODEL DATASET LOCATION      */
%let inset=MODEL_DATA;        /* MODEL DATASET NAME    */
%let target= Y_VAR;           /* DEPENDENT VARIABLE    */
libname outlib “/Desktop/Output"; /* OUTPUT LOCATION       */
%let VIF_limit = 2;           /* VIF LIMIT             */
%let VIF_val = 100;

/* VARIABLE LIST */
%let varlist =
X1
X2
X3
…
X100
;

data inset;
set dataloc.&inset.;
run;

/* TO CREATE A BLANK TABLE FOR REMOVED VARIABLE */
ods output "Parameter Estimates"=vif;
proc reg data=inset ;
model &target. =
&varlist.
/VIF;
run;

data outlib.removed_variable_list;
set vif;
if _n_ = 0 then output outlib.removed_variable_list;
run;


/* LOOP FOR ITERATIONS */
%macro vif_automated;
%do %while (%sysevalf(&vif_val. > &VIF_limit.));

ods output "Parameter Estimates"=vif;

proc reg data=inset ;
model &target. =
&varlist.
/VIF;
run;

proc sort data=     vif;
by descending VarianceInflation;
run;

data vif_top vif_others;
set vif;
if _n_ = 1 then output vif_top;
if _n_ gt 1 then output vif_others;
run;

data vif_top;
set vif_top;
call symput( compress("vif_val"),compress(VarianceInflation));
run;

data outlib.removed_variable_list;
set vif_top outlib.removed_variable_list;

proc sql;
select distinct variable into: varlist separated by " "
from vif_others
where variable ^= "Intercept"
;
quit;
%end;

data outlib.final_variable_vif;
set vif;
run;

%mend;
%vif_automated;
