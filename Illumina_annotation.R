##Annotation plotting functions

plotucsc <-function(ucsc_isl,chromy,start,end){
  ##Check for UCSC Island
  in_ucscisl=ucsc_isl[( (ucsc_isl$X.chrom==chromy)& ( ((ucsc_isl$chromStart>start)&(ucsc_isl$chromStart<end))|((ucsc_isl$chromEnd>start)&(ucsc_isl$chromEnd<end)))),]
  
  ##Plot UCSC Island
  if (nrow(in_ucscisl)>0) {
    for(j in 1:nrow(in_ucscisl)){
      ##cat("Island in ", i, "\n")
      isl_start=in_ucscisl$chromStart[j]
      isl_end=in_ucscisl$chromEnd[j]
      ##Setting the color is a bit tricky - we want it to be transparent, and orange, in this case
      ##To figure out the hex use rgb(t(col2rgb("orange")), maxColorValue=255, alpha=255*.33)
      polygon(c(isl_start,isl_end,isl_end,isl_start),c(-5,-5,5,5),col="#FFA50054", border=NA)
    }
  }
}

plothmm <-function(hmm_isl, chromy, start, end){
  ##Check for HMM Island
  in_hmmisl=hmm_isl[( (hmm_isl$chr==chromy)& ( ((hmm_isl$start>start)&(hmm_isl$start<end))|((hmm_isl$end>start)&(hmm_isl$end<end)))),]
  
  ##plot HMM Island
  if (nrow(in_hmmisl)>0) {
    for(j in 1:nrow(in_hmmisl)){
      ##cat("Island in ", i, "\n")
      isl_start=in_hmmisl$start[j]
      isl_end=in_hmmisl$end[j]
      
      polygon(c(isl_start,isl_end,isl_end,isl_start),c(0,0,0.0375,0.0375),density=10,col="red",angle=-45)
    }
  }
}

cpgsrug <- function(chromy, start, end) {
  ##Get the chromosome sequence
  seq <- Hsapiens[[chromy]]
  ##cat("Plot CPGDens ",chromy, start, end)
  ##Subset the sequence
  subseq <- subseq(seq,start=start,end=end)
  ##Find CpGs
  cpgs=start(matchPattern("CG",subseq))+start-1

  rug(cpgs, ticksize=.03)
}


plotcpgdens <- function(chromy,start,end){
  ##Get the chromosome sequence
  seq <- Hsapiens[[chromy]]
  ##cat("Plot CPGDens ",chromy, start, end)
  ##Subset the sequence
  subseq <- subseq(seq,start=start,end=end)
  ##Find CpGs
  cpgs=start(matchPattern("CG",subseq))+start-1
  ##Create the CpG bins
  cuts=seq(start,end,8)
  ##Bin the CpGs
  scpgs=cut(cpgs,cuts,include.lowest=TRUE)
  
  x = (cuts[1:(length(cuts)-1)]+cuts[2:(length(cuts))])/2
  y = table(scpgs)/8
  SPAN=400/diff(range(x))
  d = loess(y~x,span=SPAN,degree=1)
  
  plot(x,d$fitted,type="l",ylim=c(0,0.2),xlab="",
       ylab="CpG density",xlim=c(start,end),xaxt="n")
  
  rug(cpgs)
}

plotgenes <- function(genes,chromy, start, end){
  ##For gene plotting, 
  ori=c(start,end)

  start=max(c(1,start-1e6))
  end=end+1e6
  ##Find Genes in Region
  in_genes=genes[( (genes$chrom==chromy)& ( ((genes$txStart>start)&(genes$txStart<end))|((genes$txEnd>start)&(genes$txEnd<end)))),]    
  ##Plot Genes
  plot(0,0,ylim=c(-1.5,1.5),xlim=c(start,end),yaxt="n",ylab="Genes",
       xlab="")
  ##Label Y-axis
  axis(2,c(-1,1),c("-","+"),tick=FALSE,las=1)
  polygon(c(ori[1],ori[2],ori[2],ori[1]),c(-1.5, -1.5, 1.5, 1.5),col="green")

  ##Add dotted line
  abline(h=0,lty=3)

  #Plot each gene
  if(nrow(in_genes)>0){
    for(j in 1:nrow(in_genes)){
      TS = in_genes$txStart[j]
      TE = in_genes$txEnd[j]
      CS = in_genes$cdsStart[j]
      CE = in_genes$cdsEnd[j]
      ES = as.numeric(strsplit(in_genes$exonStarts[j],",")[[1]])
      EE = as.numeric(strsplit(in_genes$exonEnds[j],",")[[1]])
      Exons=cbind(ES,EE)
      Strand=ifelse(in_genes$strand[j]=="+",1,-1)
      polygon(c(TS,TE,TE,TS),Strand/2+c(-0.4,-0.4,0.4,0.4),density=0,col=j)
      polygon(c(CS,CE,CE,CS),Strand/2+c(-0.25,-0.25,0.25,0.25),density=0,
              col=j) 
      apply(Exons,1,function(x) polygon(c(x[1],x[2],x[2],x[1]),
                                        Strand/2+c(-0.2,-0.2,0.2,0.2),col=j))     
      text((max(start,TS)+min(end,TE))/2,Strand*0.9,in_genes$X.geneName[j],cex=1,
           pos=Strand+2)
      ##Strand +2 works cuase -1 turns into 1 (below) and 1 
      ##turns into 3 (above)
    }
  }

}
