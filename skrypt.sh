#!/bin/bash

calc_min=1
calc_max=1
calc_avg=1
postfix=".mod"

# Help
usage() {
    cat << EOF
Usage: $0 [options] [file1.csv file2.csv ...]
Options:
    -h          Show help message
    --no-min    Do not calculate min
    --no-max    Do not calculate max
    --no-avg    Do not calculate avg
    -p POSTFIX   Use POSTFIX for the output file instead of (.mod)
EOF
exit 0
}

# Definicja argumentów
files=()
while [[ $# -gt 0 ]]; do 
    case "$1" in 
    -h) usage 
    ;;
    --no-min)
    calc_min=0
    shift 
    ;;
    --no-max)
    calc_max=0
    shift 
    ;;
    --no-avg)
    calc_avg=0
    shift 
    ;;
    -p)
    shift


    if [[ -n "$1" ]]; then
        postfix="$1"
        shift
    else
        echo "Error. This cannot be empty."
        exit 1
    fi
    ;;
    -*)
    echo "Error. Unknown option"
    usage
    ;;
    *)
    
    #pliki do tablicy
    files+=("$1")
    shift
    ;;

esac
done

# Jezeli brak plikow
if [ ${#files[@]} -eq 0 ]; then
    echo "Input data with standard input. Ctrl + D to end."
    # tempfile=$(mktemp "/tmp/plik_XXXX.mod")
    tempfile=$(mktemp "plik_XXXX.mod")
    cat > "$tempfile"
    files=("$tempfile")
fi

# Procesujemy
for file in "${files[@]}"; do
    # Walidacja
    if [ ! -s "$file" ]; then
        echo "File '$file' does not exist"
        continue
    fi

    output="${file%.*}${postfix}.csv"
    
    LC_NUMERIC=en_US.UTF-8 awk -v calc_min="$calc_min" -v calc_max="$calc_max" -v calc_avg="$calc_avg" '
    BEGIN  {
        FS = OFS = ",";
        # Zmienna do obliczeń
        first_line = 1;
    }
    
    # Procesowanie headerów
    NR==1 {
        nfields = NF;
        # Zakładając, że pierwsza linia to nagłówki
        for(i=1; i<=NF; i++){
            header[i] = $i
            numeric[i] = 1
            sum[i] = 0
            count[i] = 0
        }
        print $0;  # Fix na nagłówki
        first_line = 0;
        next;
    }
    
    # Procesowanie kolumn
    {
        skip_row = 0
        for(i=1; i<=NF; i++){
            # Walidacja komórek
            if($i ~ /^-?[0-9]+([.][0-9]+)?$/){
                value = $i + 0;
                sum[i] += value
                count[i]++;
                if(count[i]==1){
                    min[i]=value;
                    max[i]=value;
                }
                else{
                    if(value<min[i]){
                        min[i] = value;
                    }
                    if(value>max[i]){
                        max[i] = value;
                    }
                }
            }
            else{
                numeric[i] = 0;
            }

            # Fix na puste wiersze
            if ($i == "") {
                skip_row = 1
            }
        }

        # Fix na puste wiersze cd.
        if(skip_row == 0){
            print $0;
        }
    }
    # Min, max, avg
    END {
        if(calc_min=="1"){
            row = "";
            for(i=1; i<=nfields; i++){
                if(numeric[i] && count[i] >0){
                    row = row (i==1 ? "" : OFS) min[i];
                }
                else{
                    row = row (i==1 ? "" : OFS);
                }
            }
            print row;
        }

        if(calc_max=="1"){
            row = "";
            for(i=1; i<=nfields; i++){
                if(numeric[i] && count[i] >0){
                    row = row (i==1 ? "" : OFS) max[i];
                }
                else{
                    row = row (i==1 ? "" : OFS);
                }
            }
            print row;
        }

        if(calc_avg=="1"){
            row = "";
            for(i=1; i<=nfields; i++){
                if(numeric[i] && count[i] >0){
                    avg = sum[i] / count[i];
                    row = row (i==1 ? "" : OFS) sprintf("%.1f", avg);
                }
                else{
                    row = row (i==1 ? "" : OFS);
                }
            }
            print row;
        }
    }
    ' "$file" > "$output"

    echo "File saved as: $output"
done

# Kasowanie tempa pliku jeżeli jest pusty
if [ -n "$tempfile" ] && [ -f "$tempfile" ]; then
    rm "$tempfile"
fi
