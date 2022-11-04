/*-----------------------------------------------------------------------------
Data Preparation
By: Angelo Santos

This do file prepares the dataset to be used to create summary statistics
and regression tables

-----------------------------------------------------------------------------*/

* Set source data directory
global datasource "/Users/angelosantos/Library/CloudStorage/OneDrive-GeorgeMasonUniversity-O365Production/PUBP 833/Datasets/DHS Philippines 2017/PHBR71DT"
global processed "/Users/angelosantos/Library/CloudStorage/OneDrive-GeorgeMasonUniversity-O365Production/PUBP 833/Datasets/Processed"


* Load the dataset
use "$datasource/PHBR71FL.DTA", clear
generate wgt = v005/1000000

* Set the data as a survey
svyset v001 [pweight=wgt], strata(v022) || caseid // actually no need to specify secondary sampling unit


* To simplify, keep only children with birth weight data. Set birth weights = 9996 or 9998 to missing
replace m19 = . if inlist(m19, 9996, 9998) 
keep if !missing(m19)

* Identify the provinces that were hit by the drought shock
gen dryspell = inlist(sprov, 11, 55, 49, 69, 71, 58, 51, 12, 82, 2, 3)
gen drought = inlist(sprov, 53, 46, 61, 72, 73, 83, 13, 18, 35, 36, 42, 43, 23, 24, 63, 47, 80, 65, 67, 7, 38, 66, 70)
gen dryspell_drought = (dryspell == 1) | drought == 1

gen rural = v102 == 2
gen infant_mortality = b7 == 0
gen agricultural = v705 == 7
xtile decile = v191 [aw = v005], n(10)

gen subsistence_farmers = agricultural ==1 & decile == 1

* Calculate incidence of low birthweight
gen lowbw = (m19<2500)
gen vlowbw = (m19<1500)
bys dryspell_drought: table b2 [aw = v005], c(mean lowbw mean vlowbw)
bys dryspell_drought: table b1 if b2 == 2015 [aw = v005], c(mean lowbw mean vlowbw)

* Generate the date variables

	* Date of birth
	gen dob = mdy(b1, b17, b2)
	format dob %td
	gen mob = mofd(dob)
	format mob %tm
	
	* Date of conception
	gen m_doc = mofd(dob) - b20
	gen d_doc = dofm(m_doc)
	gen y_conception = year(d_doc)
	format m_doc %tm
	format d_doc %td


	* End of drought
	gen end_of_drought = mdy(07, 31, 2016)
	format end_of_drought %td
	
	gen m_eod = mofd(end_of_drought)
	format m_eod %tm
	
	* Start of drought
	gen start_of_drought = mdy(02, 01, 2015)
	format start_of_drought %td
	
	gen m_sod = mofd(start_of_drought)
	format m_sod %tm
	
	* Calculate distances
	
	gen run_helper = mdy(1,1,2012)
	gen run_dob = dob - run_helper //Date of birth runner
	gen run_sod = start_of_drought - run_helper //Start of drought runner
	gen run_eod = end_of_drought - run_helper
	gen run_doc = d_doc - run_helper
	
	gen inutero_exposed = inrange(run_doc, 1127, 1673) | inrange(run_doc, 1127, 1673)
	gen inutero_exposed_6 = inrange(run_doc, 1127, 1307) | inrange(run_doc, 1127, 1307)
	
	* Generate duration of exposure
	
	gen duration = 0
	replace duration = run_dob - run_sod if run_doc < 1127 & inrange(run_dob, 1127, 1673)
	replace duration = run_dob - run_doc if inrange(run_doc, 1127, 1673) & inrange(run_dob, 1127, 1673)
	replace duration = run_eod - run_doc if inrange(run_doc, 1127, 1673) & run_dob > 1673
	assert duration>=0
	
	* Migrants to drought provinces
	gen moved_after_drought = inrange(v104, 0, 1)
	gen moved_from_dryspell = inlist(s104p, 53, 46, 61, 72, 73, 83, 13, 18, 35, 36, 42, 43, 23, 24, 63, 47, 80, 65, 67, 7, 38, 66, 70) & moved_after_drought == 1
	gen moved_from_dryspell_drought = (moved_after_drought == 1) | (moved_after_drought == 1)

	* Recode the treatment variable
	replace dryspell_drought = 0 if moved_after_drought == 1 & dryspell_drought == 1
	replace dryspell_drought = 1 if moved_after_drought == 1 & moved_from_dryspell_drought == 1
	
	replace drought = 0 if moved_after_drought == 1 & drought == 1
	replace drought = 1 if moved_after_drought == 1 & moved_after_drought == 1

	
	* Generate control variables
	
	gen married = (v501 == 1)
	xtile wq = v191 [aw = v005], n(5)
	gen bottom20 = wq == 1
	gen top20 = wq == 5
	gen preterm = b20<9
	gen hs_educ = inrange(v106, 2, 3)
	gen died = b7 != .
	gen male = b4 == 1
	gen birthcohort = b2
	
	* Keep only children / mothers that were on the same place of residence since the drought started
	keep if v104 >=3 & !missing(v104)
	
	* Drop the preterm births
	* drop if preterm == 1 | died == 1
	
	* keep only the variables we need
	keep married preterm hs_educ vlowbw lowbw m19 wgt male birthcohort wq rural m19a v001 bord birthcohort sprov
	
		* Merge with the geographic dataset
	*shp2dta using "/Users/angelosantos/Library/CloudStorage/OneDrive-GeorgeMasonUniversity-O365Production/PUBP 833/Datasets/DHS Philippines 2017/PH_2017_DHS_10242022_224_125323/PHGE71FL/PHGE71FL.shp", database("$processed/clusterdata") coordinates("$processed/coordinates")
	gen _ID = v001
	
	merge m:1 _ID using "$processed/clusterdata.dta", keep(master match)
	
	
	save "$processed/ndhs_birthmodule.dta", replace
