String generatePGN(Map meta, List<String> moves) {
  final buffer = StringBuffer();

  buffer.writeln('[White "${meta["white"]}"]');
  buffer.writeln('[Black "${meta["black"]}"]');
  if (meta["event"].toString().isNotEmpty)
    buffer.writeln('[Event "${meta["event"]}"]');
  if (meta["location"].toString().isNotEmpty)
    buffer.writeln('[Site "${meta["location"]}"]');
  if (meta["date"].toString().isNotEmpty)
    buffer.writeln('[Date "${meta["date"]}"]');

  buffer.writeln('[Result "${meta["result"]}"]');
  buffer.writeln();

  // Moves
  for (int i = 0; i < moves.length; i += 2) {
    int num = (i ~/ 2) + 1;
    String white = moves[i];
    String black = (i + 1) < moves.length ? moves[i + 1] : "";

    buffer.write("$num. $white ");
    if (black.isNotEmpty) buffer.write("$black ");
  }

  buffer.write(meta["result"]);

  return buffer.toString();
}
