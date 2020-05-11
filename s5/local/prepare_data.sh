#!/usr/bin/env bash
# Copyright 2015-2016  Sarah Flora Juan
# Copyright 2016  Johns Hopkins University (Author: Yenda Trmal)
# Copyright 2018  Yuan-Fu Liao, National Taipei University of Technology
#                 AsusTek Computer Inc. (Author: Alex Hung)

# Apache 2.0

set -e -o pipefail

train_dir=train/wav
eval_dir=test/wav


. ./path.sh
. parse_options.sh

for x in $train_dir $eval_dir; do
  if [ ! -d "$x" ] ; then
    echo >&2 "The directory $x does not exist"
  fi
done

if [ -z "$(command -v dos2unix 2>/dev/null)" ]; then
    echo "dos2unix not found on PATH. Please install it manually."
    exit 1;
fi

# have to remove previous files to avoid filtering speakers according to cmvn.scp and feats.scp
rm -rf   data/local/train
mkdir -p data/local/train


# make utt2spk, wav.scp and text
find -L $train_dir -name *.wav -exec sh -c 'x={}; y=$(basename -s .wav $x); printf "%s %s\n"     $y $y' \; | sed 's/\xe3\x80\x80\|\xc2\xa0//g' | dos2unix > data/train/utt2spk
find -L $train_dir -name *.wav -exec sh -c 'x={}; y=$(basename -s .wav $x); printf "%s %s\n"     $y $x' \; | sed 's/\xe3\x80\x80\|\xc2\xa0//g' | dos2unix > data/train/wav.scp
find -L $train_dir -name *.txt -exec sh -c 'x={}; y=$(basename -s .txt $x); printf "%s " $y; cat $x'    \; | sed 's/\xe3\x80\x80\|\xc2\xa0//g' | dos2unix > data/train/text

# fix_data_dir.sh fixes common mistakes (unsorted entries in wav.scp,
# duplicate entries and so on). Also, it regenerates the spk2utt from
# utt2spk
utils/fix_data_dir.sh data/train



# for LM training
echo "cp data/train/text data/local/train/text for language model training"
cat data/train/text | awk '{$1=""}1;' | awk '{$1=$1}1;' > data/local/train/text

# preparing EVAL set.
find -L $eval_dir     -name *.wav -exec sh -c 'x={}; y=$(basename -s .wav $x); printf "%s %s\n"     $y $y' \; | sed 's/\xe3\x80\x80\|\xc2\xa0//g' | dos2unix > data/test/utt2spk
find -L $eval_dir     -name *.wav -exec sh -c 'x={}; y=$(basename -s .wav $x); printf "%s %s\n"     $y $x' \; | sed 's/\xe3\x80\x80\|\xc2\xa0//g' | dos2unix > data/test/wav.scp
find -L $eval_dir     -name *.txt -exec sh -c 'x={}; y=$(basename -s .txt $x); printf "%s " $y; cat $x'    \; | sed 's/\xe3\x80\x80\|\xc2\xa0//g' | dos2unix > data/test/text
utils/fix_data_dir.sh data/test

echo "Data preparation completed."
exit 0;
