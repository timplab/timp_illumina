##This code takes aligned probes, find the sbe, and figures out snp status
##As well as blocks, etc.


#Load libraries in
library(Biostrings)
library(BSgenome)
library(BSgenome.Hsapiens.UCSC.hg19)
library(GenomicRanges)

source("~/Code/timp_genetics/region_tools.R")

##Get chromosome names
seqnames <- seqnames(Hsapiens)

chr.list=c("chr1", "chr2", "chr3", "chr4", "chr5", "chr6", "chr7", "chr8",
  "chr9", "chr10", "chr11", "chr12", "chr13", "chr14", "chr15", "chr16", "chr17", "chr18", "chr19",
  "chr20", "chr21", "chr22", "chrX", "chrY")


setwd("~/Dropbox/Data/Genetics/Infinium/121311_analysis")
load("tmp.rda")


load("remap_f.rda")


##First find the probes which have one and only one match
num.remap=table(values(remap.probe)$ori.index)
values(gprobes)$single.hyb=num.remap==1

multmatch=num.remap>1
values(gprobes)$map.idx=match(values(gprobes)$name, values(remap.probe)$name)

for (j in which(multmatch)) {
  mapped.probes=which(values(remap.probe)$ori.index==j)
  ##Nearest currently broken for GRanges (known bug, doesn't pick up overlaps
  ##This is a fix
  mapped.probes=mapped.probes[as.logical(seqnames(gprobes[j])==seqnames(remap.probe[mapped.probes]))]
  intended=nearest(ranges(gprobes[j]), ranges(remap.probe[mapped.probes]))
  values(gprobes)$map.idx[j]=mapped.probes[intended]
}

gprobes=gprobes[order(as.numeric(match(seqnames(gprobes), chr.list)), start(gprobes))]

##Convenience idx
idx=values(gprobes)$map.idx


##Reorder reamp probe to match gprobes
remap.probe=remap.probe[idx]

##Make Single base extension GRanges
sbe=flank(remap.probe,1)
g.site=flank(remap.probe,2)
g.site=psetdiff(g.site, sbe)
values(g.site)=values(sbe)


if (file.exists("relevantsnp.rda")) {
  load("relevantsnp.rda")
} else {
  load("~/LData/Genetics/121511_dbSNP/snp135_ucsc.rda")
  ##Get just snps which are relevant to these probes and their
  ##Single base extentions
  int.area=resize(remap.probe, width=width(remap.probe)+2, fix="end")
  snp.list=subsetByOverlaps(snp.list, int.area)
  save(file="relevantsnp.rda", list="snp.list")
}





##Init sbe snp fields
values(sbe)$sbe.snp.boo=logical(length(sbe))
values(sbe)$sbe.snp.name=character(length(sbe))
values(sbe)$sbe.snp.het=numeric(length(sbe))
##Match SBE to SNP
sbe.snp=findOverlaps(sbe, snp.list, select="first")
snp.present=!is.na(sbe.snp)
sbe.snp=sbe.snp[snp.present]
##Use match
values(sbe[snp.present])$sbe.snp.boo=T
values(sbe[snp.present])$sbe.snp.name=
  as.character(values(snp.list[sbe.snp])$name)
values(sbe[snp.present])$sbe.snp.het=
  values(snp.list[sbe.snp])$avHet

##Init g.site snp fields
values(g.site)$g.site.snp.boo=logical(length(g.site))
values(g.site)$g.site.snp.name=character(length(g.site))
values(g.site)$g.site.snp.het=numeric(length(g.site))
##Match G.SITE to SNP
g.site.snp=findOverlaps(g.site, snp.list, select="first")
snp.present=!is.na(g.site.snp)
g.site.snp=g.site.snp[snp.present]
##Use match
values(g.site[snp.present])$g.site.snp.boo=T
values(g.site[snp.present])$g.site.snp.name=
  as.character(values(snp.list[g.site.snp])$name)
values(g.site[snp.present])$g.site.snp.het=
  values(snp.list[g.site.snp])$avHet


##Repeat for whole probe 

values(remap.probe)$num.snps=numeric(length(remap.probe))
values(remap.probe)$snp.name=character(length(remap.probe))
values(remap.probe)$snp.dist=numeric(length(remap.probe))
values(remap.probe)$snp.het=numeric(length(remap.probe))


##Added to distinguish probes w/o snps - their distance to snp is -1 by default
values(remap.probe)$snp.dist=-1

##Match REMAP.PROBE to SNP
##By using first, get the one closest to the 3' end
remap.probe.snp=findOverlaps(remap.probe, snp.list, select="first")
snp.present=!is.na(remap.probe.snp)
remap.probe.snp=remap.probe.snp[snp.present]
##Use match

values(remap.probe)$num.snps=countOverlaps(remap.probe, snp.list)
values(remap.probe)$boo.snps=values(remap.probe)$num.snps>0

values(remap.probe[snp.present])$snp.name=
  as.character(values(snp.list[remap.probe.snp])$name)

##Get the start base location - use
three.prime=resize(remap.probe[snp.present],1)

values(remap.probe[snp.present])$snp.dist=
  width(pgap(three.prime, snp.list[remap.probe.snp]))

values(remap.probe[snp.present])$snp.het=
  values(snp.list[remap.probe.snp])$avHet


##Do the same, but just for snps with nonzero het score
##Have to redo because of the case of multiple snps in probe, some may not be het

values(remap.probe)$hetsnp.name=character(length(remap.probe))
values(remap.probe)$hetsnp.dist=numeric(length(remap.probe))
values(remap.probe)$hetsnp.het=numeric(length(remap.probe))

het.snp.list=snp.list[values(snp.list)$avHet>0]

##Match REMAP.PROBE to SNP
##By using first, get the one closest to the 3' end
remap.probe.hetsnp=findOverlaps(remap.probe, het.snp.list, select="first")
snp.present=!is.na(remap.probe.hetsnp)
remap.probe.hetsnp=remap.probe.hetsnp[snp.present]

##Use match

values(remap.probe)$num.hetsnps=countOverlaps(remap.probe, het.snp.list)
values(remap.probe)$boo.hetsnps=values(remap.probe)$num.hetsnps>0

values(remap.probe[snp.present])$hetsnp.name=
  as.character(values(het.snp.list[remap.probe.hetsnp])$name)

##Get the start base location - use
three.prime=resize(remap.probe[snp.present],1)

values(remap.probe)$hetsnp.dist[snp.present]=
  width(pgap(three.prime, het.snp.list[remap.probe.hetsnp]))

values(remap.probe)$hetsnp.het[snp.present]=
  values(het.snp.list)$avHet[remap.probe.hetsnp[snp.present]]


##Add SNP info to gprobes
values(gprobes)=cbind(values(gprobes), values(sbe)[,-(1:2)],
        values(remap.probe)[,-(1:2)])

##Add G Site SNP info to gprobes

values(gprobes)=cbind(values(gprobes), values(g.site))

##If type I probe, g.site is irrelvant
type.i=values(gprobes)$probe.type=="I"

values(gprobes)$g.site.snp.boo[type.i]=F
values(gprobes)$g.site.snp.name[type.i]=""
values(gprobes)$g.site.snp.het[type.i]=0



save(file="probe_obj_t0.rda", list=c("gprobes", "sbe", "remap.probe"))

load(file="probe_obj_t0.rda")

##Need to calc dist to CpG Island, dist to genes
##Load islands and genes object
load("~/Dropbox/Data/Genetics/MethSeq/072111_blocks/gene_island.rda")

##This is needed so nearest will work, seems to be an issue with the version
##Of GRanges which made the object??
##Note - no longer an issue - left in to help solve potential future issues
##refseq.genes=updateObject(refseq.genes)
##ucsc.isl=updateObject(ucsc.isl)

##Find nearest genes to each probe(including overlap)
##Because of a current problem w/ GRanges, I had to make a function
##which goes by chromosome and uses just nearest IRanges
close=g.nearest(gprobes, refseq.genes)
##close=nearest(gprobes, refseq.genes)

##Put gene name and dist to gene
values(gprobes)$nearest.gene=values(refseq.genes[close])$gene.name
values(gprobes)$dist.gene=width(pgap(ranges(gprobes),               
                 ranges(refseq.genes[close])))



##Find nearest UCSC CpG islands to each probe (including overlap)
close=g.nearest(gprobes, ucsc.isl)

##UCSC island index, and dist to ucsc isl
values(gprobes)$nearest.island.index=close
values(gprobes)$dist.island=width(pgap(ranges(gprobes),
                 ranges(ucsc.isl[close])))

##Add probe sequence
values(gprobes)$probe.seq=ill$pattern


##Get DMR info
load("~/Dropbox/Data/Genetics/MethSeq/092011_Capture/dmr_cap.rda")

##cdmrs=updateObject(cdmrs)
z=as.matrix(findOverlaps(gprobes, cdmrs.hg19))

##DMR index and boolean init
values(gprobes)$cdmr.boo=logical(length(gprobes))
values(gprobes)$cdmr.idx=numeric(length(gprobes))

values(gprobes)$cdmr.boo[z[,1]]=T
values(gprobes)$cdmr.idx[z[,1]]=z[,2]

##tdmrs=updateObject(tdmrs)
z=as.matrix(findOverlaps(gprobes, tdmrs.hg19))

##tdmrs index and boolean init
values(gprobes)$tdmr.boo=logical(length(gprobes))
values(gprobes)$tdmr.idx=numeric(length(gprobes))

values(gprobes)$tdmr.boo[z[,1]]=T
values(gprobes)$tdmr.idx[z[,1]]=z[,2]

##rdmrs=updateObject(rdmrs)
z=as.matrix(findOverlaps(gprobes, rdmrs.hg19))

##DMR index and boolean init
values(gprobes)$rdmr.boo=logical(length(gprobes))
values(gprobes)$rdmr.idx=numeric(length(gprobes))

values(gprobes)$rdmr.boo[z[,1]]=T
values(gprobes)$rdmr.idx[z[,1]]=z[,2]

##Get Block/LOCK/LAD info
load("~/Dropbox/Data/Genetics/MethSeq/072111_blocks/lg_regions2.rda")


ccancer.blocks=updateObject(ccancer.blocks)
z=as.matrix(findOverlaps(gprobes, ccancer.blocks))

##DMR index and boolean init
values(gprobes)$blocks.boo=logical(length(gprobes))
values(gprobes)$blocks.idx=numeric(length(gprobes))

values(gprobes)$blocks.boo[z[,1]]=T
values(gprobes)$blocks.idx[z[,1]]=z[,2]

locks=updateObject(locks)
z=as.matrix(findOverlaps(gprobes, locks))

##DMR index and boolean init
values(gprobes)$locks.boo=logical(length(gprobes))
values(gprobes)$locks.idx=numeric(length(gprobes))

values(gprobes)$locks.boo[z[,1]]=T
values(gprobes)$locks.idx[z[,1]]=z[,2]

datadir=("~/Code/timp_illumina/timp_illumina_data")

save(file=file.path(datadir, "probe_obj_final.rda"), compress="gzip", list=c("gprobes", "sbe", "remap.probe"))

#Checking Chris SNPs v. Winston SNPs

filedir="~/Dropbox/Data/Genetics/Infinium/071312_analysis"

x=load(file.path(filedir, "snps_chris.rda"))
snps.chris=get(x)



idx=match(rownames(snps.chris), values(remap.probe)$name)

#Check if probe locations match

z=start(remap.probe[idx])==snps.chris$PrStart

#Only the weird ch.# probes don't match up in location

z=values(gprobes[idx])$sbe.snp.boo==(snps.chris$SBEsnp_RefSeqID!="FALSE")
a=snps.chris[!z,]
b=sbe[idx[!z]]


