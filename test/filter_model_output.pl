my $instruction_index = -1;
while (<>) {
  if (/^# PC/ .. /ILLEGAL OPCODE/) {
    s/^# //;
    my @words = split;
    if ($instruction_index == -1) {
      $instruction_index = $#words;
      print;
    } else {
      for my  $i ($instruction_index .. $#words) {
        $words[$i] = '';
      }
      print join(" ", @words), "\n";;
    }
  }
}

