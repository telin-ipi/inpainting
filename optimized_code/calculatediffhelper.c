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

void calculatediffhelper(const int M, const int N, 
			const double *img, const int nlab, const double *lab,
            const int L, const double *neighbourLabels, const double *ind1, 
            const double *ind2, const int gap, double *diff) 
{
    register int l,k,p,x,y,xx,yy,i,imask,j,jmask,ndx,ndxPatch,ndxMask,numPix=M*N,sizePatch=2*gap+1,sizeOverlap=(gap+1)*(2*gap+1);
    double patchErr=0.0,err=0.0,minErr=1000000000.0;
    double *patch1, *patch2;
    
    patch1 = malloc(3*sizeOverlap*sizeof(double)); 
    patch2 = malloc(3*sizeOverlap*sizeof(double)); 
    /* foreach label of the current node*/
    for (l=0; l<=nlab-1; l++) {
        /*MatLab indexes x and y (from 1)*/
        p=(int)lab[l]-1; y=p/M+1; p=p%M; x=p+1;
        
        ndx = 0;
        for (j=y-gap,jmask=1; j<=y+gap; j++,jmask++) {
            for (i=x-gap,imask=1; i<=x+gap; i++,imask++) {
                ndxPatch = i-1 + M*(j-1);
                ndxMask = imask-1 + sizePatch*(jmask-1);
                if (ind2[ndxMask]) {
                    patch1[ndx] = img[ndxPatch];
                    patch1[ndx+sizeOverlap] = img[ndxPatch+=numPix];
                    patch1[ndx+2*sizeOverlap] = img[ndxPatch+=numPix];
                    ndx++;
                }
            }
        }
        /* compare with all the labels of the neighbouring node which was pruned*/
        for (k=0; k<=L-1; k++) {
            p=(int)neighbourLabels[k]-1; yy=p/M+1; p=p%M; xx=p+1; 
            
            ndx = 0;
            for (j=yy-gap,jmask=1; j<=yy+gap; j++,jmask++) {
                for (i=xx-gap,imask=1; i<=xx+gap; i++,imask++) {
                    ndxPatch = i-1 + M*(j-1);
                    ndxMask = imask-1 + sizePatch*(jmask-1);
                    if (ind1[ndxMask]) {
                        patch2[ndx] = img[ndxPatch];
                        patch2[ndx+sizeOverlap] = img[ndxPatch+=numPix];
                        patch2[ndx+2*sizeOverlap] = img[ndxPatch+=numPix];
                        ndx++;
                    }
                }
            }
            /*** Calculate patch error ***/
            for (i=0; i<=3*sizeOverlap-1; i++) { 
                err=patch1[i] - patch2[i]; patchErr += err*err;
            }
            /*** Update ***/
            if (patchErr < minErr) {
                minErr = patchErr;
            }
            patchErr = 0.0;
        }
        
        diff[l] = minErr;
        minErr=1000000000.0;
    }
    free(patch1);
    free(patch2);
}

/* diff = calculatediffhelper(M, N, img, nlab, lab, L, neighbourLabels, ind1, ind2, gap); */
void mexFunction(int nlhs,mxArray *plhs[],int nrhs,const mxArray *prhs[]) 
{
  int M,N,nlab, L, gap, i;
  double *img, *lab, *neighbourLabels, *diff, *ind1,*ind2;

  /* Extract the inputs */
  M = (int)mxGetScalar(prhs[0]);
  N = (int)mxGetScalar(prhs[1]);
  img = mxGetPr(prhs[2]);
  nlab = (int)mxGetScalar(prhs[3]);
  lab = mxGetPr(prhs[4]);
  L = (int)mxGetScalar(prhs[5]);
  neighbourLabels = mxGetPr(prhs[6]);
  ind1 = mxGetPr(prhs[7]);
  ind2 = mxGetPr(prhs[8]);
  gap = (int)mxGetScalar(prhs[9]);
 
  /* Setup the output */
  plhs[0] = mxCreateDoubleMatrix(1, nlab, mxREAL);
  diff = mxGetPr(plhs[0]);
  for (i=0; i<=nlab-1; ++i)
      diff[i] = 0.0;
  

  /* Do the actual work */
  calculatediffhelper(M, N, img, nlab, lab, L, neighbourLabels, ind1, ind2, gap, diff);
}
