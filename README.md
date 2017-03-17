# auto_reorder

 Automate the removal of the virtual orbitals in
 Molpro/MRCC calculation.

 Creates an AWK script which can act on the integral part of the fort.55 file

 We need to remove orbitals above a certain cutoff value (say, 30.0 au)
 from the integral file fort.55 and the vector in fort.56

 You can pre-input everything in a text file and then hand it over to the
 script like ./auto_reorder.sh < inputfile


 (c) Paul Jerabek, 2017 (Massey University, Auckland, New Zealand)

      with creative help (design of the AWK script) by Lukas Pasteka

