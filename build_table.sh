#!/bin/bash

# create log-folder
TIMESTAMP=`date +%Y%m%d-%H%M%S`
LOGDIR=./logs
# LOGDIR=./logs-$TIMESTAMP
mkdir -p $LOGDIR

# get list of variables from netCDF file (1. option: new netcdf, 2. option: old netcdf)
vlist=$(ncdump -h "$1" | grep -E 'double|float' | cut -d'(' -f 1 | cut -d' ' -f2)
# vlist=`ncdump -h "$1" | grep double | cut -d'(' -f 1 | cut -d' ' -f2`

# check the netcdf file type [flow/scal/ibm] 
# go through the database file using awk and extract the lines needed
rm -f $LOGDIR/cmd1
for v in ${vlist[@]}; do
    if [ $v = "rS" ]; then
        TYPE="scal"
        HEADER="Vertical scalar profiles"
        DTYPE="data_base_scal.txt"
    elif [ $v = "rU" ]; then
        TYPE="flow"
        HEADER="Vertical velocity profiles"
        DTYPE="data_base_flow.txt"
    elif [ $v = "eps2d" ]; then
        TYPE="ibm"
        HEADER="Horizontal distribution of roughness elements"
        DTYPE="data_base_ibm.txt"
    fi
    echo "/^${v} / {print}" >> $LOGDIR/cmd1
done

echo "netcdf-file type: $TYPE $HEADER"

awk -f $LOGDIR/cmd1 $DTYPE > $LOGDIR/vars

# get information which groups are there 
groups=`awk -F'&' '!seen[$2]++' $LOGDIR/vars | cut -d'&' -f 2 `

# extract lines from tmp1 by group and build the ordered file tmp2
rm -f $LOGDIR/vars_sorted
for g in $groups; do
    gmatch="${g} "
    echo "\$2 ~ /${gmatch}/ { print }" > $LOGDIR/cmd
    awk -F'&' -f $LOGDIR/cmd $LOGDIR/vars >> $LOGDIR/vars_sorted
done 

# remove duplicate lines from file 
awk '!visited[$0]++' $LOGDIR/vars_sorted > $LOGDIR/vars_deduplicated 

#  we need to take care of the underscores in the variable names
# (we replace them by \_ so the variable names are printed as their netCDF names) 
cut -d'&' -f 1 $LOGDIR/vars_deduplicated | sed -e's/_/\\_/g' > $LOGDIR/var_list
cut -d'&' -f 2- $LOGDIR/vars_deduplicated >  $LOGDIR/var_info
paste -d '&' $LOGDIR/var_list $LOGDIR/var_info > $LOGDIR/vars_sorted2

old_group="NOGROUP"

echo " &  &  \\\\" > var_list.tex 
echo "\\toprule\multicolumn{3}{c}{\\cellcolor{gray!60} {\\bf  \large{$HEADER} } }  \\\\ \\midrule &  &  \\\\" >> var_list.tex

while IFS= read -r line; do
    group=`echo $line | cut -d'&' -f 2`
    if [ $group != $old_group ]; then
	echo "NEW GROUP $group" 
	echo "\\toprule\multicolumn{3}{c}{\\cellcolor{gray!20} {\\bf  $group } }  \\\\ \\midrule" >> var_list.tex
	
    fi
    echo $line | cut -d'&' -f1 > $LOGDIR/c1
    echo $line | cut -d'&' -f3-> $LOGDIR/c3p
    paste -d'&' $LOGDIR/c1 $LOGDIR/c3p > $LOGDIR/new
    cat $LOGDIR/new >> var_list.tex

    old_group=$group 
done < $LOGDIR/vars_sorted2
echo "\\bottomrule" >> var_list.tex

# build the latex table 
TABNAME="tab_$TYPE.tex"
echo $TABNAME
cat <<EOF > $TABNAME
\documentclass{standalone}
\usepackage{amsmath} 
\usepackage{amssymb} 
\usepackage{booktabs}
\usepackage{tabularx}  
\usepackage{colortbl}
\usepackage{xcolor} 
\newcommand{\fa}[1]{$\left\langle{#1}\right\rangle$}
\newcommand{\ra}[1]{$\overline{#1}$} 
\newcommand{\p}{\partial} 
\begin{document}
\begin{tabularx}{20cm}{m{5cm} m{7cm} m{7cm}}
\input{var_list.tex} 
\end{tabularx} 
\end{document} 
EOF

# build the pdf 
pdflatex --interaction=nonstopmode $TABNAME >& $LOGDIR/tex_log 

exit