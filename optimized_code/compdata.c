/**
 * A best exemplar finder.  Scans over the entire image (using a
 * sliding window) and finds the exemplar which minimizes the sum
 * squared error (SSE) over the to-be-filled pixels in the target
 * patch. 
 *
 * @author Sooraj Bhat
 */
#include "mex.h"
#include <limits.h>
#include <math.h>

void compdata(const int M, const int N, 
			const double *img, const double *patch, 
			const mxLogical *mask, const int nlab, const double *lab,
			const int gap, double *diff) 
{
    register int l,p,x,y,ii,jj,ii2,jj2,ndxLabel,ndxPatch,numPix=M*N,patchSize=2*gap+1,numPixPatch=patchSize*patchSize;
    double patchErr=0.0,err=0.0;

    /* foreach patch */
    for (l=0; l<=nlab-1; l++) {
        /*MatLab indexes x and y (from 1)*/
        p=(int)lab[l]-1; y=p/M+1; p=p%M; x=p+1;
        /*** Calculate patch error ***/
        /* foreach pixel in the current patch (ii2,jj2) */
        for (jj=y-gap,jj2=1; jj<=y+gap; jj++,jj2++) { 
            for (ii=x-gap,ii2=1; ii<=x+gap; ii++,ii2++) {   
                ndxLabel = ii-1+M*(jj-1);
                ndxPatch=ii2-1+patchSize*(jj2-1);
                if (mask[ndxPatch]) {
                    err=img[ndxLabel        ] - patch[ndxPatch             ]; patchErr += err*err;
                    err=img[ndxLabel+=numPix] - patch[ndxPatch+=numPixPatch]; patchErr += err*err;
                    err=img[ndxLabel+=numPix] - patch[ndxPatch+=numPixPatch]; patchErr += err*err;
                }
            }
        }
        /*** Update ***/
        diff[l] = patchErr;
        patchErr = 0.0;
    }
}

/* [diff, priority] = compdata(M, N, img, patch, mask, nlab, lab, gap); */
void mexFunction(int nlhs,mxArray *plhs[],int nrhs,const mxArray *prhs[]) 
{
  int M,N,nlab, gap, i;
  double *img, *patch, *diff, *lab;
  mxLogical *mask;

  /* Extract the inputs */
  M = (int)mxGetScalar(prhs[0]);
  N = (int)mxGetScalar(prhs[1]);
  img = mxGetPr(prhs[2]);
  patch = mxGetPr(prhs[3]);
  mask = mxGetLogicals(prhs[4]);
  nlab = (int)mxGetScalar(prhs[5]);
  lab = mxGetPr(prhs[6]);
  gap = (int)mxGetScalar(prhs[7]);
 
  /* Setup the output */
  plhs[0] = mxCreateDoubleMatrix(1, nlab, mxREAL);
  diff = mxGetPr(plhs[0]);
  for (i=0; i<=nlab-1; i++)
      diff[i] = 0.0;
  

  /* Do the actual work */
  compdata(M, N, img, patch, mask, nlab, lab, gap, diff);
}
