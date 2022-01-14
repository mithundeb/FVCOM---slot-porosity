# FVCOM with slot-porosity

Here, we have modified some of the FVCOM 3.2 (http://fvcom.smast.umassd.edu/fvcom/) modules to incorporate a slot algorithm in the mass and momentum conservation equation to improve the present-day limitations in tidal wetland marsh surface wetting and drying. These modifications are primarily done to eliminate artificial ponding effects observed in hydrodynamic model simulations in coastal salt marsh systems. For more details about the changes in governing equations, model implementation, and validation, we encourage the reader to see chapter 4 of this [document](https://cpb-us-w2.wpmucdn.com/sites.udel.edu/dist/0/7241/files/2018/01/CACR-20-04_reduced.pdf).

It is required to download FVCOM version 3.2 and replace these exact subroutines from the source directory to compile the executable.  
