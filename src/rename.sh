for file in *.v; do
    mv -- "$file" "${file%.v}.sv"
done