/* Data Preprocessing*/

data peanbutr;
	INFILE "H:\peanbutr\peanbutr_groc_1114_1165" FIRSTOBS = 2;
	INPUT IRI_KEY WEEK SY GE VEND ITEM UNITS DOLLARS F $ D PR;
	UPC= catx('-',SY,GE,VEND,ITEM);
RUN;

data peanbutr2;
	SET peanbutr (drop = SY GE VEND ITEM);
RUN;
PROC IMPORT OUT= WORK.PRODPEANBUTR 
            DATAFILE= "H:\peanbutr\prod_peanbutr.xls" 
            DBMS=EXCEL REPLACE;
     RANGE="Sheet1$"; 
     GETNAMES=YES;
     MIXED=NO;
     SCANTEXT=YES;
     USEDATE=YES;
     SCANTIME=YES;
 
RUN;

data WORK.PRODPEANBUTR;
	SET prodpeanbutr (drop = UPC);
RUN;
data prodpeanbutr;
	SET prodpeanbutr;
	UPC = catx('-',SY,GE,VEND,ITEM);
RUN;
proc sort data=peanbutr2;
   by UPC;
run;
proc sort data=prodpeanbutr;
   by UPC;
run;
data peanbutr3;
   merge peanbutr2 prodpeanbutr;
   by UPC;
run;
PROC PRINT DATA = peanbutr3(OBS=30);
RUN;
PROC MEANS data = peanbutr3 sum STACKODSOUTPUT; VAR DOLLARS; CLASS l5;
ods output Summary=SUMSummary;  /* write statistics to data set */
run;  
data peanbutr4; 
	set peanbutr3; 
	if not (L5 = 'JIF' or L5 = 'PRIVATE LABEL' or L5 = 'SKIPPY' or L5 = 'PETER PAN' or L5 = 'SKIPPY SUPER CHUNK' or L5 = 'SMUCKERS') then L5 = 'OTHER';
run;
 
data peanbutrn;
	set peanbutr4;
	pricepounce = DOLLARS/VOL_EQ ;
	weights = pricepounce*units;
run;
PROC PRINT DATA = peanbutrn(OBS=30);
RUN;
PROC means data = peanbutrn; VAR weights; CLASS l5;
RUN;
proc tabulate data=peanbutrn out=work.tabout;
  class l5;
  var weights;
  tables l5, weights*(N sum);
run;
proc summary data=work.tabout;
var weights_N weights_Sum;
output out=totals sum=;
run;
data peanbutrn2;
	set work.tabout;
	brandmarketshare = weights_Sum / 2235175525.7;
run;
 
data pf;
	set peanbutrn;
	if l5 = 'JIF' then brandmarketshare = 0.26216;
	else if l5 = 'OTHER' then brandmarketshare = 0.07868;
	else if l5 = 'PETER PAN' then brandmarketshare = 0.14574;
	else if l5 = 'PRIVATE LABEL' then brandmarketshare = 0.17438;
	else if l5 = 'SKIPPY' then brandmarketshare = 0.29185;
	else if l5 = 'SKIPPY SUPER CHUNK' then brandmarketshare = 0.04058;
	else brandmarketshare = 0.00660;
run;

data pf2;
	set pf;
	averageweightedprice = pricepounce*brandmarketshare;
run;
proc print data=pf2(OBS=30);
run;
PROC MEANS data = pf2;var F; CLASS l5;
RUN;
 
data pf3;
set pf2;
if      F='NONE' then Fnew = 0;
else if F='C' then Fnew = 1;
else if F='B' then Fnew = 2;
else if F='A' then Fnew = 3;
else Fnew = 4;
run;
 
data pf4;
	set pf3;
	weightedD = D*brandmarketshare;
	weightedF = Fnew*brandmarketshare;
run;
 
/* Descriptive Analysis*/

proc freq data=pf4;
   tables F;
run;
ods output summary=q7means;
PROC MEANS data = pf4 stackodsoutput; VAR averageweightedprice; CLASS l5 week;
output out=q7 mean=;
run;
ods output close;
 
data myattrmap;
set q7means(keep=L5 $ Week Mean);
by L5;
if L5='JIF' then linecolor='Blue';
else if L5='OTHER' then linecolor='Red';
else if L5='PETER PAN' then linecolor='Orange';
else if L5='PRIVATE LABEL' then linecolor='Yellow';
else if L5='SKIPPY' then linecolor='Green';
else if L5='SKIPPY SUPER CHUNK' then linecolor='Magenta';
else if L5='SMUCKERS' then linecolor='Brown';
run;
 
proc sgplot data=q7means dattrmap=myattrmap;
    series x=WEEK y=Mean / group=L5
				break
                 markerattrs=(symbol=circlefilled color=blue)
                 legendlabel='rates for store1';
   xaxis type=discrete grid label=' ';
   yaxis label= 'mean' grid values=(0 to 14 by 1);
run;
 
 
proc means data = pf4;
class l5;
var averageweightedprice;
run;
 
proc means data = pf4;
class l5;
var weightedD weightedF;
run;
 
proc freq data = pf4;
tables F*L5 / NOROW NOCOL NOFREQ;
run;
 
 
proc univariate data=pf4;
class l5;
var averageweightedprice;
run;
 
proc corr data=pf4 ;
var averageweightedprice weightedD weightedF;
run;
 
PROC PRINT DATA = pf4(OBS=30);
RUN;
 
 
/* Brand Choice and conjoint analysis*/
 
data pf5;
set pf4;
totweeklysales = averageweightedprice*units;
run;
 
proc transreg data=pf5 utilities;
model identity(totweeklysales) = class(l5 D Fnew);
run;quit;
 
 
data b1(keep=UPC brand decision pricepounce brandmarketshare averageweightedprice weightedF weightedD totweeklysales);
set pf5;
if l5 = 'JIF' then brand = 1;
else if l5 = 'OTHER' then brand = 2;
else if l5 = 'PETER PAN' then brand = 3;
else if l5 = 'PRIVATE LABEL' then brand = 4;
else if l5 = 'SKIPPY' then brand = 5;
else if l5 = 'SKIPPY SUPER CHUNK' then brand = 5;
else brand = 6;
UPC =  compress(UPC,'-');;
 
run;
 
data b2; set b1;
p1 = ifn(brand = 1, averageweightedprice, 0);
p2 = ifn(brand = 2, averageweightedprice, 0);
p3 = ifn(brand = 3, averageweightedprice, 0);
p4 = ifn(brand = 4, averageweightedprice, 0);
p5 = ifn(brand = 5, averageweightedprice, 0);
p6 = ifn(brand = 6, averageweightedprice, 0);
d1 = ifn(brand = 1, weightedD, 0);
d2 = ifn(brand = 2, weightedD, 0);
d3 = ifn(brand = 3, weightedD, 0);
d4 = ifn(brand = 4, weightedD, 0);
d5 = ifn(brand = 5, weightedD, 0);
d6 = ifn(brand = 6, weightedD, 0);
f1 = ifn(brand = 1, weightedF, 0);
f2 = ifn(brand = 2, weightedF, 0);
f3 = ifn(brand = 3, weightedF, 0);
f4 = ifn(brand = 4, weightedF, 0);
f5 = ifn(brand = 5, weightedF, 0);
f6 = ifn(brand = 6, weightedF, 0);
intercept1 = ifn(brand = 1, 1, 0);
intercept2 = ifn(brand = 2, 1, 0);
intercept3 = ifn(brand = 3, 1, 0);
intercept4 = ifn(brand = 4, 1, 0); 
intercept5 = ifn(brand = 5, 1, 0);
intercept6 = ifn(brand = 6, 1, 0);
 
run;
data b3(keep=id brand1 decision price display feature);
set b1;
array tvec{6} p1 - p6;
array svec{6} d1 - d6;
array pvec{6} f1 - f6;
 
retain id 0;
   id + 1;
   do i = 1 to 6;
      brand1 = i;
      price = tvec{i};
	  feature = pvec{i};
	  display = svec{i};
      decision = ( brand = i );
      output;
   end;
run;
data newtwo;
      set b3;
      if nmiss(of id brand1 decision price display feature) = 0 then _include = 1;
      run;
 
proc means data=newtwo noprint;
      where _include = 1;
      by id;
      var decision;
      output out=newthree(keep=id _sum) sum = _sum;
      run;
 data new;
      merge b3 newthree;
      by id;
      run;
proc mdc data=new; 
      where _sum ne 0;
      model decision = price feature display
	  /type=clogit nchoice =6 covest=hess;
	  id id; 
      run;

/* Data and forecasting for time series  ---------  */
PROC MEANS data = pf sum STACKODSOUTPUT; VAR DOLLARS; CLASS l5 week;
ods output Summary=WeeklySales; 
run;  
proc print data=WeeklySales(OBS=10);
run; 

Data jif_ts;
	set WeeklySales;
	if L5 = 'JIF';
	run;
proc print data=jif_ts(OBS=30);
run; 
proc arima data = jif_ts; 
identify var = Sum minic;
run;
proc arima data = jif_ts; 
identify var = Sum stationarity=(adf=0);
run;
identify var = Sum stationarity=(pp=0);
run;
proc arima data = jif_ts; 
identify var = Sum;
estimate p=2 q=1;
forecast lead=8 id=WEEK out=jif_result;
run;

Data skippy_ts;
	set WeeklySales;
	if L5 = 'SKIPPY';
	run;
proc arima data = skippy_ts; 
identify var = Sum minic;
run;
proc arima data = skippy_ts; 
identify var = Sum stationarity=(adf=0);
run;
identify var = Sum stationarity=(pp=0);
run;
proc arima data = skippy_ts; 
identify var = Sum;
estimate p=0 q=1;
forecast lead=8 id=WEEK out=skippy_result;
run;
proc print data=skippy_result;
run; 

Data skippy2_ts;
	set WeeklySales;
	if L5 = 'SKIPPY SUPER CHUNK';
	run;
proc arima data = skippy2_ts; 
identify var = Sum minic;
run;
proc arima data = skippy2_ts; 
identify var = Sum stationarity=(adf=0);
run;
identify var = Sum stationarity=(pp=0);
run;
proc arima data = skippy2_ts; 
identify var = Sum;
estimate p=0 q=4;
forecast lead=8 id=WEEK out=skippy2_result;
run;
proc print data=skippy2_result;
run; 

Data pp_ts;
	set WeeklySales;
	if L5 = 'PETER PAN';
	run;
proc arima data = pp_ts; 
identify var = Sum minic;
run;
proc arima data = pp_ts; 
identify var = Sum stationarity=(adf=0);
run;
identify var = Sum stationarity=(pp=0);
run;
proc arima data = pp_ts; 
identify var = Sum;
estimate p=1 q=0;
forecast lead=8 id=WEEK out=pp_result;
run;
proc print data=pp_result;
run; 

Data pl_ts;
	set WeeklySales;
	if L5 = 'PRIVATE LABEL';
	run;
proc arima data = pl_ts; 
identify var = Sum minic;
run;
proc arima data = pl_ts; 
identify var = Sum stationarity=(adf=0);
run;
identify var = Sum stationarity=(pp=0);
run;
proc arima data = pl_ts; 
identify var = Sum;
estimate p=0 q=5;
forecast lead=8 id=WEEK out=pl_result;
run;
proc print data=pl_result;
run; 

Data smuckers_ts;
	set WeeklySales;
	if L5 = 'SMUCKERS';
	run;
proc arima data = smuckers_ts; 
identify var = Sum minic;
run;
proc arima data = smuckers_ts; 
identify var = Sum stationarity=(adf=0);
run;
identify var = Sum stationarity=(pp=0);
run;
proc arima data = smuckers_ts; 
identify var = Sum;
estimate p=1 q=0;
forecast lead=8 id=WEEK out=smuckers_result;
run;
proc print data=smuckers_result;
run; 

Data other_ts;
	set WeeklySales;
	if L5 = 'OTHER';
	run;
proc arima data = other_ts; 
identify var = Sum minic;
run;
proc arima data = other_ts; 
identify var = Sum stationarity=(adf=0);
run;
identify var = Sum stationarity=(pp=0);
run;
proc arima data = other_ts; 
identify var = Sum;
estimate p=0 q=5;
forecast lead=8 id=WEEK out=other_result;
run;
proc print data=other_result;
run; 

data final;
      set jif_result(keep=week forecast
                   rename=(forecast=jif_F));
      set skippy_result(keep=week forecast
                   rename=(forecast=skippy_F));
      set skippy2_result(keep=week forecast
					rename=(forecast=skippy2_F));
	  set pp_result(keep=week forecast
					rename=(forecast=pp_F));
	  set pl_result(keep=week forecast
					rename=(forecast=pl_F));
	  set smuckers_result(keep=week forecast
					rename=(forecast=smuckers_F));
	  set other_result(keep=week forecast
					rename=(forecast=other_F));

   run;
   title 'Brand Forecasts';
   symbol1 i=spline width=2 v=dot  c=black mode= INCLUDE; 
   symbol2 i=spline width=2 v=dot c=red mode= INCLUDE;    
   symbol3 i=spline width=2 v=dot c=green mode= INCLUDE;  
   symbol4 i=spline width=2 v=dot c=blue mode= INCLUDE;
   symbol5 i=spline width=2 v=dot c=magenta mode= INCLUDE;
   symbol6 i=spline width=2 v=dot c=yellow mode= INCLUDE;
   symbol7 i=spline width=2 v=dot c=brown mode= INCLUDE;
   axis1 offset=(1 cm)
         label=('Weeks') minor=none
         order=(1166 to 1174 by 2);
   axis2 label=(angle=90 'Forecast of Weekly Sales')
         order=(15000 to 275000 by 50000);

   legend1 across=1
           cborder=black
           position=(top inside right)
           offset=(-2,0)
           value=(tick=1 'JIF'
                  tick=2 'SKIPPY'
                  tick=3 'SKIPPY2'
                  tick=4 'PETER PAN'
				tick=5 'PRIVATE LABEL'
				tick=6 'SMUCKERS'
				tick=7 'OTHER')
           shape=symbol(2,.25)
           mode=share
           label=none;
proc gplot data=final;
  
      plot jif_F * week = 1
           skippy_F  * week = 2
           skippy2_F  * week = 3
           pp_F  * week = 4
			pl_F  * week = 5
			smuckers_F  * week = 6
			other_F  * week = 7/ overlay noframe
                               vaxis=axis2
                               vminor=1
                               haxis=axis1
                               legend=legend1;
   run;
   quit;
