plotDiagnosticScatter <- function(BM, binWidth = 0.018, cexID = 0.5, saveFig = TRUE, saveFigDir = BM$outputDir, 
                                  prefixFig, rerun = FALSE, placeLegend = "topright", overwriteFig = FALSE, showPlot)
{
  ## written by Dr. Jie Hao, Imperial College London
  ## Diagnostic scatter plot of batman metabolites fit vs NMR spectra bins or minimum wavelet fit 
  if (missing(BM))
    return(cat("Please input batman data list.\n"))
  
  warnDef<-options("warn")$warn
  warnRead<-options(warn = -1)
  
  bound <- binWidth/2
  ptype <- "pdf"
  pdfdev = FALSE
  
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
  
  nmult <- dim(BM$delta)[1]
  nsp <- dim(BM$delta)[2]
  nmult2 <- dim(BM$deltaSam)[2]
  myVector <- strsplit(colnames(BM$deltaSam), "_")
  multiName <- matrix(data = NA, ncol = nmult2/nmult, nrow = nmult)
  multiPpm <- matrix(data = 0, ncol = nmult2/nmult, nrow = nmult)
  for (i in 1:(nmult2/nmult))
  {
    for (j in 1:nmult)
    {
      multiName[j,i] <-myVector[[(i-1)*nmult + j]][1]
      if (substr(myVector[[(i-1)*nmult + j]][2],1,1) == '.')
      {
        myVector[[(i-1)*nmult + j]][2] <-substr(myVector[[(i-1)*nmult + j]][2],2,nchar(myVector[[(i-1)*nmult + j]][2]))
      }
      multiPpm[j,i] <-as.numeric(myVector[[(i-1)*nmult + j]][2])    
    }  
  }
  
  deltaT <- multiPpm + BM$delta
  
  if (!is.null(BM$sFit) && !rerun) 
  {
    sFit <- BM$sFit
    beta <- BM$beta
    rerunString <- NULL
  }  else if (!is.null(BM$sFitRerun) && rerun) 
  {
    sFit <- BM$sFitRerun
    beta <- BM$betaRerun
    rerunString <- '(rerun)'
  }  else {
    cat("No results found.\n")
  }
  
  sFitbins<- matrix(data = 0, ncol = dim(sFit)[2], nrow = dim(deltaT)[1])
  #sFitmin<- matrix(data = 0, ncol = dim(sFit)[2], nrow = dim(deltaT)[1])
  sFitbinsMax <- matrix(data = 0, ncol = 5, nrow = dim(deltaT)[1])
  for (i in 1:dim(deltaT)[1])
  {
    for (j in 1:dim(deltaT)[2])
    {
      dTmin <- deltaT[i,j]-bound
      dTmax <- deltaT[i,j]+bound
      
      pind<-which(sFit[,1]<=dTmax & sFit[,1]>=dTmin)
      cS <- colSums(sFit[pind,(1+5*(j-1)):(5*j)])
      dim(cS) <- c(1,length(cS)) 
      sFitbins[i,(1+5*(j-1)):(5*j)] <- cS
      cSm <- min(sFit[pind,(5*j-1)])
      sFitbins[i,(5*j)] <- cSm
    }
  }
  
  for (i in 1:dim(deltaT)[1])
  {
    ## normalise
    for (j2 in 2:5)
    {
      sFitbinsMax[i,j2] <- max(sFitbins[i,seq(j2,dim(sFitbins)[2],by=5)])
      #cat('sfitma=',sFitbinsMax[i,j2] )

        ma <- abs(min(sFitbins[i,seq(j2,dim(sFitbins)[2],by=5)]))
        if (abs(sFitbinsMax[i,j2]) < ma)
        {
          sFitbinsMax[i,j2] <- ma
         }
      sFitbins[i,seq(j2,dim(sFitbins)[2],by=5)] <-sFitbins[i,seq(j2,dim(sFitbins)[2],by=5)]/sFitbinsMax[i,j2]
   #   cat(',i= ', i,'j2=',j2,'max=', max(sFitbins[i,seq(j2,dim(sFitbins)[2],by=5)]),'min=', min(sFitbins[i,seq(j2,dim(sFitbins)[2],by=5)]), '\n')  
    }
  } 
  
  metaName <- rownames(beta)
  multiName1 <- multiName[,1]
  
  mName <-NULL
  for (i in 1:length(multiName1))
  {
    mName<-rbind(mName, gsub("[:.:]","-",multiName1[i]))
  }  
  
  multiName2 <- gsub("[:.:]", " ", multiName1)
  metaName2 <- gsub("[:.:]", " ", metaName)
  metaName2 <- gsub("-", " ", metaName2)
  sFitnames <- names(sFit)[1:5]
  
  sFitnames <- gsub("[:.:]", " ", sFitnames)
  sFitnames[5] <-'Wavelet Fit min'
  nMeta <- length(metaName2)
  multiNameLeg <- colnames(BM$deltaSam)[1:length(multiName2)]
  multiNameLeg <- gsub("_", " ", multiNameLeg)
  
  
  for (i2 in 1:nMeta)
  {
    if (!missing(prefixFig))
      outpdf1 <- paste(saveFigDir, "/", prefixFig,"_diagScatter_", metaName2[i2], rerunString,,".",ptype, sep="")
    else
      outpdf1 <- paste(saveFigDir,"/diagScatter_", metaName2[i2], rerunString,".",ptype, sep="")
    
    if ((!showPlot && overwriteFig) || (!showPlot && (!file.exists(outpdf1))))
    {
        pdf(outpdf1)  
        pdfdev = TRUE
    }          
    else if (!showPlot && (file.exists(outpdf1) && !overwriteFig))
    {  
      cat("\nCan't save figure, file", outpdf1, "already exists.\n")
      tmpOP <- strsplit(outpdf1, "[.]")
      outpdf1 <- paste(tmpOP[[1]][1], "_", format(Sys.time(), "%d_%b_%H_%M_%S"), ".", tmpOP[[1]][2], sep = "")
      cat("Figure saved in new file \"", outpdf1, "\".\n")
      pdf(outpdf1)  
      pdfdev = TRUE
    }
    else
      x11()
    
    mid <- which(metaName2[i2] == multiName2) 
    if (length(mid) <5)
    {
      par(mfrow=c(2,2), oma = c(0, 0, 3, 0))
    } else {
      par(mfrow=c(3,3), oma = c(0, 0, 3, 0))
    }
    for (i in 2:5)
    {
      co <- 1
      legendName <- NULL
      
      for (j in mid)
      {
        if (co == 1)
        {
          if (i<5)
          {
            plot(t(beta[i2,]),((sFitbins[j,seq(i, dim(sFitbins)[2], 5)])), col=co,
                 pch = co, type = "p", cex = 0.02, 
                 ylim = c(min(sFitbins[mid,seq(i, dim(sFitbins)[2], 5)]),max(sFitbins[mid,seq(i, dim(sFitbins)[2], 5)])),
                 xlab = "Batman fit (relative concentration)", ylab = "Integrated bin intensity",
                 main=paste(sFitnames[i],":", metaName2[i2], rerunString, sep =""))
          } else {
            plot(t(beta[i2,]),((sFitbins[j,seq(i, dim(sFitbins)[2], 5)])), col=co,
                 pch = co, type = "p", cex = 0.02, 
                 ylim = c(min(sFitbins[mid,seq(i, dim(sFitbins)[2], 5)]),max(sFitbins[mid,seq(i, dim(sFitbins)[2], 5)])),
                 #ylim = c(min(((sFitbins[j,seq(i, dim(sFitbins)[2], 5)]))), max(((sFitbins[mid,seq(i, dim(sFitbins)[2], 5)])))*1.2),
                 xlab = "Batman fit (relative concentration)", ylab = "NMR intensity",
                 main=paste(sFitnames[i], ":", metaName2[i2], rerunString, sep =""))
          }
          text(t(beta[i2,]),(sFitbins[j,seq(i, dim(sFitbins)[2], 5)]), col = co, labels = 1:dim((t(beta[i2,])))[1], cex = cexID)
          
          co <- co +1
        }
        else {
          points(t(beta[i2,]),(sFitbins[j,seq(i, dim(sFitbins)[2], 5)]), col = co, pch = co, cex = 0.02)
          text(t(beta[i2,]),(sFitbins[j,seq(i, dim(sFitbins)[2], 5)]), col = co, labels = 1:dim((t(beta[i2,])))[1], cex = cexID)
          co <- co+1
        }
        legendName <- rbind(legendName, multiNameLeg[j])
      }      
      legend(placeLegend, legend = legendName, col = 1:co, 
             lty = rep(-1, co), pch = 1:co,  cex = 0.5)
      box()
      
    }
    if (saveFig)
    {
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
      
      #if (file.exists(outpdf1) && !(overwriteFig))
      #{ 
      # cat("Can't save figure, file", outpdf1, "already exists.\n")
      #} else {
      #  df = dev.copy2pdf(device=x11, file = outpdf1)
      #}
    }
  }
  warnRead<-options(warn = warnDef)
}
