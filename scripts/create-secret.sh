#!/bin/sh

read -p "Enter file name: " file_name

echo "Enter secrets pairs in the format key=value. Press enter to finish"
while read -p "" secret_pair; do
    if [ -z "$secret_pair" ]; then
        break
    fi
    secrets+="$secret_pair\n"
done

echo -e $secrets > $file_name.enc
nix shell nixpkgs#sops \
    --command sops \
    --encrypt \
    --in-place \
    --input-type dotenv \
    --output-type dotenv \
    $file_name.enc
