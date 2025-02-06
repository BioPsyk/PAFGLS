# Run example tut
library(devtools)
library(data.table)
library(kinship2)
library(PAFGLS)

# run generate example data and kinship first
# continuous version
df$t1 <- qnorm(df$k_p)
h2 <- 0.3
df <- as.data.table(df)
kinship_df <- as.data.table(kinship_df)

out_cont <- FGLS_wrapper_continuous(df$id[1:10000],
            K=kinship_df[,.(i=id1,j=id2,x=relatedness/2)],
            pheno=df[!is.na(dead)&!is.na(t1),.(id,aff=dead)],
            h2=h2,
            t1=df[!is.na(dead)&!is.na(t1)]$t1,
            method="PAFGRS")

# bianary version
df$ind_dx <- 0
df[df$dead==1 & df$age_dx < 50,]$ind_dx <- 1
df$k_pop <- 0.4
df[df$sex=="K",]$k_pop <- 0.3

df$w <- ifelse(df$ind_dx==0,df$k_p/df$k_pop,1)
df$thr <- qnorm(1-df$k_pop)

out_bin <- FGLS_wrapper_binary(df$id[1:10000],
            K=kinship_df[,.(i=id1,j=id2,x=relatedness/2)],
            pheno=df[!is.na(ind_dx)&!is.na(w),.(id,aff=ind_dx)],
            h2=h2,
            thr=df[!is.na(ind_dx)&!is.na(w)]$thr,
            w=df[!is.na(ind_dx)&!is.na(w)]$w,
            method="PAFGRS")

