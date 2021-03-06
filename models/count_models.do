
set matsize 11000
* cd "/Users/rbtrichler/Box Sync/cambodia_eba_gie"
* cd "/Users/christianbaehr/Box Sync/cambodia_eba_gie"

insheet using "ProcessedData/panel.csv", clear

* dropping observations if the commune name variable contains NA values. Keeping these observations
* creates problematic clusters when clustering errors at commune level

* replace border_cell_enddate_type = "." if border_cell_enddate_type == "NA"
* destring border_cell_enddate_type, replace
* replace intra_cell_enddate_type = "." if intra_cell_enddate_type == "NA"
* destring intra_cell_enddate_type, replace

* replacing year index with actual year
replace year = year + 1991

replace province_name = "" if province_name == "NA"
encode province_name, gen(province_number)

* replace unique_commune_name = "" if strpos(unique_commune_name, "n.a") > 0
encode unique_commune_name, gen(commune_number)
gen temp = (province_number==16 & strpos(unique_commune_name, "n.a") > 0)
drop if temp==1

* formatting missing data values for the treatment date variable
* replace intra_cell_earliest_enddate = "." if intra_cell_earliest_enddate == "NA"
* destring intra_cell_earliest_enddate, replace
* replace border_cell_earliest_enddate = "." if border_cell_earliest_enddate == "NA"
* destring border_cell_earliest_enddate, replace

* generating the "village within cell" treatment variable 
* gen intra_cell_treatment = 0
* replace intra_cell_treatment = 1 if year >= intra_cell_earliest_enddate

* generating the "village surrounding cell" treatment variable
* gen border_cell_treatment = 0
* replace border_cell_treatment = 1 if year >= border_cell_earliest_enddate

* gen earliest project end_date
* gen earliest_end= border_cell_earliest_enddate 
* replace earliest_end = intra_cell_earliest_enddate if intra_cell_earliest_enddate<border_cell_earliest_enddate

*gen ntl dummy that reflects if lit before 1992
gen ntl_dummy_pre92 = 0
*only equals 1 if lit before 1992
replace ntl_dummy_pre92=1 if ntl>0 & year==1992 
egen ntl_lit_pre92 = max(ntl_dummy_pre92), by(cell_id)

* gen dummy that reflects if become lit between 1992-2002
gen ntl_dummy_pre03=0
*only equals 1 if lit 2002 or earlier
replace ntl_dummy_pre03=1 if ntl>0 & year==2002
egen ntl_lit_pre03 = max(ntl_dummy_pre03), by(cell_id)


* generating dependent variables

* ntl dummy
gen ntl_dummy = .
replace ntl_dummy = 0 if ntl == 0
replace ntl_dummy = 1 if ntl > 0

* binned ntl (rounded down)
egen ntl_binned = cut(ntl), at(0, 10, 20, 30, 40, 50, 60, 70)
* table ntl_binned, contents(min ntl max ntl)

*** MODELS ****
gen project_count = intra_cell_count + border_cell_count
egen max_projects = max(project_count), by(cell_id)

* outsheet using "Report/ntl_sum_stats.csv", comma

***

* bysort cell_id (year): gen ntl_pre_baseline = ntl[11]
* xtile ntl_baseline = ntl_pre_baseline, n(4)

cgmreg ntl_dummy intra_cell_count, cluster(commune_number year)
est sto a1
outreg2 using "Results/count_treatment/ntl_dummy.doc", replace noni nocons addtext("Year FEs", N, "Grid cell FEs", N, "Lin. Time Trends by Prov.", N) ///
	addnote("Notes: DV={0 if NTL=0, 1 otherwise}. 'intra_cell_count' refers to the treatment variable that only considers villages within a cell. 'border_cell_count' refers to the treatment variable that only considers villages in the eight cells bordering a cell, but NOT within the cell itself.")
cgmreg ntl_dummy intra_cell_count border_cell_count, cluster(commune_number year)
est sto a2
outreg2 using "Results/count_treatment/ntl_dummy.doc", append noni nocons addtext("Year FEs", N, "Grid cell FEs", N, "Lin. Time Trends by Prov.", N)
reghdfe ntl_dummy intra_cell_count border_cell_count, cluster(commune_number year) absorb(year)
est sto a3
outreg2 using "Results/count_treatment/ntl_dummy.doc", append noni addtext("Year FEs", Y, "Grid cell FEs", N, "Lin. Time Trends by Prov.", N) ///
	keep(intra_cell_count border_cell_count)
reghdfe ntl_dummy intra_cell_count border_cell_count i.year, cluster(commune_number year) absorb(cell_id)
est sto a4
outreg2 using "Results/count_treatment/ntl_dummy.doc", append noni addtext("Year FEs", Y, "Grid cell FEs", Y, "Lin. Time Trends by Prov.", N) /// 
	keep(intra_cell_count border_cell_count)
reghdfe ntl_dummy intra_cell_count border_cell_count i.year c.year#i.province_number, cluster(commune_number year) absorb(cell_id)
est sto a5
outreg2 using "Results/count_treatment/ntl_dummy.doc", append noni addtext("Year FEs", Y, "Grid cell FEs", Y, "Lin. Time Trends by Prov.", Y) /// 
	keep(intra_cell_count border_cell_count)

* NTL binned dependent variable

cgmreg ntl_binned intra_cell_count, cluster(commune_number year)
est sto b1
outreg2 using "Results/count_treatment/ntl_binned.doc", replace noni nocons addtext("Year FEs", N, "Grid cell FEs", N, "Lin. Time Trends by Prov.", N) ///
	addnote("Notes: DV=NTL rounded down to the nearest 10. 'intra_cell_count' refers to the treatment variable that only considers villages within a cell. 'border_cell_count' refers to the treatment variable that only considers villages in the eight cells bordering a cell, but NOT within the cell itself.")
cgmreg ntl_binned intra_cell_count border_cell_count, cluster(commune_number year)
est sto b2
outreg2 using "Results/count_treatment/ntl_binned.doc", append noni nocons addtext("Year FEs", N, "Grid cell FEs", N, "Lin. Time Trends by Prov.", N)
reghdfe ntl_binned intra_cell_count border_cell_count, cluster(commune_number year) absorb(year)
est sto b3
outreg2 using "Results/count_treatment/ntl_binned.doc", append noni addtext("Year FEs", Y, "Grid cell FEs", N, "Lin. Time Trends by Prov.", N) /// 
	keep(intra_cell_count border_cell_count)
reghdfe ntl_binned intra_cell_count border_cell_count i.year, cluster(commune_number year) absorb(cell_id)
est sto b4
outreg2 using "Results/count_treatment/ntl_binned.doc", append noni addtext("Year FEs", Y, "Grid cell FEs", Y, "Lin. Time Trends by Prov.", N) ///
	keep(intra_cell_count border_cell_count)
reghdfe ntl_binned intra_cell_count border_cell_count i.year c.year#i.province_number, cluster(commune_number year) absorb(cell_id)
est sto b5
outreg2 using "Results/count_treatment/ntl_binned.doc", append noni addtext("Year FEs", Y, "Grid cell FEs", Y, "Lin. Time Trends by Prov.", Y) ///
	keep(intra_cell_count border_cell_count)

* NTL continuous dependent variable

cgmreg ntl intra_cell_count, cluster(commune_number year)
est sto c1
outreg2 using "Results/count_treatment/ntl_continuous.doc", replace noni nocons addtext("Year FEs", N, "Grid cell FEs", N, "Lin. Time Trends by Prov.", N) ///
	addnote("Notes: DV=NTL. 'intra_cell_count' refers to the treatment variable that only considers villages within a cell. 'border_cell_count' refers to the treatment variable that only considers villages in the eight cells bordering a cell, but NOT within the cell itself.")
cgmreg ntl intra_cell_count border_cell_count, cluster(commune_number year)
est sto c2
outreg2 using "Results/count_treatment/ntl_continuous.doc", append noni nocons addtext("Year FEs", N, "Grid cell FEs", N, "Lin. Time Trends by Prov.", N)
reghdfe ntl intra_cell_count border_cell_count, cluster(commune_number year) absorb(year)
est sto c3
outreg2 using "Results/count_treatment/ntl_continuous.doc", append noni addtext("Year FEs", Y, "Grid cell FEs", N, "Lin. Time Trends by Prov.", N) ///
	keep(intra_cell_count border_cell_count)
reghdfe ntl intra_cell_count border_cell_count i.year, cluster(commune_number year) absorb(cell_id)
est sto c4
outreg2 using "Results/count_treatment/ntl_continuous.doc", append noni addtext("Year FEs", Y, "Grid cell FEs", Y, "Lin. Time Trends by Prov.", N) ///
	keep(intra_cell_count border_cell_count)
reghdfe ntl intra_cell_count border_cell_count i.year c.year#i.province_number, cluster(commune_number year) absorb(cell_id)
est sto c5
outreg2 using "Results/count_treatment/ntl_continuous.doc", append noni addtext("Year FEs", Y, "Grid cell FEs", Y, "Lin. Time Trends by Prov.", Y) ///
	keep(intra_cell_count border_cell_count)

reghdfe ntl intra_cell_count border_cell_count year##province_number, cluster(commune_number year) absorb(cell_id)

***

* Additional NTL continuous models
reghdfe ntl intra_cell_count border_cell_count year##province_number, cluster(commune_number year) absorb(cell_id)

reghdfe ntl intra_cell_count border_cell_count i.year c.year#i.province_number if ntl_lit_pre03==1, cluster(commune_number year) absorb(cell_id)
reghdfe ntl intra_cell_count border_cell_count i.year c.year#i.province_number if ntl_lit_pre03==0, cluster(commune_number year) absorb(cell_id)


* gen project_count for single merged count
***

cgmreg ntl project_count, cluster(commune_number year)
est sto d1
outreg2 using "Results/count_treatment/additional_models/merged_treatment/ntl_continuous.doc", replace noni nocons ///
	addtext("Year FEs", N, "Grid cell FEs", N, "Lin. Time Trends by Prov.", N) ///
	addnote("Notes: DV=NTL. 'intra_cell_count' refers to the treatment variable that only considers villages within a cell. 'border_cell_count' refers to the treatment variable that only considers villages in the eight cells bordering a cell, but NOT within the cell itself.")
cgmreg ntl project_count, cluster(commune_number year)
est sto d2
outreg2 using "Results/count_treatment/additional_models/merged_treatment/ntl_continuous.doc", append noni nocons ///
	addtext("Year FEs", N, "Grid cell FEs", N, "Lin. Time Trends by Prov.", N)
reghdfe ntl project_count, cluster(commune_number year) absorb(year)
est sto d3
outreg2 using "Results/count_treatment/additional_models/merged_treatment/ntl_continuous.doc", append noni ///
	addtext("Year FEs", Y, "Grid cell FEs", N, "Lin. Time Trends by Prov.", N) keep(project_count)
reghdfe ntl project_count i.year, cluster(commune_number year) absorb(cell_id)
est sto d4
outreg2 using "Results/count_treatment/additional_models/merged_treatment/ntl_continuous.doc", append noni ///
	addtext("Year FEs", Y, "Grid cell FEs", Y, "Lin. Time Trends by Prov.", N) keep(project_count)
reghdfe ntl project_count i.year c.year#i.province_number, cluster(commune_number year) absorb(cell_id)
est sto d5
outreg2 using "Results/count_treatment/additional_models/merged_treatment/ntl_continuous.doc", append noni ///
	addtext("Year FEs", Y, "Grid cell FEs", Y, "Lin. Time Trends by Prov.", Y) keep(project_count)

	
* gen cell count categories
	
gen trt1_intra = (intra_cell_count>=1)
gen trt2_intra = (intra_cell_count>=2)
gen trt3_intra = (intra_cell_count>=3)
gen trt4_intra = (intra_cell_count>=4)
gen trt5_intra = (intra_cell_count>=5)
reghdfe ntl trt1_intra trt2_intra trt3_intra trt4_intra trt5_intra i.year c.year#i.province_number, cluster(commune_number year) absorb(cell_id)

*gen trt1 = (intra_cell_count+border_cell_count>=1)
*gen trt2_4 = (intra_cell_count+border_cell_count>=2)
*gen trt5_9 = (intra_cell_count+border_cell_count>=5)
*gen trt10_ = (intra_cell_count+border_cell_count>=10)

***

gen trt1 = (project_count>=1)
gen trt2_4 = (project_count>=2)
gen trt5_9 = (project_count>=5)
gen trt10_ = (project_count>=10)

gen dummy_2008 = (year>=2008)
gen intra_interact_2008 = intra_cell_count*dummy_2008
gen border_interact_2008 = border_cell_count*dummy_2008
gen project_interact_2008 = project_count*dummy_2008

gen trt1_interact_2008 = trt1*dummy_2008
gen trt2_4_interact_2008 = trt2_4*dummy_2008
gen trt5_9_interact_2008 = trt5_9*dummy_2008
gen trt10_interact_2008 = trt10_*dummy_2008

gen proj_count_interact = project_count*vills

cgmreg ntl project_count, cluster(commune_number year)
outreg2 using "Report/main_models.doc", replace noni nocons ///
	addtext("Year FEs", N, "Grid cell FEs", N, "Lin. Time Trends by Prov.", N)
reghdfe ntl project_count, cluster(commune_number year) absorb(year)
outreg2 using "Report/main_models.doc", append noni ///
	addtext("Year FEs", Y, "Grid cell FEs", N, "Lin. Time Trends by Prov.", N) keep(project_count)
reghdfe ntl project_count i.year, cluster(commune_number year) absorb(cell_id)
outreg2 using "Report/main_models.doc", append noni ///
	addtext("Year FEs", Y, "Grid cell FEs", Y, "Lin. Time Trends by Prov.", N) keep(project_count)
reghdfe ntl project_count i.year c.year#i.province_number, cluster(commune_number year) absorb(cell_id)
outreg2 using "Report/main_models.doc", append noni addtext("Year FEs", Y, "Grid cell FEs", Y, "Lin. Time Trends by Prov.", Y) ///
	keep(project_count)
reghdfe ntl project_count project_interact_2008 i.year ///
	c.year#i.province_number, cluster(commune_number year) absorb(cell_id)
outreg2 using "Report/main_models.doc", append noni addtext("Year FEs", Y, "Grid cell FEs", Y, "Lin. Time Trends by Prov.", Y) ///
	keep(project_count project_interact_2008)
reghdfe ntl trt1 trt2_4 trt5_9 trt10_ i.year c.year#i.province_number, cluster(commune_number year) absorb(cell_id)
outreg2 using "Report/main_models.doc", append noni addtext("Year FEs", Y, "Grid cell FEs", Y, "Lin. Time Trends by Prov.", Y) ///
	keep(trt1 trt2_4 trt5_9 trt10_)
reghdfe ntl trt1 trt2_4 trt5_9 trt10_ trt1_interact_2008 trt2_4_interact_2008 trt5_9_interact_2008 ///
	trt10_interact_2008 i.year c.year#i.province_number, cluster(commune_number year) absorb(cell_id)
outreg2 using "Report/main_models.doc", append noni addtext("Year FEs", Y, "Grid cell FEs", Y, "Lin. Time Trends by Prov.", Y) ///
	keep(trt1 trt2_4 trt5_9 trt10_ trt1_interact_2008 trt2_4_interact_2008 trt5_9_interact_2008 trt10_interact_2008)
*reghdfe ntl trt1 trt2_4 trt5_9 trt10_ proj_count_interact i.year c.year#i.province_number, cluster(commune_number year) absorb(cell_id)
*outreg2 using "Report/main_models.doc", append noni addtext("Year FEs", Y, "Grid cell FEs", Y, "Lin. Time Trends by Prov.", Y) ///
*	keep(trt1 trt2_4 trt5_9 trt10_ proj_count_interact)

erase "Report/main_models.txt"

***

	
***

bysort cell_id: egen temp1 = min(year) if trt1==1
bysort cell_id: egen temp2 = min(year) if trt2_4==1
bysort cell_id: egen temp3 = min(year) if trt5_9==1
bysort cell_id: egen temp4 = min(year) if trt10_==1

bysort cell_id: egen year_crossed_trt1 = min(temp1)
bysort cell_id: egen year_crossed_trt2_4 = min(temp2)
bysort cell_id: egen year_crossed_trt5_9 = min(temp3)
bysort cell_id: egen year_crossed_trt10_ = min(temp4)

reg year_crossed_trt1 councilors_per_vil i.province_number if year==2013, cluster(province_number)
outreg2 using "/Users/christianbaehr/Desktop/add_models.doc", replace noni addtext("Province FEs", Y) ///
	keep(councilors_per_vil)
reg year_crossed_trt2_4 councilors_per_vil i.province_number if year==2013, cluster(province_number)
outreg2 using "/Users/christianbaehr/Desktop/add_models.doc", append noni addtext("Province FEs", Y) ///
	keep(councilors_per_vil)
reg year_crossed_trt5_9 councilors_per_vil i.province_number if year==2013, cluster(province_number)
outreg2 using "/Users/christianbaehr/Desktop/add_models.doc", append noni addtext("Province FEs", Y) ///
	keep(councilors_per_vil)
reg year_crossed_trt10_ councilors_per_vil i.province_number if year==2013, cluster(province_number)
outreg2 using "/Users/christianbaehr/Desktop/add_models.doc", append noni addtext("Province FEs", Y) ///
	keep(councilors_per_vil)

graph twoway (lfit councilors_per_vil year_crossed_trt1 if year==2013) ///
	(scatter councilors_per_vil year_crossed_trt1 if year==2013), xtitle("Year trt1 turns on") ///
	ytitle("#councilors/village") name(graph1) legend(off)

graph twoway (lfit councilors_per_vil year_crossed_trt2_4 if year==2013) ///
	(scatter councilors_per_vil year_crossed_trt2_4 if year==2013), xtitle("Year trt2_4 turns on") ///
	ytitle("#councilors/village") name(graph2) legend(off)

graph twoway (lfit councilors_per_vil year_crossed_trt5_9 if year==2013) ///
	(scatter councilors_per_vil year_crossed_trt5_9 if year==2013), xtitle("Year trt5_9 turns on") ///
	ytitle("#councilors/village") name(graph3) legend(off)

graph twoway (lfit councilors_per_vil year_crossed_trt10_ if year==2013) ///
	(scatter councilors_per_vil year_crossed_trt10_ if year==2013), xtitle("Year trt10_ turns on") ///
	ytitle("#councilors/village") name(graph4) legend(off)
	
graph combine graph1 graph2 graph3 graph4, title("Year treatment threshold crossed / #councilors per village")

*

egen mean_councilors1 = mean(councilors_per_vil) if year == 2013, by(year_crossed_trt1)
egen mean_councilors2 = mean(councilors_per_vil) if year == 2013, by(year_crossed_trt2_4)
egen mean_councilors3 = mean(councilors_per_vil) if year == 2013, by(year_crossed_trt5_9)
egen mean_councilors4 = mean(councilors_per_vil) if year == 2013, by(year_crossed_trt10_)


graph twoway (lfit councilors_per_vil year_crossed_trt1 if year==2013) ///
	(scatter mean_councilors1 year_crossed_trt1 if year==2013), xtitle("Year trt1 turns on") ///
	ytitle("avg. #councilors/village") name(graph5) legend(off)

graph twoway (lfit councilors_per_vil year_crossed_trt2_4 if year==2013) ///
	(scatter mean_councilors2 year_crossed_trt2_4 if year==2013), xtitle("Year trt2_4 turns on") ///
	ytitle("avg. #councilors/village") name(graph6) legend(off)

graph twoway (lfit councilors_per_vil year_crossed_trt5_9 if year==2013) ///
	(scatter mean_councilors3 year_crossed_trt5_9 if year==2013), xtitle("Year trt5_9 turns on") ///
	ytitle("avg. #councilors/village") name(graph7) legend(off)

graph twoway (lfit councilors_per_vil year_crossed_trt10_ if year==2013) ///
	(scatter mean_councilors4 year_crossed_trt10_ if year==2013), xtitle("Year trt10_ turns on") ///
	ytitle("avg. #councilors/village") name(graph8) legend(off)
	
graph combine graph5 graph6 graph7 graph8,  title("Year treatment threshold crossed / avg. #councilors per village")

***

tabstat councilors_per_vil priorities_funded_02 priorities_funded_03 pct_women_02 pct_women_03 ///
	new_chiefs_prev_served new_ccMem_prev_served excom_staff if year==2013, by(trt1)
	
tabstat councilors_per_vil priorities_funded_02 priorities_funded_03 pct_women_02 pct_women_03 ///
	new_chiefs_prev_served new_ccMem_prev_served excom_staff if year==2013, by(trt2_4)

tabstat councilors_per_vil priorities_funded_02 priorities_funded_03 pct_women_02 pct_women_03 ///
	new_chiefs_prev_served new_ccMem_prev_served excom_staff if year==2013, by(trt5_9)
	
tabstat councilors_per_vil priorities_funded_02 priorities_funded_03 pct_women_02 pct_women_03 ///
	new_chiefs_prev_served new_ccMem_prev_served excom_staff if year==2013, by(trt10_)

tabstat trt1 trt2_4 trt5_9 trt10_ if year==2013

replace gov = councilors_per_vill
gen project_count_sq = project_count^2

reghdfe ntl c.project_count##c.gov project_count_sq i.year c.year#i.province_number, ///
	cluster(commune_number year) absorb(cell_id)

reghdfe ntl c.project_count##c.gov project_count_sq i.year c.year#i.province_number, ///
	cluster(commune_number year) absorb(cell_id)
outreg2 using "Results/governance/n_councilors_ad.doc", replace noni addtext("Year FEs", Y, ///
	"Grid cell FEs", Y, "Lin. Time Trends by Prov.", Y) keep(project_count gov c.project_count#c.gov) ///
	addnote("gov = # of councilors/# of villages. Commune-level")

replace gov = pct_new_cc_mem_prev_served_2002

reghdfe ntl c.project_count##c.gov project_count_sq i.year c.year#i.province_number, ///
	cluster(commune_number year) absorb(cell_id)
outreg2 using "Results/governance/prev_served_ad.doc", append noni addtext("Year FEs", Y, ///
	"Grid cell FEs", Y, "Lin. Time Trends by Prov.", Y) keep(project_count gov ///
	c.project_count#c.gov) ctitle("council members")

***

gen trt1 = (project_count>=1)
gen trt2_4 = (project_count>=2)
gen trt5_9 = (project_count>=5)
gen trt10_ = (project_count>=10)

replace pct_comp_bids="." if pct_comp_bids=="NA"
destring pct_comp_bids, replace

replace n_bids = "." if n_bids=="NA"
destring n_bids, replace

replace unit_cost = "." if unit_cost=="NA"
destring unit_cost, replace

replace unitcost_quantile = "." if unitcost_quantile=="NA"
destring unitcost_quantile, replace

gen uc_dummy = (unitcostdummy=="TRUE")

replace pct_comp_bids_comm="." if pct_comp_bids_comm=="NA"
destring pct_comp_bids_comm, replace

replace n_bids_comm = "." if n_bids_comm=="NA"
destring n_bids_comm, replace

replace unit_cost_comm = "." if unit_cost_comm=="NA"
destring unit_cost_comm, replace

replace unitcost_quantile_comm = "." if unitcost_quantile_comm=="NA"
destring unitcost_quantile_comm, replace

replace n_vill_in_comm="" if n_vill_in_comm=="NA"
destring n_vill_in_comm, replace
replace n_councilors_03="" if n_councilors_03=="NA"
destring n_councilors_03, replace
gen councilors_per_vill = n_councilors_03/n_vill_in_comm

gen comm_priorities_funded_02 = cond(pct_commune_priorities_funded_20=="NA", "", pct_commune_priorities_funded_20)
destring comm_priorities_funded_02, replace

gen comm_priorities_funded_03 = cond(v26=="NA", "", v26)
destring comm_priorities_funded_03, replace

replace cs_council_pct_women_2002 = cond(cs_council_pct_women_2002=="NA", "", cs_council_pct_women_2002)
destring cs_council_pct_women_2002, replace
replace cs_council_pct_women_2003 = cond(cs_council_pct_women_2003=="NA", "", cs_council_pct_women_2003)
destring cs_council_pct_women_2003, replace

gen pct_new_chiefs_prev_served_02 = cond(pct_new_commchiefs_prev_served_2=="NA", "", pct_new_commchiefs_prev_served_2)
destring pct_new_chiefs_prev_served_02, replace
replace pct_new_cc_mem_prev_served_2002 = cond(pct_new_cc_mem_prev_served_2002=="NA", "", pct_new_cc_mem_prev_served_2002)
destring pct_new_cc_mem_prev_served_2002, replace

replace n_excom_staff_2003 = cond(n_excom_staff_2003=="NA", "", n_excom_staff_2003)
destring n_excom_staff_2003, replace

gen councilors_per_vil = councilors_per_vill
gen priorities_funded_02 = comm_priorities_funded_02
gen priorities_funded_03 = comm_priorities_funded_03
gen pct_women_02 = cs_council_pct_women_2002
gen pct_women_03 = cs_council_pct_women_2003
gen new_chiefs_prev_served = pct_new_chiefs_prev_served_02
gen new_ccMem_prev_served = pct_new_cc_mem_prev_served_2002
gen excom_staff = n_excom_staff_2003

***

* additional final report models

* CGEO models

reghdfe ntl c.project_count##c.burial_dummy i.year c.year##i.province_number, cluster(commune_number year) absorb(cell_id)
outreg2 using "Results/governance/cgeo_models.doc", replace noni addtext("Year FEs", Y, ///
	"Grid cell FEs", Y, "Lin. Time Trends by Prov.", Y) keep(project_count c.project_count#c.burial_dummy)
reghdfe ntl c.project_count##c.prison_dummy i.year c.year##i.province_number, cluster(commune_number year) absorb(cell_id)
outreg2 using "Results/governance/cgeo_models.doc", append noni addtext("Year FEs", Y, ///
	"Grid cell FEs", Y, "Lin. Time Trends by Prov.", Y) keep(project_count c.project_count#c.prison_dummy)
reghdfe ntl c.project_count##c.bombing_dummy i.year c.year##i.province_number, cluster(commune_number year) absorb(cell_id)
outreg2 using "Results/governance/cgeo_models.doc", append noni addtext("Year FEs", Y, ///
	"Grid cell FEs", Y, "Lin. Time Trends by Prov.", Y) keep(project_count c.project_count#c.bombing_dummy)
reghdfe ntl c.project_count##c.memorial_dummy i.year c.year##i.province_number, cluster(commune_number year) absorb(cell_id)
outreg2 using "Results/governance/cgeo_models.doc", append noni addtext("Year FEs", Y, ///
	"Grid cell FEs", Y, "Lin. Time Trends by Prov.", Y) keep(project_count c.project_count#c.memorial_dummy)
reghdfe ntl c.project_count##c.n_burials i.year c.year##i.province_number, cluster(commune_number year) absorb(cell_id)
outreg2 using "Results/governance/cgeo_models.doc", append noni addtext("Year FEs", Y, ///
	"Grid cell FEs", Y, "Lin. Time Trends by Prov.", Y) keep(project_count c.project_count#c.n_burials)
reghdfe ntl c.project_count##c.n_bombings i.year c.year##i.province_number if n_bombings!=9282, cluster(commune_number year) absorb(cell_id)
outreg2 using "Results/governance/cgeo_models.doc", append noni addtext("Year FEs", Y, ///
	"Grid cell FEs", Y, "Lin. Time Trends by Prov.", Y) keep(project_count c.project_count#c.n_bombings)
reghdfe ntl c.project_count##c.n_prisons i.year c.year##i.province_number, cluster(commune_number year) absorb(cell_id)
outreg2 using "Results/governance/cgeo_models.doc", append noni addtext("Year FEs", Y, ///
	"Grid cell FEs", Y, "Lin. Time Trends by Prov.", Y) keep(project_count c.project_count#c.n_prisons)
reghdfe ntl c.project_count##c.n_memorials i.year c.year##i.province_number, cluster(commune_number year) absorb(cell_id)
outreg2 using "Results/governance/cgeo_models.doc", append noni addtext("Year FEs", Y, ///
	"Grid cell FEs", Y, "Lin. Time Trends by Prov.", Y) keep(project_count c.project_count#c.n_memorials)

* Seila Annual Report models

gen governance = councilors_per_vill
reghdfe ntl c.project_count##c.governance i.year c.year#i.province_number, ///
	cluster(commune_number year) absorb(cell_id)
outreg2 using "Results/governance/seila_gov_models.doc", replace noni addtext("Year FEs", Y, ///
	"Grid cell FEs", Y, "Lin. Time Trends by Prov.", Y) keep(project_count governance ///
	c.project_count#c.governance) ctitle("CC Members per Village")
reghdfe ntl c.(trt1 trt2_4 trt5_9 trt10_)##c.governance i.year c.year#i.province_number, ///
	cluster(commune_number year) absorb(cell_id)
outreg2 using "Results/governance/seila_gov_models.doc", append noni addtext("Year FEs", Y, ///
	"Grid cell FEs", Y, "Lin. Time Trends by Prov.", Y) keep(trt1 trt2_4 trt5_9 trt10_  ///
	gov c.trt1#c.governance c.trt2_4#c.governance c.trt5_9#c.governance c.trt10_#c.governance)

replace governance = pct_new_cc_mem_prev_served_2002
reghdfe ntl c.project_count##c.governance i.year c.year#i.province_number, ///
	cluster(commune_number year) absorb(cell_id)
outreg2 using "Results/governance/seila_gov_models.doc", append noni addtext("Year FEs", Y, ///
	"Grid cell FEs", Y, "Lin. Time Trends by Prov.", Y) keep(project_count governance ///
	c.project_count#c.governance) ctitle("% CC Members Prev. Unelected")
reghdfe ntl c.(trt1 trt2_4 trt5_9 trt10_)##c.governance i.year c.year#i.province_number, ///
	cluster(commune_number year) absorb(cell_id)
outreg2 using "Results/governance/seila_gov_models.doc", append noni addtext("Year FEs", Y, ///
	"Grid cell FEs", Y, "Lin. Time Trends by Prov.", Y) keep(trt1 trt2_4 trt5_9 trt10_  ///
	gov c.trt1#c.governance c.trt2_4#c.governance c.trt5_9#c.governance c.trt10_#c.governance)

replace governance = n_excom_staff_2003
reghdfe ntl c.project_count##c.governance i.year c.year#i.province_number, ///
	cluster(commune_number year) absorb(cell_id)
outreg2 using "Results/governance/seila_gov_models.doc", append noni addtext("Year FEs", Y, ///
	"Grid cell FEs", Y, "Lin. Time Trends by Prov.", Y) keep(project_count governance c.project_count#c.governance) ///
	ctitle("Total ExCom Staff")

replace governance = cs_council_pct_women_2002
reghdfe ntl c.project_count##c.governance i.year c.year#i.province_number, ///
	cluster(commune_number year) absorb(cell_id)
outreg2 using "Results/governance/seila_gov_models.doc", append noni addtext("Year FEs", Y, ///
	"Grid cell FEs", Y, "Lin. Time Trends by Prov.", Y) keep(project_count governance c.project_count#c.governance) ///
	ctitle("% Women in Councils 02")

replace governance = cs_council_pct_women_2003
reghdfe ntl c.project_count##c.governance i.year c.year#i.province_number, ///
	cluster(commune_number year) absorb(cell_id)
outreg2 using "Results/governance/seila_gov_models.doc", append noni addtext("Year FEs", Y, ///
	"Grid cell FEs", Y, "Lin. Time Trends by Prov.", Y) keep(project_count governance c.project_count#c.governance) ///
	ctitle("% Women in Councils 03")
	
replace governance = comm_priorities_funded_02
reghdfe ntl c.project_count##c.governance i.year c.year#i.province_number, ///
	cluster(commune_number year) absorb(cell_id)
outreg2 using "Results/governance/seila_gov_models.doc", append noni addtext("Year FEs", Y, ///
	"Grid cell FEs", Y, "Lin. Time Trends by Prov.", Y) keep(project_count governance c.project_count#c.governance) ///
	ctitle("% Priorities Funded 02")

replace governance = comm_priorities_funded_03
reghdfe ntl c.project_count##c.governance i.year c.year#i.province_number, ///
	cluster(commune_number year) absorb(cell_id)
outreg2 using "Results/governance/seila_gov_models.doc", append noni addtext("Year FEs", Y, ///
	"Grid cell FEs", Y, "Lin. Time Trends by Prov.", Y) keep(project_count governance c.project_count#c.governance) ///
	ctitle("% Priorities Funded 03")
	
* try 2 

reghdfe ntl c.project_count##c.councilors_per_vill i.year c.year#i.province_number, ///
	cluster(commune_number year) absorb(cell_id)
outreg2 using "Results/governance/seila_gov_models.doc", replace noni addtext("Year FEs", Y, ///
	"Grid cell FEs", Y, "Lin. Time Trends by Prov.", Y) keep(project_count councilors_per_vill ///
	c.project_count#c.councilors_per_vill)
reghdfe ntl c.(trt1 trt2_4 trt5_9 trt10_)##c.councilors_per_vill i.year c.year#i.province_number, ///
	cluster(commune_number year) absorb(cell_id)
outreg2 using "Results/governance/seila_gov_models.doc", append noni addtext("Year FEs", Y, ///
	"Grid cell FEs", Y, "Lin. Time Trends by Prov.", Y) keep(trt1 trt2_4 trt5_9 trt10_  ///
	councilors_per_vill c.trt1#c.councilors_per_vill c.trt2_4#c.councilors_per_vill c.trt5_9#c.councilors_per_vill c.trt10_#c.councilors_per_vill)

reghdfe ntl c.project_count##c.pct_new_cc_mem_prev_served_2002 i.year c.year#i.province_number, ///
	cluster(commune_number year) absorb(cell_id)
outreg2 using "Results/governance/seila_gov_models.doc", append noni addtext("Year FEs", Y, ///
	"Grid cell FEs", Y, "Lin. Time Trends by Prov.", Y) keep(project_count pct_new_cc_mem_prev_served_2002 ///
	c.project_count#c.pct_new_cc_mem_prev_served_2002)
reghdfe ntl c.(trt1 trt2_4 trt5_9 trt10_)##c.pct_new_cc_mem_prev_served_2002 i.year c.year#i.province_number, ///
	cluster(commune_number year) absorb(cell_id)
outreg2 using "Results/governance/seila_gov_models.doc", append noni addtext("Year FEs", Y, ///
	"Grid cell FEs", Y, "Lin. Time Trends by Prov.", Y) keep(trt1 trt2_4 trt5_9 trt10_  ///
	pct_new_cc_mem_prev_served_2002 c.trt1#c.pct_new_cc_mem_prev_served_2002 c.trt2_4#c.pct_new_cc_mem_prev_served_2002 c.trt5_9#c.pct_new_cc_mem_prev_served_2002 c.trt10_#c.pct_new_cc_mem_prev_served_2002)

reghdfe ntl c.project_count##c.n_excom_staff_2003 i.year c.year#i.province_number, ///
	cluster(commune_number year) absorb(cell_id)
outreg2 using "Results/governance/seila_gov_models.doc", append noni addtext("Year FEs", Y, ///
	"Grid cell FEs", Y, "Lin. Time Trends by Prov.", Y) keep(project_count n_excom_staff_2003 c.project_count#c.n_excom_staff_2003) ///

reghdfe ntl c.project_count##c.cs_council_pct_women_2002 i.year c.year#i.province_number, ///
	cluster(commune_number year) absorb(cell_id)
outreg2 using "Results/governance/seila_gov_models.doc", append noni addtext("Year FEs", Y, ///
	"Grid cell FEs", Y, "Lin. Time Trends by Prov.", Y) keep(project_count cs_council_pct_women_2002 c.project_count#c.cs_council_pct_women_2002) ///

reghdfe ntl c.project_count##c.cs_council_pct_women_2003 i.year c.year#i.province_number, ///
	cluster(commune_number year) absorb(cell_id)
outreg2 using "Results/governance/seila_gov_models.doc", append noni addtext("Year FEs", Y, ///
	"Grid cell FEs", Y, "Lin. Time Trends by Prov.", Y) keep(project_count cs_council_pct_women_2003 c.project_count#c.cs_council_pct_women_2003) ///
	
reghdfe ntl c.project_count##c.comm_priorities_funded_02 i.year c.year#i.province_number, ///
	cluster(commune_number year) absorb(cell_id)
outreg2 using "Results/governance/seila_gov_models.doc", append noni addtext("Year FEs", Y, ///
	"Grid cell FEs", Y, "Lin. Time Trends by Prov.", Y) keep(project_count comm_priorities_funded_02 c.project_count#c.comm_priorities_funded_02) ///

reghdfe ntl c.project_count##c.comm_priorities_funded_03 i.year c.year#i.province_number, ///
	cluster(commune_number year) absorb(cell_id)
outreg2 using "Results/governance/seila_gov_models.doc", append noni addtext("Year FEs", Y, ///
	"Grid cell FEs", Y, "Lin. Time Trends by Prov.", Y) keep(project_count comm_priorities_funded_03 c.project_count#c.comm_priorities_funded_03) ///


***

* PID bidding/unit cost measures

reghdfe ntl c.project_count##c.n_bids i.year c.year##i.province_number if year >=2003, cluster(commune_number year) absorb(cell_id)
outreg2 using "Results/governance/bid_UC_models.doc", replace noni addtext("Year FEs", Y, ///
	"Grid cell FEs", Y, "Lin. Time Trends by Prov.", Y) keep(project_count c.project_count#c.n_bids)
reghdfe ntl c.(trt1 trt2_4 trt5_9 trt10_)##c.n_bids i.year c.year#i.province_number if year >=2003, cluster(commune_number year) absorb(cell_id)
outreg2 using "Results/governance/bid_UC_models.doc", append noni addtext("Year FEs", Y, ///
	"Grid cell FEs", Y, "Lin. Time Trends by Prov.", Y) keep(trt1 trt2_4 trt5_9 trt10_ c.trt1#c.n_bids ///
	c.trt2_4#c.n_bids c.trt5_9#c.n_bids c.trt10_#c.n_bids)
reghdfe ntl c.project_count##c.pct_comp_bids i.year c.year##i.province_number if year >=2003, cluster(commune_number year) absorb(cell_id)
outreg2 using "Results/governance/bid_UC_models.doc", append noni addtext("Year FEs", Y, ///
	"Grid cell FEs", Y, "Lin. Time Trends by Prov.", Y) keep(project_count c.project_count#c.pct_comp_bids)
reghdfe ntl c.(trt1 trt2_4 trt5_9 trt10_)##c.pct_comp_bids i.year c.year#i.province_number if year >=2003, cluster(commune_number year) absorb(cell_id)
outreg2 using "Results/governance/bid_UC_models.doc", append noni addtext("Year FEs", Y, ///
	"Grid cell FEs", Y, "Lin. Time Trends by Prov.", Y) keep(trt1 trt2_4 trt5_9 trt10_ c.trt1#c.pct_comp_bids ///
	c.trt2_4#c.pct_comp_bids c.trt5_9#c.pct_comp_bids c.trt10_#c.pct_comp_bids)
	
reghdfe ntl c.project_count##c.unit_cost i.year c.year##i.province_number if year >= 2003, cluster(commune_number year) absorb(cell_id)
outreg2 using "Results/governance/bid_UC_models.doc", append noni addtext("Year FEs", Y, ///
	"Grid cell FEs", Y, "Lin. Time Trends by Prov.", Y) keep(project_count c.project_count#c.unit_cost)
reghdfe ntl c.(trt1 trt2_4 trt5_9 trt10_)##c.unit_cost i.year c.year#i.province_number if year >= 2003, cluster(commune_number year) absorb(cell_id)
outreg2 using "Results/governance/bid_UC_models.doc", append noni addtext("Year FEs", Y, ///
	"Grid cell FEs", Y, "Lin. Time Trends by Prov.", Y) keep(trt1 trt2_4 trt5_9 trt10_ c.trt1#c.unit_cost ///
	c.trt2_4#c.unit_cost c.trt5_9#c.unit_cost c.trt10_#c.unit_cost)
reghdfe ntl c.project_count##c.uc_dummy i.year c.year##i.province_number if year >= 2003, cluster(commune_number year) absorb(cell_id)
outreg2 using "Results/governance/bid_UC_models.doc", append noni addtext("Year FEs", Y, ///
	"Grid cell FEs", Y, "Lin. Time Trends by Prov.", Y) keep(project_count c.project_count#c.uc_dummy)
reghdfe ntl c.(trt1 trt2_4 trt5_9 trt10_)##c.uc_dummy i.year c.year#i.province_number if year >= 2003, cluster(commune_number year) absorb(cell_id)
outreg2 using "Results/governance/bid_UC_models.doc", append noni addtext("Year FEs", Y, ///
	"Grid cell FEs", Y, "Lin. Time Trends by Prov.", Y) keep(trt1 trt2_4 trt5_9 trt10_ c.trt1#c.uc_dummy ///
	c.trt2_4#c.uc_dummy c.trt5_9#c.uc_dummy c.trt10_#c.uc_dummy)
	
***

* correlations

gen baseline_ntl = ntl if year==2002

corr n_burials n_bombings n_prisons n_memorials baseline_ntl
pwcorr n_burials n_bombings n_prisons n_memorials baseline_ntl

corr burial_dummy bombing_dummy prison_dummy memorial_dummy unit_cost uc_dummy n_bids pct_comp_bids baseline_ntl
pwcorr burial_dummy bombing_dummy prison_dummy memorial_dummy unit_cost uc_dummy n_bids pct_comp_bids baseline_ntl

pwcorr n_bids pct_comp_bids unit_cost uc_dummy


***

* ntl pre-trend regressions
gen earliest_end_date = intra_cell_earliest_enddate if intra_cell_earliest_enddate<border_cell_earliest_enddate
replace earliest_end_date = border_cell_earliest_enddate if intra_cell_earliest_enddate>border_cell_earliest_enddate

* using trends
reg earliest_end ntlpre_9202 i.province_number if year==2002
reg intra_cell_earliest_enddate ntlpre_9202 i.province_number if year==2002
gen time_to_trt = year - earliest_end_date
qui sum time_to_trt, d
loc min = `r(min)'
loc max = `r(max)'
egen time_to_trt_p = cut(time_to_trt), at(-20(1)20)

reghdfe earliest_end ntlpre_9202 if year==2002, absorb (commune_number)
levelsof time_to_trt_p, loc(levels) sep()

foreach l of local levels{
	local j = `l' + 50
	local label `"`label' `j' "`l'" "'
	}

* using ntl_dummy
reghdfe earliest_end ntl_dummy if year==2002, absorb (commune_number)
reghdfe earliest_end ntl_dummy if year==2002 & ntl_lit_pre92==0, absorb (commune_number)	

cap la drop time_to_trt_p `label'
la def time_to_trt_p `label', replace

replace time_to_trt_p = time_to_trt_p + 50
la values time_to_trt_p time_to_trt_p

reghdfe ntl i.time_to_trt_p i.year, cluster(commune_number year) absorb(cell_id)
outreg2 using "Report/time_to_trt/NTL", replace excel ci

***

cd "Results/count_treatment"
local txtfiles: dir . files "ntl_continuous.doc"
foreach txt in `txtfiles' {
    erase `"`txt'"'
}
