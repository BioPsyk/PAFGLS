# PA-FGLS

## Download package

``` r
# Make sure to clone this repository
git clone git@github.com:BioPsyk/PAFGLS.git

# Enter the cloned repository
cd PAFGLS/PAFGLS-master

# Start R and run
library(devtools)
devtools::install()
library(PAFGLS)
```
### Install dependecies
If needed prior to above installation, you can install the dependencies using a conda environment.
```
conda env create docker/env.yaml
conda activate fgls 
```

## Running PAFGLS
For running PAFGLS, there is the option to either run longvity as a continouous or a binary trait. It is also possible to include an age censoring threshold, in which the individuals who have died before the specified threshold, will be censored. 

Data files needed for both binary and continuous traits of longevity:
1. Kinship dataframe - data structure on how related individuals are in your data sample. Will be a three column dataframe, that includes i (id number of relative 1), j (id number of relative 2), and relatedness - x (the rate of relatedness between the relative 1 and 2). 

Example of kinship dataframe:
```
i j x
001 011 0.25 
001 012 0.25
002 011 0.125
```
2. Lifetable - When computing the phenotype dataframe, it is good to use a lifetable that describes the life expactancy for the population, stratified by birthyear and sex. 

CI curves are downloaded from: https://statbank.dk/statbank5a/default.asp?w=1792
Goes from ages 0-99, with the columns representing birth cohorts. 
![alt text](image-1.png)

### Binary longevity trait
Firstly, you have to decided the value for some variables for the phenotype defintion:
1. Age threshold - that defines which value should divided cases and controls. Ex. 90 yrs old
2. Censoring threshold - the individuals who died prior to this threshold will be censored in analysis (if you do not wish to include censoring, you set this variable to zero). Ex. 5 yrs old, meaning deaths occuring prior to 5 yrs old will be censored in analysis.
3. Heritability - input an estimate of heritability of the measured trait. Ex. 0.5, meaning 50%  

Using these variables you will compute a phenotype dataframe that includes the columns: id, aff, k_p, k_pop, thr, w.
1. id = the identification number of the relative.
2. aff = the affektiv status of the relative as a binary variable, 0 or 1. The phenotype is reversed for computational purposes so aff = 1 if relative's age is below the age threshold, and aff = 0 if relative's age is above the age threshold.
3. k_p = a metric from 0 - 1 that describes each individuals accumulated risk for the event (death), as determined by the lifetable.
4. k_pop = a metrics from 0 - 1 that describes the population risk of event (death), given the age threshold, as determined by the lifetable.
5. thr = qnorm(1-k_pop), which is the threshold that will be used for each relative.
6. w = k_p/k_pop, the proportion of risk experienced by each relative.

example of phenotype dataframe for binary trait:
```
id aff thr w 
001 0 -0.891 0.007
002 0 -0.559 0.713 
003 1 -1.253 1
004 0 -1.229 0
```
(individual 004 is censored in this data example)

![alt text](image.png)

Four add-on rules apply for the w variable:
1. If a relative is considered a case, then set w = 1.
2. If w > 1, then set w = 1.
3. If individual is dead or alive above the age threshold then w = 1.
4. If you wish to censor an individual, w = 0 and aff = 0. The combination is registered as an NA by the algorithm.

In addition, you will supply the wrapper function with a list of you proband ids (not relatives, but the people you want the score computed for), and you estimate of heritability (h2).

You run the script by calling the following code, if we assume that our list of proband ids is called "proband_ids", our kinship matrix is called "K" and our phenotype dataframe is called "pheno":
```
output <- FGLS_wrapper_binary(proband_ids,K,pheno,method="PAFGRS",h2,w=pheno$w,thr=pheno$thr)
```

### Continuous longevity trait

Firstly, you have to decided the value for some variables for the phenotype definition:
1. Censoring threshold - the individuals who died prior to this threshold will be censored in analysis (if you do not wish to include censoring, you set this variable to zero). Ex. 5 yrs old, meaning deaths occuring prior to 5 yrs old will be censored in analysis.
2. Heritability - input an estimate of heritability of the measured trait. Ex. 0.5, meaning 50% 

Using these variables you will compute a phenotype dataframe that includes the columns: id, aff, t1
1. id = the identification number of the relative.
2. aff = dead or alive as a binary variable.
3. t1 = qnorm(k_p), and set any value of 0 to 0.001 and 1 to 0.999 (adding more decimals will create NAs; k_p = a metric from 0 - 1 that describes each individuals accumulated risk for the event (death), as determined by the lifetable)

You censor individuals by setting aff and t1 to 0.

example of phenotype dataframe for continuous trait:
```
id aff t1
001 0 0.345
002 0 -2.611
003 1 -1.758
004 0 0
```
(individual 004 is censored in this data example)

We are using a two-threshold model ...

![alt text](image-2.png)

Additionally you will supply the wrapper function with a list of your proband ids (not relatives, but the people you want the score computed for), and you estimate of heritability (h2).

You run the script by calling the following code, if we assume that our list of proband ids is called "proband_ids", our kinship matrix is called "K" and our phenotype dataframe is called "pheno":
```
output <- FGLS_wrapper_continuous(proband_ids,K,pheno,method="PAFGRS",h2,t1=pheno$t1)
```

### Accuracy

You can get a deregression value ('r') for each individual by changing the method to "accuracy" instead of "PAFGRS". This can be used to deregress your PAFGRS postM scores, to accomodate for differences in family size for the probands. 

### Output

For both continuous and binary phenotype analysis you will get an output dataframe that includes columns: id, postM, postVar, n_rels.
1. id = identification number of proband
2. postM = posterior mean of score 
3. postVar = posterior variance of score
4. n_rels = number of relatives that the score was computed from for that proband

For the accuracy function you will get the following output:
1. id = identification number of proband
2. r = accuracy score
3. n_rels = number of relatives that the score was computed from for that proband

