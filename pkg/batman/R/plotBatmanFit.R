plotBatmanFit<-function(BM, xfrom, xto, yfrom, yto, listMeta = FALSE, metaName, saveFig = TRUE, 
                        saveFigDir = BM$outputDir, prefixFig, rerun = FALSE, placeLegend = "topright", 
                        plotColour, overwriteFig = FALSE, showPlot)
{
  ## written by Dr. Jie Hao, Imperial College London
  ## plot batman metabolites fittings of NMR spectra (with down sampling)
  if (missing(BM))
    return(cat("Please input batman data list.\n"))
  
  warnDef<-options("warn")$warn
  warnRead<-options(warn = -1)
  
  ## os information
  os <- NULL
  if (missing(showPlot))
  {
    sysinf <- Sys.info()
    os <- "notlisted"
    if (!is.null(sysinf)){
      os1 <- sysinf['sysname']
      if (os1 == 'Darwin')
      {os <- "osx"}
      else if (grepl("windows", tolower(os1)))
      {os<- "win"}       
      else if (grepl("linux", tolower(os1)))
      {os<- "linux" }
    } else { ## mystery machine
      #os <- .Platform$OS.type
      if (grepl("^darwin", R.version$os))
        os <- "osx"
      if (grepl("linux-gnu", R.version$os))
        os <- "linux"
    }
  }
  
  if (!is.null(os))
  {
    if (os == 'win' || os == 'osx')
    { showPlot <- TRUE }
    else 
    { #if (os == 'linux')
      showPlot <- FALSE
      cat("\nThis operating system may not support X11, no plot will be displayed, figures in .pdf format will be saved in output folder.")
      cat("\nCheck input argument 'showPlot' for more detail.")
    }
  }
  
  pdfdev = FALSE
  ptype = "pdf"
  cex = 0.8
  cex1 = 0.5
  ns<-5
  ## if missing from and to parameters, use whole spectrum
  if (missing(xfrom))
    xfrom = min(BM$sFit[1,1],BM$sFit[nrow(BM$sFit),1])
  if (missing(xto))
    xto =  max(BM$sFit[1,1],BM$sFit[nrow(BM$sFit),1])
  if (xfrom > xto)
  {
    temp<-xfrom
    xfrom<-xto
    xto<-temp
  }
  ytoIP <- 1
  if (missing(yfrom))
    yfrom <- 0
  if (missing(yto))
  {
    ytoIP<-NULL
  } 
  pind<-which(BM$sFit[,1]<=xto & BM$sFit[,1]>=xfrom)
  if (length(pind)== 0)
    pind<-which(BM$sFit[,1]<=xfrom & BM$sFit[,1]>=xto)
  
  if (missing(plotColour))
  {
    pc1 <- rainbow(max(nrow(BM$beta)+3, 20))
    pc2 <- rainbow(3)
    plotColour<- sample(setdiff(pc1, pc2),nrow(BM$beta))
  }
  
  ## match metabolite 
  nometa<-FALSE
  m<-row.names(BM$beta)
  if (!missing(metaName))
  {
    mind<-which(tolower(m) %in% (tolower(metaName))) 
    if (length(mind)==0) {cat("No matching metabolite found...\n")}  
  } else if (missing(metaName) && listMeta) {
    mind<-1:length(m)
    nometa<-TRUE
    metaName<-"all"
  } else {
    mind<-NULL
    nometa<-TRUE
    metaName<-NULL
  }
  if (length(plotColour) >= length(mind))
    plotColour<-plotColour[mind]
  else
    stop("plotColour length smaller than metabolite names.\n")
  
  sno<-BM$specRange
  n <- 2
  metaTmplty <-ns
  metaTmplwd <-2
  
  outpdf1<-NULL
  gind<-NULL
  gapsize<-NULL
  gap<-NULL
  ## set gap for plot
  if (!is.null(BM$sFit))
  {
    x<-BM$sFit[pind,1]
    df<-abs(diff(BM$sFit[pind,1]))
    gind<-which(df>(min(df)*3))
    for (gi in 1:length(gind))
      gap<-rbind(gap, BM$sFit[pind[gind[gi]],1],BM$sFit[pind[gind[gi]+1],1])
    gap<-(sort(gap))
    lgap <- length(gap)
    gapsize<-abs(diff(gap))
    if (lgap>0)
      gapsizeodd<-gapsize[seq(1,length(gapsize),2)]
    xlim <- c(min(BM$sFit[pind,1]), max(BM$sFit[pind,1]) - gapsize[1])
    xtics <- pretty(BM$sFit[pind,1],n=(abs(diff(range(x)))%/%0.05))
    xticlab <- xtics
    lgap <- length(gap)
    lgo<-(lgap-2)/2
    if (lgap>0)  
    {
      littleones <- which(x <= gap[1])
      if (lgap > 3) 
      {
        middleones <-NULL
        for (ig in 1:lgo)
        {
          if (ig == 1)
            middleones <- list(which(x >= gap[ig*2] & x <= gap[ig*2+1]))
          else
            middleones[[ig]]<-which(x >= gap[ig*2] & x <= gap[ig*2+1])
        }                
        bigones <- which(x >= gap[lgap] )
        #lostones <- sum(c(x > gap[1] & x < gap[2],x > gap[3] & x < gap[4] ))
      } else {
        middleones <- NULL
        bigones <- which(x >= gap[2])
        #lostones <- sum(x > gap[1] & x < gap[2])
      }
      littletics <- which(xtics < gap[1])
      if (length(gapsize) > 2) 
      {
        middletics<-NULL
        maxdif<-0
        midshowat<-NULL
        midshowlab<-NULL
        middif<-NULL
        for (ig in 1:lgo)
        {
          maxdif <- maxdif + gapsizeodd[ig]
          middif<-rbind(middif, maxdif)
          middletics <- which(xtics >= gap[ig*2] & xtics <=gap[ig*2+1])
          midshowat<-c(midshowat, xtics[middletics] - maxdif)
          midshowlab<-c(midshowlab,xticlab[middletics])
        }
        maxdif<-maxdif + gapsizeodd[length(gapsizeodd)]
        xlim <- c(min(x), max(x)-maxdif)
        bigtics <- which(xtics >= gap[lgap])
        show.at <- c(xtics[littletics], midshowat, xtics[bigtics] - maxdif)
        #show.at <- c(xtics[littletics], xtics[middletics] - gapsize[1], xtics[bigtics] - (gapsize[1] + gapsize[3]))
        show.labels <- c(xticlab[littletics], midshowlab,xticlab[bigtics])
      } else {
        xlim <- c(min(x), max(x) - gapsize[1])
        bigtics <- which(xtics >= gap[2])
        show.at <- c(xtics[littletics], xtics[bigtics] - gapsize[1])
        show.labels <- c(xticlab[littletics], xticlab[bigtics])
      }
    }
  }
  ## plot batman results
  if (!is.null(BM$sFit) && !rerun) 
  {
    for (j in 1:length(sno))
    {
      if ((j%%n) == 1)
      { 
        if ((length(sno)-j)>=1) 
        {
          if (!missing(prefixFig))
            outpdf1 <- paste(saveFigDir, "/", prefixFig,"_specFit_", sno[j], "to",sno[j+n-1],"_",metaName,".",ptype, sep="")
          else
            outpdf1 <- paste(saveFigDir,"/specFit_",sno[j], "to",sno[j+n-1],"_",metaName,".",ptype, sep="")	           
          
          if ((!showPlot && overwriteFig) || (!showPlot && (!file.exists(outpdf1))))
          {
            pdf(outpdf1,20,15)  
            pdfdev = TRUE
          }
          else if (!showPlot && (file.exists(outpdf1) && !overwriteFig))
          {
            cat("\nCan't save figure, file \"", outpdf1, "\" already exists.\n")
            tmpOP <- strsplit(outpdf1, "[.]")
            outpdf1 <- paste(tmpOP[[1]][1], "_", format(Sys.time(), "%d_%b_%H_%M_%S"), ".", tmpOP[[1]][2], sep = "")
            cat("Figure saved in new file \"", outpdf1, "\".\n")
            pdf(outpdf1,20,15)  
            pdfdev = TRUE
          }
          else if(showPlot)
            x11(20,15)
          par(mfrow=c(n,1))	         		
        } else {
          if (!missing(prefixFig))
            outpdf1 <- paste(saveFigDir, "/", prefixFig, "_specFit_", sno[j], "_",metaName,".",ptype, sep="")
          else
            outpdf1 <- paste(saveFigDir,"/specFit_",sno[j],"_",metaName,".",ptype, sep="")
          
          if ((!showPlot && overwriteFig) || (!showPlot && (!file.exists(outpdf1))))
          {
            pdf(outpdf1,20,15)  
            pdfdev = TRUE
          }          
          else if (!showPlot && (file.exists(outpdf1) && !overwriteFig))
          {  
            cat("\nCan't save figure, file", outpdf1, "already exists.\n")
            tmpOP <- strsplit(outpdf1, "[.]")
            outpdf1 <- paste(tmpOP[[1]][1], "_", format(Sys.time(), "%d_%b_%H_%M_%S"), ".", tmpOP[[1]][2], sep = "")
            cat("Figure saved in new file \"", outpdf1, "\".\n")
            pdf(outpdf1,20,15)  
            pdfdev = TRUE
          }
          else
            x11(20,15)
        }
      } 
      i <- (ns*(j-1)+1)
      
      if (is.null(ytoIP))
        yto <- max(max(BM$sFit[pind,(i+1):(i+ns-1)]))
      
      if (yfrom > yto)
      {
        temp<-yfrom
        yfrom<-yto
        yto<-temp
      }      
      if (length(gap)>0)
      {    
        ## plot metabolites fit with gap
        ylim <- c(yfrom, yto)
        ytics <- pretty(ylim)
        yticlab <- ytics
        
        plot(BM$sFit[pind[littleones],i], BM$sFit[pind[littleones],i+1], xlim = rev(xlim), 
             ylim = ylim, axes = FALSE, lwd = 0.5, col = 4, lty = 1,
             type="l", xlab="ppm", ylab="Standardized Intensity",
             main=paste("NMR Spectrum ",sno[j],": ",BM$specTitle[2,j],sep=""))
        box()
        axis(2, at = ytics, labels = yticlab)
        axis(1, at = show.at, labels = show.labels)
        axis.break(1, gap[1], style = "zigzag")
        if (length(gapsize) > 2) {
          for (ig in 1:lgo)
          {
            axis.break(1, gap[ig*2+1] - middif[ig], style = "zigzag")
            lines(BM$sFit[pind[middleones[[ig]]],i]-middif[ig],BM$sFit[pind[middleones[[ig]]],i+1],col=4,lwd=0.5,lty=1)
            lines(BM$sFit[pind[middleones[[ig]]],i]-middif[ig],BM$sFit[pind[middleones[[ig]]],i+2],col=3,lwd=0.5,lty=1)
            lines(BM$sFit[pind[middleones[[ig]]],i]-middif[ig],BM$sFit[pind[middleones[[ig]]],i+3],col=2,lwd=0.5,lty=1)
            lines(BM$sFit[pind[middleones[[ig]]],i]-middif[ig],BM$sFit[pind[middleones[[ig]]],i+4],col=1,lwd=0.5,lty=1)
          }
          lines(BM$sFit[pind[bigones],i]-maxdif,BM$sFit[pind[bigones],i+1],col=4,lwd=0.5,lty=1)
          lines(BM$sFit[pind[littleones],i],BM$sFit[pind[littleones],i+2],col=3,lwd=0.5,lty=1)
          lines(BM$sFit[pind[bigones],i]-maxdif,BM$sFit[pind[bigones],i+2],col=3,lwd=0.5,lty=1)
          lines(BM$sFit[pind[littleones],i],BM$sFit[pind[littleones],i+3],col=2,lwd=0.5,lty=1)
          lines(BM$sFit[pind[bigones],i]-maxdif,BM$sFit[pind[bigones],i+3],col=2,lwd=0.5,lty=1)
          lines(BM$sFit[pind[littleones],i],BM$sFit[pind[littleones],i+4],col=1,lwd=0.5,lty=1)
          lines(BM$sFit[pind[bigones],i]-maxdif,BM$sFit[pind[bigones],i+4],col=1,lwd=0.5,lty=1)
          if (listMeta && nometa)
          {
            ## if listMeta is TRUE and missing metabolite name, plot all
            for (i2 in 1:nrow(BM$beta))
            {
              ytmp <- BM$beta[i2,j]*BM$metaTemp[pind,i2+(j-1)*nrow(BM$beta)]
              lines(BM$sFit[pind[littleones],i],ytmp[littleones],col=plotColour[i2],lwd = metaTmplwd, lty = metaTmplty)
              for (ig in 1:lgo)
                lines(BM$sFit[pind[middleones[[ig]]],i]-middif[ig],ytmp[middleones[[ig]]],col=plotColour[i2],lwd = metaTmplwd, lty = metaTmplty)
              
              lines(BM$sFit[pind[bigones],i]-maxdif,ytmp[bigones],col=plotColour[i2],lwd = metaTmplwd, lty = metaTmplty)
            }
            legend(placeLegend, c("Original Spectrum", "Metabolites Fit", "Wavelet Fit", "Fit Sum",
                                  row.names(BM$beta)), col=c(4,3,2,1,plotColour), ncol = 2, cex = cex1,
                   lty=c(1,1,1,1,rep(metaTmplty, nrow(BM$beta))),lwd = c(0.5,0.5,0.5,0.5,rep(metaTmplwd, nrow(BM$beta))))
          } else if (length(mind)!=0) {
            ## plot named metabolite
            ## lines(BM$beta[mind,j]*BM$metaTemp[pind,mind+(j-1)*nrow(BM$beta)],col=plotColour[mind], lwd = metaTmplwd, lty = metaTmplty )
            for (md in 1:length(mind))
            {
              ytmp <- BM$beta[mind[md],j]*BM$metaTemp[pind,mind[md]+(j-1)*nrow(BM$beta)]
              lines(BM$sFit[pind[littleones],i],ytmp[littleones],col=plotColour[md], lwd = metaTmplwd, lty = metaTmplty)
              for (ig in 1:lgo)
                lines(BM$sFit[pind[middleones[[ig]]],i]-middif[ig],ytmp[middleones[[ig]]],col=plotColour[md], lwd = metaTmplwd, lty = metaTmplty)
              lines(BM$sFit[pind[bigones],i]-maxdif,ytmp[bigones],col=plotColour[md], lwd = metaTmplwd, lty = metaTmplty)
            }
            legend(placeLegend, c("Original Spectrum", "Metabolites Fit", "Wavelet Fit", "Fit Sum",
                                  row.names(BM$beta)[mind]), col=c(4,3,2,1,plotColour), cex = cex,
                   lty=c(1,1,1,1,rep(metaTmplty, length(mind))),lwd = c(0.5,0.5,0.5,0.5,rep(metaTmplwd, length(mind))))
          } else {
            legend(placeLegend, c("Original Spectrum", "Metabolites Fit", "Wavelet Fit", "Fit Sum"), col=c(4,3,2,1), 
                   lty=c(1,1,1,1),lwd = c(0.5,0.5,0.5,0.5), cex = cex)
          }
        } else {
          lines(BM$sFit[pind[bigones],i]-(gapsize[1]),BM$sFit[pind[bigones],i+1],col=4,lwd=0.5,lty=1)
          lines(BM$sFit[pind[littleones],i],BM$sFit[pind[littleones],i+2],col=3,lwd=0.5,lty=1)
          lines(BM$sFit[pind[bigones],i]-(gapsize[1]),BM$sFit[pind[bigones],i+2],col=3,lwd=0.5,lty=1)
          lines(BM$sFit[pind[littleones],i],BM$sFit[pind[littleones],i+3],col=2,lwd=0.5,lty=1)
          lines(BM$sFit[pind[bigones],i]-(gapsize[1]),BM$sFit[pind[bigones],i+3],col=2,lwd=0.5,lty=1)
          lines(BM$sFit[pind[littleones],i],BM$sFit[pind[littleones],i+4],col=1,lwd=0.5,lty=1)
          lines(BM$sFit[pind[bigones],i]-(gapsize[1]),BM$sFit[pind[bigones],i+4],col=1,lwd=0.5,lty=1)
          
          if (listMeta && nometa)
          {
            ## if listMeta is TRUE and missing metabolite name, plot all
            for (i2 in 1:nrow(BM$beta))
            {
              ytmp <- BM$beta[i2,j]*BM$metaTemp[pind,i2+(j-1)*nrow(BM$beta)]
              lines(BM$sFit[pind[littleones],i],ytmp[littleones],col=plotColour[i2],lwd = metaTmplwd, lty = metaTmplty)
              lines(BM$sFit[pind[bigones],i]-(gapsize[1]),ytmp[bigones],col=plotColour[i2],lwd = metaTmplwd, lty = metaTmplty)
            }
            legend(placeLegend, c("Original Spectrum", "Metabolites Fit", "Wavelet Fit", "Fit Sum",
                                  row.names(BM$beta)), col=c(4,3,2,1,plotColour), ncol = 2, cex = cex1,
                   lty=c(1,1,1,1,rep(metaTmplty, nrow(BM$beta))),lwd = c(0.5,0.5,0.5,0.5,rep(metaTmplwd, nrow(BM$beta))))
          } else if (length(mind)!=0) {
            ## plot named metabolite
            ## lines(BM$beta[mind,j]*BM$metaTemp[pind,mind+(j-1)*nrow(BM$beta)],col=plotColour[mind], lwd = metaTmplwd, lty = metaTmplty )
            for (md in 1:length(mind))
            {
              ytmp <- BM$beta[mind[md],j]*BM$metaTemp[pind,mind[md]+(j-1)*nrow(BM$beta)]
              lines(BM$sFit[pind[littleones],i],ytmp[littleones],col=plotColour[md], lwd = metaTmplwd, lty = metaTmplty)
              lines(BM$sFit[pind[bigones],i]-(gapsize[1]),ytmp[bigones],col=plotColour[md], lwd = metaTmplwd, lty = metaTmplty)
            }
            
            legend(placeLegend, c("Original Spectrum", "Metabolites Fit", "Wavelet Fit", "Fit Sum",
                                  row.names(BM$beta)[mind]), col=c(4,3,2,1,plotColour), cex = cex,
                   lty=c(1,1,1,1,rep(metaTmplty, length(mind))),lwd = c(0.5,0.5,0.5,0.5,rep(metaTmplwd, length(mind))))
          } else {
            legend(placeLegend, c("Original Spectrum", "Metabolites Fit", "Wavelet Fit", "Fit Sum"), col=c(4,3,2,1), 
                   lty=c(1,1,1,1),lwd = c(0.5,0.5,0.5,0.5), cex = cex)
          }
        }
      } else {
        ## plot metabolites fit without gap
        plot(BM$sFit[pind,i],BM$sFit[pind,i+1],type="l",xlim=rev(range(BM$sFit[pind,i])),xlab="ppm",
             ylab="Standardized Intensity", main=paste("NMR Spectrum ",sno[j],": ",BM$specTitle[2,j],sep=""), 
             ylim = c(yfrom, yto), lwd = 0.5, col = 4, lty = 1)
        lines(BM$sFit[pind,i],BM$sFit[pind,i+2],col=3, lwd = 0.5, lty = 1)
        lines(BM$sFit[pind,i],BM$sFit[pind,i+3],col=2, lwd = 0.5, lty = 1)
        lines(BM$sFit[pind,i],BM$sFit[pind,i+4],col=1, lwd = 0.5, lty = 1)
        
        if (listMeta && nometa)
        {
          ## if listMeta is TRUE and missing metabolite name, plot all
          for (i2 in 1:nrow(BM$beta))
            lines(BM$sFit[pind,i],BM$beta[i2,j]*BM$metaTemp[pind,i2+(j-1)*nrow(BM$beta)],col=plotColour[i2], lwd = metaTmplwd, lty = metaTmplty )
          
          legend(placeLegend, c("Original Spectrum", "Metabolites Fit", "Wavelet Fit", "Fit Sum",
                                row.names(BM$beta)), col=c(4,3,2,1,plotColour), ncol = 2, cex = cex1,
                 lty=c(1,1,1,1,rep(metaTmplty, nrow(BM$beta))),lwd = c(0.5,0.5,0.5,0.5,rep(metaTmplwd, nrow(BM$beta))))
        } else if (length(mind)!=0) {
          ## plot named metabolite
          for (md in 1:length(mind))
          {
            lines(BM$sFit[pind,i],BM$beta[mind[md],j]*BM$metaTemp[pind,mind[md]+(j-1)*nrow(BM$beta)],col=plotColour[md], lwd = metaTmplwd, lty = metaTmplty )
          }
          legend(placeLegend, c("Original Spectrum", "Metabolites Fit", "Wavelet Fit", "Fit Sum",
                                row.names(BM$beta)[mind]), col=c(4,3,2,1,plotColour), cex = cex,
                 lty=c(1,1,1,1,rep(metaTmplty, length(mind))),lwd = c(0.5,0.5,0.5,0.5,rep(metaTmplwd, length(mind))))
        } else {
          legend(placeLegend, c("Original Spectrum", "Metabolites Fit", "Wavelet Fit", "Fit Sum"), col=c(4,3,2,1), 
                 lty=c(1,1,1,1),lwd = c(0.5,0.5,0.5,0.5), cex = cex)
        }
      }
      if ((length(sno) == j || !(j%%n)) && saveFig) {
        if (pdfdev)
        {
          pdfoff = dev.off()    
          pdfdev = FALSE
        }        
        else if (showPlot && (file.exists(outpdf1) && !overwriteFig))
        {  
          cat("\nCan't save figure, file", outpdf1, "already exists.\n")
          tmpOP <- strsplit(outpdf1, "[.]")
          outpdf1 <- paste(tmpOP[[1]][1], "_", format(Sys.time(), "%d_%b_%H_%M_%S"), ".", tmpOP[[1]][2], sep = "")
          cat("Figure saved in new file \"", outpdf1, "\".\n")
          df = dev.copy2pdf(device=x11, file = outpdf1)
        }
        else
          df = dev.copy2pdf(device=x11, file = outpdf1)
        
        
        #(file.exists(outpdf1) && !overwriteFig)
        #  cat("Can't save figure, file", outpdf1, "already exists.\n")
        #else
        #  df = dev.copy2pdf(device=x11, file = outpdf1)
      }
    }
  }
  ## plot batman rerun results
  else if (!is.null(BM$sFitRerun) && rerun) 
  {     
    outpdf2 <-NULL
    for (j in 1:length(sno))
    {
      ## set subplot
      if ((j%%n)==1)
      {
        if ((length(sno)-j)>=1) 
        {
          if (!missing(prefixFig))
            outpdf2 <- paste(saveFigDir, "/", prefixFig,"_specfitRerun_", sno[j], "to",sno[j+n-1],"_",metaName,".",ptype, sep="")
          else
            outpdf2 <- paste(saveFigDir,"/specfitRerun_",sno[j], "to",sno[j+n-1],"_",metaName,".",ptype, sep="")
          
          if ((!showPlot && overwriteFig) || (!showPlot && (!file.exists(outpdf2))))
          {
            pdf(outpdf2,20,15)   
            pdfdev = TRUE
          }       
          else if (!showPlot && (file.exists(outpdf2) && !overwriteFig))
          {  
            cat("\nCan't save figure, file", outpdf2, "already exists.\n")
            tmpOP <- strsplit(outpdf2, "[.]")
            outpdf2 <- paste(tmpOP[[1]][1], "_", format(Sys.time(), "%d_%b_%H_%M_%S"), ".", tmpOP[[1]][2], sep = "")
            cat("Figure saved in new file \"", outpdf2, "\".\n")
            pdf(outpdf2,20, 15)  
            pdfdev = TRUE
          } 
          else
            x11(20,15)

          par(mfrow=c(n,1))			
        } else {

          if (!missing(prefixFig))
            outpdf2 <- paste(saveFigDir, "/", prefixFig,"_specfitRerun_", sno[j], "_",metaName,".",ptype, sep="")
          else
            outpdf2 <- paste(saveFigDir,"/specfitRerun_",sno[j],"_",metaName,".",ptype, sep="")
          
          if ((!showPlot && overwriteFig) || (!showPlot && (!file.exists(outpdf2))))
          {
            pdf(outpdf2,20,15)  
            pdfdev = TRUE
          }         
          else if (!showPlot && (file.exists(outpdf2) && !overwriteFig))
          {  
            cat("\nCan't save figure, file", outpdf2, "already exists.\n")
            tmpOP <- strsplit(outpdf2, "[.]")
            outpdf2 <- paste(tmpOP[[1]][1], "_", format(Sys.time(), "%d_%b_%H_%M_%S"), ".", tmpOP[[1]][2], sep = "")
            cat("Figure saved in new file \"", outpdf2, "\".\n")
            pdf(outpdf2,20,15)  
            pdfdev = TRUE
          } 
          else
            x11(20,15)
        } 
      }
      i = ns*(j-1)+1
      
      if (is.null(ytoIP))
        yto <- max(max(BM$sFitRerun[pind,i+1]),max(BM$sFitRerun[pind,i+2]),max(BM$sFitRerun[pind,i+3]),max(BM$sFitRerun[pind,i+4]))
      
      if (yfrom > yto)
      {
        temp<-yfrom
        yfrom<-yto
        yto<-temp
      }
      if (length(gap)>0)
      {    
        ## plot metabolites fit with gap
        ylim <- c(yfrom, yto)
        ytics <- pretty(ylim)
        yticlab <- ytics
        
        plot(BM$sFitRerun[pind[littleones],i], BM$sFitRerun[pind[littleones],i+1], xlim = rev(xlim), 
             ylim = ylim, axes = FALSE, lwd = 0.5, col = 4, lty = 1,type="l", xlab="ppm", ylab="Standardized Intensity",
             main=paste("NMR Spectrum ",sno[j], ": ",BM$specTitle[2,j],"(Rerun)", sep=""))
        box()
        axis(2, at = ytics, labels = yticlab)
        axis(1, at = show.at, labels = show.labels)
        axis.break(1, gap[1], style = "zigzag")
        if (length(gapsize) > 2) {
          for (ig in 1:lgo)
          {
            axis.break(1, gap[ig*2+1] - middif[ig], style = "zigzag")
            lines(BM$sFitRerun[pind[middleones[[ig]]],i]-middif[ig],BM$sFitRerun[pind[middleones[[ig]]],i+1],col=4,lwd=0.5,lty=1)
            lines(BM$sFitRerun[pind[middleones[[ig]]],i]-middif[ig],BM$sFitRerun[pind[middleones[[ig]]],i+2],col=3,lwd=0.5,lty=1)
            lines(BM$sFitRerun[pind[middleones[[ig]]],i]-middif[ig],BM$sFitRerun[pind[middleones[[ig]]],i+3],col=2,lwd=0.5,lty=1)
            lines(BM$sFitRerun[pind[middleones[[ig]]],i]-middif[ig],BM$sFitRerun[pind[middleones[[ig]]],i+4],col=1,lwd=0.5,lty=1)
          }
          lines(BM$sFitRerun[pind[bigones],i]-maxdif,BM$sFitRerun[pind[bigones],i+1],col=4,lwd=0.5,lty=1)
          lines(BM$sFitRerun[pind[littleones],i],BM$sFitRerun[pind[littleones],i+2],col=3,lwd=0.5,lty=1)
          lines(BM$sFitRerun[pind[bigones],i]-maxdif,BM$sFitRerun[pind[bigones],i+2],col=3,lwd=0.5,lty=1)
          lines(BM$sFitRerun[pind[littleones],i],BM$sFitRerun[pind[littleones],i+3],col=2,lwd=0.5,lty=1)
          lines(BM$sFitRerun[pind[bigones],i]-maxdif,BM$sFitRerun[pind[bigones],i+3],col=2,lwd=0.5,lty=1)
          lines(BM$sFitRerun[pind[littleones],i],BM$sFitRerun[pind[littleones],i+4],col=1,lwd=0.5,lty=1)
          lines(BM$sFitRerun[pind[bigones],i]-maxdif,BM$sFitRerun[pind[bigones],i+4],col=1,lwd=0.5,lty=1)
          
          if (listMeta && nometa)
          {
            ## if listMeta is TRUE and missing metabolite name, plot all
            for (i2 in 1:nrow(BM$betaRerun))
            {
              ytmp <- BM$betaRerun[i2,j]*BM$metaTempRerun[pind,i2+(j-1)*nrow(BM$betaRerun)]
              lines(BM$sFitRerun[pind[littleones],i],ytmp[littleones],col=plotColour[i2],lwd = metaTmplwd, lty = metaTmplty)
              for (ig in 1:lgo)
                lines(BM$sFitRerun[pind[middleones[[ig]]],i]-middif[ig],ytmp[middleones[[ig]]],col=plotColour[i2],lwd = metaTmplwd, lty = metaTmplty)
              lines(BM$sFitRerun[pind[bigones],i]-maxdif,ytmp[bigones],col=plotColour[i2],lwd = metaTmplwd, lty = metaTmplty)
            }
            legend(placeLegend, c("Original Spectrum", "Metabolites Fit", "Wavelet Fit", "Fit Sum",
                                  row.names(BM$betaRerun)), col=c(4,3,2,1,plotColour), ncol = 2, cex = cex1,
                   lty=c(1,1,1,1,rep(metaTmplty, nrow(BM$betaRerun))),lwd = c(0.5,0.5,0.5,0.5,rep(metaTmplwd, nrow(BM$betaRerun))))
          } else if (length(mind)!=0) {
            ## plot named metabolite
            ## lines(BM$beta[mind,j]*BM$metaTemp[pind,mind+(j-1)*nrow(BM$beta)],col=plotColour[mind], lwd = metaTmplwd, lty = metaTmplty )
            for (md in 1:length(mind))
            {
              ytmp <- BM$betaRerun[mind[md],j]*BM$metaTempRerun[pind,mind[md]+(j-1)*nrow(BM$betaRerun)]
              lines(BM$sFitRerun[pind[littleones],i],ytmp[littleones],col=plotColour[md], lwd = metaTmplwd, lty = metaTmplty)
              for (ig in 1:lgo)
                lines(BM$sFitRerun[pind[middleones[[ig]]],i]-middif[ig],ytmp[middleones[[ig]]],col=plotColour[md], lwd = metaTmplwd, lty = metaTmplty)
              lines(BM$sFitRerun[pind[bigones],i]-maxdif,ytmp[bigones],col=plotColour[md], lwd = metaTmplwd, lty = metaTmplty)
            }
            legend(placeLegend, c("Original Spectrum", "Metabolites Fit", "Wavelet Fit", "Fit Sum",
                                  row.names(BM$betaRerun)[mind]), col=c(4,3,2,1,plotColour), cex = cex,
                   lty=c(1,1,1,1,rep(metaTmplty, length(mind))),lwd = c(0.5,0.5,0.5,0.5,rep(metaTmplwd, length(mind))))
          } else {
            legend(placeLegend, c("Original Spectrum", "Metabolites Fit", "Wavelet Fit", "Fit Sum"), col=c(4,3,2,1), 
                   lty=c(1,1,1,1),lwd = c(0.5,0.5,0.5,0.5), cex = cex)
          }
        } else {
          lines(BM$sFitRerun[pind[bigones],i]-(gapsize[1]),BM$sFitRerun[pind[bigones],i+1],col=4,lwd=0.5,lty=1)
          lines(BM$sFitRerun[pind[littleones],i],BM$sFitRerun[pind[littleones],i+2],col=3,lwd=0.5,lty=1)
          lines(BM$sFitRerun[pind[bigones],i]-(gapsize[1]),BM$sFitRerun[pind[bigones],i+2],col=3,lwd=0.5,lty=1)
          lines(BM$sFitRerun[pind[littleones],i],BM$sFitRerun[pind[littleones],i+3],col=2,lwd=0.5,lty=1)
          lines(BM$sFitRerun[pind[bigones],i]-(gapsize[1]),BM$sFitRerun[pind[bigones],i+3],col=2,lwd=0.5,lty=1)
          lines(BM$sFitRerun[pind[littleones],i],BM$sFitRerun[pind[littleones],i+4],col=1,lwd=0.5,lty=1)
          lines(BM$sFitRerun[pind[bigones],i]-(gapsize[1]),BM$sFitRerun[pind[bigones],i+4],col=1,lwd=0.5,lty=1)
          
          if (listMeta && nometa)
          {
            ## if listMeta is TRUE and missing metabolite name, plot all
            for (i2 in 1:nrow(BM$betaRerun))
            {
              ytmp <- BM$betaRerun[i2,j]*BM$metaTempRerun[pind,i2+(j-1)*nrow(BM$betaRerun)]
              lines(BM$sFitRerun[pind[littleones],i],ytmp[littleones],col=plotColour[i2],lwd = metaTmplwd, lty = metaTmplty)
              lines(BM$sFitRerun[pind[bigones],i]-(gapsize[1]),ytmp[bigones],col=plotColour[i2],lwd = metaTmplwd, lty = metaTmplty)
            }
            legend(placeLegend, c("Original Spectrum", "Metabolites Fit", "Wavelet Fit", "Fit Sum",
                                  row.names(BM$betaRerun)), col=c(4,3,2,1,plotColour), ncol = 2, cex = cex1,
                   lty=c(1,1,1,1,rep(metaTmplty, nrow(BM$betaRerun))),lwd = c(0.5,0.5,0.5,0.5,rep(metaTmplwd, nrow(BM$betaRerun))))
          } else if (length(mind)!=0) {
            ## plot named metabolite
            ## lines(BM$beta[mind,j]*BM$metaTemp[pind,mind+(j-1)*nrow(BM$beta)],col=plotColour[mind], lwd = metaTmplwd, lty = metaTmplty )
            for (md in 1:length(mind))
            {
              ytmp <- BM$betaRerun[mind[md],j]*BM$metaTempRerun[pind,mind[md]+(j-1)*nrow(BM$betaRerun)]
              lines(BM$sFitRerun[pind[littleones],i],ytmp[littleones],col=plotColour[md], lwd = metaTmplwd, lty = metaTmplty)
              lines(BM$sFitRerun[pind[bigones],i]-(gapsize[1]),ytmp[bigones],col=plotColour[md], lwd = metaTmplwd, lty = metaTmplty)
            }
            legend(placeLegend, c("Original Spectrum", "Metabolites Fit", "Wavelet Fit", "Fit Sum",
                                  row.names(BM$betaRerun)[mind]), col=c(4,3,2,1,plotColour), cex = cex,
                   lty=c(1,1,1,1,rep(metaTmplty, length(mind))),lwd = c(0.5,0.5,0.5,0.5,rep(metaTmplwd, length(mind))))
          } else {
            legend(placeLegend, c("Original Spectrum", "Metabolites Fit", "Wavelet Fit", "Fit Sum"), col=c(4,3,2,1), 
                   lty=c(1,1,1,1),lwd = c(0.5,0.5,0.5,0.5), cex = cex)
          }
        }
      } else {
        ## plot metabolites fit without gap
        plot(BM$sFitRerun[pind,i],BM$sFitRerun[pind,i+1],type="l",xlim=rev(range(BM$sFitRerun[pind,i])),xlab="ppm",
             ylab="Standardized Intensity", main=paste("NMR Spectrum ",sno[j], ": ",BM$specTitle[2,j],"(Rerun)", sep=""), 
             ylim = c(yfrom, yto), lwd = 0.5, col = 4, lty = 1)
        #axis(1, 1:length(pind), lab = format(BM$sFitRerun[pind,i]),xlim=rev(range(BM$sFitRerun[pind,i])))     
        lines(BM$sFitRerun[pind,i],BM$sFitRerun[pind,i+2],col=3, lwd = 0.5, lty = 1)
        lines(BM$sFitRerun[pind,i],BM$sFitRerun[pind,i+3],col=2, lwd = 0.5, lty = 1)
        lines(BM$sFitRerun[pind,i],BM$sFitRerun[pind,i+4],col=1, lwd = 0.5, lty = 1)
        
        if (listMeta  && nometa)
        {
          ## if listMeta is TRUE and missing metabolite name, plot all
          for (i2 in 1:nrow(BM$betaRerun))
            lines(BM$sFitRerun[pind,i],BM$betaRerun[i2,j]*BM$metaTempRerun[pind,i2+(j-1)*nrow(BM$betaRerun)],col=plotColour[i2], lwd = metaTmplwd, lty = metaTmplty )
          legend(placeLegend, c("Original Spectrum", "Metabolites Fit", "Wavelet Fit", "Fit Sum",
                                row.names(BM$betaRerun)), col=c(4,3,2,1,plotColour), ncol = 2, cex = cex1,
                 lty=c(1,1,1,1,rep(metaTmplty, nrow(BM$betaRerun))),lwd = c(0.5,0.5,0.5, 0.5,rep(metaTmplwd, nrow(BM$betaRerun))))
        } else if (length(mind)!=0) {
          ## plot named metabolite
          for (md in 1:length(mind))
          {
            lines(BM$sFitRerun[pind,i],BM$betaRerun[mind[md],j]*BM$metaTempRerun[pind,mind[md]+(j-1)*nrow(BM$betaRerun)],col=plotColour[md], lwd = metaTmplwd, lty = metaTmplty )
          }
          legend(placeLegend, c("Original Spectrum", "Metabolites Fit", "Wavelet Fit", "Fit Sum",
                                row.names(BM$betaRerun)[mind]), col=c(4,3,2,1,plotColour), cex = cex,
                 lty=c(1,1,1,1,rep(metaTmplty, length(mind))),lwd = c(0.5,0.5,0.5,0.5,rep(metaTmplwd, length(mind))))
        } else {
          legend(placeLegend, c("Original Spectrum", "Metabolites Fit", "Wavelet Fit", "Fit Sum"), col=c(4,3,2,1), 
                 lty=c(1,1,1,1),lwd = c(0.5,0.5,0.5,0.5), cex = cex)
        }
      }
      ## save plot
      if ((length(sno) == j || !(j%%n)) && saveFig) 
      {
        if (pdfdev)
        {
          pdfoff = dev.off()    
          pdfdev = FALSE
        }      
        else if (showPlot && (file.exists(outpdf2) && !overwriteFig))
        {  
          cat("\nCan't save figure, file", outpdf2, "already exists.\n")
          tmpOP <- strsplit(outpdf2, "[.]")
          outpdf2 <- paste(tmpOP[[1]][1], "_", format(Sys.time(), "%d_%b_%H_%M_%S"), ".", tmpOP[[1]][2], sep = "")
          cat("Figure saved in new file \"", outpdf2, "\".\n")
          df = dev.copy2pdf(device=x11, file = outpdf2)
        }
        else
          df = dev.copy2pdf(device=x11, file = outpdf2)
        
        ## if (file.exists(outpdf2) && !(overwriteFig))
        ##   cat("Can't save figure, file", outpdf2, "already exists.\n")
        ## else
        ##   df = dev.copy2pdf(device=x11, file = outpdf2)
      }
    }
  } else {
    cat("No results found.\n")
  }
  warnRead<-options(warn = warnDef)
} 
