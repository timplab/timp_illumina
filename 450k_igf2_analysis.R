codedir=getwd()
source(paste(codedir,"450k_sum_stats.R", sep="/"))

##Put us in the right dir for output
setwd("~/Data/Infinium/011412_analysis/")

##Experimental file location
expdatapath="/thumper2/feinbergLab/core/arrays/illumina/"

##Current 450k package name
##Kasper says ignore warnings about "contains no R code"
##This is the local(expanded) version of minfi
library(minfi)
library(minfiLocal)
library(rtracklayer)

##This will list commands
##ls("package:minfi")


##Read in plates
plates=read.450k.sheet(expdatapath, "IL00[25789]_v2.csv$", recursive=T)
plates=rbind(plates, read.450k.sheet(expdatapath, "IL010_v2.csv$", recursive=T))

##Read in data
RGset=read.450k.exp(base=expdatapath, targets=plates)

icr.geneious=read.csv(file="h19_icr1.csv", stringsAsFactors=F)

##Skip h19
icr.geneious=icr.geneious[-1,]

icr.locs=GRanges(seqnames="chr11",
  ranges=IRanges(start=icr.geneious$Minimum, end=icr.geneious$Maximum),
  name=icr.geneious$Name)
                                     

##Ok - regions
##DMR0 ncbi36:11, 2125904-2126160 - Ito et al
##DMR0 hg19 chr11:2169328-2169584
dmr0=GRanges(seqnames="chr11", ranges=IRanges(start=2169328,
                                 end=2169584), name="dmr0")
##ICR is -2kb to -4kb of h19
h19.start=2019065
big.icr=GRanges(seqnames="chr11", ranges=IRanges(start=2019065+2000,
                                end=2019065+4000), name="icr")

##Get IGF2 gene location
##load("~/Data/Genetics/072111_blocks/gene_island.rda")
##igf2.gene=reduce(refseq.genes[values(refseq.genes)$gene.name=="IGF2"])
##igf2.reg=igf2.gene
##values(igf2.reg)=NULL
##values(igf2.reg)$id="IGF2"

loi.reg=c(dmr0, icr.locs, big.icr)



##Get out just cancer samples
tis.samp=(pData(RGset)$Tissue %in% c("colon", "lung", "breast", "thyroid",
  "kidney", "pancreas"))
##Alternatively pData(RGset) gets out the plates variable again

tis.data=preprocessMinfi(RGset[,(tis.samp)])

load("~/Data/Infinium/121311_analysis/probe_obj_final.rda")

##Add something indexing gprobes vs actual data order
values(gprobes)$minfi.idx=match(values(gprobes)$name,
                 rownames(getM(tis.data[,1])))

##Obtain those probes
icr.probes=values(gprobes)$minfi.idx[(gprobes %in% loi.reg)]

##Chromosome 11 probes
chr11.probes=gprobes[as.character(seqnames(gprobes))=="chr11"]
export.bed(chr11.probes, "chr11_450k.bed")

##Probes with no problems SNPs
good.probes=values(gprobes)$minfi.idx[(!values(gprobes)$sbe.snp.boo)&
  (!values(gprobes)$boo.snps)&(values(gprobes)$single.hyb)]

pheno=c("metastasis", "cancer", "adenoma", "hyperplastic", "normal")
tissue=c("breast", "colon", "kidney", "lung", "pancreas", "thyroid")

## ok - for dot plot, need to set y values to the different tissue types, and add jitter 
tissue.y=match(pData(tis.data)$Tissue,tissue)*6-
  (match(pData(tis.data)$Phenotype,pheno))

##Coloring for dots tumor normal
colly=c("red", "orange", "green", "blue", "purple")

##ybig=max(tissue.y)+1

tissue.y=jitter(tissue.y)

tis.beta=getBeta(tis.data)

pdf("Plots/icr1.pdf")


##Get methyl and unmethyl signal
for (i in icr.probes) {

  plot(tis.beta[i,], tissue.y,
       bg=as.character(colly[match(pData(tis.data)$Phenotype,pheno)]),
       pch=21, xlim=c(0,1),
       main=rownames(tis.beta)[i],
       ##ylim=c(0,ybig),
       yaxt="n", ylab="")
  
  axis(2, at=6*(1:6)-3,
       labels=tissue)
  
}
dev.off()


##Just Icr.probes
icr.data=tis.data[icr.probes,]

##Number of samples
samp.tab=tis.pheno(pData(tis.data))

probe.tests=logical()

##Do per probe tests for each tissue
for (i in 1:dim(samp.tab)[1]) {

  norm.stat=per.stats(icr.data, tissue=rownames(samp.tab)[i], pheno="normal")
  canc.stat=per.stats(icr.data, tissue=rownames(samp.tab)[i], pheno="cancer")
  
  sig.var=canc.stat$vars>(norm.stat$vars*qf(.95, samp.tab[i,4], samp.tab[i,1]))
  probe.tests=cbind(probe.tests, sig.var)
  
  colnames(probe.tests)[i]=rownames(samp.tab)[i]

}
  
rownames(probe.tests)=rownames(tis.beta[icr.probes,])

rownames(tis.beta[icr.probes[icr.probes %in% good.probes],])
