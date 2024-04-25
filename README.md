# Refubium-tlab

Toolbox for preparing tlab-generated data for publication on the Refubium.

## Usage
First, create a data description with the corresponding data_description_template.tex:

```shell
pdflatex --interaction=nonstopmode data_description_example.tex
cp data_description_example.pdf data_description_archive/
```

Second, build tables with the bash-script build_table.sh.
Run the following commands in the terminal:

```shell
chmod u=rwx build_table.sh   
./build_table.sh ./example_file.nc
```
This will generate a table either for velocity/scalar/ibm variables, depending on the netcdf file provided.

Third, merge all pdf-files with:
```shell
pdfunite a.pdf b.pdf merge.pdf
```